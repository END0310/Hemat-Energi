import 'package:sqflite/sqflite.dart';

import '../models/saving_device_model.dart';
import '../models/saving_target_model.dart';
import '../models/saving_simulation_model.dart';
import '../services/saving_calculator_service.dart';
import 'saving_database.dart';

/// PR1 memakai ruang demo eksplisit. Ganti dengan ID dari sesi saat auth siap.
const savingDemoUserId = 'demo-modul-3';

class SavingInputs {
  final List<SavingDevice> devices;
  final double? tariffPerKwh;
  const SavingInputs(this.devices, this.tariffPerKwh);
}

class SavingRepository {
  final String userId;
  final Future<Database> Function() _openDatabase;

  SavingRepository({required this.userId, Future<Database> Function()? openDb})
    : _openDatabase = openDb ?? (() => SavingDatabase.instance.database);

  Future<List<SavingTarget>> targets() async {
    final db = await _openDatabase();
    final rows = await db.query(
      'saving_targets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'period DESC',
    );
    return rows.map(SavingTarget.fromMap).toList();
  }

  Future<void> saveTarget(SavingTarget target) async {
    target.validate();
    if (target.userId != userId) {
      throw ArgumentError('Pemilik target tidak sesuai.');
    }
    final db = await _openDatabase();
    if (target.id == null) {
      // UNIQUE(user_id, period) mencegah dua target pada bulan yang sama.
      await db.insert('saving_targets', target.toMap());
    } else {
      final count = await db.update(
        'saving_targets',
        target.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [target.id, userId],
      );
      if (count != 1) throw StateError('Target tidak ditemukan.');
    }
  }

  Future<void> deleteTarget(int id) async {
    final db = await _openDatabase();
    await db.delete(
      'saving_targets',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<SavingInputs> inputs() async {
    final db = await _openDatabase();
    final rows = await db.query('devices', orderBy: 'name ASC');
    // Jangan memakai fallback tarif: pasangan kategori + daya harus ditemukan.
    final tariffs = await db.rawQuery('''
      SELECT t.tariff_per_kwh FROM electricity_profile p
      INNER JOIN tariff_configurations t
        ON p.category = t.category AND p.power_va = t.power_va
      ORDER BY p.id, t.id LIMIT 1
    ''');
    final tariff = tariffs.isEmpty
        ? null
        : (tariffs.first['tariff_per_kwh'] as num).toDouble();
    return SavingInputs(
      rows.map(SavingDevice.fromMap).toList(),
      tariff != null && tariff.isFinite && tariff > 0 ? tariff : null,
    );
  }

  Future<List<SavingSimulation>> simulations() async {
    final db = await _openDatabase();
    final rows = await db.query(
      'saving_simulations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(SavingSimulation.fromMap).toList();
  }

  Future<void> saveSimulation(SavingSimulation simulation) async {
    if (simulation.userId != userId) {
      throw ArgumentError('Pemilik tidak sesuai.');
    }
    // Hitung ulang snapshot; jangan percaya nilai turunan dari pemanggil.
    final checked = SavingCalculatorService.simulate(
      id: simulation.id,
      userId: userId,
      device: SavingDevice(
        id: simulation.deviceId,
        name: simulation.deviceName,
        powerWatt: simulation.powerWatt,
        quantity: simulation.quantity,
        dailyHours: simulation.originalHours,
      ),
      proposedHours: simulation.proposedHours,
      tariffPerKwh: simulation.tariffPerKwh,
    );
    if (checked.monthlySavedKwh <= 0) {
      throw ArgumentError('Pilih pengurangan durasi.');
    }
    final db = await _openDatabase();
    if (checked.id == null) {
      await db.insert('saving_simulations', checked.toMap());
    } else {
      final count = await db.update(
        'saving_simulations',
        checked.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [checked.id, userId],
      );
      if (count != 1) throw StateError('Simulasi tidak ditemukan.');
    }
  }

  Future<void> deleteSimulation(int id) async {
    final db = await _openDatabase();
    await db.delete(
      'saving_simulations',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
