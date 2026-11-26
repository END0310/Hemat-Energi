# Backend Server — Hemat Energi (SDG 7)

Server REST API berbasis **Node.js + Express + MySQL** untuk aplikasi mobile **Hemat Energi**.

---

## 1. Persiapan & Menjalankan Server (Otomatis Tanpa Import Manual!)

Anda dan teman kelompok **tidak perlu membuka phpMyAdmin atau meng-import SQL secara manual**. Server sudah dilengkapi **Auto-Migration** yang otomatis membuat database `hemat_energi`, ke-8 tabel, dan mengisi tarif resmi PLN begitu server dinyalakan.

Langkah-langkahnya cukup:

1. Buka **XAMPP Control Panel** atau **Laragon**, lalu klik **Start** pada **MySQL**.
2. Jika baru pertama kali clone/pull di laptop masing-masing, salin `.env.example` menjadi `.env`:
   ```bash
   cp .env.example .env
   ```
   *(Sesuaikan `DB_PASSWORD=` di `.env` hanya jika MySQL di laptop Anda memakai password).*
3. Buka terminal di folder `hemat_energi/backend`, lalu jalankan:
   ```bash
   # Instal paket npm (cukup 1 kali di awal)
   npm install

   # Jalankan server (sekaligus otomatis menjalankan auto-migration!)
   npm run dev
   ```
   *(Atau jika ingin menjalankan migrasi saja tanpa menyalakan server: `npm run migrate`).*

4. Cek di browser: buka **`http://localhost:3000/api/health`**.
   Jika berhasil, akan tampil:
   ```json
   {
     "success": true,
     "data": {
       "service": "Hemat Energi API",
       "database": "connected"
     }
   }
   ```

---

## 2. Jika Nanti Ada Perubahan Struktur Tabel

Jika di tengah pengembangan ada penambahan kolom baru:
- Buat file `.sql` baru di dalam folder `backend/migrations/` (contoh: `backend/migrations/001_tambah_kolom.sql`).
- Saat teman satu tim melakukan `git pull` dan menjalankan `npm run dev`, file migrasi baru tersebut **otomatis dieksekusi satu kali** (tercatat di tabel `schema_migrations`) tanpa menghapus isi data yang sudah ada di laptop mereka.

---

## 3. Pembagian File Route untuk Tim

- **Zikri (Auth & Modul 1):** `auth.js`, `tariffs.js`, `profile.js`, `tokens.js`, `meterReadings.js` *(sudah selesai)*
- **Kevin (Modul 2):** Silakan lengkapi CRUD perangkat di `src/routes/devices.js`
- **Fauzin (Modul 3):** Silakan lengkapi CRUD target & simulasi di `src/routes/targets.js` dan `src/routes/simulations.js`
