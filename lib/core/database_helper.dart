import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'constants.dart';
import '../models/device_models.dart';
import '../models/notification_model.dart';
import '../models/electricity_profile_model.dart' as m2_prof;
import '../models/meter_reading_model.dart' as m2_meter;
import '../models/token_purchase_model.dart' as m2_token;

/// DatabaseHelper mengelola inisialisasi SQLite, relasi tabel Modul 1, 2, dan 3,
/// serta seed data awal PLN dan perangkat.
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
    // Inisialisasi driver SQLite berdasarkan platform yang sedang berjalan
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Aktifkan foreign key enforcement di SQLite
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // 1. Tabel users (Modul 1)
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nama TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          salt TEXT NOT NULL
        );
      ''');

      // 2. Tabel electricity_profiles (relasi 1:1 dengan user - Modul 1)
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

      // 3. Tabel tariff_configs (lookup tarif resmi PLN - Modul 1)
      await db.execute('''
        CREATE TABLE tariff_configs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          kategori TEXT NOT NULL,
          daya INTEGER NOT NULL,
          tarif REAL NOT NULL
        );
      ''');

      // 4. Tabel token_purchases (relasi 1:N dengan user - Modul 1)
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

      // 5. Tabel meter_readings (relasi 1:N dengan user - Modul 1)
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

      // 6. Tabel devices & notifikasi (Modul 2)
      await _createModule2Tables(db);

      // Seed data tarif dari assets/tariff_seed.json
      await _seedTariffs(db);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createModule2Tables(db);
    }
  }

  Future<void> _createModule2Tables(Database db) async {
    // Tabel devices (FR-05)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        power_watt REAL NOT NULL,
        quantity INTEGER NOT NULL,
        daily_hours REAL NOT NULL
      );
    ''');

    // Tabel app_notifications (Modul 2)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        date_time TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        payload TEXT
      );
    ''');

    // Seed perangkat contoh awal jika belum ada
    final deviceCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM devices');
    final deviceCount = Sqflite.firstIntValue(deviceCountRes) ?? 0;
    if (deviceCount == 0) {
      final initialDevices = [
        {'name': 'AC Kamar', 'power_watt': 500.0, 'quantity': 1, 'daily_hours': 6.0},
        {'name': 'Kulkas 1 Pintu', 'power_watt': 100.0, 'quantity': 1, 'daily_hours': 15.0},
        {'name': 'TV LED Kos', 'power_watt': 100.0, 'quantity': 1, 'daily_hours': 4.0},
        {'name': 'Lampu Belajar', 'power_watt': 12.0, 'quantity': 2, 'daily_hours': 8.0},
      ];
      for (final dev in initialDevices) {
        await db.insert('devices', dev);
      }
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
      // Abaikan jika seed gagal pada environment test tanpa assets
    }
  }

  // ===================== CRUD DEVICES (Modul 2 - FR-05) =====================
  Future<int> insertDevice(Device device) async {
    final db = await database;
    final map = device.toMap();
    map.remove('id');
    return await db.insert(
      'devices',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Device>> getDevices() async {
    final db = await database;
    final result = await db.query(
      'devices',
      orderBy: 'id DESC',
    );
    return result.map((json) => Device.fromMap(json)).toList();
  }

  Future<int> deleteDevice(int id) async {
    final db = await database;
    return await db.delete(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateDevice(Device device) async {
    final db = await database;
    return await db.update(
      'devices',
      device.toMap(),
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  // ===================== NOTIFICATIONS (Modul 2) =====================
  Future<int> insertNotification(AppNotificationItem notification) async {
    final db = await database;
    final map = notification.toMap();
    map.remove('id');
    return await db.insert('app_notifications', map);
  }

  Future<List<AppNotificationItem>> getNotifications() async {
    final db = await database;
    final result = await db.query(
      'app_notifications',
      orderBy: 'date_time DESC',
    );
    return result.map((json) => AppNotificationItem.fromMap(json)).toList();
  }

  Future<int> markNotificationAsRead(int id) async {
    final db = await database;
    return await db.update(
      'app_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasNotificationForDateAndType({
    required String datePrefix,
    required String type,
  }) async {
    final db = await database;
    final result = await db.query(
      'app_notifications',
      where: 'date_time LIKE ? AND type = ?',
      whereArgs: ['$datePrefix%', type],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ===================== ACTIVE USER RESOLUTION =====================
  Future<int?> _resolveActiveUserId(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefId = prefs.getInt(AppConstants.keyLoggedInUserId);
      if (prefId != null) {
        final found = await db.query(
          'users',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [prefId],
          limit: 1,
        );
        if (found.isNotEmpty) return prefId;
      }
    } catch (_) {}

    final firstUser = await db.query(
      'users',
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (firstUser.isNotEmpty) {
      return firstUser.first['id'] as int;
    }
    return null;
  }

  Future<int> _ensureUserIdForWrite(Database db) async {
    final existingId = await _resolveActiveUserId(db);
    if (existingId != null) return existingId;

    return await db.insert('users', {
      'nama': 'Pengguna Demo',
      'email': 'demo@hematenergi.local',
      'password_hash': 'demo',
      'salt': 'demo',
    });
  }

  // ===================== PROFILE & TARIFF BRIDGING (Modul 2) =====================
  Future<m2_prof.ElectricityProfile> getElectricityProfile() async {
    final db = await database;
    try {
      final activeUserId = await _resolveActiveUserId(db);
      final profiles = await db.query(
        'electricity_profiles',
        where: activeUserId != null ? 'user_id = ?' : null,
        whereArgs: activeUserId != null ? [activeUserId] : null,
        limit: 1,
      );
      if (profiles.isNotEmpty) {
        final p = profiles.first;
        final kategori = p['kategori'] as String? ?? 'Rumah Tangga R-1/TR';
        final daya = (p['daya'] as num?)?.toInt() ?? 1300;
        final jenis = p['jenis_listrik'] as String? ?? 'Prabayar / Token';

        double tariffPerKwh = 1444.70;
        final tariffs = await db.query(
          'tariff_configs',
          where: 'kategori = ? AND daya = ?',
          whereArgs: [kategori, daya],
          limit: 1,
        );
        if (tariffs.isNotEmpty) {
          tariffPerKwh = (tariffs.first['tarif'] as num).toDouble();
        }

        return m2_prof.ElectricityProfile(
          id: p['id'] as int?,
          category: kategori,
          powerVa: daya,
          connectionType: jenis,
          tariffPerKwh: tariffPerKwh,
        );
      }
    } catch (_) {}

    return const m2_prof.ElectricityProfile(
      category: 'Rumah Tangga R-1/TR',
      powerVa: 1300,
      connectionType: 'Prabayar / Token',
      tariffPerKwh: 1444.70,
    );
  }

  // ===================== METER READINGS BRIDGING (Modul 2) =====================
  Future<List<m2_meter.MeterReading>> getMeterReadings({bool ascending = false}) async {
    final db = await database;
    final activeUserId = await _resolveActiveUserId(db);
    final result = await db.query(
      'meter_readings',
      where: activeUserId != null ? 'user_id = ?' : null,
      whereArgs: activeUserId != null ? [activeUserId] : null,
      orderBy: ascending ? 'tanggal_waktu ASC' : 'tanggal_waktu DESC',
    );
    return result.map((row) {
      final tStr = row['tanggal_waktu'] as String;
      final dt = DateTime.tryParse(tStr) ?? DateTime.now();
      return m2_meter.MeterReading(
        id: row['id'] as int?,
        readingDate: dt,
        kwhMeter: (row['saldo_kwh'] as num).toDouble(),
        photoPath: row['foto_path'] as String?,
        createdAt: dt,
      );
    }).toList();
  }

  Future<int> insertMeterReading(m2_meter.MeterReading reading) async {
    final db = await database;
    final userId = await _ensureUserIdForWrite(db);
    return await db.insert('meter_readings', {
      'user_id': userId,
      'tanggal_waktu': reading.readingDate.toIso8601String(),
      'saldo_kwh': reading.kwhMeter,
      'foto_path': reading.photoPath,
    });
  }

  Future<int> deleteMeterReading(int id) async {
    final db = await database;
    return await db.delete('meter_readings', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== TOKEN PURCHASES BRIDGING (Modul 2) =====================
  Future<List<m2_token.TokenPurchase>> getTokenPurchases({bool ascending = false}) async {
    final db = await database;
    final activeUserId = await _resolveActiveUserId(db);
    final result = await db.query(
      'token_purchases',
      where: activeUserId != null ? 'user_id = ?' : null,
      whereArgs: activeUserId != null ? [activeUserId] : null,
      orderBy: ascending ? 'tanggal_waktu ASC' : 'tanggal_waktu DESC',
    );
    return result.map((row) {
      final tStr = row['tanggal_waktu'] as String;
      final dt = DateTime.tryParse(tStr) ?? DateTime.now();
      return m2_token.TokenPurchase(
        id: row['id'] as int?,
        purchaseDate: dt,
        amountRp: (row['nominal'] as num).toDouble(),
        kwhToken: (row['kwh_token'] as num).toDouble(),
        createdAt: dt,
      );
    }).toList();
  }

  Future<int> insertTokenPurchase(m2_token.TokenPurchase purchase) async {
    final db = await database;
    final userId = await _ensureUserIdForWrite(db);
    return await db.insert('token_purchases', {
      'user_id': userId,
      'tanggal_waktu': purchase.purchaseDate.toIso8601String(),
      'nominal': purchase.amountRp,
      'kwh_token': purchase.kwhToken,
    });
  }

  Future<int> deleteTokenPurchase(int id) async {
    final db = await database;
    return await db.delete('token_purchases', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetDummyModule1Data() async {
    final db = await database;
    final userId = await _ensureUserIdForWrite(db);
    await db.delete('meter_readings', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('token_purchases', where: 'user_id = ?', whereArgs: [userId]);

    final now = DateTime.now();
    await db.insert('token_purchases', {
      'user_id': userId,
      'tanggal_waktu': now.subtract(const Duration(days: 4, hours: 2)).toIso8601String(),
      'nominal': 50000.0,
      'kwh_token': 33.7,
    });

    await db.insert('meter_readings', {
      'user_id': userId,
      'tanggal_waktu': now.subtract(const Duration(days: 2, hours: 14)).toIso8601String(),
      'saldo_kwh': 21.4,
      'foto_path': null,
    });

    await db.insert('meter_readings', {
      'user_id': userId,
      'tanggal_waktu': now.subtract(const Duration(days: 1, hours: 14)).toIso8601String(),
      'saldo_kwh': 18.2,
      'foto_path': null,
    });
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
