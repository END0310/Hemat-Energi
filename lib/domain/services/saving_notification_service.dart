import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/saving_target.dart';
import '../../data/repositories/saving_repository.dart';
import 'saving_calculator.dart';

/// KERANGKA Notifikasi Modul 3 — Target Penghematan (local notification).
///
/// Tiga kondisi (PRD bagian 13):
/// 1. Berisiko tidak tercapai : proyeksi akhir periode > target
/// 2. Hampir tercapai         : sisa periode <= 3 hari dan proyeksi <= target
/// 3. Tercapai                : periode selesai dan konsumsi aktual <= target
///
/// Cara pakai (contoh): panggil setelah data meter baru disimpan atau saat
/// layar Penghematan dibuka:
///   await SavingNotificationService.instance.cekTarget(target);
///
/// TODO(merge): jika tim membuat satu NotificationService bersama, cukup
/// pindahkan method [cekTarget] ke sana dan pakai [_tampilkan] milik tim.
class SavingNotificationService {
  SavingNotificationService._();
  static final SavingNotificationService instance = SavingNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _sudahInit = false;

  // ID notifikasi Modul 3 memakai seri 3xx agar tidak bentrok dengan modul lain.
  static const int idBerisiko = 301;
  static const int idHampirTercapai = 302;
  static const int idTercapai = 303;

  static const String _channelId = 'hemat_energi_module_3';
  static const String _channelName = 'Target Penghematan';

  /// Inisialisasi plugin + minta izin notifikasi (Android 13+).
  Future<void> init() async {
    if (_sudahInit || kIsWeb) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _sudahInit = true;
    } catch (e) {
      debugPrint('Gagal init notifikasi Modul 3: $e');
    }
  }

  /// Mengecek kondisi target lalu mengirim notifikasi bila perlu.
  /// Mengembalikan status target (berguna untuk ditampilkan di UI).
  Future<TargetStatus> cekTarget(SavingTarget target) async {
    final progress = SavingRepository.instance.hitungProgress(target);

    switch (progress.status) {
      case TargetStatus.berisiko:
        await _kirimSekali(
          target: target,
          id: idBerisiko,
          judul: 'Target hemat berisiko',
          isi: 'Proyeksi konsumsi bulan ini melebihi target. '
              'Kurangi pemakaian perangkat berdaya besar.',
        );
        break;
      case TargetStatus.hampirTercapai:
        await _kirimSekali(
          target: target,
          id: idHampirTercapai,
          judul: 'Target hemat hampir tercapai',
          isi: 'Sisa ${progress.sisaHari} hari lagi. Pertahankan pemakaianmu!',
        );
        break;
      case TargetStatus.tercapai:
        await _kirimSekali(
          target: target,
          id: idTercapai,
          judul: 'Target penghematan tercapai',
          isi: 'Selamat! Konsumsi periode ini berada di bawah target.',
        );
        break;
      default:
        // aman / belum mulai / tidak tercapai -> tidak ada notifikasi.
        break;
    }
    return progress.status;
  }

  /// Anti-duplikasi sederhana: notifikasi yang sama untuk target yang sama
  /// hanya dikirim satu kali per hari.
  Future<void> _kirimSekali({
    required SavingTarget target,
    required int id,
    required String judul,
    required String isi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final hariIni = '${now.year}-${now.month}-${now.day}';
    final key = 'saving_notif_${target.id}_$id';

    if (prefs.getString(key) == hariIni) return; // sudah dikirim hari ini

    await _tampilkan(id: id, judul: judul, isi: isi);
    await prefs.setString(key, hariIni);
  }

  Future<void> _tampilkan({
    required int id,
    required String judul,
    required String isi,
  }) async {
    await init();
    if (!_sudahInit) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Status target penghematan listrik (Modul 3)',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(id: id, title: judul, body: isi, notificationDetails: details);
    } catch (e) {
      debugPrint('Gagal menampilkan notifikasi Modul 3: $e');
    }
  }
}
