const express = require('express');
const { pool } = require('../config/db');
const authenticateToken = require('../middleware/auth');

const router = express.Router();

/**
 * Mengubah string tanggal ISO (misal dari Flutter toIso8601String) menjadi format DATETIME MySQL.
 */
function toMysqlDateTime(dateInput) {
  const parsed = dateInput ? new Date(dateInput) : new Date();
  if (Number.isNaN(parsed.getTime())) return null;
  const pad = (n) => String(n).padStart(2, '0');
  return (
    `${parsed.getFullYear()}-${pad(parsed.getMonth() + 1)}-${pad(parsed.getDate())} ` +
    `${pad(parsed.getHours())}:${pad(parsed.getMinutes())}:${pad(parsed.getSeconds())}`
  );
}

function formatTokenRow(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    tanggal: row.tanggal instanceof Date ? row.tanggal.toISOString() : row.tanggal,
    nominal: Number(row.nominal),
    kwh_token: Number(row.kwh_token),
  };
}

/**
 * FR-04: GET /api/tokens/summary?month=YYYY-MM
 * Mengembalikan ringkasan pembelian token bulan tertentu serta total pengeluaran sepanjang waktu.
 */
router.get('/summary', authenticateToken, async (req, res, next) => {
  try {
    const now = new Date();
    const defaultMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const monthParam = (req.query.month || defaultMonth).trim();

    if (!/^\d{4}-\d{2}$/.test(monthParam)) {
      return res.status(400).json({
        success: false,
        message: 'Format parameter month harus YYYY-MM (contoh: 2026-11).',
      });
    }

    const [yearStr, monStr] = monthParam.split('-');
    const year = Number(yearStr);
    const month = Number(monStr);
    const startOfMonth = `${yearStr}-${monStr}-01 00:00:00`;
    const lastDay = new Date(year, month, 0).getDate();
    const endOfMonth = `${yearStr}-${monStr}-${String(lastDay).padStart(2, '0')} 23:59:59`;

    const [monthlyRows] = await pool.execute(
      `SELECT 
         COUNT(*) AS count,
         COALESCE(SUM(nominal), 0) AS total_nominal,
         COALESCE(SUM(kwh_token), 0) AS total_kwh
       FROM token_purchases
       WHERE user_id = ? AND tanggal >= ? AND tanggal <= ?`,
      [req.user.id, startOfMonth, endOfMonth]
    );

    const [allTimeRows] = await pool.execute(
      `SELECT 
         COUNT(*) AS count,
         COALESCE(SUM(nominal), 0) AS total_nominal,
         COALESCE(SUM(kwh_token), 0) AS total_kwh
       FROM token_purchases
       WHERE user_id = ?`,
      [req.user.id]
    );

    return res.json({
      success: true,
      data: {
        month: monthParam,
        monthly: {
          count: Number(monthlyRows[0].count),
          total_nominal: Number(monthlyRows[0].total_nominal),
          total_kwh: Number(monthlyRows[0].total_kwh),
        },
        all_time: {
          count: Number(allTimeRows[0].count),
          total_nominal: Number(allTimeRows[0].total_nominal),
          total_kwh: Number(allTimeRows[0].total_kwh),
        },
      },
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * FR-02 & FR-04: GET /api/tokens
 * Mengambil daftar transaksi token milik pengguna, mendukung filter ?from=YYYY-MM-DD&to=YYYY-MM-DD.
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const clauses = ['user_id = ?'];
    const params = [req.user.id];

    if (req.query.from) {
      clauses.push('tanggal >= ?');
      params.push(`${req.query.from} 00:00:00`);
    }
    if (req.query.to) {
      clauses.push('tanggal <= ?');
      params.push(`${req.query.to} 23:59:59`);
    }

    const [rows] = await pool.execute(
      `SELECT id, user_id, tanggal, nominal, kwh_token
       FROM token_purchases
       WHERE ${clauses.join(' AND ')}
       ORDER BY tanggal DESC`,
      params
    );

    return res.json({
      success: true,
      data: rows.map(formatTokenRow),
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * FR-02: POST /api/tokens
 * Menambah transaksi pembelian token baru.
 */
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const tanggal = toMysqlDateTime(req.body.tanggal || req.body.tanggal_waktu);
    const nominal = Number(req.body.nominal);
    const kwhToken = Number(req.body.kwh_token);

    if (!tanggal) {
      return res.status(400).json({ success: false, message: 'Format tanggal tidak valid.' });
    }
    if (!Number.isFinite(nominal) || nominal <= 0 || !Number.isFinite(kwhToken) || kwhToken <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Nominal Rupiah dan jumlah kWh token harus lebih dari 0.',
      });
    }

    const [result] = await pool.execute(
      'INSERT INTO token_purchases (user_id, tanggal, nominal, kwh_token) VALUES (?, ?, ?, ?)',
      [req.user.id, tanggal, Math.round(nominal), kwhToken]
    );

    const [rows] = await pool.execute(
      'SELECT id, user_id, tanggal, nominal, kwh_token FROM token_purchases WHERE id = ? LIMIT 1',
      [result.insertId]
    );

    return res.status(201).json({
      success: true,
      data: formatTokenRow(rows[0]),
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * FR-02: PUT /api/tokens/:id
 * Mengubah catatan pembelian token milik pengguna.
 */
router.put('/:id', authenticateToken, async (req, res, next) => {
  try {
    const tokenId = Number(req.params.id);
    const tanggal = toMysqlDateTime(req.body.tanggal || req.body.tanggal_waktu);
    const nominal = Number(req.body.nominal);
    const kwhToken = Number(req.body.kwh_token);

    if (!tanggal || !Number.isFinite(nominal) || nominal <= 0 || !Number.isFinite(kwhToken) || kwhToken <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Tanggal, nominal, dan kWh token wajib diisi dengan benar.',
      });
    }

    const [result] = await pool.execute(
      'UPDATE token_purchases SET tanggal = ?, nominal = ?, kwh_token = ? WHERE id = ? AND user_id = ?',
      [tanggal, Math.round(nominal), kwhToken, tokenId, req.user.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Data transaksi token tidak ditemukan.',
      });
    }

    const [rows] = await pool.execute(
      'SELECT id, user_id, tanggal, nominal, kwh_token FROM token_purchases WHERE id = ? LIMIT 1',
      [tokenId]
    );

    return res.json({
      success: true,
      data: formatTokenRow(rows[0]),
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * FR-02: DELETE /api/tokens/:id
 * Menghapus catatan pembelian token milik pengguna.
 */
router.delete('/:id', authenticateToken, async (req, res, next) => {
  try {
    const tokenId = Number(req.params.id);
    const [result] = await pool.execute(
      'DELETE FROM token_purchases WHERE id = ? AND user_id = ?',
      [tokenId, req.user.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Data transaksi token tidak ditemukan.',
      });
    }

    return res.json({
      success: true,
      data: { deleted: true, id: tokenId },
    });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
