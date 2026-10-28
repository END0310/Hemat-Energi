/// Entity Saving Simulation (Modul 3 - FR-10).
///
/// Semua angka di sini adalah ESTIMASI (dihitung dari data perangkat),
/// bukan konsumsi aktual.
class SavingSimulation {
  final int? id;
  final int userId;
  final int deviceId;
  final String namaPerangkat; // disimpan agar riwayat tetap terbaca
  final double jamDikurangi; // perubahan durasi (jam/hari)
  final double kwhHematBulanan; // estimasi kWh hemat per bulan
  final double biayaHemat; // estimasi biaya hemat per bulan (Rp)
  final DateTime dibuatPada;

  SavingSimulation({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.namaPerangkat,
    required this.jamDikurangi,
    required this.kwhHematBulanan,
    required this.biayaHemat,
    required this.dibuatPada,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'nama_perangkat': namaPerangkat,
      'jam_dikurangi': jamDikurangi,
      'kwh_hemat_bulanan': kwhHematBulanan,
      'biaya_hemat': biayaHemat,
      'dibuat_pada': dibuatPada.toIso8601String(),
    };
  }

  factory SavingSimulation.fromMap(Map<String, dynamic> map) {
    return SavingSimulation(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      deviceId: map['device_id'] as int,
      namaPerangkat: map['nama_perangkat'] as String,
      jamDikurangi: (map['jam_dikurangi'] as num).toDouble(),
      kwhHematBulanan: (map['kwh_hemat_bulanan'] as num).toDouble(),
      biayaHemat: (map['biaya_hemat'] as num).toDouble(),
      dibuatPada: DateTime.parse(map['dibuat_pada'] as String),
    );
  }

  SavingSimulation copyWith({int? id}) {
    return SavingSimulation(
      id: id ?? this.id,
      userId: userId,
      deviceId: deviceId,
      namaPerangkat: namaPerangkat,
      jamDikurangi: jamDikurangi,
      kwhHematBulanan: kwhHematBulanan,
      biayaHemat: biayaHemat,
      dibuatPada: dibuatPada,
    );
  }
}
