// server.js
const express = require('express');
const fs = require('fs');
const path = require('path');
const os = require('os');

// When packaged with pkg, point native bindings to files next to the exe
if (process.pkg) {
  const exeDir = path.dirname(process.execPath);
  if (!process.env.SQLITE3_BINARY_PATH) {
    try {
      process.env.SQLITE3_BINARY_PATH = path.join(exeDir, 'node_sqlite3.node');
    } catch (_) { /* ignore */ }
  }
  // Point bcrypt to the native binding next to the exe
  try {
    const bcryptBinding = path.join(exeDir, 'bcrypt_lib.node');
    if (fs.existsSync(bcryptBinding)) {
      // Monkey-patch the bcrypt binding resolution
      const Module = require('module');
      const originalResolveFilename = Module._resolveFilename;
      Module._resolveFilename = function (request, parent, isMain, options) {
        if (request.includes('bcrypt_lib.node')) {
          return bcryptBinding;
        }
        return originalResolveFilename.call(this, request, parent, isMain, options);
      };
    }
  } catch (_) { /* ignore */ }
}

const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const sqlite3 = require('sqlite3').verbose();
const { open } = require('sqlite');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');
const xss = require('xss-clean');
const securityAudit = require('./security-audit');

// Respect external dotenv path when provided (e.g., packaged mode)
const dotenvPath = process.env.DOTENV_CONFIG_PATH;
if (dotenvPath && fs.existsSync(dotenvPath)) {
  require('dotenv').config({ path: dotenvPath });
} else {
  require('dotenv').config();
}

const app = express();

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '10mb' }));
app.use(xss());

// Rate limiting for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: 'Too many authentication attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    console.log(`Rate limit exceeded for IP: ${req.ip}`);
    securityAudit.logRateLimitExceeded(req.ip, req.path);
    res.status(429).json({
      error: 'Too many authentication attempts. Please try again in 15 minutes.',
    });
  },
});

// Rate limiting for general API endpoints
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/vault', apiLimiter);

// Brute force protection - track failed login attempts
const failedLoginAttempts = new Map();
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_DURATION = 15 * 60 * 1000; // 15 minutes

function checkBruteForce(identifier) {
  const now = Date.now();
  const attempts = failedLoginAttempts.get(identifier);

  if (!attempts) return { allowed: true, attemptsLeft: MAX_FAILED_ATTEMPTS };

  // Clean up old attempts
  const recentAttempts = attempts.filter((time) => now - time < LOCKOUT_DURATION);
  failedLoginAttempts.set(identifier, recentAttempts);

  if (recentAttempts.length >= MAX_FAILED_ATTEMPTS) {
    const oldestAttempt = Math.min(...recentAttempts);
    const timeLeft = Math.ceil((LOCKOUT_DURATION - (now - oldestAttempt)) / 1000 / 60);
    securityAudit.logBruteForceDetected(identifier, identifier.split('-')[0], recentAttempts.length);
    return { allowed: false, timeLeft };
  }

  return { allowed: true, attemptsLeft: MAX_FAILED_ATTEMPTS - recentAttempts.length };
}

function recordFailedAttempt(identifier) {
  const attempts = failedLoginAttempts.get(identifier) || [];
  attempts.push(Date.now());
  failedLoginAttempts.set(identifier, attempts);
}

function clearFailedAttempts(identifier) {
  failedLoginAttempts.delete(identifier);
}

// Clean up old failed attempts periodically
setInterval(() => {
  const now = Date.now();
  for (const [identifier, attempts] of failedLoginAttempts.entries()) {
    const recentAttempts = attempts.filter((time) => now - time < LOCKOUT_DURATION);
    if (recentAttempts.length === 0) {
      failedLoginAttempts.delete(identifier);
    } else {
      failedLoginAttempts.set(identifier, recentAttempts);
    }
  }
}, 5 * 60 * 1000); // Clean up every 5 minutes

let db; // will be assigned after init

