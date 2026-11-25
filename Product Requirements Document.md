# PROJECT PRD — Product Requirements Document

| Item | Keterangan |
| --- | --- |
| Project Name | Hemat Energi (SDG 7) |
| Team | Alfi Zikri (2411521002), Kevin Rahmat Illahi (2411522006), Fauzin Azimi (2311522003) |
| Course | Mobile Programming |
| Version | 3.1 (penyempurnaan final dari v3.0 pasca-penggabungan branch `main`: keputusan terbuka ditetapkan, tabel tarif resmi PLN dilengkapi, skema & pembagian tugas per anggota diselaraskan dengan kode aktual) |
| Date | 25 November 2026 |

> **Cara memakai dokumen ini (untuk Tim & AI):** baca seluruh dokumen sebelum mengubah kode. Dokumen ini adalah sumber kebenaran untuk menyempurnakan proyek yang sudah tergabung di branch `main`. Jika kode lama bertentangan dengan dokumen ini, dokumen ini yang menang. Jangan menulis ulang proyek dari nol; ikuti strategi bertahap pada Lampiran D & G.

---

## 1. Problem & Users

### 1.1 Problem Statement

Mahasiswa dan anak kos pengguna listrik prabayar (token) sering tidak mengetahui konsumsi listrik yang sebenarnya, perangkat mana yang paling boros, dan kapan saldo kWh akan habis, sehingga sulit mengontrol biaya bulanan dan menyusun target penghematan.

### 1.2 Target Users

Mahasiswa/anak kos yang tinggal mandiri di kos atau kontrakan, mengelola listrik prabayar/token sendiri, memiliki smartphone Android, dan ingin lebih hemat serta sadar lingkungan dalam pemakaian listrik sehari-hari.

### 1.3 User Needs / Pain Points

- Token sering habis mendadak karena pengguna tidak tahu seberapa cepat saldo kWh berkurang.
- Sulit mencatat pembelian token dan saldo meter secara konsisten, sehingga konsumsi aktual tidak diketahui.
- Tidak tahu perangkat mana yang paling boros dan tidak punya cara mengukur hasil penghematan.
- Sulit memperkirakan pengeluaran listrik tiap bulan dan minim rekomendasi hemat yang praktis.

### 1.4 Project Goal

Membantu mahasiswa/anak kos mencatat token dan meter, mengetahui konsumsi listrik aktual, memperkirakan konsumsi per perangkat, serta menyusun dan mengevaluasi target penghematan, sejalan dengan SDG 7 (Energi Bersih & Terjangkau). Fokus aplikasi adalah monitoring dan penghematan listrik prabayar/token, bukan sistem PLN atau sistem manajemen energi yang kompleks.

---

## 2. Product Requirements

### 2.1 Functional Requirements

Aplikasi hanya memiliki satu role: **Pengguna** (tidak ada Admin atau role lain). Setiap modul memiliki 4 fungsionalitas utama dan 1 notifikasi, dan **semua modul mendukung CRUD** (*Create, Read, Update, Delete*: tambah, lihat, ubah, hapus). Data utama disimpan di server lewat REST API; aplikasi memakai database lokal **SQLite** sebagai *cache* (cadangan baca-saja saat offline).

**Komponen Umum – Autentikasi, Dashboard, Riwayat**

- **AUTH-01**: Pengguna dapat register (`nama`, `email/username`, `password`) lewat server; email/username harus unik.
- **AUTH-02**: Pengguna dapat login memakai email/username dan password; server memverifikasi lalu mengembalikan token JWT (*tanda pengenal login*) yang disimpan aman di aplikasi. Jika token masih berlaku, aplikasi langsung masuk Dashboard saat dibuka. Jika login gagal, tampilkan pesan error.
- **AUTH-03**: Pengguna dapat logout: token dihapus dari HP, aplikasi kembali ke halaman Login, data di server tidak dihapus.
- **AUTH-04**: Pengguna dapat melihat dan mengubah nama profil pengguna.
- **DB-01**: Dashboard menampilkan kondisi listrik (saldo kWh, estimasi sisa hari, kategori, daya), konsumsi (aktual, rata-rata, perbandingan dengan periode sebelumnya), keuangan (total pembelian token, estimasi biaya, pengeluaran), dan penghematan (target, progress, status, estimasi potensi hemat). Data diambil dari API, perhitungan ringkasan dilakukan di aplikasi.
- **DB-02**: Dashboard menampilkan tiga visualisasi minimal: (1) grafik konsumsi mingguan, (2) *Actual vs Target*, dan (3) estimasi konsumsi perangkat.
- **RW-01**: Pengguna dapat melihat riwayat gabungan pembelian token, catatan meter, konsumsi aktual, dan target penghematan.

**Modul 1 – Manajemen Token & Listrik**

