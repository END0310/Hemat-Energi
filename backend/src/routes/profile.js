const express = require('express');
const { pool } = require('../config/db');
const authenticateToken = require('../middleware/auth');

const router = express.Router();

async function getProfileWithTariff(userId) {
  const [rows] = await pool.execute(
    `SELECT 
       ep.id,
       ep.user_id,
       ep.kategori,
       ep.daya_va,
       ep.jenis_listrik,
       ep.saldo_awal_kwh,
       tc.tarif_per_kwh
     FROM electricity_profiles ep
     LEFT JOIN tariff_configurations tc
       ON ep.kategori = tc.kategori AND ep.daya_va = tc.daya_va
     WHERE ep.user_id = ?
     LIMIT 1`,
    [userId]
  );

  if (rows.length === 0) return null;

  const p = rows[0];
  return {
    id: p.id,
    user_id: p.user_id,
    kategori: p.kategori,
    daya_va: Number(p.daya_va),
    jenis_listrik: p.jenis_listrik,
    saldo_awal_kwh: p.saldo_awal_kwh !== null ? Number(p.saldo_awal_kwh) : null,
    tarif_per_kwh: p.tarif_per_kwh !== null ? Number(p.tarif_per_kwh) : null,
  };
}

/**
 * FR-01: GET /api/profile
 * Mengambil profil listrik milik pengguna yang sedang login.
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const profile = await getProfileWithTariff(req.user.id);
    return res.json({
      success: true,
      data: profile,
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * Handler simpan/ubah profil listrik (dipakai oleh POST dan PUT /api/profile).
 * Memastikan kombinasi kategori + daya tersedia di tabel tarif resmi PLN (tanpa menebak tarif).
 */
async function upsertProfile(req, res, next) {
  try {
    const kategori = (req.body.kategori || '').trim();
    const dayaVa = Number(req.body.daya_va ?? req.body.daya);
    const saldoAwal =
      req.body.saldo_awal_kwh !== undefined && req.body.saldo_awal_kwh !== null
        ? Number(req.body.saldo_awal_kwh)
        : null;

    if (!kategori || !Number.isFinite(dayaVa) || dayaVa <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Kategori golongan dan daya VA wajib dipilih dengan benar.',
      });
    }

    const [tariffs] = await pool.execute(
      'SELECT tarif_per_kwh FROM tariff_configurations WHERE kategori = ? AND daya_va = ? LIMIT 1',
      [kategori, dayaVa]
    );
    if (tariffs.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Kombinasi golongan dan daya tidak ditemukan pada konfigurasi tarif resmi PLN.',
      });
    }

    await pool.execute(
      `INSERT INTO electricity_profiles (user_id, kategori, daya_va, jenis_listrik, saldo_awal_kwh)
       VALUES (?, ?, ?, 'Prabayar/Token', ?)
       ON DUPLICATE KEY UPDATE
         kategori = VALUES(kategori),
         daya_va = VALUES(daya_va),
         jenis_listrik = 'Prabayar/Token',
         saldo_awal_kwh = VALUES(saldo_awal_kwh)`,
      [req.user.id, kategori, dayaVa, saldoAwal]
    );

    const saved = await getProfileWithTariff(req.user.id);
    return res.status(req.method === 'POST' ? 201 : 200).json({
      success: true,
      data: saved,
    });
  } catch (err) {
    return next(err);
  }
}

router.post('/', authenticateToken, upsertProfile);
router.put('/', authenticateToken, upsertProfile);

/**
 * FR-01: DELETE /api/profile
 * Mereset / menghapus profil listrik pengguna.
 */
router.delete('/', authenticateToken, async (req, res, next) => {
  try {
    await pool.execute('DELETE FROM electricity_profiles WHERE user_id = ?', [req.user.id]);
    return res.json({
      success: true,
      data: { deleted: true },
    });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
