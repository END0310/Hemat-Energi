import 'package:flutter/material.dart';
import '../../data/models/electricity_profile.dart';
import '../../data/models/meter_reading.dart';
import '../../data/models/token_purchase.dart';
import '../../data/repositories/electricity_profile_repository.dart';
import '../../data/repositories/meter_reading_repository.dart';
import '../../data/repositories/token_purchase_repository.dart';
import '../../domain/services/balance_estimator.dart';
import '../../domain/services/consumption_service.dart';
import '../../domain/services/low_balance_notification_service.dart';

/// Provider utama untuk Modul 1 (Profil Listrik, Token, Meter, Riwayat, dan Rumus Konsumsi)
class ElectricityProvider extends ChangeNotifier {
  final ElectricityProfileRepository _profileRepo;
  final TokenPurchaseRepository _tokenRepo;
  final MeterReadingRepository _meterRepo;

  ElectricityProfile? _profile;
  double? _tariff;
  List<TokenPurchase> _tokenPurchases = [];
  List<MeterReading> _meterReadings = [];
  Map<String, dynamic> _monthlyTokenSummary = {'count': 0, 'total_nominal': 0.0, 'total_kwh': 0.0};
  Map<String, dynamic> _allTimeTokenSummary = {'count': 0, 'total_nominal': 0.0, 'total_kwh': 0.0};

  List<ConsumptionPeriod> _consumptionPeriods = [];
  double? _averageDailyConsumption;
  double? _remainingDays;
  BalanceStatus _balanceStatus = BalanceStatus.belumCukupData;
  Map<DateTime, double> _sevenDayConsumption = {};

  bool _isLoading = false;
  String? _errorMessage;

  ElectricityProvider({
    ElectricityProfileRepository? profileRepo,
    TokenPurchaseRepository? tokenRepo,
    MeterReadingRepository? meterRepo,
  })  : _profileRepo = profileRepo ?? ElectricityProfileRepository(),
        _tokenRepo = tokenRepo ?? TokenPurchaseRepository(),
        _meterRepo = meterRepo ?? MeterReadingRepository();

  ElectricityProfile? get profile => _profile;
  double? get tariff => _tariff;
  List<TokenPurchase> get tokenPurchases => _tokenPurchases;
  List<MeterReading> get meterReadings => _meterReadings;
  MeterReading? get latestMeterReading => _meterReadings.isNotEmpty ? _meterReadings.first : null;
  Map<String, dynamic> get monthlyTokenSummary => _monthlyTokenSummary;
  Map<String, dynamic> get allTimeTokenSummary => _allTimeTokenSummary;