// Ensure required secrets exist; if missing, generate and persist to .env when possible
function ensureEnv() {
  let changed = false;
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.trim() === '') {
    const bytes = crypto.randomBytes(32);
    process.env.JWT_SECRET = bytes.toString('hex');
    changed = true;
  }
  if (!process.env.VAULT_KEY || Buffer.from(process.env.VAULT_KEY, 'base64').length !== 32) {
    const key = crypto.randomBytes(32);
    process.env.VAULT_KEY = key.toString('base64');
    changed = true;
  }
  if (!process.env.DB_PATH || process.env.DB_PATH.trim() === '') {
    const appLocal = process.env.LOCALAPPDATA || process.env.USERPROFILE || os.homedir();
    const fallbackDir = appLocal ? path.join(appLocal, 'DaManage') : path.join(process.cwd(), 'data');
    const fallbackDb = path.join(fallbackDir, 'usdm.db');
    process.env.DB_PATH = fallbackDb;
    changed = true;
  }
  // Persist back to .env if DOTENV_CONFIG_PATH is set and file is writable
  if (changed && process.env.DOTENV_CONFIG_PATH) {
    try {
      const envPath = process.env.DOTENV_CONFIG_PATH;
      let current = '';
      try { current = fs.readFileSync(envPath, 'utf8'); } catch { }
      const lines = current.split(/\r?\n/).filter(Boolean);
      const map = new Map(lines.map((l) => {
        const idx = l.indexOf('=');
        if (idx === -1) return [l, ''];
        return [l.slice(0, idx), l.slice(1 + idx)];
      }));
      map.set('JWT_SECRET', process.env.JWT_SECRET);
      map.set('VAULT_KEY', process.env.VAULT_KEY);
      map.set('DB_PATH', process.env.DB_PATH);
      const out = Array.from(map.entries()).map(([k, v]) => `${k}=${v}`).join('\n');
      fs.writeFileSync(envPath, out, 'utf8');
      console.log(' Secrets generated and written to .env');
    } catch (e) {
      console.warn('Could not persist generated secrets to .env:', e.message);
    }
  }
}

async function initDB() {
  const dbFile = process.env.DB_PATH || process.env.DB_FILE || path.join(__dirname, 'data', 'usdm.db');
  const dir = path.dirname(dbFile);
  console.log('Using SQLite DB file:', dbFile);
  if (!fs.existsSync(dir)) {
    console.log('Creating directory for DB:', dir);
    fs.mkdirSync(dir, { recursive: true });
  }
  const sqlite = await open({ filename: dbFile, driver: sqlite3.Database });
  await sqlite.exec('PRAGMA foreign_keys = ON;');
  // Apply schema
  const schemaPath = path.join(__dirname, 'schema.sql');
  try {
    const schema = fs.readFileSync(schemaPath, 'utf8');
    await sqlite.exec(schema);
  } catch (e) {
    console.warn('Schema load/apply warning:', e.message);
  }
  // Provide a helper similar to mysql2 .promise().execute
  db = {
    async execute(sql, params = []) {
      const isSelect = /^\s*select/i.test(sql);
      if (isSelect) {
        const rows = await sqlite.all(sql, params);
        return [rows];
      }
      const result = await sqlite.run(sql, params);
      return [{ changes: result.changes, lastID: result.lastID }];
    },
  };
  console.log('Connected to SQLite at', dbFile);
}

// Input validation middleware
const validateSignup = [
  body('username')
    .trim()
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .matches(/^[a-zA-Z0-9_-]+$/)
    .withMessage('Username can only contain letters, numbers, underscores, and hyphens'),
  body('password')
    .isLength({ min: 12 })
    .withMessage('Password must be at least 12 characters long')
    .matches(/[a-z]/)
    .withMessage('Password must contain at least one lowercase letter')
    .matches(/[A-Z]/)
    .withMessage('Password must contain at least one uppercase letter')
    .matches(/[0-9]/)
    .withMessage('Password must contain at least one number')
    .matches(/[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]/)
    .withMessage('Password must contain at least one special character'),
];

