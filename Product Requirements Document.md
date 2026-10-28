Product Requirements Document — Hemat Energi (SDG 7)
Mata Kuliah: Mobile Programming
Tim: Alfi Zikri (2411521002), Kevin Rahmat Illahi (2411522006), Fauzin Azimi (2311522003)
Versi: 2.0 (revisi dari v1.1 "Hemat Air & Energi")
Tanggal: 5 Oktober 2026
Ringkasan perubahan dari v1.1: fokus dipersempit ke listrik prabayar/token (SDG 7); fitur air, GPS/peta, laporan kebocoran, serta Tips & Perawatan dihapus; ditambahkan Authentication lokal (Register/Login/Logout); tarif kini ditentukan dari konfigurasi kategori/golongan + daya (bukan input bebas); konsumsi aktual dipisahkan dari konsumsi estimasi; tiga modul disusun ulang.
1. Project Overview
Hemat Energi adalah aplikasi mobile Android (Flutter) untuk membantu pengguna listrik prabayar/token memantau dan menghemat listrik. Pengguna mencatat pembelian token, saldo kWh di meter, dan perangkat listrik yang dimiliki. Aplikasi lalu menghitung konsumsi aktual, memperkirakan konsumsi per perangkat, memantau pengeluaran, membuat target hemat, mensimulasikan penghematan, dan memberi rekomendasi sederhana.
Fokus produk: monitoring dan penghematan listrik prabayar/token. Aplikasi ini bukan sistem PLN dan bukan sistem manajemen energi yang kompleks.
2. Background
SDG 7 menargetkan energi yang bersih dan terjangkau. Pada skala individu, hal ini berarti pengguna mampu mengendalikan pemakaian dan biaya listrik. Mahasiswa dan anak kos yang mengelola listrik prabayar sendiri membeli token secara berkala, tetapi jarang tahu seberapa cepat saldo kWh berkurang dan perangkat mana yang paling boros. Akibatnya, token sering habis mendadak dan pengeluaran sulit direncanakan.
Versi sebelumnya (v1.1) mencakup air dan listrik. Revisi ini mempersempit ruang lingkup agar lebih fokus, lebih realistis untuk project Mobile Programming, dan konsisten dengan aturan project (tanpa Firebase, data lokal, notifikasi per modul, memakai fitur perangkat).
3. Problem Statement
Mahasiswa dan anak kos pengguna listrik token sulit mengetahui pemakaian listrik sebenarnya, perangkat mana yang paling boros, dan kapan saldo token akan habis. Tanpa pencatatan yang mudah, mereka sulit mengatur pengeluaran listrik dan menyusun target penghematan yang terukur.
4. Target User
•	Mahasiswa dan anak kos yang tinggal mandiri di kos atau kontrakan;
•	Pengguna yang mengelola listrik prabayar/token sendiri;
•	Memiliki smartphone Android dan bersedia mencatat data secara manual.
5. User Pain Points
•	Tidak tahu seberapa cepat saldo kWh berkurang, sehingga token sering habis mendadak.
•	Tidak tahu konsumsi listrik yang sebenarnya karena tidak ada pencatatan yang konsisten.
•	Tidak tahu perangkat mana yang paling boros.
•	Sulit memperkirakan dan mengendalikan pengeluaran token tiap bulan.
•	Tidak tahu langkah hemat yang paling berdampak dan tidak bisa mengukur hasilnya.
6. Product Goals
1.	Memudahkan pencatatan pembelian token dan saldo meter secara manual.
2.	Menampilkan konsumsi listrik aktual yang dihitung dari data token dan meter.
3.	Memberi estimasi konsumsi per perangkat (dan menandainya jelas sebagai estimasi).
4.	Memperkirakan sisa hari saldo dan memantau pengeluaran listrik.
5.	Membantu pengguna menyusun target hemat, mensimulasikan penghematan, dan mengevaluasi hasilnya.
6.	Berjalan offline dengan data tersimpan di perangkat.
7. User Role
Aplikasi hanya memiliki satu role: Pengguna (User). Tidak ada Admin, Operator, Super Admin, Petugas, Moderator, Manager, atau role lain. Semua pengguna memiliki hak akses fitur yang sama. Tidak ada RBAC (pembagian hak akses berdasarkan peran).
Aplikasi
├── Authentication
│   ├── Register
│   └── Login
└── Pengguna
    ├── Profil Listrik
    ├── Token
    ├── Meter
    ├── Perangkat
    ├── Dashboard
    ├── Monitoring
    ├── Penghematan
    └── Riwayat
