class TokenPurchase {
  final int? id;
  final int userId;
  final DateTime tanggalWaktu;
  final double nominal; // Rp
  final double kwhToken; // kWh yang diterima

  TokenPurchase({
    this.id,
    required this.userId,
    required this.tanggalWaktu,
    required this.nominal,
    required this.kwhToken,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'tanggal_waktu': tanggalWaktu.toIso8601String(),
      'nominal': nominal,
      'kwh_token': kwhToken,
    };
  }

  factory TokenPurchase.fromMap(Map<String, dynamic> map) {
    return TokenPurchase(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      tanggalWaktu: DateTime.parse(map['tanggal_waktu'] as String),
      nominal: (map['nominal'] as num).toDouble(),
      kwhToken: (map['kwh_token'] as num).toDouble(),
    );
  }

  TokenPurchase copyWith({
    int? id,
    int? userId,
    DateTime? tanggalWaktu,
    double? nominal,
    double? kwhToken,
  }) {
    return TokenPurchase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tanggalWaktu: tanggalWaktu ?? this.tanggalWaktu,
      nominal: nominal ?? this.nominal,
      kwhToken: kwhToken ?? this.kwhToken,
    );
  }
}
