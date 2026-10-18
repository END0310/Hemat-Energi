import 'package:flutter_test/flutter_test.dart';
import 'package:hemat_energi/domain/services/balance_estimator.dart';

void main() {
  group('BalanceEstimator Unit Tests', () {
    test('calculateRemainingDays rumus PRD: 6 kWh / 4 kWh/hari = 1,5 hari', () {
      final days = BalanceEstimator.calculateRemainingDays(
        latestBalanceKwh: 6.0,
        averageDailyConsumptionKwh: 4.0,
      );
      expect(days, equals(1.5));
    });

    test('calculateRemainingDays mengembalikan null jika data tidak lengkap atau rata-rata <= 0', () {
      expect(
        BalanceEstimator.calculateRemainingDays(
          latestBalanceKwh: null,
          averageDailyConsumptionKwh: 4.0,
        ),
        isNull,
      );
      expect(
        BalanceEstimator.calculateRemainingDays(
          latestBalanceKwh: 10.0,
          averageDailyConsumptionKwh: 0.0,
        ),
        isNull,
      );
      expect(
        BalanceEstimator.calculateRemainingDays(
          latestBalanceKwh: 10.0,
          averageDailyConsumptionKwh: null,
        ),
        isNull,
      );
    });

    test('getStatus mengelompokkan status saldo secara akurat', () {
      expect(BalanceEstimator.getStatus(null), BalanceStatus.belumCukupData);
      expect(BalanceEstimator.getStatus(0.8), BalanceStatus.kritis); // <= 1.0
      expect(BalanceEstimator.getStatus(1.0), BalanceStatus.kritis); // <= 1.0
      expect(BalanceEstimator.getStatus(1.5), BalanceStatus.waspada); // <= 2.0
      expect(BalanceEstimator.getStatus(2.0), BalanceStatus.waspada); // <= 2.0
      expect(BalanceEstimator.getStatus(2.1), BalanceStatus.aman); // > 2.0
      expect(BalanceEstimator.getStatus(7.0), BalanceStatus.aman);
    });

    test('shouldTriggerLowBalanceNotification mematuhi syarat PRD (min 2 meter dan sisa <= 2 hari)', () {
      // 1 catatan meter -> tidak boleh trigger meskipun sisa hari rendah
      expect(
        BalanceEstimator.shouldTriggerLowBalanceNotification(
          remainingDays: 1.0,
          meterReadingsCount: 1,
        ),
        isFalse,
      );

      // 2 catatan meter tapi sisa hari aman (> 2 hari) -> tidak trigger
      expect(
        BalanceEstimator.shouldTriggerLowBalanceNotification(
          remainingDays: 3.5,
          meterReadingsCount: 2,
        ),
        isFalse,
      );

      // 2 catatan meter dan sisa hari <= 2.0 -> trigger!
      expect(
        BalanceEstimator.shouldTriggerLowBalanceNotification(
          remainingDays: 1.8,
          meterReadingsCount: 2,
        ),
        isTrue,
      );

      // 3 catatan meter dan sisa hari kritis (0.5 hari) -> trigger!
      expect(
        BalanceEstimator.shouldTriggerLowBalanceNotification(
          remainingDays: 0.5,
          meterReadingsCount: 3,
        ),
        isTrue,
      );
    });
  });
}