- **FR-01**: Pengguna dapat membuat, melihat, mengubah, dan menghapus (reset) profil listrik (`kategori/golongan`, `daya`, `jenis listrik Prabayar/Token`, `saldo awal` bila diperlukan). Tarif ditentukan otomatis dari tabel konfigurasi tarif (`kategori/golongan + daya`); pengguna tidak mengetik tarif secara manual.
- **FR-02**: Pengguna dapat menambah, melihat, mengubah, dan menghapus catatan pembelian token (`tanggal + jam`, `nominal`, `kWh token`). Nilai kWh diisi sesuai yang benar-benar diterima pada struk transaksi, tidak dihitung dari `nominal ÷ tarif`.
- **FR-03**: Pengguna dapat menambah, melihat, mengubah, dan menghapus catatan saldo meter (`tanggal + jam`, `saldo kWh`, `foto meter` opsional dari kamera/galeri yang diunggah ke server sebagai bukti). Tidak memakai OCR (*pengenalan teks otomatis dari gambar*); angka tetap diinput manual. Setelah disimpan, konsumsi aktual dihitung ulang.
- **FR-04**: Pengguna dapat melihat riwayat dan ringkasan token: daftar transaksi, filter rentang tanggal (`from` – `to`), total pembelian dan total kWh per bulan, serta total seluruh pengeluaran.
- **NTF-01**: Sistem memberi notifikasi lokal saldo token rendah saat estimasi sisa hari (`saldo ÷ rata-rata konsumsi harian`) **≤ 2 hari** (aktif apabila tersedia minimal 2 catatan meter).

**Modul 2 – Monitoring Konsumsi**

- **FR-05**: Pengguna dapat menambah, melihat, mengubah, dan menghapus daftar perangkat (`nama`, `daya/watt`, `jumlah`, `jam penggunaan per hari`).
- **FR-06**: Sistem menghitung estimasi konsumsi kWh (harian dan bulanan) dan estimasi biaya per perangkat; hasil selalu berlabel **estimasi**.
- **FR-07**: Sistem menghitung dan menampilkan konsumsi aktual dari data meter dan token (per periode, rata-rata harian, grafik mingguan).
- **FR-08**: Sistem mengurutkan perangkat berdasarkan estimasi konsumsi terbesar. Seluruh teks peringkat wajib menyertakan kata **“estimasi”** (contoh: *“AC merupakan perangkat dengan estimasi konsumsi terbesar”*), bukan menyebutnya konsumsi aktual.
- **NTF-02**: Sistem memberi notifikasi lokal konsumsi meningkat saat konsumsi harian melewati rata-rata (*baseline*, angka acuan pembanding) dengan kenaikan **≥ 30%**. Perhitungan murni aritmatika tanpa Machine Learning.

**Modul 3 – Penghematan Listrik**

- **FR-09**: Pengguna dapat membuat, melihat, mengubah, dan menghapus target penghematan: target bulanan (persentase hemat dari konsumsi periode sebelumnya) dengan acuan monitoring mingguan.
- **FR-10**: Pengguna dapat mensimulasikan penghematan (pilih perangkat dari daftar perangkat Modul 2, kurangi jam pemakaian), menyimpan hasilnya, melihat daftar simulasi, mengubah, dan menghapusnya. Hasil berlabel **estimasi**.
- **FR-11**: Sistem memberi rekomendasi berbasis aturan (*rule-based*, yaitu aturan IF–THEN manual, bukan ML/AI) berdasarkan data perangkat Modul 2 dan konsumsi aktual Modul 1:
  1. Jika perangkat X adalah estimasi terbesar → sarankan mengurangi durasi pemakaian X.
  2. Jika konsumsi aktual berjalan > target proporsional → sarankan memeriksa perangkat estimasi terbesar.
  3. Jika konsumsi harian > rata-rata × (1 + 30%) → tampilkan peringatan konsumsi meningkat.
- **FR-12**: Sistem mengevaluasi penghematan dengan membandingkan konsumsi periode sebelumnya dan periode sekarang (`kWh hemat`, `persentase hemat`, dan status target `tercapai` atau `belum tercapai`).
- **NTF-03**: Sistem memberi notifikasi lokal saat target berstatus **berisiko tidak tercapai**, **hampir tercapai**, atau **tercapai** (definisi pada Bagian 2.8).

### 2.2 Non-functional Requirements

- **NFR-01**: Data utama disimpan di database MySQL pada server dan diakses lewat REST API (format JSON). Database lokal **SQLite (`sqflite`)** yang sudah berjalan di proyek dipertahankan sebagai *cache*. Firebase dan Supabase tidak dipakai untuk penyimpanan data.
- **NFR-02**: Authentication lewat server. Password disimpan sebagai hash memakai `bcrypt` (bukan plaintext). Setiap permintaan data wajib membawa token JWT pada header `Authorization: Bearer <token>`, dan pengguna hanya dapat mengakses datanya sendiri. Token disimpan di HP dengan `flutter_secure_storage`.
- **NFR-03**: Antarmuka mudah digunakan tanpa pelatihan khusus; input token, meter, dan perangkat dapat diselesaikan maksimal 3 langkah dari Dashboard.
- **NFR-04**: Aplikasi berjalan lancar pada Android minimum yang ditentukan proyek (Android 8.0 / API 26 ke atas).
- **NFR-05**: Koneksi: aplikasi memerlukan internet untuk menambah, mengubah, dan menghapus data. Saat tidak ada internet, aplikasi menampilkan data terakhir dari cache SQLite (*read-only*) dan menonaktifkan tombol tambah/ubah/hapus dengan pesan *“Perlu koneksi internet”*. Antrean tulis offline dan sinkronisasi dua arah masuk *Optional / Future Development*.
- **NFR-06**: Notifikasi utama memakai *local notification* (`flutter_local_notifications`, dijadwalkan dari perangkat dengan seri ID terpisah: `1xx` Modul 1, `2xx` Modul 2, `3xx` Modul 3). Penggunaan **FCM (Firebase Cloud Messaging)** diperbolehkan khusus untuk pengiriman notifikasi (bukan penyimpanan data) apabila diperlukan tim.
- **NFR-07**: Hasil perhitungan sesuai rumus pada Bagian 2.8 dan tampil maksimal 2 detik setelah data diterima; konsumsi **aktual** dan **estimasi** selalu dibedakan secara tegas di UI.
- **NFR-08**: Keamanan dasar: rahasia (password database, kunci JWT) disimpan di file `.env` yang tidak di-commit; query SQL memakai *parameterized query* (mencegah *SQL injection*); input divalidasi di aplikasi dan server.
- **NFR-09**: Semua respons API memakai format JSON yang konsisten (Lampiran C), dan aplikasi menampilkan kondisi *loading*, *kosong (empty state)*, dan *error*.

