const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

/**
 * Auto-Migration Runner:
 * 1. Membaca dan menjalankan `backend/schema.sql` secara otomatis
 *    (membuat database `hemat_energi`, ke-8 tabel, dan seed tarif PLN jika belum ada).
 * 2. Menjalankan file migrasi tambahan di `backend/migrations/*.sql` (jika ada perubahan tabel ke depannya)
 *    dan mencatatnya ke tabel `schema_migrations` agar tidak pernah dijalankan dua kali.
 *
 * Dengan ini, anggota tim cukup menyalakan MySQL (XAMPP/Laragon) lalu `npm run dev`
 * tanpa perlu import SQL manual lewat phpMyAdmin.
 */
async function runMigrations() {
  let connection;
  try {
    // Terhubung ke server MySQL tanpa menyebut nama database dulu
    // supaya tidak error ketika database `hemat_energi` belum pernah dibuat di laptop teman.
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || '127.0.0.1',
      port: Number(process.env.DB_PORT || 3306),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true,
      timezone: '+07:00',
    });

    // 1. Jalankan schema utama (idempoten: memakai IF NOT EXISTS & ON DUPLICATE KEY UPDATE)
    const schemaPath = path.join(__dirname, '..', '..', 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    await connection.query(schemaSql);

    // 2. Pastikan tabel pencatat riwayat migrasi tersedia
    const dbName = process.env.DB_NAME || 'hemat_energi';
    await connection.changeUser({ database: dbName });
    await connection.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        filename VARCHAR(255) PRIMARY KEY,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 3. Jalankan file migrasi lanjutan di folder backend/migrations/ (jika suatu saat ada)
    const migrationsDir = path.join(__dirname, '..', '..', 'migrations');
    if (fs.existsSync(migrationsDir)) {
      const files = fs
        .readdirSync(migrationsDir)
        .filter((f) => f.endsWith('.sql'))
        .sort();

      for (const file of files) {
        const [done] = await connection.execute(
          'SELECT filename FROM schema_migrations WHERE filename = ? LIMIT 1',
          [file]
        );
        if (done.length === 0) {
          const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
          await connection.query(sql);
          await connection.execute(
            'INSERT INTO schema_migrations (filename) VALUES (?)',
            [file]
          );
          console.log(`[Migrate] Berhasil menerapkan migrasi baru: ${file}`);
        }
      }
    }

    console.log(`[Migrate] Database '${dbName}', seluruh tabel, dan data tarif PLN siap digunakan.`);
    return true;
  } catch (err) {
    console.warn(`[Migrate] Gagal menjalankan auto-migration: ${err.message}`);
    console.warn('          Pastikan MySQL di XAMPP / Laragon sudah diklik Start.');
    return false;
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Memungkinkan dijalankan mandiri lewat `npm run migrate`
if (require.main === module) {
  runMigrations().then((ok) => process.exit(ok ? 0 : 1));
}

module.exports = { runMigrations };
