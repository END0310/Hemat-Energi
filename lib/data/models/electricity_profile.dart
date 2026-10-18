class ElectricityProfile {
  final int? id;
  final int userId;
  final String kategori;
  final int daya; // e.g. 450, 900, 1300, 2200, 3500
  final String jenisListrik; // Selalu 'Prabayar/Token'
  final double? saldoAwalKwh;

  ElectricityProfile({
    this.id,
    required this.userId,
    required this.kategori,
    required this.daya,
    this.jenisListrik = 'Prabayar/Token',
    this.saldoAwalKwh,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'kategori': kategori,
      'daya': daya,
      'jenis_listrik': jenisListrik,
      'saldo_awal_kwh': saldoAwalKwh,
    };
  }

  factory ElectricityProfile.fromMap(Map<String, dynamic> map) {
    return ElectricityProfile(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      kategori: map['kategori'] as String,
      daya: map['daya'] as int,
      jenisListrik: map['jenis_listrik'] as String? ?? 'Prabayar/Token',
      saldoAwalKwh: (map['saldo_awal_kwh'] as num?)?.toDouble(),
    );
  }

  ElectricityProfile copyWith({
    int? id,
    int? userId,
    String? kategori,
    int? daya,
    String? jenisListrik,
    double? saldoAwalKwh,
  }) {
    return ElectricityProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      kategori: kategori ?? this.kategori,
      daya: daya ?? this.daya,
      jenisListrik: jenisListrik ?? this.jenisListrik,
      saldoAwalKwh: saldoAwalKwh ?? this.saldoAwalKwh,
    );
  }
}