  List<ConsumptionPeriod> get consumptionPeriods => _consumptionPeriods;
  double? get averageDailyConsumption => _averageDailyConsumption;
  double? get remainingDays => _remainingDays;
  BalanceStatus get balanceStatus => _balanceStatus;
  Map<DateTime, double> get sevenDayConsumption => _sevenDayConsumption;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Memuat semua data Modul 1 untuk user tertentu
  Future<void> loadAllData(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Muat profil listrik
      _profile = await _profileRepo.getProfile(userId);
      if (_profile != null) {
        _tariff = await _profileRepo.lookupTariff(_profile!.kategori, _profile!.daya);
      } else {
        _tariff = null;
      }

      // 2. Muat transaksi token (DESC)
      _tokenPurchases = await _tokenRepo.getTokenPurchases(userId);

      // 3. Muat ringkasan token bulan ini & total keseluruhan pengeluaran (FR-04)
      _monthlyTokenSummary = await _tokenRepo.getMonthlySummary(userId, DateTime.now());
      _allTimeTokenSummary = await _tokenRepo.getAllTimeSummary(userId);

      // 4. Muat catatan meter (DESC untuk tampilan riwayat)
      _meterReadings = await _meterRepo.getMeterReadings(userId, ascending: false);

      // 5. Hitung rumus konsumsi dan estimasi
      _recalculateMetrics();

      // 6. Evaluasi notifikasi lokal saldo token rendah (NTF-01)
      await LowBalanceNotificationService.instance.checkAndNotify(
        userId: userId,
        latestBalanceKwh: latestMeterReading?.saldoKwh,
        remainingDays: _remainingDays,
        meterReadingsCount: _meterReadings.length,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Menjalankan kalkulasi ulang seluruh metrik konsumsi dan estimasi
  void _recalculateMetrics() {
    // Balik urutan ke ASC (kronologis) untuk kalkulasi periode
    final chronologicalReadings = List<MeterReading>.from(_meterReadings.reversed);

    _consumptionPeriods = ConsumptionService.calculateAllPeriods(
      readings: chronologicalReadings,
      allTokens: _tokenPurchases,
    );

    _averageDailyConsumption = ConsumptionService.calculateAverageDailyConsumption(
      readings: chronologicalReadings,
      allTokens: _tokenPurchases,
    );

    final latestSaldo = latestMeterReading?.saldoKwh;
    _remainingDays = BalanceEstimator.calculateRemainingDays(
      latestBalanceKwh: latestSaldo,
      averageDailyConsumptionKwh: _averageDailyConsumption,
    );

    _balanceStatus = BalanceEstimator.getStatus(_remainingDays);

    _sevenDayConsumption = ConsumptionService.getSevenDayConsumption(
      readings: chronologicalReadings,
      allTokens: _tokenPurchases,
      today: DateTime.now(),
    );
  }

  // ===================== OPERASI PROFIL LISTRIK =====================

  Future<List<String>> getCategories() async {
    return await _profileRepo.getCategories();
  }

  Future<List<int>> getPowerOptions(String kategori) async {
    return await _profileRepo.getPowerOptions(kategori);
  }

  Future<double?> lookupTariff(String kategori, int daya) async {
    return await _profileRepo.lookupTariff(kategori, daya);
  }

  Future<bool> saveProfile({
    required int userId,
    required String kategori,
    required int daya,
    double? saldoAwalKwh,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tariffLookup = await _profileRepo.lookupTariff(kategori, daya);
      if (tariffLookup == null) {
        _errorMessage = 'Kombinasi kategori dan daya tidak ditemukan dalam konfigurasi tarif PLN.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newProfile = ElectricityProfile(
        userId: userId,
        kategori: kategori,
        daya: daya,
        saldoAwalKwh: saldoAwalKwh,
      );

      await _profileRepo.saveOrUpdateProfile(newProfile);
      _profile = newProfile;
      _tariff = tariffLookup;

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

  /// Hapus / reset profil listrik milik pengguna (FR-01 Delete)
  Future<bool> deleteProfile(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepo.deleteProfile(userId);
      _profile = null;
      _tariff = null;
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

  // ===================== OPERASI PEMBELIAN TOKEN =====================

  Future<bool> addTokenPurchase({
    required int userId,
    required DateTime tanggalWaktu,
    required double nominal,
    required double kwhToken,
  }) async {
    if (nominal <= 0 || kwhToken <= 0) {
      _errorMessage = 'Nominal dan kWh token harus bernilai lebih dari 0.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final token = TokenPurchase(
        userId: userId,
        tanggalWaktu: tanggalWaktu,
        nominal: nominal,
        kwhToken: kwhToken,
      );

      await _tokenRepo.insertTokenPurchase(token);
      await loadAllData(userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTokenPurchase(TokenPurchase token) async {
    if (token.nominal <= 0 || token.kwhToken <= 0) {
      _errorMessage = 'Nominal dan kWh token harus bernilai lebih dari 0.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _tokenRepo.updateTokenPurchase(token);
      await loadAllData(token.userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTokenPurchase(int id, int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _tokenRepo.deleteTokenPurchase(id, userId);
      await loadAllData(userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ===================== OPERASI CATATAN METER =====================

  /// Mengecek apakah input catatan meter baru berpotensi menghasilkan konsumsi negatif
  bool checkWillResultInNegativeConsumption({
    required double newSaldoKwh,
    required DateTime newTanggalWaktu,
  }) {
    if (_meterReadings.isEmpty) return false;

    // Cari catatan meter persis sebelum tanggal ini
    final prevList = _meterReadings
        .where((m) => m.tanggalWaktu.isBefore(newTanggalWaktu))
        .toList();
    if (prevList.isEmpty) return false;

    final prev = prevList.first; // Karena _meterReadings terurut DESC

    // Token antara prev dan new
    final tokens = _tokenPurchases.where((t) {
      return t.tanggalWaktu.isAfter(prev.tanggalWaktu) &&
          (t.tanggalWaktu.isBefore(newTanggalWaktu) ||
              t.tanggalWaktu.isAtSameMomentAs(newTanggalWaktu));
    });
    final totalToken = tokens.fold<double>(0.0, (sum, t) => sum + t.kwhToken);

    final rawConsumption = prev.saldoKwh + totalToken - newSaldoKwh;
    return rawConsumption < 0;
  }

  Future<bool> addMeterReading({
    required int userId,
    required DateTime tanggalWaktu,
    required double saldoKwh,
    String? fotoPath,
  }) async {
    if (saldoKwh < 0) {
      _errorMessage = 'Saldo kWh tidak boleh bernilai negatif.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final reading = MeterReading(
        userId: userId,
        tanggalWaktu: tanggalWaktu,
        saldoKwh: saldoKwh,
        fotoPath: fotoPath,
      );

      await _meterRepo.insertMeterReading(reading);
      await loadAllData(userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMeterReading(MeterReading reading) async {
    if (reading.saldoKwh < 0) {
      _errorMessage = 'Saldo kWh tidak boleh bernilai negatif.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _meterRepo.updateMeterReading(reading);
      await loadAllData(reading.userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMeterReading(int id, int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _meterRepo.deleteMeterReading(id, userId);
      await loadAllData(userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mengisi data contoh (dummy) Modul 1 yang realistis untuk memudahkan pengujian
  /// grafik 7 hari, riwayat, filter rentang tanggal, dan notifikasi saldo rendah.
  Future<bool> seedDummyDataForUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Pastikan profil listrik terisi (Rumah Tangga R-1/TR • 1.300 VA)
      await _profileRepo.saveOrUpdateProfile(
        ElectricityProfile(
          userId: userId,
          kategori: 'Rumah Tangga R-1/TR',
          daya: 1300,
          saldoAwalKwh: 25.0,
        ),
      );

      // 2. Bersihkan data lama milik user ini agar tidak bertumpuk ganda saat di-reset
      final existingTokens = await _tokenRepo.getTokenPurchases(userId);
      for (final t in existingTokens) {
        if (t.id != null) await _tokenRepo.deleteTokenPurchase(t.id!, userId);
      }
      final existingMeters = await _meterRepo.getMeterReadings(userId);
      for (final m in existingMeters) {
        if (m.id != null) await _meterRepo.deleteMeterReading(m.id!, userId);
      }

      final now = DateTime.now();

      // 3. Tambahkan 4 transaksi pembelian token lintas bulan (untuk uji Filter Tanggal & Total Pengeluaran)
      final sampleTokens = [
        TokenPurchase(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 38, hours: 3)),
          nominal: 100000,
          kwhToken: 67.5,
        ),
        TokenPurchase(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 21, hours: 5)),
          nominal: 50000,
          kwhToken: 33.7,
        ),
        TokenPurchase(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 10, hours: 2)),
          nominal: 50000,
          kwhToken: 33.7,
        ),
        TokenPurchase(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 3, hours: 6)),
          nominal: 20000,
          kwhToken: 13.2,
        ),
      ];
      for (final token in sampleTokens) {
        await _tokenRepo.insertTokenPurchase(token);
      }

      // 4. Tambahkan 5 catatan saldo meter selama 7 hari terakhir
      // (diakhiri saldo 5,6 kWh dengan rata-rata ~4,0 kWh/hari -> sisa ±1,4 hari agar NTF-01 ikut teruji)
      final sampleReadings = [
        MeterReading(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 6, hours: 2)),
          saldoKwh: 21.0,
        ),
        MeterReading(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 4, hours: 2)),
          saldoKwh: 13.2,
        ),
        // Setelah hari ke-3 masuk token +13,2 kWh -> saldo naik lalu terpakai lagi
        MeterReading(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 3, hours: 1)),
          saldoKwh: 22.0,
        ),
        MeterReading(
          userId: userId,
          tanggalWaktu: now.subtract(const Duration(days: 1, hours: 2)),
          saldoKwh: 10.2,
        ),
        MeterReading(
          userId: userId,
          tanggalWaktu: now,
          saldoKwh: 5.6,
        ),
      ];
      for (final reading in sampleReadings) {
        await _meterRepo.insertMeterReading(reading);
      }

      await loadAllData(userId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
