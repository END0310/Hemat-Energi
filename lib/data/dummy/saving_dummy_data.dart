/// DATA DUMMY untuk Modul 3 (Penghematan).
///
/// Data asli belum tersedia, jadi semua angka di file ini sementara.
/// Saat merge, ganti setiap bagian bertanda `TODO(merge)` dengan data asli:
/// - userId          -> AuthProvider.currentUser.id
/// - tarif           -> ElectricityProvider (profil listrik + Tariff Configuration)
/// - konsumsi aktual -> ConsumptionService (Modul 1)
/// - perangkat       -> Device repository (Modul 2)
class SavingDummyData {
  // TODO(merge): ambil dari AuthProvider.
  static const int userId = 1;

  // TODO(merge): ambil dari profil listrik (kategori + daya -> tarif).
  static const double tarifPerKwh = 1444.70;

  // TODO(merge): konsumsi AKTUAL periode sebelumnya dari data meter + token.
  static const double konsumsiPeriodeSebelumnya = 150.0;

  // TODO(merge): rata-rata konsumsi AKTUAL harian (baseline) dari Modul 1.
  static const double rataRataHarian = 4.25;

  // TODO(merge): konsumsi AKTUAL hari ini dari Modul 1 / Modul 2.
  static const double konsumsiHariIni = 6.0;

  /// Konsumsi AKTUAL pada rentang tanggal tertentu.
  /// Dummy: rata-rata harian x jumlah hari yang sudah berjalan.
  // TODO(merge): ganti dengan perhitungan ConsumptionService (Modul 1).
  static double konsumsiAktual(int hariBerjalan) {
    return rataRataHarian * hariBerjalan;
  }

  // TODO(merge): ganti dengan daftar perangkat dari Modul 2 (FR-05).
  static const List<DummyDevice> perangkat = [
    DummyDevice(id: 1, nama: 'AC', watt: 500, jumlah: 1, jamPerHari: 6),
    DummyDevice(id: 2, nama: 'Kulkas', watt: 60, jumlah: 1, jamPerHari: 24),
    DummyDevice(id: 3, nama: 'TV', watt: 60, jumlah: 1, jamPerHari: 4),
    DummyDevice(id: 4, nama: 'Lampu LED', watt: 10, jumlah: 4, jamPerHari: 10),
  ];
}

/// Bentuk sederhana data perangkat. Hanya dipakai selama data Modul 2 belum ada.
class DummyDevice {
  final int id;
  final String nama;
  final double watt;
  final int jumlah;
  final double jamPerHari;

  const DummyDevice({
    required this.id,
    required this.nama,
    required this.watt,
    required this.jumlah,
    required this.jamPerHari,
  });

  /// ESTIMASI kWh per bulan = (Watt x Jam x Jumlah) / 1000 x 30
  double get estimasiKwhBulanan => watt * jamPerHari * jumlah / 1000 * 30;
}
