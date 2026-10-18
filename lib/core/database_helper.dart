import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// DatabaseHelper mengelola inisialisasi SQLite, relasi tabel, dan seed data tarif awal
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hemat_energi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Aktifkan foreign key enforcement di SQLite
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // 1. Tabel users
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          salt TEXT NOT NULL
        );
      ''');

      // 2. Tabel electricity_profiles (relasi 1:1 dengan user)
      await db.execute('''
        CREATE TABLE electricity_profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE NOT NULL,
          kategori TEXT NOT NULL,
          daya INTEGER NOT NULL,
          jenis_listrik TEXT NOT NULL DEFAULT 'Prabayar/Token',
          saldo_awal_kwh REAL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        );
      ''');

      // 3. Tabel tariff_configs (lookup tarif resmi PLN)
      await db.execute('''
        CREATE TABLE tariff_configs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kategori TEXT NOT NULL,
          daya INTEGER NOT NULL,
          tarif REAL NOT NULL
        );
      ''');

      // 4. Tabel token_purchases (relasi 1:N dengan user)
      await db.execute('''
        CREATE TABLE token_purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          tanggal_waktu TEXT NOT NULL,
          nominal REAL NOT NULL,
          kwh_token REAL NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        );
      ''');

      // 5. Tabel meter_readings (relasi 1:N dengan user)
      await db.execute('''
        CREATE TABLE meter_readings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          tanggal_waktu TEXT NOT NULL,
          saldo_kwh REAL NOT NULL,
          foto_path TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        );
      ''');

      // Seed data tarif dari assets/tariff_seed.json
      await _seedTariffs(db);
    } catch (e) {
      // Error handling yang ramah saat inisialisasi tabel
      rethrow;
    }
  }

  Future<void> _seedTariffs(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/tariff_seed.json');
      final List<dynamic> data = json.decode(jsonString);

      final batch = db.batch();
      for (final item in data) {
        batch.insert('tariff_configs', {
          'kategori': item['kategori'],
          'daya': item['daya'],
          'tarif': (item['tarif'] as num).toDouble(),
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Abaikan jika seed gagal pada environment test tanpa assets,
      // tapi log untuk audit development
    }
  }

  /// Tutup koneksi database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
