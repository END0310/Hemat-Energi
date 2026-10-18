class TariffConfig {
  final int? id;
  final String kategori;
  final int daya;
  final double tarif; // Rp per kWh

  TariffConfig({
    this.id,
    required this.kategori,
    required this.daya,
    required this.tarif,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'kategori': kategori,
      'daya': daya,
      'tarif': tarif,
    };
  }

  factory TariffConfig.fromMap(Map<String, dynamic> map) {
    return TariffConfig(
      id: map['id'] as int?,
      kategori: map['kategori'] as String,
      daya: map['daya'] as int,
      tarif: (map['tarif'] as num).toDouble(),
    );
  }
}
