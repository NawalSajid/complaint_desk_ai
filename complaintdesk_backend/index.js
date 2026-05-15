// ComplaintDesk.AI Backend

require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const cors = require('cors');

const app = express();

// Middlewares

app.use(cors());
app.use(express.json());

// Environment variables

const PORT = process.env.PORT || 5000;
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_USER = process.env.DB_USER || 'root';
const DB_PASSWORD = process.env.DB_PASSWORD || '';
const DB_NAME = process.env.DB_NAME || 'complaintdesk_ai';

// MySQL Connection

const db = mysql.createConnection({
  host: DB_HOST,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
});

db.connect(err => {
  if (err) {
    console.error('❌ Database connection failed:', err);
    process.exit(1);
  } else {
    console.log('✅ MySQL connected');

    // Create users table if not exists
    db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role ENUM('user','admin') NOT NULL DEFAULT 'user',
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Ensure legacy databases also have role column
    db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS role ENUM('user','admin') NOT NULL DEFAULT 'user'
    `);

    // Create complaints table if not exists
    db.query(`
      CREATE TABLE IF NOT EXISTS complaints (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        category VARCHAR(50) NOT NULL,
        description TEXT NOT NULL,
        document VARCHAR(255),
        status VARCHAR(50) DEFAULT 'New',
        priority VARCHAR(50) DEFAULT 'Normal',
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
  }
});

// Test API

app.get('/', (req, res) => {
  res.send('ComplaintDesk.AI Backend is running');
});

// REGISTER API

app.post('/api/register', async (req, res) => {
  const { name, email, password, role } = req.body;
  const safeRole = role === 'admin' ? 'admin' : 'user';
  const normalizedEmail = (email || '').trim().toLowerCase();
  if (!name || !email || !password)
    return res.status(400).json({ message: 'All fields are required' });

  db.query('SELECT * FROM users WHERE LOWER(TRIM(email)) = ?', [normalizedEmail], async (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    if (results.length > 0) return res.status(400).json({ message: 'Email already registered' });

    const hashedPassword = await bcrypt.hash(password, 10);
    db.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, normalizedEmail, hashedPassword, safeRole],
      (err, result) => {
        if (err) return res.status(500).json({ message: 'Database error' });

        res.status(201).json({
          message: 'User registered successfully',
          user: { id: result.insertId, name, email: normalizedEmail, role: safeRole },
        });
      }
    );
  });
});

// LOGIN API

app.post('/api/login', (req, res) => {
  const { email, password, role } = req.body;
  const requestedRole = role === 'admin' ? 'admin' : 'user';
  const normalizedEmail = (email || '').trim().toLowerCase();
  if (!email || !password)
    return res.status(400).json({ message: 'Email and password required' });

  db.query('SELECT * FROM users WHERE LOWER(TRIM(email)) = ?', [normalizedEmail], async (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    if (results.length === 0) return res.status(401).json({ message: 'Invalid email or password' });

    const user = results[0];
    // Support both properly hashed passwords and legacy plain-text records.
    let isMatch = false;
    if (typeof user.password === 'string' && user.password.startsWith('$2')) {
      isMatch = await bcrypt.compare(password, user.password);
    } else {
      isMatch = password === user.password;
      // Optional auto-migration to bcrypt after successful legacy login.
      if (isMatch) {
        const newHashed = await bcrypt.hash(password, 10);
        db.query('UPDATE users SET password = ? WHERE id = ?', [newHashed, user.id]);
      }
    }

    if (!isMatch) return res.status(401).json({ message: 'Invalid email or password' });

    if ((user.role || 'user') !== requestedRole) {
      return res.status(403).json({ message: 'Access denied for selected role' });
    }

    res.status(200).json({
      message: 'Login successful',
      userId: user.id,
      role: user.role || 'user',
      user: { id: user.id, name: user.name, email: user.email, role: user.role || 'user' },
    });
  });
});

// GET USER PROFILE API

app.get('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  if (isNaN(userId))
    return res.status(400).json({ message: 'Invalid user ID' });

  db.query(
    'SELECT id, name, email FROM users WHERE id = ?',
    [userId],
    (err, results) => {
      if (err) return res.status(500).json({ message: 'Database error' });
      if (results.length === 0)
        return res.status(404).json({ message: 'User not found' });

      res.json(results[0]);
    }
  );
});

// UPDATE USER NAME API

app.put('/api/users/:id', (req, res) => {
  const userId = parseInt(req.params.id);
  const { name } = req.body;

  if (isNaN(userId))
    return res.status(400).json({ message: 'Invalid user ID' });

  if (!name || name.trim() === '')
    return res.status(400).json({ message: 'Name is required' });

  db.query(
    'UPDATE users SET name = ? WHERE id = ?',
    [name.trim(), userId],
    (err, result) => {
      if (err) return res.status(500).json({ message: 'Database error' });
      if (result.affectedRows === 0)
        return res.status(404).json({ message: 'User not found' });

      res.json({ message: 'Name updated successfully' });
    }
  );
});

// ADD COMPLAINT API

app.post('/api/complaints', (req, res) => {
  const { user_id, category, description, document } = req.body;

  if (!user_id || !category || !description)
    return res.status(400).json({ message: 'All fields are required' });

  const uid = parseInt(user_id);
  if (isNaN(uid)) return res.status(400).json({ message: 'Invalid user ID' });

  db.query(
    'INSERT INTO complaints (user_id, category, description, document) VALUES (?, ?, ?, ?)',
    [uid, category, description, document || null],
    (err, result) => {
      if (err) {
        console.error('❌ Complaint insert error:', err);
        return res.status(500).json({ message: 'Database error' });
      }

      res.status(201).json({
        message: 'Complaint added successfully',
        complaint: {
          id: result.insertId,
          user_id: uid,
          category,
          description,
          document: document || null,
          status: 'New',
          priority: 'Normal',
          created_at: new Date(),
        },
      });
    }
  );
});

// GET COMPLAINTS API

app.get('/api/complaints', (req, res) => {
  const userId = parseInt(req.query.user_id);
  if (isNaN(userId)) return res.status(400).json({ message: 'Invalid user ID' });

  db.query(
    'SELECT * FROM complaints WHERE user_id = ? ORDER BY created_at DESC',
    [userId],
    (err, results) => {
      if (err) {
        console.error('❌ Complaint fetch error:', err);
        return res.status(500).json({ message: 'Database error' });
      }

      res.json(results.map(c => ({
        id: c.id,
        user_id: c.user_id,
        category: c.category,
        description: c.description,
        document: c.document,
        status: c.status,
        priority: c.priority,
        created_at: c.created_at,
      })));
    }
  );
});

// Start Server

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});



