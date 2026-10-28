import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../domain/services/saving_calculator.dart';

/// Widget kecil yang dipakai berulang di layar Modul 3.
/// Mengikuti Design System Hemat Energi v1.0:
/// - Radius : 10 input · 14 card · 18 dialog
/// - Spacing: 4 · 8 · 12 · 16 · 24 · 32
/// - Elevasi: border dulu, tanpa shadow
/// - Tap target minimal 44 x 44

class SavingText {
  static const heading = TextStyle(
    fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600,
    color: AppConstants.textPrimary,
  );
  static const subheading = TextStyle(
    fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600,
    color: AppConstants.textPrimary,
  );
  static const body = TextStyle(
    fontFamily: 'Inter', fontSize: 14, color: AppConstants.textPrimary,
  );
  static const bodyMuted = TextStyle(
    fontFamily: 'Inter', fontSize: 14, color: AppConstants.textSecondary,
  );
  static const caption = TextStyle(
    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500,
    color: AppConstants.textSecondary,
  );
}

/// App bar putih dengan garis bawah (mendukung subtitle atau tombol kanan).
class SavingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;

  const SavingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.trailing,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 74 : 64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppConstants.borderLight)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: showBack ? 4 : 16, right: 16),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppConstants.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SavingText.subheading.copyWith(fontSize: 18)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: SavingText.caption),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu radius 14 dengan border (warna bisa diganti untuk kartu hijau/kuning).
class SavingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  const SavingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppConstants.surface,
    this.borderColor = AppConstants.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Baris label kiri - nilai kanan.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: SavingText.bodyMuted.copyWith(fontSize: 13))),
          Text(value, style: SavingText.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Label kecil "Estimasi" / "Aktual" agar dua jenis konsumsi selalu dibedakan.
class KonsumsiBadge extends StatelessWidget {
  final bool estimasi;

  const KonsumsiBadge({super.key, required this.estimasi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: estimasi ? AppConstants.warningBg : AppConstants.primaryLightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estimasi ? AppConstants.warningBorder : AppConstants.primaryLightGreen,
        ),
      ),
      child: Text(
        estimasi ? 'ESTIMASI' : 'AKTUAL',
        style: SavingText.caption.copyWith(
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: estimasi ? const Color(0xFF7A5D00) : AppConstants.primaryDarkGreen,
        ),
      ),
    );
  }
}

/// Banner status (seperti komponen "Target aman" pada design system).
class StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Color backgroundColor;

  const StatusBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.backgroundColor = AppConstants.primaryLightGreen,
  });

  /// Membuat banner otomatis dari [TargetStatus].
  factory StatusBanner.fromStatus(TargetStatus status, {String? customSubtitle}) {
    final info = statusInfo(status);
    final isWarning = status == TargetStatus.berisiko || status == TargetStatus.tidakTercapai;
    return StatusBanner(
      icon: info.icon,
      color: info.color,
      title: info.label,
      subtitle: customSubtitle ?? info.keterangan,
      backgroundColor: isWarning ? AppConstants.warningBg : AppConstants.primaryLightGreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SavingText.body.copyWith(fontWeight: FontWeight.w600, color: color),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: SavingText.caption.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label, warna, ikon, dan keterangan untuk setiap status target.
class StatusInfo {
  final String label;
  final String keterangan;
  final Color color;
  final IconData icon;

  const StatusInfo(this.label, this.keterangan, this.color, this.icon);
}

StatusInfo statusInfo(TargetStatus status) {
  switch (status) {
    case TargetStatus.belumMulai:
      return const StatusInfo('Belum dimulai', 'Periode target belum berjalan.',
          AppConstants.textSecondary, Icons.schedule_rounded);
    case TargetStatus.aman:
      return const StatusInfo('Target masih aman', 'Proyeksi masih di bawah target.',
          AppConstants.primaryGreen, Icons.check_circle_outline_rounded);
    case TargetStatus.hampirTercapai:
      return const StatusInfo('Hampir tercapai', 'Sisa periode ≤ 3 hari dan proyeksi di bawah target.',
          AppConstants.primaryGreen, Icons.flag_outlined);
    case TargetStatus.berisiko:
      return const StatusInfo('Berisiko tidak tercapai', 'Proyeksi akhir periode melebihi target.',
          Color(0xFF8A6500), Icons.warning_amber_rounded);
    case TargetStatus.tercapai:
      return const StatusInfo('Target tercapai', 'Konsumsi aktual di bawah target.',
          AppConstants.primaryGreen, Icons.emoji_events_outlined);
    case TargetStatus.tidakTercapai:
      return const StatusInfo('Target tidak tercapai', 'Konsumsi aktual melebihi target.',
          AppConstants.errorRed, Icons.error_outline_rounded);
  }
}