Login tidak berarti aplikasi memiliki banyak role. Login hanya mengidentifikasi pengguna dan melindungi data lokal miliknya.
8. Authentication
Authentication bersifat lokal (Local Authentication — akun dan proses verifikasi sepenuhnya di perangkat, tanpa server). Tidak memakai Firebase Authentication, Google Sign-In, server, backend, atau API authentication.
ID	Fitur	Deskripsi
AUTH-01	Register	Pengguna membuat akun dengan nama, email/username, dan password. Validasi: semua field wajib diisi, email/username unik di perangkat, password memenuhi panjang minimum.
AUTH-02	Login	Pengguna masuk dengan email/username dan password. Jika valid → Dashboard; jika tidak → pesan error login.
AUTH-03	Logout	Pengguna keluar dan diarahkan ke halaman Login. Logout tidak menghapus data pengguna.
Keamanan credential: password tidak boleh disimpan sebagai plaintext (teks asli). Simpan dalam bentuk hash (hasil pengacakan satu arah yang tidak bisa dikembalikan ke password asli) dengan salt (nilai acak tambahan agar dua password yang sama menghasilkan hash berbeda). Status login (session) disimpan secara lokal sehingga pengguna yang sudah login langsung masuk ke Dashboard saat aplikasi dibuka.
Alur: Buka aplikasi → cek status login → belum login: halaman Login/Register → valid: Dashboard; sudah login: langsung Dashboard.
Semua data (profil listrik, token, meter, perangkat, target, simulasi) terikat ke user_id sehingga tiap akun hanya melihat datanya sendiri.
9. Product Scope
Aplikasi hanya mendukung listrik prabayar/token. Pembahasan lengkap scope ada pada bagian 24 (In Scope) dan 25 (Out of Scope).
Keputusan scope penting:
•	Status subsidi/non-subsidi tidak menjadi fitur, field (subsidy_status), pilihan UI, maupun bagian business logic.
•	Tarif tetap dipakai dalam perhitungan biaya, tetapi ditentukan dari kategori/golongan + daya yang dipilih pengguna, bukan input bebas.
•	Fitur tambahan yang tidak ada di dokumen ini ditandai Optional / Future Development dan tidak diimplementasikan lebih dulu.
10. Functional Requirements
Ringkasan seluruh FR. Setiap modul memiliki 4 fungsionalitas utama dan 1 notifikasi, sesuai aturan project (minimal 4 fungsionalitas terintegrasi per modul, notifikasi per modul).
ID	Fungsionalitas	Modul
FR-01	Profil Listrik	1
FR-02	Pencatatan Pembelian Token	1
FR-03	Pencatatan Saldo Meter (+ foto opsional)	1
FR-04	Riwayat Token	1
FR-05	Daftar Perangkat	2
FR-06	Kalkulator Konsumsi kWh	2
FR-07	Monitoring Konsumsi Aktual	2
FR-08	Analisis Perangkat	2
FR-09	Target Penghematan	3
FR-10	Simulasi Penghematan	3
FR-11	Rekomendasi Berbasis Aturan	3
FR-12	Evaluasi Penghematan	3
Setiap data yang dikelola mendukung CRUD (Create, Read, Update, Delete — tambah, lihat, ubah, hapus) pada layar masing-masing.
11. Module 1 — Manajemen Token & Listrik
Mengelola profil listrik, pembelian token, saldo, dan catatan meter.
FR-01 — Profil Listrik
Pengguna dapat membuat dan mengubah profil listrik.
•	Data: kategori/golongan listrik, daya listrik, jenis listrik (Prabayar/Token, tetap), dan saldo awal kWh jika diperlukan.
•	Tarif tidak diketik pengguna. Sistem mencari tarif dari konfigurasi: kategori/golongan + daya → tarif.
•	Satu pengguna memiliki satu profil listrik (relasi 1:1).
FR-02 — Pencatatan Pembelian Token
Pengguna mencatat transaksi pembelian token.
•	Input: tanggal, nominal pembelian (Rp), jumlah kWh token yang diperoleh.
•	kWh token tidak dihitung dari nominal ÷ tarif. Pengguna memasukkan kWh sesuai informasi yang benar-benar diterima pada transaksi/token. Sistem menyimpan nominal dan kWh apa adanya.
•	Contoh: nominal Rp100.000, kWh diperoleh 68,5 kWh → keduanya disimpan.
FR-03 — Pencatatan Saldo Meter
Pengguna mencatat saldo kWh yang terlihat di meter.
•	Input: tanggal, saldo kWh, foto meter (opsional, memakai kamera/galeri sebagai bukti atau arsip).
•	Foto tidak dibaca dengan OCR (pengenalan teks otomatis dari gambar). Angka tetap dimasukkan manual.
•	Foto meter adalah fitur perangkat (kamera) yang memenuhi syarat aturan project.
•	Setelah disimpan, sistem menghitung konsumsi aktual (lihat bagian 17).
FR-04 — Riwayat Token
Menampilkan daftar transaksi token: tanggal, nominal, kWh, serta total pembelian. Pengguna dapat mengubah atau menghapus transaksi.
Notifikasi Modul 1 — Saldo Token Rendah
Sistem memperkirakan lama saldo bertahan dari rata-rata konsumsi harian.
•	Contoh: saldo 6 kWh, rata-rata 4 kWh/hari → 6 ÷ 4 = 1,5 hari.
•	Notifikasi lokal dikirim jika estimasi sisa hari ≤ ambang batas. Usulan default: 2 hari, dapat diatur tim/pengguna.
•	Notifikasi hanya muncul jika data rata-rata sudah tersedia (minimal dua catatan meter).
12. Module 2 — Monitoring Konsumsi
Memantau konsumsi listrik. Dua jenis konsumsi harus dibedakan di seluruh UI dan logika:
	Konsumsi Aktual	Konsumsi Estimasi
