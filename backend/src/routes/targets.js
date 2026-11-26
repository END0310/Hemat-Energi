const express = require('express');
const authenticateToken = require('../middleware/auth');
// const { pool } = require('../config/db');

const router = express.Router();

/**
 * ============================================================================
 * KERANGKA ROUTE MODUL 3 — TARGET PENGHEMATAN (/api/targets)
 * Penanggung Jawab: Fauzin Azimi (2311522003)
 * Tabel MySQL: `saving_targets`
 *
 * Route ini sudah didaftarkan di src/app.js pada path `/api/targets`
 * dan sudah dilindungi middleware `authenticateToken` (`req.user.id`).
 * Silakan isi implementasi GET, POST, PUT /:id, dan DELETE /:id di bawah ini.
 * ============================================================================
 */
router.use(authenticateToken);

router.get('/', async (_req, res) => {
  return res.json({
    success: true,
    data: [],
    note: 'Kerangka endpoint /api/targets siap diisi oleh Fauzin (Modul 3).',
  });
});

module.exports = router;
