/// Entity Saving Target (Modul 3 - FR-09).
///
/// Target bulanan dengan monitoring mingguan.
/// [konsumsiSebelumnya] disimpan sebagai baseline agar target tidak berubah
/// ketika data meter lama diedit (lihat catatan teknis PRD bagian 19).
class SavingTarget {
  final int? id;
  final int userId;
  final DateTime periodeMulai;
  final DateTime periodeSelesai;
  final double konsumsiSebelumnya; // kWh aktual periode sebelumnya (baseline)
  final double persenHemat; // target penghematan, contoh: 10 (%)
  final double targetKonsumsi; // kWh, hasil: sebelumnya x (1 - persen/100)

  SavingTarget({
    this.id,
    required this.userId,
    required this.periodeMulai,
    required this.periodeSelesai,
    required this.konsumsiSebelumnya,
    required this.persenHemat,
    required this.targetKonsumsi,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'periode_mulai': periodeMulai.toIso8601String(),
      'periode_selesai': periodeSelesai.toIso8601String(),
      'konsumsi_sebelumnya': konsumsiSebelumnya,
      'persen_hemat': persenHemat,
      'target_konsumsi': targetKonsumsi,
    };
  }

  factory SavingTarget.fromMap(Map<String, dynamic> map) {
    return SavingTarget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      periodeMulai: DateTime.parse(map['periode_mulai'] as String),
      periodeSelesai: DateTime.parse(map['periode_selesai'] as String),
      konsumsiSebelumnya: (map['konsumsi_sebelumnya'] as num).toDouble(),
      persenHemat: (map['persen_hemat'] as num).toDouble(),
      targetKonsumsi: (map['target_konsumsi'] as num).toDouble(),
    );
  }

  SavingTarget copyWith({
    int? id,
    DateTime? periodeMulai,
    DateTime? periodeSelesai,
    double? konsumsiSebelumnya,
    double? persenHemat,
    double? targetKonsumsi,
  }) {
    return SavingTarget(
      id: id ?? this.id,
      userId: userId,
      periodeMulai: periodeMulai ?? this.periodeMulai,
      periodeSelesai: periodeSelesai ?? this.periodeSelesai,
      konsumsiSebelumnya: konsumsiSebelumnya ?? this.konsumsiSebelumnya,
      persenHemat: persenHemat ?? this.persenHemat,
      targetKonsumsi: targetKonsumsi ?? this.targetKonsumsi,
    );
  }
}
