// server.js
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
require('dotenv').config();

const app = express();


app.use(cors());
app.use(express.json()); 


const db = mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'flutter_user',
  password: process.env.DB_PASSWORD || 'secure_password_123',
  database: process.env.DB_NAME || 'usdm_app'
});

db.connect(err => {
  if (err) {
    console.error('❌ MySQL connection error:', err);
    process.exit(1);
  }
  console.log('Connected to MySQL');
});

app.post('/signup', async (req, res) => {

  const { username, password } = req.body || {};

  if (!username || !password) {
    return res.status(400).json({ error: "Username and password are required" });
  }
  if (password.length < 5) {
    return res.status(400).json({ error: "Password must be at least 5 characters" });
  }

  try {
    const [existing] = await db.promise().execute(
      "SELECT id FROM users WHERE username = ?",
      [username]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: "Username already taken" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    await db.promise().execute(
      "INSERT INTO users (username, password_hash) VALUES (?, ?)",
      [username, hashedPassword]
    );

    res.status(201).json({ message: "User registered successfully!" });
  } catch (err) {
    console.error('Server error:', err);
    res.status(500).json({ error: "Internal server error" });
  }
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => {
  console.log(` Backend running on http://localhost:${PORT}`);
});

app.post('/login', async (req, res) => {
  const {username, password} = req.body || {};

  if (!username || !password) {
    return res.status(400).json({ error: "Username and password are required" });
  }
  if (password.length < 5) {
    return res.status(400).json({ error: "Password must be at least 5 characters" });
  }

  try{
    const [rows] = await db.promise().execute(
      "SELECT id, password_hash FROM users WHERE username = ?",
      [username]
    )
    if(rows.length == 0){
      return res.status(404).json({error: "Username not found"})
    }

    const user = rows[0]

    const passwordMatch = await bcrypt.compare(password, user.password_hash)

    if(!passwordMatch){
      return res.status(401).json({error: "Incorrect password"})
    }

    const token = jwt.sign(
      { sub: user.id },
      process.env.JWT_SECRET || 'dev_jwt_secret_change_me',
      { expiresIn: '2h' }
    );

    res.status(200).json({message: "Login successfull!", token})

  } catch(err){
    console.error("Login error: ", err)
    res.status(500).json({error: "Internal server error"})
  }
});

function auth(req, res, next) {
  const header = req.headers['authorization'] || '';
  const parts = header.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  try {
    const payload = jwt.verify(parts[1], process.env.JWT_SECRET || 'dev_jwt_secret_change_me');
    req.userId = payload.sub;
    next();
  } catch (e) {
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

app.post('/vault', auth, async (req, res) => {
  const { title, username, url, password, notes } = req.body || {};
  if (!title || !password) {
    return res.status(400).json({ error: 'title and password are required' });
  }
  const enc = encryptSecret(password);
  if (!enc) {
    return res.status(500).json({ error: 'Vault not configured' });
  }
  try {
    await db.promise().execute(
      'INSERT INTO vault_items (user_id, title, username, url, password_encrypted, notes) VALUES (?, ?, ?, ?, ?, ?)',
      [req.userId, title, username || null, url || null, enc, notes || null]
    );
    res.status(201).json({ message: 'Created' });
  } catch (e) {
    console.error('Vault create error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/vault', auth, async (req, res) => {
  try {
    const [rows] = await db.promise().execute(
      'SELECT id, title, username, url, password_encrypted, notes, created_at, updated_at FROM vault_items WHERE user_id = ? ORDER BY created_at DESC',
      [req.userId]
    );
    const items = rows.map(r => ({
      id: r.id,
      title: r.title,
      username: r.username,
      url: r.url,
      password: (() => { try { return decryptSecret(r.password_encrypted) } catch { return null } })(),
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
  const { title, username, url, password, notes } = req.body || {};
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
    if (fields.length === 0) return res.status(400).json({ error: 'No updates' });
    values.push(req.userId, req.params.id);
    const sql = `UPDATE vault_items SET ${fields.join(', ')} WHERE user_id = ? AND id = ?`;
    const [result] = await db.promise().execute(sql, values);
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Updated' });
  } catch (e) {
    console.error('Vault update error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/vault/:id', auth, async (req, res) => {
  try {
    const [result] = await db.promise().execute(
      'DELETE FROM vault_items WHERE user_id = ? AND id = ?',
      [req.userId, req.params.id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Deleted' });
  } catch (e) {
    console.error('Vault delete error:', e);
    res.status(500).json({ error: 'Internal server error' });
  }
});