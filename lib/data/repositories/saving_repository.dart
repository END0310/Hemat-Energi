import '../dummy/saving_dummy_data.dart';
import '../models/saving_simulation.dart';
import '../models/saving_target.dart';
import '../../domain/services/saving_calculator.dart';

/// Penyimpanan data Modul 3 (target & simulasi).
///
/// Sementara disimpan di memori (List) karena data belum ada.
/// TODO(merge): ganti isi method dengan query SQLite lewat DatabaseHelper
/// (tabel `saving_targets` & `saving_simulations`). Nama method sengaja
/// dibuat sama dengan pola repository Modul 1 supaya mudah diganti.
class SavingRepository {
  SavingRepository._();
  static final SavingRepository instance = SavingRepository._();

  int _nextTargetId = 2;
  int _nextSimulationId = 1;

  // Satu target contoh untuk bulan berjalan agar layar tidak kosong.
  final List<SavingTarget> _targets = [
    SavingTarget(
      id: 1,
      userId: SavingDummyData.userId,
      periodeMulai: DateTime(DateTime.now().year, DateTime.now().month, 1),
      periodeSelesai: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
      konsumsiSebelumnya: SavingDummyData.konsumsiPeriodeSebelumnya,
      persenHemat: 10,
      targetKonsumsi: SavingCalculator.targetKonsumsi(
        SavingDummyData.konsumsiPeriodeSebelumnya,
        10,
      ),
    ),
  ];

  final List<SavingSimulation> _simulations = [];

  // ---------------------------------------------------------------------------
  // CRUD Saving Target (FR-09)
  // ---------------------------------------------------------------------------

  List<SavingTarget> getTargets(int userId) {
    final list = _targets.where((t) => t.userId == userId).toList();
    list.sort((a, b) => b.periodeMulai.compareTo(a.periodeMulai)); // terbaru dulu
    return list;
  }

  /// Target yang periodenya mencakup hari ini (null jika tidak ada).
  SavingTarget? getActiveTarget(int userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final t in getTargets(userId)) {
      if (!today.isBefore(t.periodeMulai) && !today.isAfter(t.periodeSelesai)) {
        return t;
      }
    }
    return null;
  }

  void insertTarget(SavingTarget target) {
    _targets.add(target.copyWith(id: _nextTargetId++));
  }

  void updateTarget(SavingTarget target) {
    final index = _targets.indexWhere((t) => t.id == target.id);
    if (index != -1) _targets[index] = target;
  }

  void deleteTarget(int id) {
    _targets.removeWhere((t) => t.id == id);
  }

  // ---------------------------------------------------------------------------
  // CRUD Saving Simulation (FR-10)
  // ---------------------------------------------------------------------------

  List<SavingSimulation> getSimulations(int userId) {
    final list = _simulations.where((s) => s.userId == userId).toList();
    list.sort((a, b) => b.dibuatPada.compareTo(a.dibuatPada));
    return list;
  }

  void insertSimulation(SavingSimulation simulation) {
    _simulations.add(simulation.copyWith(id: _nextSimulationId++));
  }

  void deleteSimulation(int id) {
    _simulations.removeWhere((s) => s.id == id);
  }

  // ---------------------------------------------------------------------------
  // Progress target (gabungan data target + konsumsi aktual)
  // ---------------------------------------------------------------------------

  TargetProgress hitungProgress(SavingTarget target) {
    final totalHari = SavingCalculator.jumlahHari(target.periodeMulai, target.periodeSelesai);
    final berjalan = SavingCalculator.hariBerjalan(
      target.periodeMulai,
      target.periodeSelesai,
      DateTime.now(),
    );
    final aktual = SavingDummyData.konsumsiAktual(berjalan); // TODO(merge)
    final proyeksi = SavingCalculator.proyeksiAkhirPeriode(
      konsumsiAktual: aktual,
      hariBerjalan: berjalan,
      jumlahHariPeriode: totalHari,
    );

    return TargetProgress(
      targetKonsumsi: target.targetKonsumsi,
      jumlahHari: totalHari,
      hariBerjalan: berjalan,
      konsumsiAktual: aktual,
      proyeksi: proyeksi,
      targetMingguan: SavingCalculator.targetMingguan(target.targetKonsumsi, totalHari),
      status: SavingCalculator.statusTarget(
        targetKonsumsi: target.targetKonsumsi,
        konsumsiAktual: aktual,
        proyeksi: proyeksi,
        hariBerjalan: berjalan,
        jumlahHariPeriode: totalHari,
      ),
    );
  }
}

/// Ringkasan kondisi sebuah target pada hari ini.
class TargetProgress {
  final double targetKonsumsi;
  final int jumlahHari;
  final int hariBerjalan;
  final double konsumsiAktual;
  final double proyeksi;
  final double targetMingguan;
  final TargetStatus status;

  TargetProgress({
    required this.targetKonsumsi,
    required this.jumlahHari,
    required this.hariBerjalan,
    required this.konsumsiAktual,
    required this.proyeksi,
    required this.targetMingguan,
    required this.status,
  });

  int get sisaHari => jumlahHari - hariBerjalan;

  /// Sisa kWh sebelum target terlampaui (minimal 0).
  double get sisaTarget =>
      (targetKonsumsi - konsumsiAktual).clamp(0, double.infinity).toDouble();

  /// Persentase target yang sudah terpakai (0.0 - 1.0).
  double get persenTerpakai =>
      targetKonsumsi <= 0 ? 0 : (konsumsiAktual / targetKonsumsi).clamp(0.0, 1.0);

  /// Batas konsumsi per hari agar target tercapai.
  double get batasHarian => SavingCalculator.batasHarian(
        targetKonsumsi: targetKonsumsi,
        konsumsiAktual: konsumsiAktual,
        sisaHari: sisaHari,
      );
}
