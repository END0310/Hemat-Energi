import '../../core/database_helper.dart';
import '../models/token_purchase.dart';

/// Repository untuk tabel token_purchases (CRUD transaksi pembelian token)
class TokenPurchaseRepository {
  final DatabaseHelper _dbHelper;

  TokenPurchaseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Tambah transaksi pembelian token baru
  Future<int> insertTokenPurchase(TokenPurchase token) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('token_purchases', token.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan transaksi token: $e');
    }
  }

  /// Update transaksi token
  Future<int> updateTokenPurchase(TokenPurchase token) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'token_purchases',
        token.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [token.id, token.userId],
      );
    } catch (e) {
      throw Exception('Gagal memperbarui transaksi token: $e');
    }
  }

  /// Hapus transaksi token
  Future<int> deleteTokenPurchase(int id, int userId) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'token_purchases',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    } catch (e) {
      throw Exception('Gagal menghapus transaksi token: $e');
    }
  }

  /// Ambil semua transaksi token milik user_id, terurut dari yang terbaru (DESC)
  Future<List<TokenPurchase>> getTokenPurchases(int userId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'token_purchases',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'tanggal_waktu DESC',
      );
      return results.map((e) => TokenPurchase.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar riwayat token: $e');
    }
  }

  /// Ambil transaksi token dalam bulan dan tahun tertentu (untuk ringkasan dashboard & token)
  Future<Map<String, dynamic>> getMonthlySummary(int userId, DateTime date) async {
    try {
      final db = await _dbHelper.database;
      final startOfMonth = DateTime(date.year, date.month, 1).toIso8601String();
      final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59).toIso8601String();

      final results = await db.rawQuery('''
        SELECT 
          COUNT(*) as count, 
          COALESCE(SUM(nominal), 0) as total_nominal, 
          COALESCE(SUM(kwh_token), 0) as total_kwh
        FROM token_purchases 
        WHERE user_id = ? AND tanggal_waktu >= ? AND tanggal_waktu <= ?
      ''', [userId, startOfMonth, endOfMonth]);

      if (results.isNotEmpty) {
        return {
          'count': results.first['count'] as int? ?? 0,
          'total_nominal': (results.first['total_nominal'] as num?)?.toDouble() ?? 0.0,
          'total_kwh': (results.first['total_kwh'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return {'count': 0, 'total_nominal': 0.0, 'total_kwh': 0.0};
    } catch (e) {
      throw Exception('Gagal memuat ringkasan pembelian token: $e');
    }
  }
}