### 2.3 Core Features

| No. | Core Feature | Purpose / Value |
| --- | --- | --- |
| 1 | Autentikasi & Profil Listrik | Mengamankan data tiap akun pengguna dan menentukan tarif otomatis dari golongan + daya. |
| 2 | Pencatatan Token & Meter | Mencatat pembelian token dan saldo kWh sebagai dasar perhitungan konsumsi aktual. |
| 3 | Monitoring Konsumsi (Aktual & Estimasi Perangkat) | Menunjukkan konsumsi sebenarnya dan mengurutkan perangkat dengan estimasi konsumsi terbesar. |
| 4 | Penghematan Listrik | Membantu pengguna menetapkan target, mensimulasikan skenario, mendapat rekomendasi, dan mengevaluasi hasil hemat. |
| 5 | Dashboard & Visualisasi | Memberi gambaran cepat kondisi listrik, konsumsi, pengeluaran, dan progres target lewat minimal 3 grafik. |
| 6 | Riwayat & Notifikasi | Menyimpan jejak aktivitas dan mengingatkan saat saldo rendah, konsumsi melonjak, atau status target berubah. |

### 2.4 User Flow

- **Alur Utama (Autentikasi):** Buka Aplikasi → Cek token JWT → (belum ada / kedaluwarsa) Login/Register → Server memverifikasi → Dashboard. Register: Nama → Email/Username → Password → Validasi → Simpan ke Server → Dashboard.
- **Alur Utama (Profil Listrik – Modul 1):** Dashboard → Profil Listrik → Ambil daftar golongan dan daya dari server → Pilih golongan → Pilih daya → Sistem menentukan tarif otomatis → Simpan ke Server (atau Reset/Hapus bila diperlukan).
- **Alur Utama (Token & Meter – Modul 1):** Dashboard → Tambah Token → Nominal + kWh struk → Simpan ke Server → Riwayat & ringkasan diperbarui. Dashboard → Catat Meter → Saldo kWh + Foto bukti (opsional) → Unggah & Simpan ke Server → Konsumsi aktual & notifikasi dievaluasi.
- **Alur Utama (Monitoring – Modul 2):** Tab Perangkat → Tambah/Ubah/Hapus Perangkat (watt, jumlah, jam) → Kalkulator kWh → Monitoring Konsumsi Aktual & Grafik → Analisis Peringkat Estimasi Perangkat.
- **Alur Utama (Penghematan – Modul 3):** Tab Hemat → Target / Simulasi / Insight Rekomendasi / Evaluasi Penghematan → Simpan ke Server → Evaluasi Notifikasi Target.
- **Alur Tanpa Internet:** Buka Aplikasi → Server tidak terjangkau → Tampilkan data terakhir dari cache SQLite (*hanya baca*) → Tombol tambah/ubah/hapus dinonaktifkan dengan pesan *“Perlu koneksi internet”*.

### 2.5 Data Requirements

| Data / Entity | Key Information | Purpose |
| --- | --- | --- |
| User | `id`, `nama`, `email_username`, `password_hash` | Identitas pengguna dan pemisah data antar akun. |
| Electricity Profile | `id`, `user_id`, `kategori`, `daya_va`, `jenis_listrik`, `saldo_awal_kwh` | Dasar penentuan tarif dan kondisi listrik pengguna. |
| Tariff Configuration | `id`, `kategori`, `daya_va`, `tarif_per_kwh` | Tabel referensi resmi untuk mencari tarif otomatis. |
| Token Purchase | `id`, `user_id`, `tanggal`, `nominal`, `kwh_token` | Dasar konsumsi aktual, pengeluaran, dan riwayat token. |
| Meter Reading | `id`, `user_id`, `tanggal`, `saldo_kwh`, `foto_path` | Dasar konsumsi aktual, bukti foto meter, dan sisa hari. |
| Device | `id`, `user_id`, `nama`, `watt`, `jumlah`, `jam_per_hari` | Dasar estimasi konsumsi, kalkulator, analisis, dan simulasi. |
| Saving Target | `id`, `user_id`, `periode_mulai`, `periode_selesai`, `konsumsi_baseline_kwh`, `target_persen`, `target_konsumsi_kwh` | Dasar monitoring, evaluasi, dan notifikasi target hemat. |
| Saving Simulation | `id`, `user_id`, `device_id`, `nama_perangkat`, `pengurangan_jam_per_hari`, `estimasi_kwh_hemat_bulan`, `estimasi_biaya_hemat` | Menyimpan skenario simulasi penghematan per perangkat. |

