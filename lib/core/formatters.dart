import 'package:intl/intl.dart';

/// Formatter utilities for Indonesian locale (id_ID)
class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static final NumberFormat _tariffFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 2,
  );

  static final NumberFormat _decimalFormat = NumberFormat('#,##0.0', 'id_ID');

  /// Format rupiah tanpa desimal, e.g. Rp50.000
  static String formatRupiah(num amount) {
    return _currencyFormat.format(amount).replaceAll(' ', '');
  }

  /// Format tarif per kWh, e.g. Rp1.444,70 / kWh
  static String formatTariff(num tariff) {
    return '${_tariffFormat.format(tariff).replaceAll(' ', '')} / kWh';
  }

  /// Format angka kWh dengan 1 desimal, e.g. 12,7
  static String formatKwh(double kwh) {
    // Menghilangkan desimal jika angka bulat, atau tampilkan dengan koma
    if (kwh == kwh.roundToDouble()) {
      return kwh.toInt().toString();
    }
    return _decimalFormat.format(kwh);
  }

  /// Format tanggal untuk header dashboard: e.g. "Senin, 12 Oktober"
  static String formatHeaderDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('EEEE, d MMMM').format(date);
    }
  }

  /// Format tanggal transaksi token: e.g. "12 Oktober 2026"
  static String formatDate(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  /// Format tanggal pendek: e.g. "12 Okt 2026"
  static String formatDateShort(DateTime date) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  /// Format tanggal + jam untuk catatan meter: e.g. "12 Oktober 2026 • 19.30"
  static String formatDateTime(DateTime date) {
    try {
      final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(date);
      final timeStr = DateFormat('HH.mm').format(date);
      return '$dateStr • $timeStr';
    } catch (_) {
      final dateStr = DateFormat('d MMMM yyyy').format(date);
      final timeStr = DateFormat('HH:mm').format(date);
      return '$dateStr • $timeStr';
    }
  }

  /// Format jam saja: e.g. "07.30"
  static String formatTimeOnly(DateTime date) {
    try {
      return DateFormat('HH.mm').format(date);
    } catch (_) {
      return DateFormat('HH:mm').format(date);
    }
  }

  /// Format waktu relatif ringkas: e.g. "Dicatat 12 Okt 2026 - 07.30"
  static String formatRecordedTime(DateTime date) {
    try {
      final d = DateFormat('d MMM yyyy', 'id_ID').format(date);
      final t = DateFormat('HH.mm').format(date);
      return 'Dicatat $d - $t';
    } catch (_) {
      final d = DateFormat('d MMM yyyy').format(date);
      final t = DateFormat('HH:mm').format(date);
      return 'Dicatat $d - $t';
    }
  }
}
