import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../domain/services/auth_service.dart';

/// State management untuk autentikasi (Splash, Login, Register, Logout)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;

  /// Cek sesi login saat splash screen
  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _currentUser = null;
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Validasi format email dengan RegExp yang andal
  bool _isValidEmail(String email) {
    final clean = email.trim();
    if (clean.isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(clean);
  }

  /// Register akun baru
  Future<bool> register({
    required String nama,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _errorMessage = null;

    if (nama.trim().isEmpty) {
      _errorMessage = 'Nama lengkap wajib diisi.';
      notifyListeners();
      return false;
    }

    if (email.trim().isEmpty) {
      _errorMessage = 'Email wajib diisi.';
      notifyListeners();
      return false;
    }

    if (!_isValidEmail(email)) {
      _errorMessage = 'Format email tidak valid (contoh: nama@email.com).';
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _errorMessage = 'Password minimal 8 karakter.';
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Password belum sama.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.register(
        nama: nama,
        email: email,
        password: password,
      );

      // Simpan sesi dan user aktif agar langsung terautentikasi
      await _authService.setSession(user.id!);
      _currentUser = user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Login akun
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;

    if (email.trim().isEmpty || password.isEmpty) {
      _errorMessage = 'Email atau password salah';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      if (user == null) {
        // Pesan generik sesuai aturan PRD
        _errorMessage = 'Email atau password salah';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Email atau password salah';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout akun
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } finally {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bersihkan pesan error dan status loading
  void clearError() {
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
