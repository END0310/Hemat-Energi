const mysql = require('mysql2/promise');
require('dotenv').config();

/**
 * Pool koneksi MySQL menggunakan mysql2/promise.
 * Pool dipakai supaya koneksi database tetap efisien dan otomatis dikelola ulang.
 */
const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'hemat_energi',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: '+07:00',
});

/**
 * Mengecek apakah database MySQL sudah nyala dan tabel sudah di-import.
 */
async function testDatabaseConnection() {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    console.log(`[DB] Terhubung ke MySQL (${process.env.DB_NAME || 'hemat_energi'})`);
    return true;
  } catch (err) {
    console.warn(`[DB] Peringatan: Belum terhubung ke MySQL (${err.message}).`);
    console.warn('     Pastikan MySQL (XAMPP/Laragon) sudah dinyalakan dan backend/schema.sql sudah dijalankan.');
    return false;
  }
}

module.exports = {
  pool,
  testDatabaseConnection,
};
