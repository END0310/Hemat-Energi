/// Snapshot agar riwayat tidak berubah saat spesifikasi perangkat diubah.
class SavingSimulation {
  final int? id;
  final String userId;
  final int deviceId;
  final String deviceName;
  final double powerWatt;
  final int quantity;
  final double originalHours;
  final double proposedHours;
  final double tariffPerKwh;
  final double monthlySavedKwh;
  final double monthlySavedCost;

  const SavingSimulation({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.powerWatt,
    required this.quantity,
    required this.originalHours,
    required this.proposedHours,
    required this.tariffPerKwh,
    required this.monthlySavedKwh,
    required this.monthlySavedCost,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'device_id': deviceId,
    'device_name': deviceName,
    'power_watt': powerWatt,
    'quantity': quantity,
    'original_hours': originalHours,
    'proposed_hours': proposedHours,
    'tariff_per_kwh': tariffPerKwh,
    'monthly_saved_kwh': monthlySavedKwh,
    'monthly_saved_cost': monthlySavedCost,
  };

  factory SavingSimulation.fromMap(Map<String, Object?> map) =>
      SavingSimulation(
        id: map['id'] as int,
        userId: map['user_id'] as String,
        deviceId: map['device_id'] as int,
        deviceName: map['device_name'] as String,
        powerWatt: (map['power_watt'] as num).toDouble(),
        quantity: map['quantity'] as int,
        originalHours: (map['original_hours'] as num).toDouble(),
        proposedHours: (map['proposed_hours'] as num).toDouble(),
        tariffPerKwh: (map['tariff_per_kwh'] as num).toDouble(),
        monthlySavedKwh: (map['monthly_saved_kwh'] as num).toDouble(),
        monthlySavedCost: (map['monthly_saved_cost'] as num).toDouble(),
      );
}
