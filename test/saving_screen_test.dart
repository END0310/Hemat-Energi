import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nama_project/core/saving_colors.dart';
import 'package:nama_project/data/saving_repository.dart';
import 'package:nama_project/models/saving_device_model.dart';
import 'package:nama_project/models/saving_target_model.dart';
import 'package:nama_project/models/saving_simulation_model.dart';
import 'package:nama_project/screens/saving_screen.dart';
import 'package:nama_project/screens/saving_simulation_screen.dart';

class DemoRepository extends SavingRepository {
  DemoRepository() : super(userId: 'demo-test');
  final List<SavingTarget> storedTargets = [];
  final List<SavingSimulation> storedSimulations = [];
  bool failLoad = false;
  bool failSave = false;
  double? tariff = 1444.7;
  List<SavingDevice> devices = [
    const SavingDevice(
      id: 1,
      name: 'AC Kamar',
      powerWatt: 500,
      quantity: 1,
      dailyHours: 6,
    ),
  ];

  @override
  Future<List<SavingTarget>> targets() async {
    if (failLoad) throw StateError('Uji kegagalan');
    return List.of(storedTargets);
  }

  @override
  Future<void> saveTarget(SavingTarget target) async {
    if (failSave) throw StateError('Uji gagal simpan');
    storedTargets.removeWhere((t) => t.id == target.id);
    storedTargets.add(
      SavingTarget(
        id: target.id ?? storedTargets.length + 1,
        userId: target.userId,
        month: target.month,
        baselineKwh: target.baselineKwh,
        savingPercent: target.savingPercent,
      ),
    );
  }

  @override
  Future<void> deleteTarget(int id) async =>
      storedTargets.removeWhere((t) => t.id == id);
  @override
  Future<SavingInputs> inputs() async => SavingInputs(devices, tariff);
  @override
  Future<List<SavingSimulation>> simulations() async =>
      List.of(storedSimulations);
  @override
  Future<void> saveSimulation(SavingSimulation item) async {
    storedSimulations.removeWhere((s) => s.id == item.id);
    storedSimulations.add(
      SavingSimulation.fromMap({
        ...item.toMap(),
        'id': item.id ?? storedSimulations.length + 1,
      }),
    );
  }

  @override
  Future<void> deleteSimulation(int id) async =>
      storedSimulations.removeWhere((s) => s.id == id);
}

const capture = bool.fromEnvironment('CAPTURE_SAVINGS');
final captureKey = GlobalKey();

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.runAsync(() async {
    // Font SDK menyamakan layout test dengan render; bukan asset aplikasi.
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    final flutter = packages.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = configFile.uri.resolve('${flutter['rootUri']}/');
    final font = File.fromUri(
      root.resolve(
        '../../bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      ),
    );
    final loader = FontLoader('Roboto')
      ..addFont(font.readAsBytes().then((b) => ByteData.sublistView(b)));
    await loader.load();
    final icons = File.fromUri(
      root.resolve(
        '../../bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      ),
    );
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(icons.readAsBytes().then((b) => ByteData.sublistView(b)));
    await iconLoader.load();
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: SavingColors.surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: SavingColors.primaryGreen,
            primary: SavingColors.primaryGreen,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> captureScreen(WidgetTester tester, String name) async {
  if (!capture) return;
  final boundary =
      captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('docs/progress-report-1/images');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'Navigasi target, validasi, simpan, ubah, hapus, kembali ke ringkasan',
    (tester) async {
      final repository = DemoRepository();
      await pumpScreen(tester, SavingScreen(repository: repository));
      expect(find.text('Belum ada target'), findsOneWidget);
      await captureScreen(tester, '01-penghematan');
      await tester.tap(find.text('Target penghematan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat target'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '101');
      await tester.tap(find.text('Simpan target'));
      await tester.pumpAndSettle();
      expect(
        find.text('Isi persentase lebih dari 0 sampai 100.'),
        findsOneWidget,
      );
      expect(repository.storedTargets, isEmpty);
      await tester.enterText(find.byType(TextFormField), '10');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await captureScreen(tester, '02-form-target');
      await tester.tap(find.text('Simpan target'));
      await tester.pumpAndSettle();
      expect(find.text('135,0 kWh'), findsOneWidget);
      await captureScreen(tester, '03-target-tersimpan');
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '20');
      await tester.tap(find.text('Simpan target'));
      await tester.pumpAndSettle();
      expect(find.text('120,0 kWh'), findsOneWidget);
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Batal'));
      await tester.pumpAndSettle();
      expect(repository.storedTargets, hasLength(1));
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Hapus').last);
      await tester.pumpAndSettle();
      expect(repository.storedTargets, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Belum ada target'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Slider, simpan, ubah dan hapus simulasi tanpa mengubah perangkat',
    (tester) async {
      final repository = DemoRepository();
      await pumpScreen(tester, SavingSimulationScreen(repository: repository));
      expect(find.text('15,0 kWh / bulan'), findsOneWidget);
      await captureScreen(tester, '04-simulasi');
      await tester.drag(find.byType(Slider), const Offset(-70, 0));
      await tester.pumpAndSettle();
      expect(find.text('15,0 kWh / bulan'), findsNothing);
      await tester.ensureVisible(find.text('Simpan simulasi'));
      await tester.tap(find.text('Simpan simulasi'));
      await tester.pumpAndSettle();
      expect(repository.storedSimulations, hasLength(1));
      expect(repository.devices.single.dailyHours, 6);
      await tester.scrollUntilVisible(find.text('Ubah'), 200);
      await Scrollable.ensureVisible(
        tester.element(find.text('Ubah')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(Slider), -200);
      await Scrollable.ensureVisible(
        tester.element(find.byType(Slider)),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      final savedBeforeEdit =
          repository.storedSimulations.single.monthlySavedKwh;
      await tester.drag(find.byType(Slider), const Offset(20, 0));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Simpan perubahan'), 200);
      await tester.tap(find.text('Simpan perubahan'));
      await tester.pumpAndSettle();
      expect(repository.storedSimulations, hasLength(1));
      expect(
        repository.storedSimulations.single.monthlySavedKwh,
        isNot(savedBeforeEdit),
      );
      await tester.scrollUntilVisible(find.text('Hapus'), 200);
      await Scrollable.ensureVisible(
        tester.element(find.text('Hapus')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Hapus').last);
      await tester.pumpAndSettle();
      expect(repository.storedSimulations, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tanpa perangkat atau tarif, simpan dinonaktifkan', (
    tester,
  ) async {
    final repository = DemoRepository()..tariff = null;
    await pumpScreen(
      tester,
      SavingSimulationScreen(repository: repository),
      scale: 1.5,
    );
    expect(find.textContaining('Tarif belum tersedia'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Simpan simulasi'), 200);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    repository.devices = [];
    await pumpScreen(tester, SavingSimulationScreen(repository: repository));
    expect(find.textContaining('Belum ada perangkat'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets(
    'Kegagalan muat bisa dicoba ulang dan kegagalan simpan tidak menutup form',
    (tester) async {
      final repository = DemoRepository()..failLoad = true;
      await pumpScreen(tester, SavingScreen(repository: repository));
      expect(find.textContaining('Target gagal dimuat'), findsOneWidget);
      repository.failLoad = false;
      await tester.tap(find.byTooltip('Perbarui'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada target'), findsOneWidget);
      await tester.tap(find.text('Target penghematan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat target'));
      await tester.pumpAndSettle();
      repository.failSave = true;
      await tester.tap(find.text('Simpan target'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Target belum tersimpan'), findsOneWidget);
      expect(repository.storedTargets, isEmpty);
    },
  );
}
