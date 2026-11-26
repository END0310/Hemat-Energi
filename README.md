# Hemat Energi (SDG 7) ⚡🌱

Aplikasi mobile **Flutter (Android)** untuk membantu mahasiswa dan anak kos pengguna listrik prabayar (token) mencatat pembelian token dan saldo meter, memantau konsumsi listrik aktual vs estimasi perangkat, serta menyusun dan mengevaluasi target penghematan listrik sejalan dengan **SDG 7 (Energi Bersih & Terjangkau)**.

Dokumen spesifikasi lengkap dan terbaru dapat dibaca di **[Product Requirements Document.md](./Product%20Requirements%20Document.md)** *(Versi 3.1)*.

---

## 👥 Tim Pengembang & Pembagian Modul

| Nama | NIM | Tanggung Jawab Utama | Kode Fitur PRD |
| --- | --- | --- | --- |
| **Alfi Zikri** | 2411521002 | Kerangka Backend, Autentikasi, Modul 1 (Manajemen Token & Listrik), Dashboard, Riwayat | `AUTH-01..04`, `FR-01..04`, `NTF-01`, `DB-01..02`, `RW-01` |
| **Kevin Rahmat Illahi** | 2411522006 | Modul 2 – Monitoring Konsumsi & Perangkat | `FR-05..08`, `NTF-02` |
| **Fauzin Azimi** | 2311522003 | Modul 3 – Penghematan Listrik | `FR-09..12`, `NTF-03` |

---

## 🏗️ Arsitektur & Teknologi

Sesuai aturan proyek terbaru pada PRD v3.1:
- **Mobile App:** Flutter, `provider` (state management), `http`, `flutter_secure_storage` (penyimpanan token JWT), `image_picker` (kamera/galeri bukti meter), `flutter_local_notifications`, `fl_chart`.
- **Cache Lokal (Offline Read-Only):** SQLite (`sqflite`) terpusat pada `lib/core/database_helper.dart`.
- **Backend Server:** Node.js + Express + MySQL (`mysql2`, `bcrypt`, `jsonwebtoken`, `multer`, `cors`, `dotenv`) di dalam folder `backend/`.
- **Tanpa** Firebase untuk penyimpanan data (FCM dibolehkan khusus notifikasi, namun proyek memakai `flutter_local_notifications` agar lebih simpel tanpa konfigurasi konsol Firebase), **tanpa** Supabase, **satu role** (`Pengguna`), dan **CRUD penuh** di semua modul.

---

## 📂 Peta Struktur Folder & Kepemilikan File

Seluruh kode modul kini sudah digabungkan ke satu branch utama (`main`). Agar tidak saling menimpa pekerjaan teman satu tim, perhatikan pembagian folder berikut:

```text
hemat_energi/
├── assets/
│   └── tariff_seed.json              # Data tarif resmi PLN (Modul 1)
├── backend/                          # Server Node.js + Express + MySQL (Disiapkan Zikri)
│   ├── schema.sql                    # Skema 8 tabel MySQL + seed tarif PLN
│   └── src/
│       ├── app.js, config/, middleware/
│       └── routes/
│           ├── auth.js, tariffs.js, profile.js, tokens.js, meterReadings.js  # (Zikri)
│           ├── devices.js            # (Ditulis oleh Kevin - Modul 2)
│           └── targets.js, simulations.js  # (Ditulis oleh Fauzin - Modul 3)
├── lib/
│   ├── core/                         # [FILE BERSAMA] Konfigurasi tema, konstanta, DatabaseHelper SQLite
│   ├── data/
│   │   ├── models/                   # Model data Modul 1 & Modul 3
│   │   └── repositories/             # Pintu akses data (API + Cache SQLite) tiap modul
│   ├── domain/services/              # Rumus murni & layanan notifikasi Modul 1 & Modul 3
│   ├── presentation/
│   │   ├── auth/                     # Login, Register, Profil Akun (Zikri)
│   │   ├── dashboard/                # Beranda & 3 Visualisasi Utama (Zikri)
│   │   ├── electricity/              # Profil Listrik, Token, Meter, Riwayat (Zikri - Modul 1)
│   │   ├── saving/                   # Target, Simulasi, Insight, Evaluasi (Fauzin - Modul 3)
│   │   └── shared/                   # Navigasi bawah 5 tab [FILE BERSAMA]
│   ├── models/                       # Model perangkat & konsumsi (Kevin - Modul 2)
│   ├── screens/                      # Layar Perangkat, Kalkulator, Monitoring, Analisis (Kevin - Modul 2)
│   ├── services/                     # Kalkulator energi & notifikasi lonjakan (Kevin - Modul 2)
│   └── main.dart                     # [FILE BERSAMA] Entry point & daftar route
└── test/                             # Unit test seluruh modul
```

> ⚠️ **Penting (Koordinasi File Bersama):**
> File `lib/main.dart`, `pubspec.yaml`, `lib/core/database_helper.dart`, dan `lib/presentation/shared/main_navigation_screen.dart` dipakai bersama. Harap beri tahu di grup sebelum mengedit file-file tersebut supaya tidak terjadi *merge conflict*.

---

## ✅ Daftar Tugas & Progres per Anggota (Mengacu PRD v3.1)