Semua tabel di server memiliki `created_at` dan `updated_at`. Relasi: satu `User` memiliki `1:1` `Electricity Profile` dan `1:N` `Token Purchase`, `Meter Reading`, `Device`, `Saving Target`, serta `Saving Simulation`; setiap `Saving Simulation` merujuk ke satu `Device`. Tidak ada entity `Admin`, `Role`, `Permission`, atau `Subsidy`, serta tidak ada kolom `subsidy_status`.

### 2.6 Constraints & Assumptions

- **Aturan Project:** (a) tiap anggota mengerjakan minimal 1 modul dengan minimal 4 fungsionalitas utama + 1 notifikasi; (b) CRUD penuh tersedia di semua modul; (c) data terintegrasi dengan server (Node.js + Express + MySQL) dan cache database lokal (SQLite); (d) tanpa Firebase untuk data dan tanpa Supabase; (e) Flutter UI; (f) minimal satu fitur perangkat keras (kamera untuk foto bukti meter + notifikasi lokal); (g) seluruh modul terintegrasi dalam satu aplikasi di branch `main` dan setiap anggota menguasai penjelasan teknis modulnya.
- Hanya listrik prabayar/token; tidak ada listrik pascabayar, pembelian token langsung, atau pembayaran listrik di aplikasi.
- Hanya satu role (`Pengguna`); tidak ada Admin, Operator, Super Admin, RBAC, atau multi-role.
- Tidak menggunakan PLN API, IoT, OCR, Machine Learning, atau AI sebagai komponen sistem.
- Status subsidi/non-subsidi tidak menjadi parameter aplikasi. Nama golongan dipakai apa adanya sesuai daftar resmi PLN.
- Perhitungan konsumsi dan rekomendasi dilakukan di aplikasi dari data yang diambil lewat API; server fokus pada autentikasi, validasi, penyimpanan MySQL, dan berkas foto.
- Selama pengembangan, backend dijalankan secara lokal (diakses emulator Android lewat `http://10.0.2.2:3000` atau HP fisik lewat IP laptop di jaringan Wi-Fi yang sama).

### 2.7 Success Criteria

- Pengguna dapat register, login, melihat/mengubah nama profil, dan logout lewat server; hanya ada satu role (`Pengguna`).
- Pengguna dapat membuat, melihat, mengubah, dan mereset profil listrik dengan penentuan tarif otomatis dari server.
- Pengguna dapat melakukan CRUD pembelian token (lengkap dengan filter tanggal & ringkasan pengeluaran) serta CRUD saldo meter beserta unggah foto bukti ke server.
- Pengguna dapat melakukan CRUD perangkat, memakai kalkulator kWh, memantau konsumsi aktual, dan melihat peringkat estimasi perangkat.
- Dashboard menampilkan ringkasan listrik, konsumsi, keuangan, penghematan, serta minimal 3 visualisasi.
- Pengguna dapat melakukan CRUD target penghematan, CRUD simulasi berdasarkan perangkat nyata, menerima rekomendasi *rule-based*, dan melihat evaluasi penghematan antarperiode.
- Data pengguna A terisolasi penuh dari pengguna B di server maupun cache.
- Notifikasi lokal Modul 1 (`NTF-01`), Modul 2 (`NTF-02`), dan Modul 3 (`NTF-03`) berfungsi sesuai ambang batas.
- Saat offline, data terakhir tetap dapat dibaca dari SQLite dan aksi tulis dinonaktifkan dengan pesan yang jelas.

### 2.8 Business Logic & Formula

| Nama | Rumus / Aturan |
| --- | --- |
| Konsumsi aktual (ada token masuk) | `Saldo awal + total kWh token masuk − Saldo akhir`. Contoh: `20 + 10 − 15 = 15 kWh` |
| Konsumsi aktual (tanpa token) | `Saldo sebelumnya − Saldo sekarang` |
| kWh perangkat per hari (estimasi) | `(Watt × Jam × Jumlah) ÷ 1000` |
| kWh perangkat per bulan (estimasi) | `kWh/hari × 30` |
| Estimasi biaya | `kWh × Tarif` (tarif dari profil listrik pengguna) |
| Estimasi sisa hari | `Saldo kWh ÷ rata-rata konsumsi kWh/hari`. Contoh: `6 ÷ 4 = 1,5 hari` |
| Kenaikan konsumsi | `(Konsumsi hari ini − rata-rata) ÷ rata-rata × 100%`. Contoh: `(6 − 4) ÷ 4 = 50%` |
| Target konsumsi | `Konsumsi sebelumnya × (1 − % target hemat)`. Contoh: `150 × (1 − 10%) = 135 kWh` |
| Simulasi hemat | `(Watt × jam dikurangi × Jumlah) ÷ 1000` per hari; `× 30` per bulan; `× tarif` untuk biaya |
| Evaluasi penghematan (`FR-12`) | `kWh hemat = Sebelumnya − Sekarang`; `Persentase hemat = (Sebelumnya − Sekarang) ÷ Sebelumnya × 100%` |

