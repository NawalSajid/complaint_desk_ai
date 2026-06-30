// ComplaintDesk.AI Backend

require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const PDFDocument = require('pdfkit');
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

    db.query(`
  ALTER TABLE complaints
  ADD COLUMN IF NOT EXISTS user_confirmed TINYINT(1) NOT NULL DEFAULT 0
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
        status VARCHAR(50) DEFAULT 'Pending',
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

// ─────────────────────────────────────────────────────────────────────────────
// Test API
// ─────────────────────────────────────────────────────────────────────────────

app.get('/', (req, res) => {
  res.send('ComplaintDesk.AI Backend is running');
});

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER API
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN API
// ─────────────────────────────────────────────────────────────────────────────

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
    let isMatch = false;
    if (typeof user.password === 'string' && user.password.startsWith('$2')) {
      isMatch = await bcrypt.compare(password, user.password);
    } else {
      isMatch = password === user.password;
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

// ─────────────────────────────────────────────────────────────────────────────
// GET USER PROFILE API
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// UPDATE USER NAME API
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// ADD COMPLAINT API
// ─────────────────────────────────────────────────────────────────────────────

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
          status: 'Pending',
          priority,
          created_at: new Date(),
        },
      });
    }
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// GET COMPLAINTS API  ← fixed: now returns latest admin_remark
// ─────────────────────────────────────────────────────────────────────────────

// 2) GET /api/complaints — include user_confirmed in response
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/complaints', (req, res) => {
  const userId = parseInt(req.query.user_id);
  if (isNaN(userId)) return res.status(400).json({ message: 'Invalid user ID' });
 
  db.query(
    `SELECT c.*,
       (SELECT cr.admin_remark FROM complaint_remarks cr
        WHERE cr.complaint_id = c.id
        ORDER BY cr.created_at DESC LIMIT 1) AS admin_remark
     FROM complaints c
     WHERE c.user_id = ?
     ORDER BY
       CASE c.priority
         WHEN 'High' THEN 1
         WHEN 'Medium' THEN 2
         WHEN 'Low' THEN 3
         ELSE 4
       END,
       c.created_at DESC`,
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
        status: c.status,                 // stays Pending/In Progress/Resolved
        priority: c.priority,
        created_at: c.created_at,
        admin_remark: c.admin_remark || '',
        user_confirmed: !!c.user_confirmed,  // ← NEW: boolean flag
      })));
    }
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// USER CONFIRM RESOLUTION API  ← NEW
// ─────────────────────────────────────────────────────────────────────────────

// 3) PUT /api/complaints/:id/confirm — flips flag only, NOT status
// ─────────────────────────────────────────────────────────────────────────────
app.put('/api/complaints/:id/confirm', (req, res) => {
  const complaintId = parseInt(req.params.id);
  if (isNaN(complaintId))
    return res.status(400).json({ message: 'Invalid complaint ID' });
 
  db.query(
    'UPDATE complaints SET user_confirmed = 1 WHERE id = ? AND status = ?',
    [complaintId, 'Resolved'],
    (err, result) => {
      if (err) {
        console.error('❌ Confirm resolution error:', err);
        return res.status(500).json({ message: 'Database error' });
      }
      if (result.affectedRows === 0)
        return res.status(404).json({ message: 'Complaint not found or not resolved yet' });
 
      res.json({ message: 'Resolution confirmed successfully' });
    }
  );
});
 

// ─────────────────────────────────────────────────────────────────────────────
// USER FEEDBACK API
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN OVERVIEW API
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN GET ALL COMPLAINTS API
// ─────────────────────────────────────────────────────────────────────────────

// 4) GET /api/admin/complaints — also include user_confirmed for admin view
// ─────────────────────────────────────────────────────────────────────────────
app.get('/api/admin/complaints', (req, res) => {
  const query = `
    SELECT
      c.id, c.user_id, c.category, c.description, c.document,
      c.status, c.priority, c.created_at, c.user_confirmed,
      u.name AS user_name, u.email AS user_email,
      (SELECT cr.admin_remark FROM complaint_remarks cr
       WHERE cr.complaint_id = c.id
       ORDER BY cr.created_at DESC LIMIT 1) AS admin_remark
    FROM complaints c
    JOIN users u ON u.id = c.user_id
    ORDER BY
      CASE c.priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
      END,
      c.created_at DESC
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
      admin_remark: c.admin_remark || '',
      user_confirmed: !!c.user_confirmed,  // ← NEW
    })));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN UPDATE COMPLAINT STATUS API
