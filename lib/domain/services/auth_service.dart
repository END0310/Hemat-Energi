import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';

/// AuthService menangani hashing password, verifikasi password, dan manajemen sesi
class AuthService {
  final UserRepository _userRepository;

  AuthService({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  /// Menghasilkan salt acak berbasis Random.secure()
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Melakukan hashing password dengan salt dan 5.000 iterasi SHA-256
  static String hashPassword(String password, String salt, {int iterations = 5000}) {
    final key = utf8.encode('$password::$salt');
    var digestBytes = sha256.convert(key).bytes;
    for (int i = 1; i < iterations; i++) {
      digestBytes = sha256.convert([...digestBytes, ...key]).bytes;
    }
    return base64Url.encode(digestBytes);
  }

  /// Membandingkan dua string hash dengan perbandingan waktu konstan (constant-time)
  /// untuk mencegah timing attacks
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Registrasi user baru
  Future<User> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final existingUser = await _userRepository.getUserByEmail(cleanEmail);
    if (existingUser != null) {
      throw Exception('Email sudah terdaftar di perangkat ini.');
    }

    final salt = generateSalt();
    final passwordHash = hashPassword(password, salt);

    final newUser = User(
      nama: nama.trim(),
      email: cleanEmail,
      passwordHash: passwordHash,
      salt: salt,
    );

    final userId = await _userRepository.insertUser(newUser);
    return newUser.copyWith(id: userId);
  }

  /// Login user dengan email dan password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final user = await _userRepository.getUserByEmail(cleanEmail);
    if (user == null) {
      return null;
    }

    final calculatedHash = hashPassword(password, user.salt);
    final isMatch = constantTimeEquals(calculatedHash, user.passwordHash);

    if (!isMatch) {
      return null;
    }

    // Simpan sesi ke shared_preferences
    await setSession(user.id!);
    return user;
  }

  /// Simpan sesi user_id yang sedang aktif
  Future<void> setSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyLoggedInUserId, userId);
  }

  /// Ambil user_id dari sesi saat ini
  Future<int?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyLoggedInUserId);
  }

  /// Ambil detail User yang sedang aktif berdasarkan sesi
  Future<User?> getCurrentUser() async {
    final userId = await getSessionUserId();
    if (userId == null) return null;
    return await _userRepository.getUserById(userId);
  }

  /// Hapus sesi (Logout) tanpa menghapus data user di SQLite
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyLoggedInUserId);
  }
}
