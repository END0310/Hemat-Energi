import '../../core/database_helper.dart';
import '../models/user.dart';

/// Repository untuk operasi tabel 'users' di SQLite
class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Tambah user baru ke database
  Future<int> insertUser(User user) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('users', user.toMap());
    } catch (e) {
      throw Exception('Gagal menyimpan data pengguna: $e');
    }
  }

  /// Ambil user berdasarkan email (lowercase)
  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mencari akun pengguna: $e');
    }
  }

  /// Ambil user berdasarkan ID
  Future<User?> getUserById(int id) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal memuat profil pengguna: $e');
    }
  }
}
