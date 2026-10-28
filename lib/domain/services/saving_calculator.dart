/// Rumus-rumus Modul 3 (PRD bagian 13 & 18).
/// Semua fungsi murni (tanpa database) supaya mudah dibaca dan dijelaskan.
class SavingCalculator {
  // ---------------------------------------------------------------------------
  // FR-09 — Target Penghematan
  // ---------------------------------------------------------------------------

  /// Target konsumsi = konsumsi sebelumnya x (1 - % target hemat)
  /// Contoh: 150 kWh, hemat 10% -> 150 - 15 = 135 kWh
  static double targetKonsumsi(double konsumsiSebelumnya, double persenHemat) {
    return konsumsiSebelumnya * (1 - persenHemat / 100);
  }

  /// Jumlah hari dalam periode (tanggal mulai & selesai ikut dihitung).
  static int jumlahHari(DateTime mulai, DateTime selesai) {
    return _tanggal(selesai).difference(_tanggal(mulai)).inDays + 1;
  }

  /// Target mingguan = target bulanan / jumlah hari periode x 7
  static double targetMingguan(double targetBulanan, int jumlahHariPeriode) {
    if (jumlahHariPeriode <= 0) return 0;
    return targetBulanan / jumlahHariPeriode * 7;
  }

  /// Berapa hari periode yang sudah berjalan sampai [hariIni].
  /// Hasil dibatasi antara 0 dan jumlah hari periode.
  static int hariBerjalan(DateTime mulai, DateTime selesai, DateTime hariIni) {
    final total = jumlahHari(mulai, selesai);
    final berjalan = _tanggal(hariIni).difference(_tanggal(mulai)).inDays + 1;
    return berjalan.clamp(0, total);
  }

  /// Proyeksi konsumsi akhir periode = rata-rata harian berjalan x jumlah hari
  static double proyeksiAkhirPeriode({
    required double konsumsiAktual,
    required int hariBerjalan,
    required int jumlahHariPeriode,
  }) {
    if (hariBerjalan <= 0) return 0;
    return konsumsiAktual / hariBerjalan * jumlahHariPeriode;
  }

  /// Batas konsumsi per hari agar target tetap tercapai
  /// = sisa target / sisa hari
  static double batasHarian({
    required double targetKonsumsi,
    required double konsumsiAktual,
    required int sisaHari,
  }) {
    if (sisaHari <= 0) return 0;
    final sisaTarget = targetKonsumsi - konsumsiAktual;
    return sisaTarget > 0 ? sisaTarget / sisaHari : 0;
  }

  /// Status target sesuai definisi notifikasi Modul 3 di PRD.
  static TargetStatus statusTarget({
    required double targetKonsumsi,
    required double konsumsiAktual,
    required double proyeksi,
    required int hariBerjalan,
    required int jumlahHariPeriode,
  }) {
    final sisaHari = jumlahHariPeriode - hariBerjalan;

    if (hariBerjalan <= 0) return TargetStatus.belumMulai;

    // Periode selesai -> bandingkan konsumsi aktual dengan target.
    if (sisaHari <= 0) {
      return konsumsiAktual <= targetKonsumsi
          ? TargetStatus.tercapai
          : TargetStatus.tidakTercapai;
    }

    // Proyeksi > target -> berisiko tidak tercapai.
    if (proyeksi > targetKonsumsi) return TargetStatus.berisiko;

    // Sisa periode <= 3 hari dan proyeksi <= target -> hampir tercapai.
    if (sisaHari <= 3) return TargetStatus.hampirTercapai;

    return TargetStatus.aman;
  }

  // ---------------------------------------------------------------------------
  // FR-10 — Simulasi Penghematan (hasil selalu ESTIMASI)
  // ---------------------------------------------------------------------------

  /// Hemat harian (kWh) = Watt x Jam dikurangi x Jumlah / 1000
  /// Contoh: AC 500 W dikurangi 1 jam -> 0,5 kWh/hari
  static double hematHarian(double watt, double jamDikurangi, int jumlah) {
    return watt * jamDikurangi * jumlah / 1000;
  }

  /// Hemat bulanan (kWh) = hemat harian x 30
  static double hematBulanan(double hematHarianKwh) {
    return hematHarianKwh * 30;
  }

  /// Estimasi biaya = kWh x tarif
  static double estimasiBiaya(double kwh, double tarif) {
    return kwh * tarif;
  }

  /// Membuang jam/menit supaya hitungan hari tidak meleset.
  static DateTime _tanggal(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Status target penghematan.
enum TargetStatus {
  belumMulai,
  aman,
  hampirTercapai,
  berisiko,
  tercapai,
  tidakTercapai,
}
