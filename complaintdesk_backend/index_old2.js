//Before sorting complaints priority-wise
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

    // Store user feedback
    db.query(`
      CREATE TABLE IF NOT EXISTS feedback (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // Store admin remarks per complaint status update
    db.query(`
      CREATE TABLE IF NOT EXISTS complaint_remarks (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        complaint_id INT NOT NULL,
        admin_remark TEXT,
        status VARCHAR(50) NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE
      )
    `);

    // Persist admin settings
    db.query(`
      CREATE TABLE IF NOT EXISTS admin_settings (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email_notifications TINYINT(1) NOT NULL DEFAULT 1,
        push_notifications TINYINT(1) NOT NULL DEFAULT 1,
        high_priority_alerts TINYINT(1) NOT NULL DEFAULT 1,
        auto_assign TINYINT(1) NOT NULL DEFAULT 0,
        resolution_deadline_hours INT NOT NULL DEFAULT 48,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    db.query(
      `INSERT INTO admin_settings (id, email_notifications, push_notifications, high_priority_alerts, auto_assign, resolution_deadline_hours)
       SELECT 1, 1, 1, 1, 0, 48
       WHERE NOT EXISTS (SELECT 1 FROM admin_settings WHERE id = 1)`
    );
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

app.post('/api/complaints', async (req, res) => {
  const { user_id, category, description, document } = req.body;

  if (!user_id || !category || !description)
    return res.status(400).json({ message: 'All fields are required' });

  const uid = parseInt(user_id);
  if (isNaN(uid)) return res.status(400).json({ message: 'Invalid user ID' });

  // Get priority prediction from NLP model
  let priority = 'Normal';
  try {
    const aiRes = await fetch('http://127.0.0.1:8000/predict', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: description }),
    });
    if (aiRes.ok) {
      const data = await aiRes.json();
      priority = data.priority || 'Normal';
    }
  } catch (e) {
    console.error('⚠️ AI priority prediction failed, using default:', e.message);
  }

  db.query(
    'INSERT INTO complaints (user_id, category, description, document, priority) VALUES (?, ?, ?, ?, ?)',
    [uid, category, description, document || null, priority],
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
          priority,
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

// USER FEEDBACK API
app.post('/api/feedback', (req, res) => {
  const userId = parseInt(req.body.user_id);
  const message = (req.body.message || '').toString().trim();

  if (isNaN(userId)) return res.status(400).json({ message: 'Invalid user ID' });
  if (!message) return res.status(400).json({ message: 'Feedback message is required' });

  db.query(
    'INSERT INTO feedback (user_id, message) VALUES (?, ?)',
    [userId, message],
    (err, result) => {
      if (err) {
        console.error('❌ Feedback insert error:', err);
        return res.status(500).json({ message: 'Database error' });
      }
      res.status(201).json({ message: 'Feedback submitted', id: result.insertId });
    }
  );
});

// ADMIN OVERVIEW API
app.get('/api/admin/overview', (req, res) => {
  const overviewQuery = `
    SELECT
      (SELECT COUNT(*) FROM complaints) AS total_complaints,
      (SELECT COUNT(*) FROM complaints WHERE status = 'Pending' OR status = 'New') AS pending_complaints,
      (SELECT COUNT(*) FROM complaints WHERE status = 'In Progress' OR status = 'In-Progress' OR status = 'in_progress') AS in_progress_complaints,
      (SELECT COUNT(*) FROM complaints WHERE status = 'Resolved') AS resolved_complaints,
      (SELECT COUNT(*) FROM users WHERE role = 'user') AS total_users
  `;

  db.query(overviewQuery, (err, results) => {
    if (err) {
      console.error('❌ Admin overview error:', err);
      return res.status(500).json({ message: 'Database error' });
    }

    const row = results[0] || {};
    res.json({
      total_complaints: row.total_complaints || 0,
      pending_complaints: row.pending_complaints || 0,
      in_progress_complaints: row.in_progress_complaints || 0,
      resolved_complaints: row.resolved_complaints || 0,
      total_users: row.total_users || 0,
    });
  });
});

// ADMIN GET ALL COMPLAINTS API
app.get('/api/admin/complaints', (req, res) => {
  const query = `
    SELECT
      c.id,
      c.user_id,
      c.category,
      c.description,
      c.document,
      c.status,
      c.priority,
      c.created_at,
      u.name AS user_name,
      u.email AS user_email
    FROM complaints c
    JOIN users u ON u.id = c.user_id
    ORDER BY c.created_at DESC
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('❌ Admin complaints fetch error:', err);
      return res.status(500).json({ message: 'Database error' });
    }

    res.json(results.map(c => ({
      id: c.id,
      user_id: c.user_id,
      user_name: c.user_name,
      user_email: c.user_email,
      category: c.category,
      description: c.description,
      document: c.document,
      status: c.status,
      priority: c.priority,
      created_at: c.created_at,
    })));
  });
});

// ADMIN UPDATE COMPLAINT STATUS API
app.put('/api/admin/complaints/:id/status', (req, res) => {
  const complaintId = parseInt(req.params.id);
  const { status, admin_remark } = req.body;

  if (isNaN(complaintId)) {
    return res.status(400).json({ message: 'Invalid complaint ID' });
  }

  const allowedStatuses = ['Pending', 'In Progress', 'Resolved', 'New'];
  if (!status || !allowedStatuses.includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  db.query('UPDATE complaints SET status = ? WHERE id = ?', [status, complaintId], (err, result) => {
    if (err) {
      console.error('❌ Admin status update error:', err);
      return res.status(500).json({ message: 'Database error' });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Complaint not found' });
    }

    db.query(
      'INSERT INTO complaint_remarks (complaint_id, admin_remark, status) VALUES (?, ?, ?)',
      [complaintId, (admin_remark || '').toString().trim(), status],
      (remarkErr) => {
        if (remarkErr) {
          console.error('❌ Admin remark insert error:', remarkErr);
          return res.status(500).json({ message: 'Status updated but remark save failed' });
        }
        res.json({ message: 'Complaint status updated successfully' });
      }
    );
  });
});

// ADMIN SETTINGS APIs
app.get('/api/admin/settings', (req, res) => {
  db.query('SELECT * FROM admin_settings WHERE id = 1', (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    const s = results[0] || {};
    res.json({
      email_notifications: !!s.email_notifications,
      push_notifications: !!s.push_notifications,
      high_priority_alerts: !!s.high_priority_alerts,
      auto_assign: !!s.auto_assign,
      resolution_deadline_hours: s.resolution_deadline_hours || 48,
    });
  });
});

app.put('/api/admin/settings', (req, res) => {
  const email = req.body.email_notifications ? 1 : 0;
  const push = req.body.push_notifications ? 1 : 0;
  const high = req.body.high_priority_alerts ? 1 : 0;
  const auto = req.body.auto_assign ? 1 : 0;
  const deadline = parseInt(req.body.resolution_deadline_hours) || 48;

  db.query(
    `UPDATE admin_settings
     SET email_notifications = ?, push_notifications = ?, high_priority_alerts = ?, auto_assign = ?, resolution_deadline_hours = ?
     WHERE id = 1`,
    [email, push, high, auto, deadline],
    (err) => {
      if (err) return res.status(500).json({ message: 'Database error' });
      res.json({ message: 'Settings updated successfully' });
    }
  );
});

app.get('/api/admin/export/complaints.csv', (req, res) => {
  const query = `
    SELECT c.id, u.name AS user_name, u.email AS user_email, c.category, c.description, c.status, c.priority, c.created_at
    FROM complaints c
    JOIN users u ON u.id = c.user_id
    ORDER BY c.created_at DESC
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ message: 'Database error' });

    const header = 'id,user_name,user_email,category,description,status,priority,created_at';
    const rows = results.map(r => [
      r.id,
      `"${String(r.user_name || '').replace(/"/g, '""')}"`,
      `"${String(r.user_email || '').replace(/"/g, '""')}"`,
      `"${String(r.category || '').replace(/"/g, '""')}"`,
      `"${String(r.description || '').replace(/"/g, '""')}"`,
      `"${String(r.status || '').replace(/"/g, '""')}"`,
      `"${String(r.priority || '').replace(/"/g, '""')}"`,
      `"${String(r.created_at || '').replace(/"/g, '""')}"`,
    ].join(','));

    const csv = [header, ...rows].join('\n');
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="complaints_export.csv"');
    res.send(csv);
  });
});

app.delete('/api/admin/complaints', (req, res) => {
  db.query('DELETE FROM complaints', (err) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    res.json({ message: 'All complaints reset successfully' });
  });
});

// Start Server

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});