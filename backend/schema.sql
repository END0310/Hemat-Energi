-- ============================================================================
-- Skema Database MySQL — Hemat Energi (SDG 7) — PRD v3.1 (Lampiran B & H)
-- Jalankan file ini di phpMyAdmin / Laragon / MySQL Workbench / CLI MySQL.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS hemat_energi
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hemat_energi;

-- 1. Tabel users (Identitas Pengguna - Satu Role)
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  email_username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Tabel tariff_configurations (Referensi Tarif Resmi PLN - Lampiran H)
CREATE TABLE IF NOT EXISTS tariff_configurations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kategori VARCHAR(50) NOT NULL,
  daya_va INT NOT NULL,
  tarif_per_kwh DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_kategori_daya (kategori, daya_va)
);

-- 3. Tabel electricity_profiles (Profil Listrik 1:1 per User - FR-01)
CREATE TABLE IF NOT EXISTS electricity_profiles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE,
  kategori VARCHAR(50) NOT NULL,
  daya_va INT NOT NULL,
  jenis_listrik VARCHAR(30) NOT NULL DEFAULT 'Prabayar/Token',
  saldo_awal_kwh DECIMAL(10,2) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_profile_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Tabel token_purchases (Pembelian Token Listrik - FR-02 & FR-04)
CREATE TABLE IF NOT EXISTS token_purchases (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  nominal BIGINT NOT NULL,
  kwh_token DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_token_user_tanggal (user_id, tanggal),
  CONSTRAINT fk_token_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 5. Tabel meter_readings (Catatan Saldo Meter + Foto Bukti - FR-03)
CREATE TABLE IF NOT EXISTS meter_readings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tanggal DATETIME NOT NULL,
  saldo_kwh DECIMAL(10,2) NOT NULL,
  foto_path VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_meter_user_tanggal (user_id, tanggal),
  CONSTRAINT fk_meter_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 6. Tabel devices (Daftar Perangkat Elektronik Modul 2 - FR-05)
CREATE TABLE IF NOT EXISTS devices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  nama VARCHAR(100) NOT NULL,
  watt DECIMAL(10,2) NOT NULL,
  jumlah INT NOT NULL DEFAULT 1,
  jam_per_hari DECIMAL(4,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_device_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 7. Tabel saving_targets (Target Penghematan Modul 3 - FR-09)
CREATE TABLE IF NOT EXISTS saving_targets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  periode_mulai DATE NOT NULL,
  periode_selesai DATE NOT NULL,
  konsumsi_baseline_kwh DECIMAL(10,2) NOT NULL,
  target_persen DECIMAL(5,2) NOT NULL,
  target_konsumsi_kwh DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_target_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 8. Tabel saving_simulations (Simulasi Penghematan Modul 3 - FR-10)
CREATE TABLE IF NOT EXISTS saving_simulations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  device_id INT NOT NULL,
  nama_perangkat VARCHAR(100) NOT NULL,
  pengurangan_jam_per_hari DECIMAL(4,2) NOT NULL,
  estimasi_kwh_hemat_bulan DECIMAL(10,2) NOT NULL,
  estimasi_biaya_hemat DECIMAL(14,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_sim_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_sim_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- ============================================================================
-- Seed Data Tarif Resmi PLN Rumah Tangga TR (Permen ESDM No. 7 Tahun 2024)
-- ============================================================================
INSERT INTO tariff_configurations (kategori, daya_va, tarif_per_kwh) VALUES
  ('Rumah Tangga R-1/TR', 900, 1352.00),
  ('Rumah Tangga R-1/TR', 1300, 1444.70),
  ('Rumah Tangga R-1/TR', 2200, 1444.70),
  ('Rumah Tangga R-2/TR', 3500, 1699.53),
  ('Rumah Tangga R-2/TR', 5500, 1699.53),
  ('Rumah Tangga R-3/TR', 6600, 1699.53)
ON DUPLICATE KEY UPDATE
  tarif_per_kwh = VALUES(tarif_per_kwh);