Sumber	Saldo meter + transaksi token	Perangkat: watt, jumlah, jam pakai
Sifat	Data hasil pencatatan nyata	Perkiraan/hitungan teoretis
Konsumsi estimasi tidak boleh ditampilkan atau dianggap sebagai konsumsi aktual.
FR-05 — Daftar Perangkat
CRUD perangkat listrik. Data: nama perangkat, daya (watt), jumlah, jam penggunaan per hari.
FR-06 — Kalkulator Konsumsi kWh
•	kWh/hari = (Watt × Jam Penggunaan × Jumlah) ÷ 1000
•	kWh/bulan = kWh/hari × 30
•	Biaya = kWh × Tarif (tarif dari profil listrik pengguna)
•	Hasil selalu berlabel estimasi.
FR-07 — Monitoring Konsumsi Aktual
Menghitung konsumsi aktual dari data meter dan token.
•	Contoh: saldo awal 20 kWh + token masuk 10 kWh − saldo akhir 15 kWh = 15 kWh.
•	Menampilkan konsumsi per periode, rata-rata harian, dan grafik mingguan.
FR-08 — Analisis Perangkat
Mengurutkan perangkat berdasarkan estimasi konsumsi terbesar.
Perangkat	Estimasi
AC	120 kWh/bulan
Kulkas	45 kWh/bulan
TV	15 kWh/bulan
•	Kalimat yang benar: "AC merupakan perangkat dengan estimasi konsumsi terbesar."
•	Kalimat yang tidak boleh dipakai: "AC menggunakan 120 kWh aktual."
Notifikasi Modul 2 — Konsumsi Meningkat
Membandingkan konsumsi dengan rata-rata (baseline).
•	Contoh: rata-rata 4 kWh/hari, hari ini 6 kWh → naik 50%.
•	Notifikasi lokal dikirim jika kenaikan melewati ambang batas. Usulan default: 30%, dapat dikonfigurasi.
•	Murni perhitungan sederhana, tanpa Machine Learning.
13. Module 3 — Penghematan Listrik
FR-09 — Target Penghematan
Konsep: target bulanan dengan monitoring mingguan.
•	Contoh: konsumsi sebelumnya 150 kWh, target hemat 10% → target konsumsi = 150 − 15 = 135 kWh.
•	Target mingguan sebagai acuan monitoring = target bulanan ÷ jumlah hari periode × 7.
•	Pengguna dapat membuat, mengubah, dan menghapus target.
FR-10 — Simulasi Penghematan
Contoh: AC 500 W, penggunaan dikurangi 1 jam/hari.
•	Hemat harian: 500 × 1 ÷ 1000 = 0,5 kWh/hari
•	Hemat bulanan: 0,5 × 30 = 15 kWh/bulan
•	Estimasi biaya hemat: 15 × tarif
Hasil simulasi dapat disimpan (entity Saving Simulation) dan ditandai sebagai estimasi.
FR-11 — Rekomendasi Berbasis Aturan
Menggunakan rule-based recommendation (aturan IF–THEN yang ditulis manual oleh developer; bukan ML/AI/predictive model).
IF perangkat X = estimasi konsumsi terbesar
THEN sarankan mengurangi durasi penggunaan X

