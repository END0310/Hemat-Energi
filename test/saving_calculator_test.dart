import 'package:flutter_test/flutter_test.dart';
import 'package:nama_project/models/saving_device_model.dart';
import 'package:nama_project/models/saving_target_model.dart';
import 'package:nama_project/services/saving_calculator_service.dart';

void main() {
  const ac = SavingDevice(
    id: 1,
    name: 'AC',
    powerWatt: 500,
    quantity: 1,
    dailyHours: 6,
  );

  test('Target PRD 150 kWh dikurangi 10% menjadi 135 kWh', () {
    final target = SavingTarget(
      userId: 'a',
      month: DateTime(2026, 10),
      baselineKwh: 150,
      savingPercent: 10,
    );
    target.validate();
    expect(target.targetKwh, 135);
    expect(target.weeklyReferenceKwh, closeTo(135 / 31 * 7, 0.00001));
  });

  test('Acuan mingguan memakai hari kalender termasuk tahun kabisat', () {
    for (final entry in [
      (2026, 2, 28),
      (2028, 2, 29),
      (2026, 4, 30),
      (2026, 10, 31),
    ]) {
      final target = SavingTarget(
        userId: 'a',
        month: DateTime(entry.$1, entry.$2),
        baselineKwh: 150,
        savingPercent: 10,
      );
      expect(target.periodDays, entry.$3);
      expect(target.weeklyReferenceKwh, closeTo(135 / entry.$3 * 7, 0.00001));
    }
  });

  test('Target menolak baseline nol dan persentase tidak valid', () {
    for (final percent in [0.0, -1.0, 100.1, double.nan, double.infinity]) {
      expect(
        () => SavingTarget(
          userId: 'a',
          month: DateTime(2026, 10),
          baselineKwh: 150,
          savingPercent: percent,
        ).validate(),
        throwsArgumentError,
      );
    }
    expect(
      () => SavingTarget(
        userId: 'a',
        month: DateTime(2026, 10),
        baselineKwh: 0,
        savingPercent: 10,
      ).validate(),
      throwsArgumentError,
    );
    final zeroTarget = SavingTarget(
      userId: 'a',
      month: DateTime(2026, 10),
      baselineKwh: 150,
      savingPercent: 100,
    );
    zeroTarget.validate();
    expect(zeroTarget.targetKwh, 0);
  });

  test('Contoh PRD 500 W dikurangi 1 jam = 15 kWh per 30 hari', () {
    final result = SavingCalculatorService.simulate(
      userId: 'a',
      device: ac,
      proposedHours: 5,
      tariffPerKwh: 1444.7,
    );
    expect(result.monthlySavedKwh, 15);
    expect(result.monthlySavedCost, closeTo(21670.5, 0.001));
    expect(ac.dailyHours, 6);
  });

  test('Jumlah perangkat dan batas tanpa pengurangan diperhitungkan', () {
    final result = SavingCalculatorService.simulate(
      userId: 'a',
      device: ac.copyWith(quantity: 2),
      proposedHours: 5,
      tariffPerKwh: 1000,
    );
    expect(result.monthlySavedKwh, 30);
    expect(
      SavingCalculatorService.simulate(
        userId: 'a',
        device: ac,
        proposedHours: 6,
        tariffPerKwh: 1000,
      ).monthlySavedKwh,
      0,
    );
    expect(
      SavingCalculatorService.simulate(
        userId: 'a',
        device: ac,
        proposedHours: 0,
        tariffPerKwh: 1000,
      ).monthlySavedKwh,
      90,
    );
  });

  test('Durasi di luar batas dan tarif tidak valid ditolak', () {
    for (final hours in [-1.0, 6.1, double.nan, double.infinity]) {
      expect(
        () => SavingCalculatorService.simulate(
          userId: 'a',
          device: ac,
          proposedHours: hours,
          tariffPerKwh: 1000,
        ),
        throwsArgumentError,
      );
    }
    for (final tariff in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => SavingCalculatorService.simulate(
          userId: 'a',
          device: ac,
          proposedHours: 5,
          tariffPerKwh: tariff,
        ),
        throwsArgumentError,
      );
    }
  });
}