const validateLogin = [
  body('username').trim().notEmpty().withMessage('Username is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

const validateVaultItem = [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

app.post('/signup', authLimiter, validateSignup, async (req, res) => {
  // Check validation errors
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: errors.array().map((e) => e.msg).join('. '),
      details: errors.array(),
    });
  }

  const { username, password } = req.body;

  try {
    const [existing] = await db.execute(
      'SELECT id FROM users WHERE username = ?',
      [username],
    );

    if (existing.length > 0) {
      return res.status(409).json({ error: 'Username already taken' });
    }

    // Use higher bcrypt rounds for password manager (12 rounds)
    const hashedPassword = await bcrypt.hash(password, 12);
    await db.execute(
      'INSERT INTO users (username, password_hash) VALUES (?, ?)',
      [username, hashedPassword],
    );

    console.log(`New user registered: ${username}`);
    securityAudit.logSignup(username, req.ip, true);
    res.status(201).json({ message: 'User registered successfully!' });
  } catch (err) {
    console.error('Server error:', err);
    securityAudit.logSignup(username, req.ip, false, err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

const PORT = Number(process.env.PORT || 3000);
ensureEnv();
initDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(` Backend running on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('SQLite init error:', err);
    process.exit(1);
  });

app.post('/login', authLimiter, validateLogin, async (req, res) => {
  // Check validation errors
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: errors.array().map((e) => e.msg).join('. '),
    });
  }

  const { username, password } = req.body;
  const identifier = `${req.ip}-${username}`;

  // Check brute force protection
  const bruteForceCheck = checkBruteForce(identifier);
  if (!bruteForceCheck.allowed) {
    console.log(`Brute force protection triggered for ${username} from IP ${req.ip}`);
    securityAudit.logFailedLogin(username, req.ip, 'Brute force protection triggered');
    return res.status(429).json({
      error: `Too many failed login attempts. Please try again in ${bruteForceCheck.timeLeft} minutes.`,
    });
  }

  try {
    const [rows] = await db.execute(
      'SELECT id, password_hash FROM users WHERE username = ?',
      [username],
    );

    if (rows.length === 0) {
      recordFailedAttempt(identifier);
      console.log(`Failed login attempt for non-existent user: ${username}`);
      securityAudit.logFailedLogin(username, req.ip, 'Invalid username');
      // Use generic message to prevent user enumeration
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const user = rows[0];

    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      recordFailedAttempt(identifier);
      const attemptsLeft = bruteForceCheck.attemptsLeft - 1;
      console.log(`Failed login attempt for user: ${username}. Attempts left: ${attemptsLeft}`);
      securityAudit.logFailedLogin(username, req.ip, 'Invalid password');
      return res.status(401).json({
        error: 'Invalid username or password',
        attemptsLeft: attemptsLeft > 0 ? attemptsLeft : 0,
      });
    }

    // Clear failed attempts on successful login
    clearFailedAttempts(identifier);

    const token = jwt.sign(
      {
        sub: user.id,
        username,
        iat: Math.floor(Date.now() / 1000),
      },
      process.env.JWT_SECRET || 'dev_jwt_secret_change_me',
      { expiresIn: '2h' },
    );

    console.log(`Successful login for user: ${username}`);
    securityAudit.logLogin(username, req.ip, true);
    securityAudit.logTokenIssued(user.id, username, '2h');
    res.status(200).json({
      message: 'Login successful!',
      token,
      expiresIn: 7200, // 2 hours in seconds
    });
  } catch (err) {
    console.error('Login error: ', err);
    securityAudit.logLogin(username, req.ip, false, err.message);
    res.status(500).json({ error: 'Internal server error' });
  }
});

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  console.log(' Authorization header received:', header);

  const parts = header.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    console.log(' Malformed or missing Authorization header');
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const payload = jwt.verify(parts[1], process.env.JWT_SECRET);
    req.userId = payload.sub;
    console.log('Authenticated user ID:', req.userId);
    next();
  } catch (e) {
    console.log(' JWT verification failed:', e.message);
    securityAudit.logTokenValidationFailed(e.message, parts[1]);
    return res.status(401).json({ error: 'Unauthorized' });
  }
}

function encryptSecret(plaintext) {
  const key = Buffer.from(process.env.VAULT_KEY || '', 'base64');
  if (!key || key.length !== 32) {
    return null;
  }
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const enc = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, enc]).toString('base64');
}

function decryptSecret(b64) {
  const key = Buffer.from(process.env.VAULT_KEY || '', 'base64');
  if (!key || key.length !== 32) {
    return null;
  }
  const buf = Buffer.from(b64, 'base64');
  const iv = buf.subarray(0, 12);
  const tag = buf.subarray(12, 28);
  const enc = buf.subarray(28);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  const dec = Buffer.concat([decipher.update(enc), decipher.final()]);
  return dec.toString('utf8');
}

app.post('/vault', auth, validateVaultItem, async (req, res) => {
  // Check validation errors
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: errors.array().map((e) => e.msg).join('. '),
    });
  }

  const {
    title, username, url, password, notes,
  } = req.body;
  const enc = encryptSecret(password);
  if (!enc) {
    return res.status(500).json({ error: 'Vault not configured' });
  }
  try {
    await db.execute(
      'INSERT INTO vault_items (user_id, title, username, url, password_encrypted, notes) VALUES (?, ?, ?, ?, ?, ?)',
      [req.userId, title, username || null, url || null, enc, notes || null],
    );
    res.status(201).json({ message: 'Created' });
  } catch (e) {
    console.error('Vault create error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/vault', auth, async (req, res) => {
  try {
    const [rows] = await db.execute(
      'SELECT id, title, username, url, password_encrypted, notes, created_at, updated_at FROM vault_items WHERE user_id = ? ORDER BY created_at DESC',
      [req.userId],
    );
    const items = rows.map((r) => ({
      id: r.id,
      title: r.title,
      username: r.username,
      url: r.url,
      password: (() => { try { return decryptSecret(r.password_encrypted); } catch { return null; } })(),
      notes: r.notes,
      created_at: r.created_at,
      updated_at: r.updated_at,
    }));
    res.json(items);
  } catch (e) {
    console.error('Vault list error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/vault/:id', auth, async (req, res) => {
  const {
    title, username, url, password, notes,
  } = req.body || {};
  try {
    let enc = null;
    if (typeof password === 'string') {
      enc = encryptSecret(password);
      if (!enc) return res.status(500).json({ error: 'Vault not configured' });
    }
    const fields = [];
    const values = [];
    if (title !== undefined) { fields.push('title = ?'); values.push(title); }
    if (username !== undefined) { fields.push('username = ?'); values.push(username); }
    if (url !== undefined) { fields.push('url = ?'); values.push(url); }
    if (notes !== undefined) { fields.push('notes = ?'); values.push(notes); }
    if (enc !== null) { fields.push('password_encrypted = ?'); values.push(enc); }
    fields.push('updated_at = CURRENT_TIMESTAMP');
    if (fields.length === 0) return res.status(400).json({ error: 'No updates' });
    values.push(req.userId, req.params.id);
    const sql = `UPDATE vault_items SET ${fields.join(', ')} WHERE user_id = ? AND id = ?`;
    const [result] = await db.execute(sql, values);
    if ((result.changes || 0) === 0) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Updated' });
  } catch (e) {
    console.error('Vault update error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/vault/:id', auth, async (req, res) => {
  try {
    const [result] = await db.execute(
      'DELETE FROM vault_items WHERE user_id = ? AND id = ?',
      [req.userId, req.params.id],
    );
    if ((result.changes || 0) === 0) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Deleted' });
  } catch (e) {
    console.error('Vault delete error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});
