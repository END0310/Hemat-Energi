import '../../core/constants.dart';

/// Status kondisi saldo token listrik
enum BalanceStatus {
  aman,
  waspada,
  kritis,
  belumCukupData,
}

/// BalanceEstimator menangani perhitungan estimasi sisa hari saldo listrik
/// dan penentuan status kelayakan notifikasi saldo rendah.
class BalanceEstimator {
  /// Menghitung estimasi sisa hari: Saldo kWh terakhir ÷ rata-rata konsumsi kWh/hari
  /// Contoh PRD: 6 kWh ÷ 4 kWh/hari = 1,5 hari
  static double? calculateRemainingDays({
    required double? latestBalanceKwh,
    required double? averageDailyConsumptionKwh,
  }) {
    if (latestBalanceKwh == null ||
        averageDailyConsumptionKwh == null ||
        averageDailyConsumptionKwh <= 0) {
      return null;
    }
    return latestBalanceKwh / averageDailyConsumptionKwh;
  }

  /// Menentukan status kondisi saldo token
  static BalanceStatus getStatus(double? remainingDays) {
    if (remainingDays == null) {
      return BalanceStatus.belumCukupData;
    }
    if (remainingDays <= AppConstants.criticalThresholdDays) {
      return BalanceStatus.kritis;
    }
    if (remainingDays <= AppConstants.warningThresholdDays) {
      return BalanceStatus.waspada;
    }
    return BalanceStatus.aman;
  }

  /// Label teks untuk ditampilkan pada badge status UI
  static String getStatusLabel(BalanceStatus status) {
    switch (status) {
      case BalanceStatus.aman:
        return 'Aman';
      case BalanceStatus.waspada:
        return 'Waspada';
      case BalanceStatus.kritis:
        return 'Kritis';
      case BalanceStatus.belumCukupData:
        return 'Normal';
    }
  }

  /// Memeriksa apakah memenuhi syarat pengiriman notifikasi saldo rendah (NTF-01)
  /// - Minimal 2 catatan meter (memiliki baseline)
  /// - Sisa hari <= ambang batas (default 2 hari)
  static bool shouldTriggerLowBalanceNotification({
    required double? remainingDays,
    required int meterReadingsCount,
    double thresholdDays = AppConstants.lowBalanceThresholdDays,
  }) {
    if (meterReadingsCount < 2) return false;
    if (remainingDays == null) return false;
    return remainingDays <= thresholdDays;
  }
}
