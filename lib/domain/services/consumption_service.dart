import '../../data/models/meter_reading.dart';
import '../../data/models/token_purchase.dart';

/// Hasil perhitungan satu periode konsumsi antar dua catatan meter
class ConsumptionPeriod {
  final MeterReading previousReading;
  final MeterReading currentReading;
  final double tokensAdded;
  final double consumptionKwh;
  final double days;
  final double dailyRateKwh;
  final bool isNegative;

  ConsumptionPeriod({
    required this.previousReading,
    required this.currentReading,
    required this.tokensAdded,
    required this.consumptionKwh,
    required this.days,
    required this.dailyRateKwh,
    required this.isNegative,
  });
}

/// ConsumptionService murni Dart untuk kalkulasi konsumsi aktual listrik
class ConsumptionService {
  /// Menghitung konsumsi satu periode antara [previous] dan [current],
  /// dengan memperhitungkan token yang masuk di antara kedua waktu tersebut.
  ///
  /// Rumus PRD:
  /// Konsumsi = Saldo awal + total kWh token masuk - Saldo akhir
  static ConsumptionPeriod calculatePeriod({
    required MeterReading previous,
    required MeterReading current,
    required List<TokenPurchase> allTokens,
  }) {
    // Cari token dengan waktu SETELAH meter sebelumnya dan SAMPAI meter sekarang
    final tokensInPeriod = allTokens.where((token) {
      return token.tanggalWaktu.isAfter(previous.tanggalWaktu) &&
          (token.tanggalWaktu.isBefore(current.tanggalWaktu) ||
              token.tanggalWaktu.isAtSameMomentAs(current.tanggalWaktu));
    }).toList();

    final tokensAdded = tokensInPeriod.fold<double>(
      0.0,
      (sum, token) => sum + token.kwhToken,
    );

    // Rumus PRD 2.8: Saldo awal + token - Saldo akhir
    final rawConsumption = previous.saldoKwh + tokensAdded - current.saldoKwh;

    // Selisih hari (minimal 0.04 hari / sekitar 1 jam agar tidak bagi nol)
    final diffMinutes = current.tanggalWaktu.difference(previous.tanggalWaktu).inMinutes;
    final days = diffMinutes <= 0 ? 0.04 : (diffMinutes / (24 * 60));

    final isNegative = rawConsumption < 0;
    final dailyRate = isNegative ? 0.0 : (rawConsumption / days);

    return ConsumptionPeriod(
      previousReading: previous,
      currentReading: current,
      tokensAdded: tokensAdded,
      consumptionKwh: rawConsumption,
      days: days,
      dailyRateKwh: dailyRate,
      isNegative: isNegative,
    );
  }

  /// Menghitung seluruh periode berurutan dari daftar catatan meter
  /// [readings] diurutkan secara kronologis (ASC: paling lama ke paling baru)
  static List<ConsumptionPeriod> calculateAllPeriods({
    required List<MeterReading> readings,
    required List<TokenPurchase> allTokens,
  }) {
    if (readings.length < 2) return [];

    final sortedReadings = List<MeterReading>.from(readings)
      ..sort((a, b) => a.tanggalWaktu.compareTo(b.tanggalWaktu));

    final List<ConsumptionPeriod> periods = [];
    for (int i = 0; i < sortedReadings.length - 1; i++) {
      final period = calculatePeriod(
        previous: sortedReadings[i],
        current: sortedReadings[i + 1],
        allTokens: allTokens,
      );
      periods.add(period);
    }
    return periods;
  }

  /// Menghitung rata-rata konsumsi harian (baseline aktual) dari periode-periode valid
  /// Membutuhkan minimal 2 catatan meter (1 periode valid)
  static double? calculateAverageDailyConsumption({
    required List<MeterReading> readings,
    required List<TokenPurchase> allTokens,
  }) {
    final periods = calculateAllPeriods(readings: readings, allTokens: allTokens);
    final validPeriods = periods.where((p) => !p.isNegative).toList();

    if (validPeriods.isEmpty) return null;

    final totalConsumption = validPeriods.fold<double>(
      0.0,
      (sum, p) => sum + p.consumptionKwh,
    );
    final totalDays = validPeriods.fold<double>(
      0.0,
      (sum, p) => sum + p.days,
    );

    if (totalDays <= 0) return null;
    return totalConsumption / totalDays;
  }

  /// Menghitung estimasi konsumsi aktual untuk 7 hari terakhir
  /// Mengembalikan Map tanggal -> konsumsi kWh harian
  static Map<DateTime, double> getSevenDayConsumption({
    required List<MeterReading> readings,
    required List<TokenPurchase> allTokens,
    required DateTime today,
  }) {
    final Map<DateTime, double> result = {};
    // Inisialisasi 7 hari terakhir (h-6 sampai h-0)
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      result[date] = 0.0;
    }

    final periods = calculateAllPeriods(readings: readings, allTokens: allTokens);
    final validPeriods = periods.where((p) => !p.isNegative).toList();

    for (final period in validPeriods) {
      final start = DateTime(
        period.previousReading.tanggalWaktu.year,
        period.previousReading.tanggalWaktu.month,
        period.previousReading.tanggalWaktu.day,
      );
      final end = DateTime(
        period.currentReading.tanggalWaktu.year,
        period.currentReading.tanggalWaktu.month,
        period.currentReading.tanggalWaktu.day,
      );

      for (final date in result.keys) {
        if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
            (date.isBefore(end) || date.isAtSameMomentAs(end))) {
          result[date] = period.dailyRateKwh;
        }
      }
    }

    return result;
  }
}
