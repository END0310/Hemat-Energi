import '../../data/dummy/saving_dummy_data.dart';
import 'saving_calculator.dart';

/// FR-11 — Rekomendasi Berbasis Aturan (rule-based, IF–THEN manual).
/// Bukan ML / AI / model prediksi.
class RecommendationService {
  /// Ambang kenaikan konsumsi harian (30%), sama dengan default Modul 2.
  static const double ambangKenaikan = 0.30;

  /// ATURAN 1
  /// IF perangkat X = estimasi konsumsi terbesar
  /// THEN sarankan mengurangi durasi penggunaan X (1 jam/hari)
  ///
  /// Hasilnya ditampilkan sebagai kartu kuning "Konsumsi terbesar".
  static TopDeviceInsight? insightPerangkatTerbesar(List<DummyDevice> perangkat) {
    if (perangkat.isEmpty) return null;

    // Cari perangkat dengan ESTIMASI konsumsi terbesar.
    var terbesar = perangkat.first;
    double total = 0;
    for (final d in perangkat) {
      total += d.estimasiKwhBulanan;
      if (d.estimasiKwhBulanan > terbesar.estimasiKwhBulanan) terbesar = d;
    }

    // Saran: kurangi 1 jam per hari.
    const jamDikurangi = 1.0;
    final hemat = SavingCalculator.hematBulanan(
      SavingCalculator.hematHarian(terbesar.watt, jamDikurangi, terbesar.jumlah),
    );

    return TopDeviceInsight(
      perangkat: terbesar,
      persenDariTotal: total == 0 ? 0 : terbesar.estimasiKwhBulanan / total * 100,
      jamSaran: (terbesar.jamPerHari - jamDikurangi).clamp(0, 24).toDouble(),
      hematBulanan: hemat,
    );
  }

  /// Menjalankan ATURAN 2 dan 3 lalu mengembalikan daftar "Insight lainnya".
  ///
  /// [targetSampaiHariIni] = target yang "boleh" terpakai sampai hari ini
  /// (target bulanan / jumlah hari x hari berjalan). Null jika belum ada target.
  static List<Recommendation> insightLainnya({
    required String? namaPerangkatTerbesar,
    required double konsumsiAktual,
    required double? targetSampaiHariIni,
    required double konsumsiHariIni,
    required double rataRataHarian,
  }) {
    final hasil = <Recommendation>[];

    // ATURAN 2
    // IF konsumsi aktual > target
    // THEN sarankan memeriksa perangkat dengan estimasi terbesar
    if (targetSampaiHariIni != null && konsumsiAktual > targetSampaiHariIni) {
      hasil.add(Recommendation(
        judul: 'Konsumsi melebihi target',
        pesan: 'Konsumsi aktual sudah melewati target sampai hari ini. '
            'Periksa ${namaPerangkatTerbesar ?? 'perangkat berdaya besar'} terlebih dahulu.',
        jenis: RecommendationType.peringatan,
      ));
    }

    // ATURAN 3
    // IF konsumsi harian > rata-rata x threshold
    // THEN tampilkan peringatan konsumsi meningkat
    if (rataRataHarian > 0 && konsumsiHariIni > rataRataHarian * (1 + ambangKenaikan)) {
      final naik = (konsumsiHariIni - rataRataHarian) / rataRataHarian * 100;
      hasil.add(Recommendation(
        judul: 'Konsumsi meningkat',
        pesan: 'Konsumsi hari ini naik ${naik.toStringAsFixed(0)}% dari rata-rata harian.',
        jenis: RecommendationType.peringatan,
      ));
    }

    return hasil;
  }
}

/// Hasil ATURAN 1 (semua angka adalah ESTIMASI).
class TopDeviceInsight {
  final DummyDevice perangkat;
  final double persenDariTotal; // % dari total estimasi semua perangkat
  final double jamSaran; // durasi baru yang disarankan (jam/hari)
  final double hematBulanan; // estimasi kWh hemat per bulan

  TopDeviceInsight({
    required this.perangkat,
    required this.persenDariTotal,
    required this.jamSaran,
    required this.hematBulanan,
  });
}

enum RecommendationType { saran, peringatan }

class Recommendation {
  final String judul;
  final String pesan;
  final RecommendationType jenis;

  Recommendation({required this.judul, required this.pesan, required this.jenis});
}
