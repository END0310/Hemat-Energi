import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/database_helper.dart';
import '../../core/formatters.dart';
import '../../models/notification_model.dart';
import 'balance_estimator.dart';

/// Layanan Notifikasi Lokal Modul 1 (NTF-01: Peringatan Saldo Token Rendah)
/// Mengirimkan local notification apabila tersedia minimal 2 catatan meter
/// dan estimasi sisa hari <= ambang batas (default: 2 hari), maksimal 1 kali per hari.
class LowBalanceNotificationService {
  LowBalanceNotificationService._();
  static final LowBalanceNotificationService instance = LowBalanceNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int notificationId = 101;
  static const String _channelId = 'hemat_energi_module_1';
  static const String _channelName = 'Peringatan Saldo Token Rendah';

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Gagal inisialisasi notifikasi Modul 1: $e');
    }
  }

  /// Mengevaluasi kondisi saldo dan memicu notifikasi lokal bila memenuhi syarat NTF-01.
  Future<bool> checkAndNotify({
    required int userId,
    required double? latestBalanceKwh,
    required double? remainingDays,
    required int meterReadingsCount,
  }) async {
    final shouldTrigger = BalanceEstimator.shouldTriggerLowBalanceNotification(
      remainingDays: remainingDays,
      meterReadingsCount: meterReadingsCount,
      thresholdDays: AppConstants.lowBalanceThresholdDays,
    );

    if (!shouldTrigger || remainingDays == null || latestBalanceKwh == null) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final prefKey = '${AppConstants.keyLastLowBalanceNotifDate}_$userId';

      // Pencegahan duplikasi: hanya kirim maksimal 1 kali di tanggal yang sama
      if (prefs.getString(prefKey) == todayKey) {
        return false;
      }

      final title = 'Saldo Token Listrik Rendah';
      final body =
          'Sisa saldo ${AppFormatters.formatKwh(latestBalanceKwh)} kWh diperkirakan '
          'hanya cukup untuk ±${AppFormatters.formatKwh(remainingDays)} hari lagi. '
          'Segera siapkan pembelian token.';

      // Simpan ke riwayat notifikasi lokal aplikasi
      await DatabaseHelper.instance.insertNotification(
        AppNotificationItem(
          title: title,
          message: body,
          type: 'low_balance',
          dateTime: now,
          payload: 'remaining_days=${remainingDays.toStringAsFixed(2)}',
        ),
      );

      // Tampilkan di status bar perangkat Android
      if (!kIsWeb) {
        await init();
        if (_isInitialized) {
          const details = NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: 'Notifikasi saat estimasi sisa hari token <= 2 hari (Modul 1)',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              showWhen: true,
            ),
          );
          await _plugin.show(
            id: notificationId,
            title: title,
            body: body,
            notificationDetails: details,
          );
        }
      }

      await prefs.setString(prefKey, todayKey);
      return true;
    } catch (e) {
      debugPrint('Gagal memproses notifikasi saldo rendah: $e');
      return false;
    }
  }
}