**Aturan penjaga data (ditetapkan tim):**

- Periode konsumsi dihitung di antara dua catatan meter berurutan secara kronologis. Token yang dihitung masuk adalah token dengan waktu `> meter sebelumnya` dan `<= meter sekarang` (disimpan lengkap beserta jam & menit).
- Jika hasil konsumsi bernilai negatif, tampilkan peringatan bahwa kemungkinan ada pembelian token yang belum dicatat atau salah input angka meter, dan abaikan periode negatif tersebut dari perhitungan rata-rata *baseline*.
- Rata-rata konsumsi harian (*baseline*) membutuhkan minimal **2 catatan meter** (minimal 1 periode valid). Jika belum cukup, `NTF-01` dan `NTF-02` ditunda.
- Jika kombinasi golongan + daya tidak ditemukan di tabel tarif, tampilkan pesan error yang jelas dan jangan menebak angka tarif.
- Definisi status target (`NTF-03`):
  - **Berisiko**: proyeksi konsumsi akhir periode (`rata-rata harian berjalan × jumlah hari periode`) `> target konsumsi`.
  - **Hampir tercapai**: sisa periode `<= 3 hari` dan proyeksi `<= target konsumsi`.
  - **Tercapai**: periode selesai (`sisa hari <= 0`) dan konsumsi aktual `<= target konsumsi`.
- Nilai `konsumsi_baseline_kwh` disimpan langsung pada `Saving Target` saat target dibuat agar acuan tidak berubah jika riwayat lama diedit.

---

## 3. Scope

### 3.1 In Scope

- Register, Login, Logout, serta lihat & ubah nama pengguna lewat server JWT (satu role).
- CRUD profil listrik (golongan, daya, penentuan tarif otomatis dari server).
- CRUD pembelian token, filter tanggal & ringkasan pengeluaran, serta CRUD catatan meter dengan unggah bukti foto ke server + `NTF-01` (Modul 1).
- CRUD perangkat, kalkulator kWh, monitoring konsumsi aktual, analisis perangkat + `NTF-02` (Modul 2).
- CRUD target penghematan, CRUD simulasi perangkat, rekomendasi *rule-based*, evaluasi penghematan + `NTF-03` (Modul 3).
- Dashboard terpusat (minimal 3 visualisasi), riwayat gabungan, cache lokal SQLite (*read-only* saat offline), dan *local notification*.

### 3.2 Out of Scope

- Admin, Operator, Super Admin, multi-role, dan RBAC.
- Status subsidi/non-subsidi sebagai fitur, field, atau parameter.
- Firebase untuk penyimpanan data, Supabase/BaaS siap pakai, dan PLN API.
- Pembelian token langsung, pembayaran tagihan, listrik pascabayar, dan *smart meter*.
- IoT, OCR, Machine Learning, AI sebagai komponen sistem, dan monitoring *real-time*.
- Fitur air (SDG 6), GPS/peta, laporan kebocoran, serta tips & jadwal perawatan dari v1.1.
- *Optional / Future Development* (tidak dikerjakan sekarang): FCM, antrean tulis offline dua arah, lupa password, ekspor PDF/CSV, dan hosting produksi berbayar.

---

## 4. AI Prompt Context

Aplikasi “Hemat Energi” (SDG 7) untuk mahasiswa/anak kos pengguna listrik prabayar/token, terdiri dari 3 modul di branch `main`: (1) Manajemen Token & Listrik, (2) Monitoring Konsumsi, (3) Penghematan Listrik. Dibangun dengan Flutter (Android) + cache lokal SQLite (`sqflite`) + backend buatan sendiri Node.js + Express + MySQL dengan REST API dan autentikasi JWT (`bcrypt`, `flutter_secure_storage`). Satu role (`Pengguna`). Semua modul mendukung CRUD penuh dan *local notification*.

---

## Lampiran A. Arsitektur & Stack

Alur: **Aplikasi Flutter (HP) → HTTP JSON / Multipart → Backend Express → Database MySQL → Backend → Aplikasi (+ simpan ke Cache SQLite).**

| Bagian | Teknologi yang Ditetapkan |
| --- | --- |
| Aplikasi Mobile | Flutter (Android), `provider`, `http`, `flutter_secure_storage`, `image_picker`, `flutter_local_notifications`, `fl_chart`, `intl` |
| Cache Lokal | **SQLite (`sqflite`)** terpusat pada `lib/core/database_helper.dart` |
| Backend Server | Node.js, Express, `mysql2`, `bcrypt`, `jsonwebtoken`, `multer` (unggah foto meter), `cors`, `dotenv` |
| Database Server | MySQL |
| Struktur Folder Backend | `backend/src/app.js`, `backend/src/config/db.js`, `backend/src/middleware/auth.js`, `backend/src/routes/*.js`, `backend/schema.sql`, `backend/uploads/` |

Catatan pengembangan:
- Emulator Android mengakses server laptop melalui `http://10.0.2.2:3000/api`; HP fisik melalui `http://<IP-Laptop>:3000/api` pada jaringan Wi-Fi yang sama.
- Tambahkan izin `android.permission.INTERNET` dan `android:usesCleartextTraffic="true"` pada `AndroidManifest.xml`.
- File `.env`, `node_modules/`, dan isi `backend/uploads/*` wajib masuk `.gitignore`.

