import 'package:flutter/material.dart';

/// App-wide constants for Hemat Energi (SDG 7)
class AppConstants {
  // App Info
  static const String appName = 'Hemat Energi';
  static const String appTagline = 'Pakai listrik lebih bijak.';

  // Colors based on Figma design tokens
  static const Color primaryGreen = Color(0xFF16794B);
  static const Color primaryDarkGreen = Color(0xFF0E5D39);
  static const Color primaryLightGreen = Color(0xFFE7F4EC);
  static const Color background = Color(0xFFF7F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDFE5E0);
  static const Color borderLight = Color(0xFFEDF0ED);
  static const Color borderInput = Color(0xFFCFD6D0);
  static const Color textPrimary = Color(0xFF17221C);
  static const Color textSecondary = Color(0xFF647068);
  static const Color textMuted = Color(0xFF9AA29D);
  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color warningYellow = Color(0xFFF4C430);
  static const Color warningBg = Color(0xFFFFF8D9);
  static const Color warningBorder = Color(0xFFEFE1A9);

  // Business Logic & Thresholds
  /// Ambang batas hari sisa saldo untuk memicu notifikasi saldo rendah (default: 2 hari)
  static const double lowBalanceThresholdDays = 2.0;

  /// Ambang batas sisa hari untuk badge status di dashboard
  static const double criticalThresholdDays = 1.0;
  static const double warningThresholdDays = 2.0;

  // Session keys
  static const String keyLoggedInUserId = 'logged_in_user_id';
  static const String keyLastLowBalanceNotifDate = 'last_low_balance_notif_date';
}
