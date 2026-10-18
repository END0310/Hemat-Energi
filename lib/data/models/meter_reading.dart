class MeterReading {
  final int? id;
  final int userId;
  final DateTime tanggalWaktu;
  final double saldoKwh;
  final String? fotoPath;

  MeterReading({
    this.id,
    required this.userId,
    required this.tanggalWaktu,
    required this.saldoKwh,
    this.fotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tanggal_waktu': tanggalWaktu.toIso8601String(),
      'saldo_kwh': saldoKwh,
      'foto_path': fotoPath,
    };
  }

  factory MeterReading.fromMap(Map<String, dynamic> map) {
    return MeterReading(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      tanggalWaktu: DateTime.parse(map['tanggal_waktu'] as String),
      saldoKwh: (map['saldo_kwh'] as num).toDouble(),
      fotoPath: map['foto_path'] as String?,
    );
  }

  MeterReading copyWith({
    int? id,
    int? userId,
    DateTime? tanggalWaktu,
    double? saldoKwh,
    String? fotoPath,
  }) {
    return MeterReading(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tanggalWaktu: tanggalWaktu ?? this.tanggalWaktu,
      saldoKwh: saldoKwh ?? this.saldoKwh,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }
}