// ─────────────────────────────────────────────────────────────────────────────

app.put('/api/admin/complaints/:id/status', (req, res) => {
  const complaintId = parseInt(req.params.id);
  const { status, admin_remark } = req.body;

  if (isNaN(complaintId)) {
    return res.status(400).json({ message: 'Invalid complaint ID' });
  }

  const allowedStatuses = ['Pending', 'In Progress', 'Resolved'];
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

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN SETTINGS APIs
// ─────────────────────────────────────────────────────────────────────────────

app.get('/api/admin/settings', (req, res) => {
  db.query(
    `SELECT
        s.*,
        u.name AS admin_name
     FROM admin_settings s
     LEFT JOIN users u ON u.role='admin'
     WHERE s.id=1
     LIMIT 1`,
    (err, results) => {
      if (err)
        return res.status(500).json({ message: 'Database error' });

      const s = results[0] || {};

      res.json({
        admin_name: s.admin_name || 'Admin',
        email_notifications: !!s.email_notifications,
        push_notifications: !!s.push_notifications,
        high_priority_alerts: !!s.high_priority_alerts,
        auto_assign: !!s.auto_assign,
        resolution_deadline_hours: s.resolution_deadline_hours || 48,
      });
    }
  );
});

app.put('/api/admin/settings', (req, res) => {

  const adminName = (req.body.admin_name || '').trim();

  const email = req.body.email_notifications ? 1 : 0;
  const push = req.body.push_notifications ? 1 : 0;
  const high = req.body.high_priority_alerts ? 1 : 0;
  const auto = req.body.auto_assign ? 1 : 0;
  const deadline = parseInt(req.body.resolution_deadline_hours) || 48;

  db.query(
    `UPDATE admin_settings
     SET
       email_notifications=?,
       push_notifications=?,
       high_priority_alerts=?,
       auto_assign=?,
       resolution_deadline_hours=?
     WHERE id=1`,
    [email, push, high, auto, deadline],
    (err) => {

      if (err)
        return res.status(500).json({ message: 'Database error' });

      if (adminName.length > 0) {

        db.query(
          "UPDATE users SET name=? WHERE role='admin'",
          [adminName],
          (err2) => {

            if (err2)
              return res.status(500).json({ message: 'Database error' });

            res.json({
              message: 'Settings updated successfully'
            });

          }
        );

      } else {

        res.json({
          message: 'Settings updated successfully'
        });

      }

    }
  );

});


// ─────────────────────────────────────────────────────────────────────────────
// CHANGE PASSWORD API
// ─────────────────────────────────────────────────────────────────────────────

app.post('/api/admin/change-password', async (req, res) => {

  console.log("========== CHANGE PASSWORD ==========");
  console.log(req.body);

  const { current_password, new_password } = req.body;

  db.query(
    "SELECT * FROM users WHERE role='admin' LIMIT 1",
    async (err, results) => {

      if (err) {
        console.log(err);
        return res.status(500).json({ message: "Database error" });
      }

      const admin = results[0];

      console.log("Entered Current:", current_password);
      console.log("Hash:", admin.password);

      const match = await bcrypt.compare(current_password, admin.password);

      console.log("Password Match:", match);

      if (!match) {
        return res.status(401).json({
          message: "Incorrect current password"
        });
      }

      const hashed = await bcrypt.hash(new_password, 10);

      console.log("New Hash:", hashed);

      db.query(
        "UPDATE users SET password=? WHERE id=?",
        [hashed, admin.id],
        (err2) => {

          console.log("Update Error:", err2);

          if (err2)
            return res.status(500).json({
              message: "Database error"
            });

          res.json({
            message: "Password changed successfully"
          });

        }
      );

    }
  );

});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN EXPORT CSV API
// ─────────────────────────────────────────────────────────────────────────────

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
      `"${(String(r.status || '').toLowerCase() === 'new' ? 'Pending' : String(r.status || '')).replace(/"/g, '""')}"`,
      `"${String(r.priority || '').replace(/"/g, '""')}"`,
      `"${String(r.created_at || '').replace(/"/g, '""')}"`,
    ].join(','));

    const csv = [header, ...rows].join('\n');
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="complaints_export.csv"');
    res.send(csv);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN EXPORT PDF  —  Professional Executive Report
