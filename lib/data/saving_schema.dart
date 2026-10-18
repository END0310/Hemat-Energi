import 'package:sqflite/sqflite.dart';

Future<void> createSavingTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE saving_targets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      period TEXT NOT NULL,
      baseline_kwh REAL NOT NULL CHECK(baseline_kwh > 0),
      saving_percent REAL NOT NULL CHECK(saving_percent > 0 AND saving_percent <= 100),
      target_kwh REAL NOT NULL CHECK(target_kwh >= 0),
      UNIQUE(user_id, period)
    )
  ''');
  await db.execute('''
    CREATE TABLE saving_simulations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      device_id INTEGER NOT NULL,
      device_name TEXT NOT NULL,
      power_watt REAL NOT NULL,
      quantity INTEGER NOT NULL,
      original_hours REAL NOT NULL,
      proposed_hours REAL NOT NULL,
      tariff_per_kwh REAL NOT NULL,
      monthly_saved_kwh REAL NOT NULL,
      monthly_saved_cost REAL NOT NULL
    )
  ''');
}
