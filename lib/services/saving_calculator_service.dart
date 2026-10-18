import '../core/energy_formulas.dart';
import '../models/saving_device_model.dart';
import '../models/saving_simulation_model.dart';

class SavingCalculatorService {
  static SavingSimulation simulate({
    int? id,
    required String userId,
    required SavingDevice device,
    required double proposedHours,
    required double tariffPerKwh,
  }) {
    if (userId.trim().isEmpty ||
        device.id == null ||
        !device.powerWatt.isFinite ||
        device.powerWatt <= 0 ||
        device.quantity <= 0 ||
        !device.dailyHours.isFinite ||
        device.dailyHours <= 0 ||
        device.dailyHours > 24 ||
        !proposedHours.isFinite ||
        proposedHours < 0 ||
        proposedHours > device.dailyHours ||
        !tariffPerKwh.isFinite ||
        tariffPerKwh <= 0) {
      throw ArgumentError('Periksa perangkat, durasi, dan konfigurasi tarif.');
    }
    final saved =
        deviceDailyKwh(
          device.powerWatt,
          device.dailyHours - proposedHours,
          device.quantity,
        ) *
        30;
    return SavingSimulation(
      id: id,
      userId: userId,
      deviceId: device.id!,
      deviceName: device.name,
      powerWatt: device.powerWatt,
      quantity: device.quantity,
      originalHours: device.dailyHours,
      proposedHours: proposedHours,
      tariffPerKwh: tariffPerKwh,
      monthlySavedKwh: saved,
      monthlySavedCost: saved * tariffPerKwh,
    );
  }
}