IF konsumsi aktual > target
THEN sarankan memeriksa perangkat dengan estimasi terbesar

IF konsumsi harian > rata-rata × threshold
THEN tampilkan peringatan konsumsi meningkat
FR-12 — Evaluasi Penghematan
Membandingkan periode sebelumnya dengan periode sekarang.
•	Contoh: sebelumnya 150 kWh, sekarang 130 kWh → hemat 20 kWh = 13,33%.
•	Jika target 10% → "Target penghematan tercapai."
Notifikasi Modul 3 — Target Penghematan
Notifikasi lokal diberikan untuk tiga kondisi, berdasarkan perhitungan sederhana dari rata-rata konsumsi. Usulan definisi (perlu disepakati tim):
Kondisi	Definisi usulan
Berisiko tidak tercapai	Proyeksi konsumsi akhir periode (rata-rata harian berjalan × jumlah hari periode) > target konsumsi
Hampir tercapai	Sisa periode ≤ 3 hari dan proyeksi ≤ target konsumsi
Tercapai	Periode selesai dan konsumsi aktual ≤ target konsumsi
14. Dashboard
Halaman utama setelah login. Harus sederhana dan mudah dipahami.
•	Kondisi listrik: saldo kWh, estimasi sisa hari, kategori listrik, daya.
•	Konsumsi: konsumsi aktual, rata-rata konsumsi, grafik konsumsi mingguan, perbandingan dengan periode sebelumnya.
•	Keuangan: total pembelian token, estimasi biaya, pengeluaran.
•	Penghematan: target, progress, status target, estimasi potensi penghematan.
Visualisasi minimal (jangan menambah grafik yang tidak bermanfaat):
1.	Grafik konsumsi mingguan — perubahan konsumsi.
2.	Actual vs Target — konsumsi aktual dibanding target.
3.	Estimasi perangkat — perangkat dengan estimasi konsumsi terbesar.
Riwayat: pengguna dapat melihat pembelian token, catatan meter, konsumsi, target penghematan, dan aktivitas penghematan jika diperlukan.
15. Notification
Semua notifikasi adalah local notification (dijadwalkan dan dikirim dari perangkat, tanpa server/internet).
Modul	Notifikasi	Pemicu
1	Saldo token rendah	Estimasi sisa hari ≤ ambang batas
2	Konsumsi meningkat	Konsumsi harian melewati rata-rata × (1 + ambang batas)
3	Target penghematan	Hampir tercapai / berisiko / tercapai
16. User Flow
•	Authentication: Splash → cek login → (belum login) Login/Register → berhasil → Dashboard.
•	Register: Register → nama → email/username → password → validasi → simpan lokal → Login/Dashboard.
•	Login: Login → email/username + password → validasi lokal → Dashboard (gagal: pesan error).
•	Profil: Dashboard → Profil Listrik → pilih kategori → pilih/masukkan daya → sistem menentukan tarif → simpan.
•	Token: Dashboard → Tambah Token → nominal + kWh → simpan → data token diperbarui.
•	Meter: Dashboard → Catat Meter → saldo kWh → foto (opsional) → simpan → konsumsi dihitung.
•	Monitoring: Dashboard → Monitoring → konsumsi aktual → grafik → analisis perangkat.
•	Penghematan: Dashboard → Penghematan → Target / Simulasi / Rekomendasi / Evaluasi.
17. Business Logic
1.	Konsumsi aktual = saldo awal + token masuk − saldo akhir. Jika tidak ada token masuk pada periode, rumusnya menjadi saldo sebelumnya − saldo sekarang (kasus khusus dengan token = 0).
2.	Konsumsi perangkat (estimasi) = Watt × jam × jumlah ÷ 1000.
3.	Estimasi biaya = kWh × tarif.
4.	Persentase hemat = (konsumsi sebelumnya − konsumsi sekarang) ÷ konsumsi sebelumnya × 100%.
5.	Penentuan tarif: profil listrik (kategori/golongan + daya) → lookup di Tariff Configuration → tarif per kWh. Jika kombinasi tidak ditemukan, tampilkan pesan dan jangan menebak tarif.
Aturan penjaga data (usulan):
•	Periode konsumsi dihitung di antara dua catatan meter berurutan. Token yang dihitung masuk adalah token dengan waktu setelah catatan meter sebelumnya dan sampai catatan meter sekarang. Agar tidak ambigu pada hari yang sama, simpan tanggal beserta jam.
•	Jika hasil konsumsi bernilai negatif, tampilkan peringatan dan minta pengguna memeriksa data (kemungkinan salah input).
•	Konsumsi harian = konsumsi periode ÷ jumlah hari periode.
•	Rata-rata konsumsi (baseline) dihitung dari catatan yang tersedia; jika data belum cukup, notifikasi dan rekomendasi terkait ditunda.
•	Hasil dari perangkat selalu berlabel "estimasi"; hasil dari meter+token berlabel "aktual".
18. Formula
Nama	Rumus
Konsumsi aktual (ada token)	Saldo awal + Σ kWh token masuk − Saldo akhir
Konsumsi aktual (tanpa token)	Saldo sebelumnya − Saldo sekarang
kWh perangkat per hari	(Watt × Jam × Jumlah) ÷ 1000
kWh perangkat per bulan	kWh/hari × 30
Estimasi biaya	kWh × Tarif
Estimasi sisa hari	Saldo kWh ÷ Rata-rata kWh/hari
Kenaikan konsumsi	(Konsumsi hari ini − Rata-rata) ÷ Rata-rata × 100%
Target konsumsi	Konsumsi sebelumnya × (1 − % target hemat)
Hemat simulasi (kWh/hari)	(Watt × Jam dikurangi × Jumlah) ÷ 1000
Persentase hemat	(Sebelumnya − Sekarang) ÷ Sebelumnya × 100%
19. Data Model
Semua data disimpan lokal (SQLite atau Hive). Tidak ada entity Admin, Role, Permission, atau Subsidy.
Entity	Field
User	id, nama, email/username, credential (password hash + salt)
Electricity Profile	id, user_id, kategori listrik, daya, jenis listrik
Tariff Configuration	id, kategori/golongan, daya, tarif
Token Purchase	id, user_id, tanggal, nominal, kWh token
Meter Reading	id, user_id, tanggal, saldo kWh, foto meter (path file, opsional)
Device	id, user_id, nama, watt, jumlah, jam penggunaan
Saving Target	id, user_id, periode, target konsumsi, target penghematan
Saving Simulation	id, user_id, device_id, perubahan durasi, estimasi kWh hemat, estimasi biaya hemat
Tariff Configuration adalah data konfigurasi yang dibuat tim (di-seed, yaitu diisi otomatis saat aplikasi pertama dijalankan). Isi daftar kategori, daya, dan tarif harus diambil dari sumber tarif resmi PLN oleh tim; dokumen ini tidak mengarang angka tarif. Format isi:
kategori/golongan	daya	tarif (Rp/kWh)
(diisi tim dari sumber resmi)	(diisi tim)	(diisi tim)
Catatan teknis (perlu disepakati tim): pada Saving Target, tim mungkin perlu menyimpan konsumsi baseline periode sebelumnya sebagai field turunan agar target tidak berubah saat data lama diedit. Ini bukan fitur baru, hanya penyimpanan nilai hitung. Field tanggal pada Token Purchase dan Meter Reading disarankan berupa tanggal+jam.
20. Relationship
User
 ├── 1 : 1 ── Electricity Profile
 ├── 1 : N ── Token Purchase
 ├── 1 : N ── Meter Reading
 ├── 1 : N ── Device
 ├── 1 : N ── Saving Target
 └── 1 : N ── Saving Simulation

