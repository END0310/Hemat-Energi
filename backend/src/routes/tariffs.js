const express = require('express');
const { pool } = require('../config/db');
const authenticateToken = require('../middleware/auth');

const router = express.Router();

/**
 * FR-01: GET /api/tariffs
 * Mengambil seluruh daftar golongan, daya VA, dan tarif resmi PLN per kWh.
 */
router.get('/', authenticateToken, async (_req, res, next) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, kategori, daya_va, tarif_per_kwh FROM tariff_configurations ORDER BY kategori ASC, daya_va ASC'
    );

    const formatted = rows.map((row) => ({
      id: row.id,
      kategori: row.kategori,
      daya_va: Number(row.daya_va),
      tarif_per_kwh: Number(row.tarif_per_kwh),
    }));

    return res.json({
      success: true,
      data: formatted,
    });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
