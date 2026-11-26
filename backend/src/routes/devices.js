const express = require('express');
const authenticateToken = require('../middleware/auth');
// const { pool } = require('../config/db');

const router = express.Router();

/**
 * ============================================================================
 * KERANGKA ROUTE MODUL 2 — DAFTAR PERANGKAT (/api/devices)
 * Penanggung Jawab: Kevin Rahmat Illahi (2411522006)
 * Tabel MySQL: `devices` (id, user_id, nama, watt, jumlah, jam_per_hari)
 *
 * Route ini sudah didaftarkan di src/app.js pada path `/api/devices`
 * dan sudah dilindungi middleware `authenticateToken` (`req.user.id`).
 * Silakan isi implementasi GET, POST, PUT /:id, dan DELETE /:id di bawah ini.
 * ============================================================================
 */
router.use(authenticateToken);

router.get('/', async (_req, res) => {
  return res.json({
    success: true,
    data: [],
    note: 'Kerangka endpoint /api/devices siap diisi oleh Kevin (Modul 2).',
  });
});

module.exports = router;
