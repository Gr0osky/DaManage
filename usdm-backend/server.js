// server.js
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const cors = require('cors');

const app = express();


app.use(cors());
app.use(express.json()); 


const db = mysql.createConnection({
  host: 'localhost',
  user: 'flutter_user',
  password: 'secure_password_123',
  database: 'usdm_app' 
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

const PORT = 3000;
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

    res.status(200).json({message: "Login successfull!"})

  } catch(err){
    console.error("Login error: ", err)
    res.status(500).json({error: "Internal server error"})
  }
});