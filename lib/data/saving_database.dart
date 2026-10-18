import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'saving_schema.dart';

/// Penyimpanan PR1 terpisah dari database modul lain.
/// Data perangkat dan tarif adalah fixture demo, bukan konsumsi pengguna.
class SavingDatabase {
  SavingDatabase._();
  static final instance = SavingDatabase._();
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    try {
      return await openDatabase(
        path.join(await getDatabasesPath(), 'hemat_energi_saving_demo.db'),
        version: 1,
        onCreate: (db, _) => createSavingDemoDatabase(db),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }
}

Future<void> createSavingDemoDatabase(DatabaseExecutor db) async {
  await createSavingTables(db);
  await db.execute('''
    CREATE TABLE devices (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      power_watt REAL NOT NULL,
      quantity INTEGER NOT NULL,
      daily_hours REAL NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE electricity_profile (
      id INTEGER PRIMARY KEY,
      category TEXT NOT NULL,
      power_va INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE tariff_configurations (
      id INTEGER PRIMARY KEY,
      category TEXT NOT NULL,
      power_va INTEGER NOT NULL,
      tariff_per_kwh REAL NOT NULL
    )
  ''');
  // Contoh profil R-1 1300 VA untuk demonstrasi perhitungan PR1.
  await db.insert('electricity_profile', {
    'id': 1,
    'category': 'demo-r1',
    'power_va': 1300,
  });
  await db.insert('tariff_configurations', {
    'id': 1,
    'category': 'demo-r1',
    'power_va': 1300,
    'tariff_per_kwh': 1444.7,
  });
  for (final device in [
    {
      'id': 1,
      'name': 'AC Kamar',
      'power_watt': 500.0,
      'quantity': 1,
      'daily_hours': 6.0,
    },
    {
      'id': 2,
      'name': 'Kulkas 1 Pintu',
      'power_watt': 100.0,
      'quantity': 1,
      'daily_hours': 15.0,
    },
    {
      'id': 3,
      'name': 'TV LED Kos',
      'power_watt': 100.0,
      'quantity': 1,
      'daily_hours': 4.0,
    },
    {
      'id': 4,
      'name': 'Lampu Belajar',
      'power_watt': 12.0,
      'quantity': 2,
      'daily_hours': 8.0,
    },
  ]) {
    await db.insert('devices', device);
  }
}
