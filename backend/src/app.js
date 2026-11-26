const path = require('path');
const express = require('express');
const cors = require('cors');
const multer = require('multer');
require('dotenv').config();

const { pool, testDatabaseConnection } = require('./config/db');
const { runMigrations } = require('./config/migrate');
const authRoutes = require('./routes/auth');
const tariffRoutes = require('./routes/tariffs');
const profileRoutes = require('./routes/profile');
const tokenRoutes = require('./routes/tokens');
const meterReadingRoutes = require('./routes/meterReadings');
const deviceRoutes = require('./routes/devices');
const targetRoutes = require('./routes/targets');
const simulationRoutes = require('./routes/simulations');

const app = express();
const PORT = Number(process.env.PORT || 3000);

// Middleware global
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Layani file foto bukti meter secara statis melalui URL /uploads/<nama_file>
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Endpoint pengecekan status server & koneksi MySQL
app.get('/api/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    return res.json({
      success: true,
      data: {
        service: 'Hemat Energi API',
        database: 'connected',
        timestamp: new Date().toISOString(),
      },
    });
  } catch (err) {
    return res.status(503).json({
      success: false,
      message: `Server Express aktif, tetapi MySQL belum siap: ${err.message}`,
    });
  }
});

// Registrasi seluruh endpoint sesuai Lampiran C PRD v3.1
app.use('/api/auth', authRoutes);
app.use('/api/tariffs', tariffRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/tokens', tokenRoutes);
app.use('/api/meter-readings', meterReadingRoutes);
app.use('/api/devices', deviceRoutes);
app.use('/api/targets', targetRoutes);
app.use('/api/simulations', simulationRoutes);

// Handler jika alamat URL endpoint tidak ditemukan (404)
app.use((req, res) => {
  return res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan.`,
  });
});

// Error handler terpusat agar format respons JSON selalu konsisten (NFR-09)
app.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError) {
    const msg =
      err.code === 'LIMIT_FILE_SIZE'
        ? 'Ukuran foto bukti meter maksimal 5 MB.'
        : `Gagal mengunggah foto: ${err.message}`;
    return res.status(400).json({ success: false, message: msg });
  }

  if (err && err.message && err.message.includes('Format file tidak didukung')) {
    return res.status(400).json({ success: false, message: err.message });
  }

  console.error('[API Error]', err);
  return res.status(500).json({
    success: false,
    message: 'Terjadi kesalahan pada server. Pastikan layanan MySQL aktif dan skema sudah sesuai.',
  });
});

if (require.main === module) {
  (async () => {
    await runMigrations();
    app.listen(PORT, '0.0.0.0', async () => {
      console.log(`=========================================================`);
      console.log(` Server Backend Hemat Energi berjalan di port ${PORT}`);
      console.log(` - Lokal laptop     : http://localhost:${PORT}/api/health`);
      console.log(` - Emulator Android : http://10.0.2.2:${PORT}/api`);
      console.log(`=========================================================`);
      await testDatabaseConnection();
    });
  })();
}

module.exports = app;