// Palette: deep slate-purple header · white body · restrained accents
// ─────────────────────────────────────────────────────────────────────────────

app.get('/api/admin/export/complaints.pdf', (req, res) => {

  const query = `
    SELECT
      c.id,
      u.name      AS user_name,
      u.email     AS user_email,
      c.category,
      c.description,
      c.status,
      c.priority,
      c.created_at
    FROM complaints c
    JOIN users u ON u.id = c.user_id
    ORDER BY c.created_at DESC
  `;

  db.query(query, (err, results) => {
    if (err) {
      console.error('PDF query error:', err);
      return res.status(500).json({ message: 'Database error' });
    }

    try {
      const doc = new PDFDocument({ margin: 50, size: 'A4', bufferPages: true });

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="ComplaintDesk_Report.pdf"');
      doc.on('error', (e) => {
        if (!res.headersSent) res.status(500).json({ message: 'PDF generation failed' });
      });
      doc.pipe(res);

      const sanitize = (str) => String(str || '').replace(/[^\x00-\x7F]/g, '');

      // Normalizes any legacy 'New' status value (old DB rows) to display as 'Pending'.
      // This does NOT touch the underlying data — only what gets drawn on the PDF.
      const statusLabel = (s) => {
        const v = (s || '').trim();
        return v.toLowerCase() === 'new' ? 'Pending' : (v || 'Pending');
      };

      // ── Design tokens ──────────────────────────────────────────────────────
      const PAGE_W  = doc.page.width;
      const M       = 50;                    // margin
      const CW      = PAGE_W - M * 2;       // content width  ≈ 495 pt

      // Palette — dark slate-purple anchor, barely-there tints
      const SLATE   = '#2D2250';   // dark header / table-head bg
      const SLATE_M = '#3D3170';   // mid slate (accent rule)
      const INK     = '#1C1C2E';   // body text
      const INK2    = '#4A4A6A';   // secondary text
      const MUTED   = '#8E8EA8';   // captions, dates
      const RULE    = '#E4E2EE';   // hairline dividers
      const GHOST   = '#F6F5FC';   // alternate row tint (near-white, barely purple)
      const WHITE   = '#FFFFFF';

      // Semantic status/priority — desaturated, professional
      const priorityColor = (p) => {
        switch ((p || '').toLowerCase()) {
          case 'high':   return { dot: '#C0392B', label: '#7B1F1F' };
          case 'medium': return { dot: '#B07D2B', label: '#6B4A00' };
          case 'low':    return { dot: '#27825A', label: '#1A5238' };
          default:       return { dot: '#7A7A9A', label: '#4A4A6A' };
        }
      };

      const statusPill = (s) => {
        // 'new' is treated identically to 'pending' since legacy rows may still hold that value
        switch ((s || '').toLowerCase()) {
          case 'resolved':    return { bg: '#E8F5EE', fg: '#1A6640', border: '#A8D5BC' };
          case 'in progress': return { bg: '#FDF4E3', fg: '#7A4F00', border: '#DEC07A' };
          case 'confirmed':   return { bg: '#E8EEF8', fg: '#1A3870', border: '#9AB2D8' };
          case 'pending':
          case 'new':         return { bg: '#EEEAF8', fg: '#3D2480', border: '#B8ACDF' };
          default:            return { bg: '#F0EFF5', fg: '#4A4A6A', border: '#C8C6D8' };
        }
      };

      // ── Helpers ────────────────────────────────────────────────────────────

      function hRule(y, color = RULE, w = 0.4) {
        doc.moveTo(M, y).lineTo(M + CW, y).strokeColor(color).lineWidth(w).stroke();
      }

      // Outlined pill badge — more refined than filled
      function drawPill(text, x, y, c) {
        doc.font('Helvetica').fontSize(7.5);
        const tw = doc.widthOfString(text);
        const PX = 6, H = 14, W = tw + PX * 2;
        doc.roundedRect(x, y, W, H, 3).fillAndStroke(c.bg, c.border);
        doc.fillColor(c.fg).font('Helvetica-Bold').fontSize(7)
           .text(text, x + PX, y + 3.5, { lineBreak: false });
        doc.fillColor(INK);
        return W;
      }

      // Dot indicator for priority
      function drawDot(text, x, y, c) {
        doc.circle(x + 3, y + 4.5, 3).fill(c.dot);
        doc.font('Helvetica').fontSize(8).fillColor(c.label)
           .text(text, x + 10, y + 0.5, { lineBreak: false });
        doc.fillColor(INK);
      }

      // Section label with rule
      function sectionLabel(text, y) {
        doc.font('Helvetica-Bold').fontSize(7.5).fillColor(MUTED)
           .text(text.toUpperCase(), M, y, { characterSpacing: 1.1 });
        hRule(y + 12, RULE, 0.4);
        return y + 20;
      }

      // ── Cover header (page 1 only) ─────────────────────────────────────────
      function drawCoverHeader() {
        // Full-width dark band
        doc.rect(0, 0, PAGE_W, 80).fill(SLATE);

        // App name
        doc.font('Helvetica-Bold').fontSize(18).fillColor(WHITE)
           .text('ComplaintDesk.AI', M, 22);

        // Subtitle
        doc.font('Helvetica').fontSize(9).fillColor('#B0A8D8')
           .text('Complaint Management Report', M, 46);

        // Right-side meta
        doc.font('Helvetica').fontSize(7.5).fillColor('#8880BB')
           .text(`Generated  ${new Date().toLocaleString()}`, M, 22, { width: CW, align: 'right' })
           .text(new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' }),
                 M, 34, { width: CW, align: 'right' });

        // Thin accent line under band
        doc.rect(0, 80, PAGE_W, 2).fill(SLATE_M);

        doc.fillColor(INK);
        doc.y = 96;
      }

      // ── Continuation header (subsequent pages) ────────────────────────────
      function drawPageHeader() {
        doc.rect(0, 0, PAGE_W, 32).fill(SLATE);
        doc.font('Helvetica-Bold').fontSize(9).fillColor(WHITE)
           .text('ComplaintDesk.AI  ·  Complaint Management Report', M, 11);
        doc.rect(0, 32, PAGE_W, 1.5).fill(SLATE_M);
        doc.fillColor(INK);
        doc.y = 44;
      }

      // ── Footer ─────────────────────────────────────────────────────────────
      function drawFooter(n, total) {
        const FY = doc.page.height - 34;
        hRule(FY - 5, RULE, 0.4);
        doc.font('Helvetica').fontSize(7).fillColor(MUTED)
           .text('Confidential  ·  ComplaintDesk.AI', M, FY, { width: CW / 2 })
           .text(`Page ${n} of ${total}`, M, FY, { width: CW, align: 'right' });
        doc.fillColor(INK);
      }

      drawCoverHeader();

      // ── Aggregate stats ────────────────────────────────────────────────────
      const total    = results.length;
      const pending  = results.filter(r => ['pending', 'new'].includes((r.status || '').toLowerCase())).length;
      const progress = results.filter(r => (r.status || '').toLowerCase() === 'in progress').length;
      const resolved = results.filter(r => (r.status || '').toLowerCase() === 'resolved').length;
      const highPri  = results.filter(r => (r.priority||'').toLowerCase() === 'high').length;

      let y = sectionLabel('Overview', doc.y);

      // Stat cards — full-width row of 5, minimal style
      const CARD_GAP = 8;
      const CARD_W   = (CW - CARD_GAP * 4) / 5;
      const CARD_H   = 52;

      const statDefs = [
        { label: 'Total',       value: total,    bar: SLATE   },
        { label: 'Pending',     value: pending,  bar: '#B07D2B'},
        { label: 'In Progress', value: progress, bar: '#2B6CB0'},
        { label: 'Resolved',    value: resolved, bar: '#27825A'},
        { label: 'High Priority', value: highPri, bar: '#C0392B'},
      ];

      statDefs.forEach((s, i) => {
        const cx = M + i * (CARD_W + CARD_GAP);
        // Card — white with hairline border
        doc.roundedRect(cx, y, CARD_W, CARD_H, 4).fillAndStroke(WHITE, RULE);
        // 3pt top colour strip
        doc.rect(cx, y, CARD_W, 3).fill(s.bar);
        // Value
        doc.font('Helvetica-Bold').fontSize(22).fillColor(INK)
           .text(String(s.value), cx + 10, y + 9, { width: CARD_W - 20 });
        // Label
        doc.font('Helvetica').fontSize(7).fillColor(MUTED)
           .text(s.label, cx + 10, y + 35, { width: CARD_W - 20 });
      });

      doc.fillColor(INK);
      y += CARD_H + 24;

      // ── Category breakdown ─────────────────────────────────────────────────
      y = sectionLabel('Complaints by category', y);

      const catMap = {};
      results.forEach(r => {
        const k = sanitize(r.category) || 'Other';
        catMap[k] = (catMap[k] || 0) + 1;
      });
      const cats    = Object.entries(catMap).sort((a, b) => b[1] - a[1]);
      const maxCat  = cats[0]?.[1] || 1;
      const TRACK_W = CW - 110;
      const BAR_H   = 8;
      const BAR_GAP = 16;

      cats.forEach(([name, count], i) => {
        const ry = y + i * BAR_GAP;
        // Label
        doc.font('Helvetica').fontSize(8).fillColor(INK2)
           .text(name, M, ry + 0.5, { width: 96, ellipsis: true });
        // Track (background)
        doc.roundedRect(M + 102, ry, TRACK_W, BAR_H, 2).fill('#EFECFA');
        // Fill
        const fw = Math.max(10, (count / maxCat) * TRACK_W);
        doc.roundedRect(M + 102, ry, fw, BAR_H, 2).fill(SLATE);
        // Count
        doc.font('Helvetica-Bold').fontSize(7.5).fillColor(INK2)
           .text(String(count), M + 102 + fw + 6, ry + 0.5, { lineBreak: false });
      });

      doc.fillColor(INK);
      y += cats.length * BAR_GAP + 24;

      // ── Complaint details table ────────────────────────────────────────────
      y = sectionLabel('Complaint details', y);

      // Columns (pt from left margin)
      const C = {
        id:   { x: M,        w: 28  },
        user: { x: M + 30,   w: 100 },
        cat:  { x: M + 132,  w: 72  },
        pri:  { x: M + 206,  w: 68  },
        stat: { x: M + 276,  w: 80  },
        date: { x: M + 358,  w: CW - 358 },
      };

      function tableHeader(ty) {
        doc.rect(M, ty, CW, 22).fill(SLATE);
        doc.font('Helvetica-Bold').fontSize(7).fillColor(WHITE);
        [['#', C.id], ['USER', C.user], ['CATEGORY', C.cat],
         ['PRIORITY', C.pri], ['STATUS', C.stat], ['DATE', C.date]]
          .forEach(([label, col]) => {
            doc.text(label, col.x + 2, ty + 7.5, { width: col.w - 4, lineBreak: false });
          });
        doc.fillColor(INK);
        return ty + 22;
      }

      const BOTTOM = doc.page.height - 48;
      y = tableHeader(y);

      results.forEach((r, idx) => {
        const desc   = sanitize(r.description);
        // Row layout: top line (id / user / cat / priority / status / date)
        // Second line: indented description in muted italic
        const ROW_TOP  = 30;   // fixed height for the data line
        const DESC_PAD = 4;
        doc.font('Helvetica').fontSize(7.8);
        const descH = doc.heightOfString(desc, { width: CW - M - 10 });
        const ROW   = ROW_TOP + descH + DESC_PAD + 6;

        // Page break
        if (y + ROW > BOTTOM) {
          doc.addPage();
          drawPageHeader();
          y = doc.y;
          y = tableHeader(y);
        }

        // Alternate row background
        if (idx % 2 !== 0) {
          doc.rect(M, y, CW, ROW).fill(GHOST);
        }

        const MID = y + 12;   // vertical centre of the data line

        // ID
        doc.font('Helvetica-Bold').fontSize(8).fillColor(SLATE)
           .text(String(r.id), C.id.x + 2, MID - 4, { width: C.id.w - 2, lineBreak: false });

        // User name + email stacked
        doc.font('Helvetica-Bold').fontSize(8).fillColor(INK)
           .text(sanitize(r.user_name), C.user.x, y + 6, { width: C.user.w - 4, ellipsis: true, lineBreak: false });
        doc.font('Helvetica').fontSize(6.8).fillColor(MUTED)
           .text(sanitize(r.user_email), C.user.x, y + 17, { width: C.user.w - 4, ellipsis: true, lineBreak: false });

        // Category
        doc.font('Helvetica').fontSize(8).fillColor(INK2)
           .text(sanitize(r.category), C.cat.x, MID - 4, { width: C.cat.w - 4, ellipsis: true, lineBreak: false });

        // Priority — dot + text
        const pc = priorityColor(r.priority);
        drawDot(sanitize(r.priority) || '–', C.pri.x, MID - 5, pc);

        // Status — outlined pill (normalized so legacy 'New' rows show as 'Pending')
        drawPill(statusLabel(sanitize(r.status)), C.stat.x, MID - 6, statusPill(r.status));

        // Date
        doc.font('Helvetica').fontSize(7.5).fillColor(MUTED)
           .text(new Date(r.created_at).toLocaleDateString('en-GB', {
             day: '2-digit', month: 'short', year: 'numeric'
           }), C.date.x, MID - 4, { width: C.date.w - 2, lineBreak: false });

        // Description — second line, indented, muted
        doc.font('Helvetica').fontSize(7.5).fillColor(MUTED)
           .text(desc, M + 30, y + ROW_TOP, { width: CW - 34 });

        // Row bottom hairline
        hRule(y + ROW, RULE, 0.35);
        y += ROW;
      });

      // ── Footers on all pages ───────────────────────────────────────────────
      const range = doc.bufferedPageRange();
      for (let i = range.start; i < range.start + range.count; i++) {
        doc.switchToPage(i);
        drawFooter(i + 1, range.count);
      }

      doc.end();

    } catch (e) {
      console.error('PDF generation error:', e);
      if (!res.headersSent) res.status(500).json({ message: 'PDF generation failed' });
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Start Server
// ─────────────────────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});