Saving Simulation ── N : 1 ── Device
Tariff Configuration ── dipakai untuk mencari tarif berdasarkan kategori/golongan + daya
Tidak ada relasi Admin → User, Role → User, atau Subsidy → User.
21. Non-Functional Requirements
Aspek	Ketentuan
Platform	Flutter, Android (disarankan Android 8.0 ke atas)
Storage	SQLite atau Hive (pilih satu yang paling sesuai implementasi); data lokal
Authentication	Local authentication; password tidak disimpan plaintext
Firebase	Tidak digunakan
Backend	Tidak diperlukan untuk fitur inti
PLN API	Tidak digunakan
OCR, IoT, ML, AI	Tidak digunakan sebagai komponen sistem
Notification	Local notification; tepat waktu sesuai kondisi/jadwal
Offline	Fitur utama dapat dipakai tanpa internet
Usability	Input utama (token, meter, perangkat) dapat diselesaikan dalam beberapa langkah tanpa pelatihan khusus
Akurasi	Perhitungan konsumsi sesuai rumus pada bagian 18; konsumsi aktual dan estimasi selalu dibedakan
22. Constraints
1.	Hanya listrik prabayar/token.
2.	Hanya satu role: Pengguna.
3.	Login tetap tersedia.
4.	Authentication bersifat lokal.
5.	Tidak ada Admin, Operator, Super Admin, RBAC, maupun multi-role.
6.	Tidak menggunakan Firebase.
7.	Tidak menggunakan backend authentication.
8.	Data utama disimpan lokal.
9.	Token dicatat manual; kWh token dicatat berdasarkan informasi transaksi.
10.	Meter dicatat manual; foto meter hanya sebagai bukti.
11.	Tidak menggunakan OCR.
12.	Tarif ditentukan berdasarkan kategori/golongan dan daya; pengguna tidak memasukkan tarif secara bebas.
13.	Subsidi/non-subsidi tidak digunakan sebagai parameter aplikasi.
14.	Tidak menggunakan PLN API.
15.	Tidak menggunakan IoT.
16.	Tidak menggunakan Machine Learning.
17.	Tidak menggunakan AI sebagai komponen sistem.
18.	Tidak mendukung listrik pascabayar.
19.	Tidak membeli token dan tidak melakukan pembayaran listrik melalui aplikasi.
20.	Tidak ada monitoring perangkat secara real-time.
23. Success Criteria
Aplikasi dianggap berhasil apabila:
1.	Pengguna dapat melakukan register, login, dan logout.
2.	Sistem hanya memiliki satu role dan tidak ada Admin.
3.	Pengguna dapat membuat profil listrik, memilih kategori/golongan, dan menentukan daya.
4.	Sistem menentukan tarif dari konfigurasi kategori/golongan + daya.
5.	Pengguna dapat mencatat pembelian token beserta kWh token.
6.	Pengguna dapat mencatat saldo meter.
7.	Sistem dapat menghitung konsumsi aktual.
8.	Pengguna dapat memasukkan perangkat dan sistem menghitung estimasi konsumsi.
9.	Dashboard menampilkan informasi utama.
10.	Pengguna dapat melihat grafik konsumsi.
11.	Pengguna dapat membuat target penghematan dan melakukan simulasi.
12.	Sistem memberi rekomendasi rule-based dan mengevaluasi penghematan.
13.	Sistem memberi notifikasi saldo rendah, konsumsi meningkat, dan target penghematan.
14.	Pengguna dapat melihat riwayat.
15.	Tiga modul terintegrasi dalam satu aplikasi dan setiap anggota dapat menjelaskan implementasi modulnya saat code review.
24. In Scope
Register; Login; Logout; Profil pengguna; Profil listrik; Kategori/golongan listrik; Daya listrik; Tarif berdasarkan kategori/golongan dan daya; Pembelian token; Saldo kWh; Catatan meter; Foto meter; Riwayat token; Daftar perangkat; Kalkulator kWh; Monitoring konsumsi aktual; Dashboard; Grafik konsumsi mingguan; Target penghematan; Simulasi penghematan; Rule-based recommendation; Evaluasi penghematan; Riwayat; Local notification.
25. Out of Scope
Admin; Operator; Super Admin; Multi-role; RBAC; Status subsidi/non-subsidi; Firebase dan Firebase Authentication; Backend authentication; PLN API; Pembelian token langsung; Pembayaran listrik; Listrik pascabayar; Smart meter; IoT; OCR; Machine Learning; AI system; Real-time monitoring; Fitur air; SDG 6; GPS; Laporan kebocoran; Maintenance/perawatan air; Tips & jadwal perawatan alat (dari v1.1).
Optional / Future Development (tidak diimplementasikan sekarang): lupa password/reset akun, ekspor data, tema gelap, dan fitur lain yang belum ada di dokumen ini.
26. Development Notes
26.1 Pemetaan ke Aturan Project Mobile Programming
Aturan	Pemenuhan
Topik SDGs	SDG 7 (Energi Bersih & Terjangkau)
Tim 3–5 orang	3 orang, 3 modul
Min. 4 fungsionalitas per modul	Modul 1: FR-01–04; Modul 2: FR-05–08; Modul 3: FR-09–12
CRUD	Profil, token, meter, perangkat, target, simulasi
Data lokal, tanpa Firebase	SQLite/Hive
Notifikasi per modul	Saldo rendah, konsumsi meningkat, target penghematan
Fitur perangkat	Kamera untuk foto meter (FR-03); local notification
Screen interaktif & integrasi	Dashboard sebagai pusat navigasi
Penjelasan teknis saat review	Setiap anggota menguasai modulnya
Pembagian modul (usulan; isi nama sesuai kesepakatan tim): Anggota A — Modul 1; Anggota B — Modul 2; Anggota C — Modul 3. Authentication dan Dashboard adalah komponen bersama; sepakati siapa yang mengerjakannya agar beban kerja seimbang dan tidak mengurangi 4 fungsionalitas milik tiap modul.
26.2 Instruksi untuk AI Coding Assistant
Jika PRD ini diberikan ke AI, ikuti aturan ini:
•	Jangan membuat role tambahan (Admin, Role, Permission, Super Admin, Operator) dan jangan membuat RBAC. Gunakan hanya User/Pengguna.
•	Jangan membuat fitur subsidi: subsidy_status, pilihan Subsidi/Non-Subsidi, halaman subsidi, atau kalkulasi khusus subsidi.
•	Jangan membuat input tarif manual; gunakan Tariff Configuration.
•	Jangan membuat PLN API, OCR, backend, atau Firebase. Foto meter hanya disimpan sebagai bukti.
•	Fitur baru di luar PRD ditandai Optional / Future Development dan tidak langsung diimplementasikan.
•	Kode dari AI wajib dipahami dan dapat dijelaskan oleh anggota saat code review; catat penggunaan AI pada AI Usage Log (tujuan, prompt, output, perubahan, verifikasi/testing).
26.3 Istilah singkat
•	kWh: satuan energi listrik; saldo token dihitung dalam kWh.
•	Token/prabayar: listrik dibayar di muka, saldo berkurang saat dipakai.
•	Baseline: angka acuan (misalnya rata-rata konsumsi) sebagai pembanding.
•	Threshold/ambang batas: batas yang memicu notifikasi.
•	Seed: mengisi data awal ke database saat aplikasi pertama kali berjalan.
•	Rule-based: keputusan dari aturan IF–THEN yang ditulis manual, bukan hasil pembelajaran mesin.
