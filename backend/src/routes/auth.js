const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const authenticateToken = require('../middleware/auth');

const router = express.Router();
const BCRYPT_ROUNDS = 10;

function createJwtToken(user) {
  return jwt.sign(
    { id: user.id, email_username: user.email_username },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

function isValidEmailOrUsername(value) {
  if (!value) return false;
  const clean = value.trim();
  if (clean.includes('@')) {
    return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(clean);
  }
  return /^[a-zA-Z0-9._]{3,}$/.test(clean);
}

/**
 * AUTH-01: POST /api/auth/register
 * Mendaftarkan pengguna baru dengan password di-hash memakai bcrypt.
 */
router.post('/register', async (req, res, next) => {
  try {
    const nama = (req.body.nama || '').trim();
    const rawIdentifier = req.body.email_username || req.body.email || '';
    const emailUsername = rawIdentifier.trim().toLowerCase();
    const password = req.body.password || '';

    if (!nama) {
      return res.status(400).json({ success: false, message: 'Nama lengkap wajib diisi.' });
    }
    if (!emailUsername || !isValidEmailOrUsername(emailUsername)) {
      return res.status(400).json({
        success: false,
        message: 'Masukkan format email yang valid atau username minimal 3 karakter tanpa spasi.',
      });
    }
    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password minimal 8 karakter.',
      });
    }

    const [existing] = await pool.execute(
      'SELECT id FROM users WHERE email_username = ? LIMIT 1',
      [emailUsername]
    );
    if (existing.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email atau username sudah terdaftar.',
      });
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const [result] = await pool.execute(
      'INSERT INTO users (nama, email_username, password_hash) VALUES (?, ?, ?)',
      [nama, emailUsername, passwordHash]
    );

    const newUser = {
      id: result.insertId,
      nama,
      email_username: emailUsername,
    };
    const token = createJwtToken(newUser);

    return res.status(201).json({
      success: true,
      data: {
        token,
        user: newUser,
      },
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * AUTH-02: POST /api/auth/login
 * Memverifikasi kredensial pengguna dan mengembalikan token JWT.
 */
router.post('/login', async (req, res, next) => {
  try {
    const rawIdentifier = req.body.email_username || req.body.email || '';
    const emailUsername = rawIdentifier.trim().toLowerCase();
    const password = req.body.password || '';

    if (!emailUsername || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email/username dan password wajib diisi.',
      });
    }

    const [rows] = await pool.execute(
      'SELECT id, nama, email_username, password_hash FROM users WHERE email_username = ? LIMIT 1',
      [emailUsername]
    );
    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Email/username atau password salah.',
      });
    }

    const userRow = rows[0];
    const isMatch = await bcrypt.compare(password, userRow.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Email/username atau password salah.',
      });
    }

    const user = {
      id: userRow.id,
      nama: userRow.nama,
      email_username: userRow.email_username,
    };
    const token = createJwtToken(user);

    return res.json({
      success: true,
      data: {
        token,
        user,
      },
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * AUTH-04: GET /api/auth/me
 * Mengambil profil akun pengguna berdasarkan token JWT aktif.
 */
router.get('/me', authenticateToken, async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, nama, email_username, created_at, updated_at FROM users WHERE id = ? LIMIT 1',
      [req.user.id]
    );
    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Pengguna tidak ditemukan.',
      });
    }

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * AUTH-04: PUT /api/auth/me
 * Mengubah nama profil pengguna yang sedang login.
 */
router.put('/me', authenticateToken, async (req, res, next) => {
  try {
    const nama = (req.body.nama || '').trim();
    if (!nama) {
      return res.status(400).json({
        success: false,
        message: 'Nama profil tidak boleh kosong.',
      });
    }

    await pool.execute('UPDATE users SET nama = ? WHERE id = ?', [nama, req.user.id]);
    const [rows] = await pool.execute(
      'SELECT id, nama, email_username, created_at, updated_at FROM users WHERE id = ? LIMIT 1',
      [req.user.id]
    );

    return res.json({
      success: true,
      data: rows[0],
    });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