---

## Lampiran B. Skema Database MySQL (`backend/schema.sql`)

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  email_username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tariff_configurations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kategori VARCHAR(50) NOT NULL,
  daya_va INT NOT NULL,
  tarif_per_kwh DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE (kategori, daya_va)
);

CREATE TABLE electricity_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE,
  kategori VARCHAR(50) NOT NULL,
  daya_va INT NOT NULL,
  jenis_listrik VARCHAR(30) NOT NULL DEFAULT 'Prabayar/Token',
  saldo_awal_kwh DECIMAL(10,2) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE token_purchases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  nominal BIGINT NOT NULL,
  kwh_token DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (user_id, tanggal),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE meter_readings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  saldo_kwh DECIMAL(10,2) NOT NULL,
  foto_path VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (user_id, tanggal),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE devices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  nama VARCHAR(100) NOT NULL,
  watt DECIMAL(10,2) NOT NULL,
  jumlah INT NOT NULL DEFAULT 1,
  jam_per_hari DECIMAL(4,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE saving_targets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  periode_mulai DATE NOT NULL,
  periode_selesai DATE NOT NULL,
  konsumsi_baseline_kwh DECIMAL(10,2) NOT NULL,
  target_persen DECIMAL(5,2) NOT NULL,
  target_konsumsi_kwh DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE saving_simulations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  device_id INT NOT NULL,
  nama_perangkat VARCHAR(100) NOT NULL,
  pengurangan_jam_per_hari DECIMAL(4,2) NOT NULL,
  estimasi_kwh_hemat_bulan DECIMAL(10,2) NOT NULL,
  estimasi_biaya_hemat DECIMAL(14,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
);
```

---

## Lampiran C. Daftar Endpoint REST API

Base path: `/api`. Semua endpoint selain `/api/auth/register` dan `/api/auth/login` wajib menyertakan header `Authorization: Bearer <token>`. Server selalu memfilter `user_id` dari payload JWT (bukan dari body/query klien).

- Format sukses: `{ "success": true, "data": ... }`
- Format gagal: `{ "success": false, "message": "..." }`
- Kode HTTP: `200`/`201` sukses, `400` validasi gagal, `401` belum login/token salah, `404` data tidak ditemukan, `500` gangguan server.

| Method | Path | Fungsi | Pemilik |
| --- | --- | --- | --- |
| `POST` | `/api/auth/register` | Daftar akun baru (`nama`, `email_username`, `password`) | Zikri |
| `POST` | `/api/auth/login` | Login, mengembalikan token JWT dan data user | Zikri |
| `GET`, `PUT` | `/api/auth/me` | Lihat dan ubah nama profil pengguna (`AUTH-04`) | Zikri |
| `GET` | `/api/tariffs` | Daftar golongan, daya VA, dan tarif resmi PLN | Zikri |
| `POST`, `GET`, `PUT`, `DELETE` | `/api/profile` | Buat, lihat, ubah, dan hapus/reset profil listrik pengguna | Zikri |
| `GET`, `POST` | `/api/tokens` | Daftar (mendukung query `?from=YYYY-MM-DD&to=YYYY-MM-DD`) & tambah token | Zikri |
| `PUT`, `DELETE` | `/api/tokens/:id` | Ubah dan hapus pembelian token | Zikri |
| `GET` | `/api/tokens/summary?month=YYYY-MM` | Ringkasan pembelian bulanan & total pengeluaran | Zikri |
| `GET`, `POST` | `/api/meter-readings` | Daftar & tambah catatan meter (`POST` mendukung `multipart/form-data` foto) | Zikri |
| `PUT`, `DELETE` | `/api/meter-readings/:id` | Ubah dan hapus catatan meter | Zikri |
| `GET`, `POST` | `/api/devices` | Daftar dan tambah perangkat pengguna | Kevin |
| `PUT`, `DELETE` | `/api/devices/:id` | Ubah dan hapus perangkat pengguna | Kevin |
| `GET`, `POST` | `/api/targets` | Daftar dan tambah target penghematan | Fauzin |
| `PUT`, `DELETE` | `/api/targets/:id` | Ubah dan hapus target penghematan | Fauzin |
| `GET`, `POST` | `/api/simulations` | Daftar dan simpan hasil simulasi penghematan | Fauzin |
| `PUT`, `DELETE` | `/api/simulations/:id` | Ubah dan hapus hasil simulasi penghematan | Fauzin |

---

## Lampiran D. Strategi Pengerjaan Bertahap di Proyek yang Sudah Ada

1. **Pertahankan UI & Rumus yang Sudah Jalan:** Jangan membangun ulang dari nol. Seluruh branch modul sudah disatukan di branch `main`.
2. **Lengkapi Kekurangan Fitur Lokal Tiap Modul Lebih Dulu:** Pastikan CRUD, evaluasi, label *"estimasi"*, dan pemicu notifikasi lokal masing-masing modul beres sebelum menyambungkan API.
3. **Bangun Lapisan `ApiClient` & Repository:** Satu kelas `ApiClient` bersama menangani URL server, token JWT dari `flutter_secure_storage`, dan pembacaan error JSON. Setiap modul mengakses data melalui kelas Repository-nya.
4. **Urutan Migrasi ke Server:**
   `Kerangka backend & schema.sql` → `Auth JWT (/auth)` → `Tarif & Profil (/tariffs, /profile)` → `Token (/tokens)` → `Meter + Foto (/meter-readings)` → `Perangkat (/devices)` → `Target & Simulasi (/targets, /simulations)` → `Mode Offline Read-Only & Penyempurnaan Dashboard`.
5. **Pola Cache Offline:** Setiap `GET` ke server yang berhasil akan memperbarui tabel SQLite lokal. Jika internet terputus, aplikasi membaca dari SQLite lokal dan mengunci tombol tambah/ubah/hapus.
6. **Aturan Git Bersama (Hanya Branch `main`):** Selalu jalankan `git pull origin main --rebase` sebelum mulai kerja, pastikan `flutter analyze` bersih sebelum commit, buat commit kecil dan jelas, **dilarang `git push --force`**, dan jangan pernah commit `.env` atau `node_modules/`.

---

## Lampiran E. Aturan untuk AI Coding Assistant

- Dilarang menambah role (`Admin`, `Operator`, `RBAC`), fitur subsidi (`subsidy_status`), input tarif manual, PLN API, OCR, atau Machine Learning/AI.
- Dilarang memakai Firebase untuk data ataupun Supabase; wajib Node.js + Express + MySQL.
- Jangan mengarang angka tarif di luar tabel Lampiran H.
- Kerjakan bertahap per fitur, ubah sesedikit mungkin file pada satu waktu, dan jelaskan setiap perubahan dengan bahasa Indonesia yang sederhana agar seluruh anggota tim paham saat *code review*.
- Simpan konfigurasi rahasia hanya di `.env` dan catat pemakaian AI pada *AI Usage Log*.

---

## Lampiran F. Keputusan Teknis yang Telah Ditetapkan Tim

Seluruh poin terbuka dari draf sebelumnya telah ditetapkan sebagai berikut agar seluruh anggota tim langsung selaras:

1. **Tabel Tarif Resmi PLN:** Menggunakan 6 kombinasi golongan Rumah Tangga Tegangan Rendah resmi PLN sesuai Lampiran H.
2. **Ambang Notifikasi:** Saldo rendah `<= 2 hari` (`NTF-01`), lonjakan konsumsi `>= 30%` di atas rata-rata (`NTF-02`), dan target hampir tercapai `sisa <= 3 hari` (`NTF-03`).
3. **Database Cache Lokal:** Ditetapkan menggunakan **SQLite (`sqflite`)** yang sudah aktif di `lib/core/database_helper.dart`.
4. **Mekanisme Notifikasi:** Menggunakan **Local Notification (`flutter_local_notifications`)** karena jauh lebih ringkas dan tidak memerlukan setup server Firebase tambahan; namun **FCM (Firebase Cloud Messaging)** tetap diperbolehkan khusus untuk fitur notifikasi (selama tidak memakai Firebase untuk penyimpanan data).
5. **Lingkungan Demo Backend:** Server Express + MySQL dijalankan di laptop saat demo (`10.0.2.2:3000` untuk emulator atau IP lokal Wi-Fi untuk HP fisik).

---

## Lampiran G. Pembagian Modul, Kepemilikan File, & Checklist Tugas per Anggota

### G.1 Ringkasan Tanggung Jawab

| Anggota | Modul & Lingkup | Kode Kebutuhan | File Utama di Flutter | File di Backend |
| --- | --- | --- | --- | --- |
| **Alfi Zikri** (2411521002) | Pondasi Backend, Auth, Modul 1 (Token & Listrik), Dashboard, Riwayat | `AUTH-01..04`, `FR-01..04`, `NTF-01`, `DB-01..02`, `RW-01` | `lib/presentation/auth/`, `lib/presentation/electricity/`, `lib/presentation/dashboard/`, `lib/data/repositories/{user,electricity_profile,token_purchase,meter_reading}_repository.dart` | `src/app.js`, `config/db.js`, `middleware/auth.js`, `routes/{auth,tariffs,profile,tokens,meterReadings}.js`, `schema.sql` |
| **Kevin Rahmat Illahi** (2411522006) | Modul 2 – Monitoring Konsumsi & Perangkat | `FR-05..08`, `NTF-02` | `lib/screens/`, `lib/models/`, `lib/services/`, `lib/data/repositories/device_repository.dart` *(baru)* | `src/routes/devices.js` |
| **Fauzin Azimi** (2311522003) | Modul 3 – Penghematan Listrik | `FR-09..12`, `NTF-03` | `lib/presentation/saving/`, `lib/data/models/saving_*.dart`, `lib/data/repositories/saving_repository.dart`, `lib/domain/services/{saving_*,recommendation_service}.dart` | `src/routes/targets.js`, `src/routes/simulations.js` |

### G.2 Checklist Pekerjaan Spesifik Tiap Anggota (Pasca-Merge ke `main`)

**1. Tugas Alfi Zikri (Auth, Modul 1, Kerangka Backend, Dashboard):**
- [ ] Melengkapi fitur lokal Modul 1 & Auth: ubah nama profil (`AUTH-04`), dukung login/register email atau username (`AUTH-01/02`), hapus/reset profil listrik (`FR-01`), filter rentang tanggal & total pengeluaran token (`FR-04`), serta pemicu notifikasi lokal saldo rendah (`NTF-01`).
- [ ] Membuat kerangka `backend/` (Express + MySQL + `schema.sql` + `multer` + JWT) dan `ApiClient` bersama di Flutter.
- [ ] Menyambungkan Auth, Tarif, Profil Listrik, Pembelian Token, dan Catatan Meter (+ upload foto) ke API server + cache SQLite + mode offline baca-saja.
- [ ] Melengkapi Dashboard (`DB-01`, `DB-02`: 3 visualisasi & ringkasan keuangan/target) dan tab Penghematan pada Riwayat (`RW-01`) setelah repository Modul 2 & 3 siap.

**2. Tugas Kevin Rahmat Illahi (Modul 2 – Monitoring Konsumsi):**
- [ ] Menambahkan fitur **Ubah / Edit Perangkat** di UI (`AddDeviceScreen` / `DeviceDetailScreen`) agar CRUD perangkat (`FR-05`) lengkap 100%.
- [ ] Memperbaiki teks badge pada `DeviceDetailScreen` menjadi *“Perangkat dengan **estimasi** konsumsi terbesar”* sesuai aturan `FR-08`, serta membersihkan tombol simulasi dummy pada `MonitoringScreen`.
- [ ] Menambahkan dukungan `user_id` pada data perangkat dan membuat `DeviceRepository` yang memanggil `ApiClient` + menyimpan cache ke SQLite.
- [ ] Menulis route backend `backend/src/routes/devices.js` (`GET`, `POST`, `PUT`, `DELETE /api/devices`) dan memastikan `NTF-02` ikut terpanggil saat catatan meter baru disimpan.

**3. Tugas Fauzin Azimi (Modul 3 – Penghematan Listrik):**
- [ ] Membuat fitur & tampilan **Evaluasi Penghematan (`FR-12`)**: menghitung selisih kWh hemat, persentase penghematan antarperiode, dan status ketercapaian target.
- [ ] Melepas ketergantungan `SavingDummyData` pada `SimulationScreen`, `RecommendationScreen`, dan `SavingRepository` agar membaca daftar perangkat asli dari Modul 2 serta konsumsi aktual & tarif dari Modul 1.
- [ ] Mengaktifkan pemanggilan otomatis `SavingNotificationService.instance.cekTarget()` (`NTF-03`).
- [ ] Menulis route backend `backend/src/routes/targets.js` & `backend/src/routes/simulations.js` serta menyambungkan `SavingRepository` ke API server + cache SQLite (`saving_targets` & `saving_simulations`).

> **Aturan Koordinasi File Bersama:** File `lib/main.dart`, `pubspec.yaml`, `lib/core/database_helper.dart`, dan `lib/presentation/shared/main_navigation_screen.dart` dipakai bersama oleh ketiga modul. Kevin dan Fauzin harap berkoordinasi dengan Zikri sebelum mengubah keempat file tersebut agar tidak terjadi konflik saat `git pull` / `git push`.

---

## Lampiran H. Data Konfigurasi Tarif Resmi PLN (`tariff_configurations`)

Mengacu pada **Peraturan Menteri ESDM Nomor 7 Tahun 2024** dan pengumuman resmi **Penetapan Penyesuaian Tarif Tenaga Listrik PT PLN (Persero)** untuk golongan Rumah Tangga Tegangan Rendah (`TR`), berikut data seed resmi yang digunakan di server (`schema.sql`) dan cache lokal (`assets/tariff_seed.json`):

| Kategori / Golongan | Daya (VA) | Tarif (Rp/kWh) | Sumber Acuan Resmi |
| --- | --- | --- | --- |
| `Rumah Tangga R-1/TR` | `900` | `1352.00` | Halaman Tarif Tenaga Listrik PLN & Permen ESDM No. 7/2024 (R-1/TR RTM) |
| `Rumah Tangga R-1/TR` | `1300` | `1444.70` | Halaman Tarif Tenaga Listrik PLN & Permen ESDM No. 7/2024 |
| `Rumah Tangga R-1/TR` | `2200` | `1444.70` | Halaman Tarif Tenaga Listrik PLN & Permen ESDM No. 7/2024 |
| `Rumah Tangga R-2/TR` | `3500` | `1699.53` | Halaman Tarif Tenaga Listrik PLN & Permen ESDM No. 7/2024 |
| `Rumah Tangga R-2/TR` | `5500` | `1699.53` | Halaman Tarif Tenaga Listrik PLN & Permen ESDM No. 7/2024 |
| `Rumah Tangga R-3/TR` | `6600` | `1699.53` | Halaman Tarif Tenaga Listrik PLN & Permen ESDM No. 7/2024 |

Catatan:
- Tidak ada kolom subsidi/non-subsidi; pemilihan tarif dilakukan murni berdasarkan pasangan unik `(kategori, daya_va)`.
- Jika terjadi perubahan ketetapan tarif triwulanan dari Kementerian ESDM/PLN, pembaruan cukup dilakukan pada tabel `tariff_configurations` di database server tanpa mengubah rumus aplikasi.
