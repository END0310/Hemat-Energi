const fs = require('fs');
const path = require('path');
const express = require('express');
const { pool } = require('../config/db');
const authenticateToken = require('../middleware/auth');
const { uploadMeterPhoto, uploadsDir } = require('../middleware/upload');

const router = express.Router();

function toMysqlDateTime(dateInput) {
  const parsed = dateInput ? new Date(dateInput) : new Date();
  if (Number.isNaN(parsed.getTime())) return null;
  const pad = (n) => String(n).padStart(2, '0');
  return (
    `${parsed.getFullYear()}-${pad(parsed.getMonth() + 1)}-${pad(parsed.getDate())} ` +
    `${pad(parsed.getHours())}:${pad(parsed.getMinutes())}:${pad(parsed.getSeconds())}`
  );
}

function formatMeterRow(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    tanggal: row.tanggal instanceof Date ? row.tanggal.toISOString() : row.tanggal,
    saldo_kwh: Number(row.saldo_kwh),
    foto_path: row.foto_path || null,
  };
}

function removeUploadedFileSafely(fotoPath) {
  if (!fotoPath || !fotoPath.startsWith('/uploads/')) return;
  const fileName = path.basename(fotoPath);
  const fullPath = path.join(uploadsDir, fileName);
  if (fs.existsSync(fullPath)) {
    fs.unlink(fullPath, () => {});
  }
}

/**
 * FR-03: GET /api/meter-readings
 * Mengambil seluruh catatan meter milik pengguna yang sedang login.
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const sortDir = String(req.query.order || 'desc').toLowerCase() === 'asc' ? 'ASC' : 'DESC';
    const [rows] = await pool.execute(
      `SELECT id, user_id, tanggal, saldo_kwh, foto_path
       FROM meter_readings
       WHERE user_id = ?
       ORDER BY tanggal ${sortDir}`,
      [req.user.id]
    );

    return res.json({
      success: true,
      data: rows.map(formatMeterRow),
    });
  } catch (err) {
    return next(err);
  }
});

/**
 * FR-03: POST /api/meter-readings
 * Menambah catatan saldo meter baru (mendukung unggah foto bukti opsional via field 'foto').
 */
router.post(
  '/',
  authenticateToken,
  uploadMeterPhoto.single('foto'),
  async (req, res, next) => {
    try {
      const tanggal = toMysqlDateTime(req.body.tanggal || req.body.tanggal_waktu);
      const saldoKwh = Number(req.body.saldo_kwh);
      const fotoPath = req.file ? `/uploads/${req.file.filename}` : null;

      if (!tanggal) {
        if (fotoPath) removeUploadedFileSafely(fotoPath);
        return res.status(400).json({ success: false, message: 'Format tanggal tidak valid.' });
      }
      if (!Number.isFinite(saldoKwh) || saldoKwh < 0) {
        if (fotoPath) removeUploadedFileSafely(fotoPath);
        return res.status(400).json({
          success: false,
          message: 'Saldo kWh wajib berupa angka 0 atau lebih.',
        });
      }

      const [result] = await pool.execute(
        'INSERT INTO meter_readings (user_id, tanggal, saldo_kwh, foto_path) VALUES (?, ?, ?, ?)',
        [req.user.id, tanggal, saldoKwh, fotoPath]
      );

      const [rows] = await pool.execute(
        'SELECT id, user_id, tanggal, saldo_kwh, foto_path FROM meter_readings WHERE id = ? LIMIT 1',
        [result.insertId]
      );

      return res.status(201).json({
        success: true,
        data: formatMeterRow(rows[0]),
      });
    } catch (err) {
      return next(err);
    }
  }
);

/**
 * FR-03: PUT /api/meter-readings/:id
 * Mengubah catatan saldo meter (serta mengganti/menghapus foto bukti bila diminta).
 */
router.put(
  '/:id',
  authenticateToken,
  uploadMeterPhoto.single('foto'),
  async (req, res, next) => {
    try {
      const meterId = Number(req.params.id);
      const [existingRows] = await pool.execute(
        'SELECT id, foto_path FROM meter_readings WHERE id = ? AND user_id = ? LIMIT 1',
        [meterId, req.user.id]
      );

      if (existingRows.length === 0) {
        if (req.file) removeUploadedFileSafely(`/uploads/${req.file.filename}`);
        return res.status(404).json({
          success: false,
          message: 'Catatan meter tidak ditemukan.',
        });
      }

      const tanggal = toMysqlDateTime(req.body.tanggal || req.body.tanggal_waktu);
      const saldoKwh = Number(req.body.saldo_kwh);

      if (!tanggal || !Number.isFinite(saldoKwh) || saldoKwh < 0) {
        if (req.file) removeUploadedFileSafely(`/uploads/${req.file.filename}`);
        return res.status(400).json({
          success: false,
          message: 'Tanggal dan saldo kWh wajib diisi dengan benar.',
        });
      }

      let nextFotoPath = existingRows[0].foto_path;
      if (req.file) {
        removeUploadedFileSafely(existingRows[0].foto_path);
        nextFotoPath = `/uploads/${req.file.filename}`;
      } else if (req.body.remove_photo === 'true' || req.body.remove_photo === true) {
        removeUploadedFileSafely(existingRows[0].foto_path);
        nextFotoPath = null;
      }

      await pool.execute(
        'UPDATE meter_readings SET tanggal = ?, saldo_kwh = ?, foto_path = ? WHERE id = ? AND user_id = ?',
        [tanggal, saldoKwh, nextFotoPath, meterId, req.user.id]
      );

      const [rows] = await pool.execute(
        'SELECT id, user_id, tanggal, saldo_kwh, foto_path FROM meter_readings WHERE id = ? LIMIT 1',
        [meterId]
      );

      return res.json({
        success: true,
        data: formatMeterRow(rows[0]),
      });
    } catch (err) {
      return next(err);
    }
  }
);

/**
 * FR-03: DELETE /api/meter-readings/:id
 * Menghapus catatan saldo meter beserta file foto buktinya di server.
 */
router.delete('/:id', authenticateToken, async (req, res, next) => {
  try {
    const meterId = Number(req.params.id);
    const [existingRows] = await pool.execute(
      'SELECT foto_path FROM meter_readings WHERE id = ? AND user_id = ? LIMIT 1',
      [meterId, req.user.id]
    );

    if (existingRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Catatan meter tidak ditemukan.',
      });
    }

    await pool.execute('DELETE FROM meter_readings WHERE id = ? AND user_id = ?', [
      meterId,
      req.user.id,
    ]);
    removeUploadedFileSafely(existingRows[0].foto_path);

    return res.json({
      success: true,
      data: { deleted: true, id: meterId },
    });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
