import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/electricity_profile.dart';
import '../models/tariff_config.dart';

/// Repository untuk tabel electricity_profiles dan tariff_configs
class ElectricityProfileRepository {
  final DatabaseHelper _dbHelper;

  ElectricityProfileRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Ambil profil listrik berdasarkan user_id (1:1)
  Future<ElectricityProfile?> getProfile(int userId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'electricity_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return ElectricityProfile.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal memuat profil listrik: $e');
    }
  }

  /// Simpan atau perbarui profil listrik (Upsert)
  Future<int> saveOrUpdateProfile(ElectricityProfile profile) async {
    try {
      final db = await _dbHelper.database;
      final existing = await getProfile(profile.userId);

      if (existing == null) {
        return await db.insert(
          'electricity_profiles',
          profile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await db.update(
          'electricity_profiles',
          profile.toMap(),
          where: 'user_id = ?',
          whereArgs: [profile.userId],
        );
        return existing.id!;
      }
    } catch (e) {
      throw Exception('Gagal menyimpan profil listrik: $e');
    }
  }

  /// Cari tarif berdasarkan kategori dan daya dari tariff_configs
  Future<double?> lookupTariff(String kategori, int daya) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'tariff_configs',
        columns: ['tarif'],
        where: 'kategori = ? AND daya = ?',
        whereArgs: [kategori, daya],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return (results.first['tarif'] as num).toDouble();
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mencari tarif listrik: $e');
    }
  }

  /// Ambil semua kategori tarif yang tersedia
  Future<List<String>> getCategories() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.rawQuery(
        'SELECT DISTINCT kategori FROM tariff_configs ORDER BY kategori ASC',
      );
      return results.map((row) => row['kategori'] as String).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar kategori tarif: $e');
    }
  }

  /// Ambil opsi daya terpasang (VA) berdasarkan kategori yang dipilih
  Future<List<int>> getPowerOptions(String kategori) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'tariff_configs',
        columns: ['daya'],
        where: 'kategori = ?',
        whereArgs: [kategori],
        orderBy: 'daya ASC',
      );
      return results.map((row) => row['daya'] as int).toList();
    } catch (e) {
      throw Exception('Gagal memuat opsi daya listrik: $e');
    }
  }

  /// Ambil seluruh daftar konfigurasi tarif
  Future<List<TariffConfig>> getAllTariffConfigs() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query('tariff_configs');
      return results.map((e) => TariffConfig.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat konfigurasi tarif: $e');
    }
  }
}
