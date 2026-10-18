import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nama_project/data/saving_repository.dart';
import 'package:nama_project/data/saving_schema.dart';
import 'package:nama_project/data/saving_database.dart';
import 'package:nama_project/models/saving_device_model.dart';
import 'package:nama_project/models/saving_target_model.dart';
import 'package:nama_project/services/saving_calculator_service.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late Directory directory;
  late String path;
  late SavingRepository alice;
  late SavingRepository bob;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('saving-test-');
    path = '${directory.path}/saving.db';
    db = await databaseFactoryFfiNoIsolate.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) => createSavingTables(db),
      ),
    );
    alice = SavingRepository(userId: 'alice', openDb: () async => db);
    bob = SavingRepository(userId: 'bob', openDb: () async => db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  SavingTarget target({int? id, double percent = 10}) => SavingTarget(
    id: id,
    userId: 'alice',
    month: DateTime(2026, 10),
    baselineKwh: 150,
    savingPercent: percent,
  );

  test('Database demo mandiri menyediakan input simulasi dan mempertahankan data setelah restart', () async {
    final demoPath = '${directory.path}/demo.db';
    var demo = await databaseFactoryFfiNoIsolate.openDatabase(
      demoPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => createSavingDemoDatabase(db),
      ),
    );
    final repository = SavingRepository(
      userId: 'alice',
      openDb: () async => demo,
    );
    try {
      final inputs = await repository.inputs();
      expect(inputs.devices, hasLength(4));
      expect(inputs.tariffPerKwh, 1444.7);
      expect(await repository.targets(), isEmpty);
      await repository.saveTarget(target());
      final ac = inputs.devices.firstWhere((d) => d.name == 'AC Kamar');
      await repository.saveSimulation(
        SavingCalculatorService.simulate(
          userId: 'alice',
          device: ac,
          proposedHours: 5,
          tariffPerKwh: inputs.tariffPerKwh!,
        ),
      );
      await demo.close();
      demo = await databaseFactoryFfiNoIsolate.openDatabase(demoPath);
      expect((await repository.targets()).single.targetKwh, 135);
      expect((await repository.simulations()).single.monthlySavedKwh, 15);
      expect(
        (await repository.inputs()).devices
            .firstWhere((d) => d.id == ac.id)
            .dailyHours,
        6,
      );
    } finally {
      await demo.close();
    }
  });

  test(
    'CRUD target, unik per bulan, isolasi pengguna, dan restart database',
    () async {
      await alice.saveTarget(target());
      expect((await alice.targets()).single.targetKwh, 135);
      expect(await bob.targets(), isEmpty);
      await expectLater(
        alice.saveTarget(target()),
        throwsA(isA<DatabaseException>()),
      );
      final id = (await alice.targets()).single.id!;
      await bob.deleteTarget(id);
      expect(await alice.targets(), hasLength(1));
      await expectLater(bob.saveTarget(target(id: id)), throwsArgumentError);
      await alice.saveTarget(target(id: id, percent: 20));
      await db.close();
      db = await databaseFactoryFfiNoIsolate.openDatabase(path);
      expect((await alice.targets()).single.targetKwh, 120);
      await alice.deleteTarget(id);
      expect(await alice.targets(), isEmpty);
    },
  );

  test('Simulasi menyimpan snapshot, dapat diubah/dihapus, dan terpisah per pengguna', () async {
    const device = SavingDevice(
      id: 8,
      name: 'AC',
      powerWatt: 500,
      quantity: 1,
      dailyHours: 6,
    );
    await alice.saveSimulation(
      SavingCalculatorService.simulate(
        userId: 'alice',
        device: device,
        proposedHours: 5,
        tariffPerKwh: 1444.7,
      ),
    );
    final snapshot = (await alice.simulations()).single;
    expect(snapshot.monthlySavedKwh, 15);
    expect(await bob.simulations(), isEmpty);
    await bob.deleteSimulation(snapshot.id!);
    expect(await alice.simulations(), hasLength(1));
    await alice.saveSimulation(
      SavingCalculatorService.simulate(
        id: snapshot.id,
        userId: 'alice',
        device: device,
        proposedHours: 4,
        tariffPerKwh: 1444.7,
      ),
    );
    await db.close();
    db = await databaseFactoryFfiNoIsolate.openDatabase(path);
    expect((await alice.simulations()).single.monthlySavedKwh, 30);
    await alice.deleteSimulation(snapshot.id!);
    expect(await alice.simulations(), isEmpty);
  });

  test('Tarif berasal dari lookup kategori dan daya, tanpa fallback', () async {
    await db.execute(
      'CREATE TABLE devices (id INTEGER, name TEXT, power_watt REAL, quantity INTEGER, daily_hours REAL)',
    );
    await db.execute(
      'CREATE TABLE electricity_profile (id INTEGER, category TEXT, power_va INTEGER, tariff_per_kwh REAL)',
    );
    await db.execute(
      'CREATE TABLE tariff_configurations (id INTEGER, category TEXT, power_va INTEGER, tariff_per_kwh REAL)',
    );
    await db.insert('electricity_profile', {
      'id': 1,
      'category': 'uji',
      'power_va': 1300,
      'tariff_per_kwh': 99999,
    });
    expect((await alice.inputs()).tariffPerKwh, isNull);
    await db.insert('tariff_configurations', {
      'id': 1,
      'category': 'uji',
      'power_va': 1300,
      'tariff_per_kwh': 1400,
    });
    expect((await alice.inputs()).tariffPerKwh, 1400);
  });

  test(
    'Migrasi v2 ke v3 menambah tabel tanpa menghapus perangkat lama',
    () async {
      final oldPath = '${directory.path}/v2.db';
      var old = await databaseFactoryFfiNoIsolate.openDatabase(
        oldPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE devices (id INTEGER PRIMARY KEY, name TEXT)',
            );
            await db.insert('devices', {'id': 1, 'name': 'AC lama'});
          },
        ),
      );
      await old.close();
      old = await databaseFactoryFfiNoIsolate.openDatabase(
        oldPath,
        options: OpenDatabaseOptions(
          version: 3,
          onUpgrade: (db, oldVersion, _) async {
            if (oldVersion < 3) await createSavingTables(db);
          },
        ),
      );
      expect((await old.query('devices')).single['name'], 'AC lama');
      final repository = SavingRepository(
        userId: 'alice',
        openDb: () async => old,
      );
      await repository.saveTarget(target());
      expect((await repository.targets()).single.targetKwh, 135);
      await old.close();
    },
  );
}
