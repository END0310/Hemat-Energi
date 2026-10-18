import 'package:flutter_test/flutter_test.dart';
import 'package:hemat_energi/data/models/meter_reading.dart';
import 'package:hemat_energi/data/models/token_purchase.dart';
import 'package:hemat_energi/domain/services/consumption_service.dart';

void main() {
  group('ConsumptionService Unit Tests', () {
    test('Konsumsi aktual tanpa token (PRD: Saldo sebelumnya - Saldo sekarang)', () {
      final t1 = DateTime(2026, 10, 10, 8, 0);
      final t2 = DateTime(2026, 10, 11, 8, 0);

      final m1 = MeterReading(id: 1, userId: 1, tanggalWaktu: t1, saldoKwh: 20.0);
      final m2 = MeterReading(id: 2, userId: 1, tanggalWaktu: t2, saldoKwh: 15.0);

      final period = ConsumptionService.calculatePeriod(
        previous: m1,
        current: m2,
        allTokens: [],
      );

      expect(period.tokensAdded, 0.0);
      expect(period.consumptionKwh, 5.0); // 20 - 15 = 5 kWh
      expect(period.isNegative, false);
      expect(period.days, closeTo(1.0, 0.01));
      expect(period.dailyRateKwh, closeTo(5.0, 0.01));
    });

    test('Konsumsi aktual dengan token masuk (PRD: Saldo awal + token - Saldo akhir: 20 + 10 - 15 = 15)', () {
      final t1 = DateTime(2026, 10, 10, 8, 0);
      final tToken = DateTime(2026, 10, 10, 14, 0);
      final t2 = DateTime(2026, 10, 11, 8, 0);

      final m1 = MeterReading(id: 1, userId: 1, tanggalWaktu: t1, saldoKwh: 20.0);
      final m2 = MeterReading(id: 2, userId: 1, tanggalWaktu: t2, saldoKwh: 15.0);

      final token = TokenPurchase(
        id: 1,
        userId: 1,
        tanggalWaktu: tToken,
        nominal: 20000,
        kwhToken: 10.0,
      );

      final period = ConsumptionService.calculatePeriod(
        previous: m1,
        current: m2,
        allTokens: [token],
      );

      expect(period.tokensAdded, 10.0);
      expect(period.consumptionKwh, 15.0); // 20 + 10 - 15 = 15 kWh
      expect(period.isNegative, false);
    });

    test('Token di luar rentang waktu meter tidak dihitung ke periode', () {
      final t1 = DateTime(2026, 10, 10, 8, 0);
      final t2 = DateTime(2026, 10, 11, 8, 0);

      final m1 = MeterReading(id: 1, userId: 1, tanggalWaktu: t1, saldoKwh: 20.0);
      final m2 = MeterReading(id: 2, userId: 1, tanggalWaktu: t2, saldoKwh: 15.0);

      final tokenSebelum = TokenPurchase(
        id: 1,
        userId: 1,
        tanggalWaktu: DateTime(2026, 10, 9, 12, 0),
        nominal: 20000,
        kwhToken: 10.0,
      );

      final tokenSesudah = TokenPurchase(
        id: 2,
        userId: 1,
        tanggalWaktu: DateTime(2026, 10, 11, 10, 0),
        nominal: 20000,
        kwhToken: 20.0,
      );

      final period = ConsumptionService.calculatePeriod(
        previous: m1,
        current: m2,
        allTokens: [tokenSebelum, tokenSesudah],
      );

      expect(period.tokensAdded, 0.0);
      expect(period.consumptionKwh, 5.0);
    });

    test('Hasil konsumsi negatif ditandai dengan flag isNegative = true', () {
      final t1 = DateTime(2026, 10, 10, 8, 0);
      final t2 = DateTime(2026, 10, 11, 8, 0);

      // Saldo naik padahal tidak ada token (salah input user)
      final m1 = MeterReading(id: 1, userId: 1, tanggalWaktu: t1, saldoKwh: 10.0);
      final m2 = MeterReading(id: 2, userId: 1, tanggalWaktu: t2, saldoKwh: 15.0);

      final period = ConsumptionService.calculatePeriod(
        previous: m1,
        current: m2,
        allTokens: [],
      );

      expect(period.consumptionKwh, -5.0);
      expect(period.isNegative, true);
      expect(period.dailyRateKwh, 0.0);
    });

    test('Rata-rata konsumsi harian membutuhkan minimal 2 catatan meter', () {
      final m1 = MeterReading(id: 1, userId: 1, tanggalWaktu: DateTime(2026, 10, 10), saldoKwh: 20.0);

      final avg1 = ConsumptionService.calculateAverageDailyConsumption(
        readings: [m1],
        allTokens: [],
      );
      expect(avg1, isNull);

      final m2 = MeterReading(id: 2, userId: 1, tanggalWaktu: DateTime(2026, 10, 12), saldoKwh: 12.0);
      final avg2 = ConsumptionService.calculateAverageDailyConsumption(
        readings: [m1, m2],
        allTokens: [],
      );
      expect(avg2, isNotNull);
      // 8 kWh dalam 2 hari = 4.0 kWh/hari
      expect(avg2, closeTo(4.0, 0.05));
    });
  });
}
