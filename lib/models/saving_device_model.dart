import '../core/energy_formulas.dart';

class SavingDevice {
  final int? id;
  final String name;
  final double powerWatt;
  final int quantity;
  final double dailyHours;

  const SavingDevice({
    this.id,
    required this.name,
    required this.powerWatt,
    required this.quantity,
    required this.dailyHours,
  });

  double get totalWatt => powerWatt * quantity;

  double get dailyKwh => deviceDailyKwh(powerWatt, dailyHours, quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'power_watt': powerWatt,
      'quantity': quantity,
      'daily_hours': dailyHours,
    };
  }

  factory SavingDevice.fromMap(Map<String, dynamic> map) {
    return SavingDevice(
      id: map['id'] as int?,
      name: map['name'] as String,
      powerWatt: (map['power_watt'] as num).toDouble(),
      quantity: map['quantity'] as int,
      dailyHours: (map['daily_hours'] as num).toDouble(),
    );
  }

  SavingDevice copyWith({
    int? id,
    String? name,
    double? powerWatt,
    int? quantity,
    double? dailyHours,
  }) {
    return SavingDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      powerWatt: powerWatt ?? this.powerWatt,
      quantity: quantity ?? this.quantity,
      dailyHours: dailyHours ?? this.dailyHours,
    );
  }
}
