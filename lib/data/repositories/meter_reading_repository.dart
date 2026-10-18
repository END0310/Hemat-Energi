import '../../core/database_helper.dart';
import '../models/meter_reading.dart';

/// Repository untuk tabel meter_readings (CRUD pencatatan saldo meter)
class MeterReadingRepository {
  final DatabaseHelper _dbHelper;

  MeterReadingRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Tambah pencatatan saldo meter baru
  Future<int> insertMeterReading(MeterReading reading) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('meter_readings', reading.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan catatan saldo meter: $e');
    }
  }

  /// Update catatan saldo meter
  Future<int> updateMeterReading(MeterReading reading) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'meter_readings',
        reading.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [reading.id, reading.userId],
      );
    } catch (e) {
      throw Exception('Gagal memperbarui catatan saldo meter: $e');
    }
  }

  /// Hapus catatan saldo meter
  Future<int> deleteMeterReading(int id, int userId) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'meter_readings',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      throw Exception('Gagal menghapus catatan saldo meter: $e');
    }
  }

  /// Ambil semua catatan meter milik user, urut waktu
  Future<List<MeterReading>> getMeterReadings(int userId, {bool ascending = false}) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'meter_readings',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'tanggal_waktu ${ascending ? 'ASC' : 'DESC'}',
      );
      return results.map((e) => MeterReading.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar catatan meter: $e');
    }
  }

  /// Ambil catatan meter terbaru milik user
  Future<MeterReading?> getLatestMeterReading(int userId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'meter_readings',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'tanggal_waktu DESC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        return MeterReading.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal memuat catatan meter terakhir: $e');
    }
  }
}