### 1. Alfi Zikri — Pondasi, Auth, Modul 1, & Dashboard
- [x] Menggabungkan seluruh branch modul ke branch `main` dan menyatukan database SQLite otomatis.
- [x] Melengkapi fitur lokal Auth & Modul 1: ubah nama profil (`AUTH-04`), login/register email atau username (`AUTH-01/02`), hapus/reset profil listrik (`FR-01`), scroll filter tanggal Hari–Bulan–Tahun & total pengeluaran token (`FR-04`), tombol isi data dummy, serta notifikasi lokal saldo rendah (`NTF-01`).
- [x] Membangun kerangka `backend/` (Express + MySQL + `schema.sql` + *auto-migration* otomatis tanpa import manual + middleware JWT + upload foto `multer`) beserta seluruh endpoint API Auth & Modul 1 (`/api/auth`, `/api/tariffs`, `/api/profile`, `/api/tokens`, `/api/meter-readings`).
- [ ] Membuat `ApiClient` & `flutter_secure_storage` di Flutter lalu menyambungkan layar Auth & Modul 1 ke server beserta mode offline baca-saja (`NFR-05`).
- [ ] Melengkapi 3 visualisasi Dashboard (`DB-02`) dan tab Penghematan pada Riwayat (`RW-01`).

### 2. Kevin Rahmat Illahi — Modul 2 (Monitoring Konsumsi)
- [ ] Menambahkan fitur **Ubah / Edit Perangkat** pada UI (`AddDeviceScreen` / `DeviceDetailScreen`) agar CRUD perangkat (`FR-05`) lengkap.
- [ ] Menambahkan kata **“estimasi”** pada badge peringkat di `lib/screens/device_detail_screen.dart` (*“Perangkat dengan estimasi konsumsi terbesar”* sesuai `FR-08`) dan merapikan tombol dummy di `MonitoringScreen`.
- [ ] Melengkapi isi query CRUD (`GET`, `POST`, `PUT /:id`, `DELETE /:id`) pada file `backend/src/routes/devices.js` *(kerangka route, middleware JWT `req.user.id`, dan tabel `devices` MySQL dari Zikri **sudah siap** dipakai)*.
- [ ] Membuat `DeviceRepository` di Flutter untuk menghubungkan layar Modul 2 ke `/api/devices` + cache SQLite per `user_id`.

### 3. Fauzin Azimi — Modul 3 (Penghematan Listrik)
- [ ] Menambahkan fitur & layar/kartu **Evaluasi Penghematan (`FR-12`)** di Modul 3 (membandingkan konsumsi periode sebelumnya vs sekarang: kWh hemat, persentase hemat, dan status target).
- [ ] Mengganti sumber data `SavingDummyData` pada `SimulationScreen` dan `RecommendationScreen` agar membaca daftar perangkat asli dari Modul 2 serta tarif & konsumsi aktual dari Modul 1.
- [ ] Mengaktifkan pemanggilan otomatis notifikasi target `SavingNotificationService.instance.cekTarget()` (`NTF-03`).
- [ ] Melengkapi isi query CRUD pada file `backend/src/routes/targets.js` & `backend/src/routes/simulations.js` *(kerangka route, middleware JWT, dan tabel `saving_targets` + `saving_simulations` MySQL dari Zikri **sudah siap** dipakai)*, lalu menyambungkan `SavingRepository` ke API server + cache SQLite.

---

## 🚀 Cara Menjalankan Proyek di Lokal

### A. Menjalankan Server Backend (Otomatis Buat Database Tanpa Import Manual)
1. Nyalakan **MySQL** di **XAMPP** atau **Laragon**.
2. Buka terminal di folder `hemat_energi/backend`:
   ```bash
   # Salin konfigurasi .env (cukup 1 kali saat pertama kali pull)
   cp .env.example .env

   # Instal package Node.js (cukup 1 kali di awal)
   npm install

   # Jalankan server (otomatis membuat DB hemat_energi, 8 tabel, & tarif PLN!)
   npm run dev
   ```
3. Cek di browser: buka `http://localhost:3000/api/health` (pastikan muncul `"database": "connected"`).

### B. Menjalankan Aplikasi Flutter
Buka terminal lain pada folder utama `hemat_energi`:

```bash
# 1. Unduh seluruh package Flutter
flutter pub get

# 2. Cek apakah ada error analisis kode
flutter analyze

# 3. Jalankan seluruh unit test (Modul 1, 2, dan 3)
flutter test

# 4. Jalankan aplikasi ke emulator Android / perangkat terhubung
flutter run
```

---

## 🔄 Aturan Kerja Git Bersama (Hanya Pakai Branch `main`)

Kita sekarang bekerja sendiri-sendiri di waktu fleksibel cukup menggunakan **satu branch `main`** saja. Ikuti urutan wajib ini setiap kali bekerja:

### 1. Saat Pertama Kali Pindah ke Branch `main` Terbaru
Bagi anggota tim yang sebelumnya masih berada di branch `modul-2` atau `modul-3`:
```bash
git fetch origin
git checkout main
git pull origin main
flutter pub get
```

### 2. Setiap Kali Akan Mulai Ngoding & Sebelum Push
```bash
# WAJIB tarik update terbaru dari teman lain dulu sebelum mulai ngoding:
git pull origin main --rebase

# ... kerjakan fitur pada file modul masing-masing ...

# Cek kode tidak ada error sebelum commit:
flutter analyze

# Simpan dan kirim ke GitHub:
git add .
git commit -m "feat(modul-2): tambah fitur edit perangkat"
git pull origin main --rebase
git push origin main
```

### 🚫 Larangan Git di Branch `main`
1. **Jangan pernah** menjalankan `git push --force` supaya commit teman satu tim tidak terhapus.
2. **Jangan pernah** meng-commit file rahasia `.env`, folder `node_modules/`, atau foto hasil tes di `backend/uploads/`.
