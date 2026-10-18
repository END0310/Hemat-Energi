import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../domain/services/balance_estimator.dart';
import '../auth/account_profile_screen.dart';
import '../auth/auth_provider.dart';
import '../electricity/electricity_provider.dart';
import '../electricity/history_screen.dart';
import '../electricity/meter_form_screen.dart';
import '../electricity/profile_screen.dart';
import '../electricity/token_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<ElectricityProvider>().loadAllData(auth.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final electricity = context.watch<ElectricityProvider>();
    final user = auth.currentUser;
    final latestReading = electricity.latestMeterReading;
    final remainingDays = electricity.remainingDays;
    final avgDaily = electricity.averageDailyConsumption;
    final status = electricity.balanceStatus;
    final profile = electricity.profile;

    final initialLetter = (user?.nama.isNotEmpty == true) ? user!.nama[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppConstants.primaryGreen,
          onRefresh: () async {
            if (user?.id != null) {
              await electricity.loadAllData(user!.id!);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Bar: Sapaan, Tanggal, Lonceng Notifikasi, Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.nama.split(" ").first ?? "Pengguna"}',
                          style: const TextStyle(
                            color: AppConstants.textPrimary,
                            fontSize: 19,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.38,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatHeaderDate(DateTime.now()),
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Tombol Notifikasi (dengan red dot)
                        InkWell(
                          onTap: () => _showNotificationSheet(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications_none,
                                    size: 22,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppConstants.errorRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Avatar Bulat
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AccountProfileScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(17),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryLightGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppConstants.primaryGreen.withValues(alpha: 0.2)),
                            ),
                            child: Center(
                              child: Text(
                                initialLetter,
                                style: const TextStyle(
                                  color: AppConstants.primaryDarkGreen,
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Prompt jika belum isi profil listrik
                if (profile == null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.warningBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.warningBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, color: Color(0xFFB58500), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Profil Listrik Belum Diatur',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF6B4E00),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pilih golongan dan daya listrik Anda agar tarif terhitung otomatis.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF6B4E00)),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: const Text('Atur', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB58500))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 2. Card Saldo Hijau Figma (Height 138)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryGreen.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Atas: Label Saldo Listrik + Badge Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Opacity(
                            opacity: 0.85,
                            child: const Text(
                              'Saldo listrik',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status == BalanceStatus.kritis
                                      ? Icons.error_outline
                                      : (status == BalanceStatus.waspada ? Icons.warning_amber : Icons.check_circle_outline),
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  BalanceEstimator.getStatusLabel(status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Baris Tengah: Nilai Saldo kWh
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            latestReading != null
                                ? AppFormatters.formatKwh(latestReading.saldoKwh)
                                : '0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -1.44,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'kWh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Baris Bawah: Estimasi Hari & Waktu Diperbarui
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Opacity(
                                opacity: 0.85,
                                child: const Icon(Icons.access_time, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              Opacity(
                                opacity: 0.85,
                                child: Text(
                                  remainingDays != null
                                      ? 'Cukup ± ${AppFormatters.formatKwh(remainingDays)} hari'
                                      : 'Belum cukup data',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Opacity(
                            opacity: 0.85,
                            child: Text(
                              latestReading != null
                                  ? 'Diperbarui ${AppFormatters.formatTimeOnly(latestReading.tanggalWaktu)}'
                                  : 'Belum ada catatan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Tombol Tambah Token & Catat Meter
                Row(
                  children: [
                    // Tambah Token
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TokenFormScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppConstants.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryLightGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.confirmation_number_outlined, color: AppConstants.primaryGreen, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Tambah token',
                                    style: TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Catat pembelian',
                                    style: TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 11,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Catat Meter
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MeterFormScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: AppConstants.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryLightGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.speed_outlined, color: AppConstants.primaryGreen, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Catat meter',
                                    style: TextStyle(
                                      color: AppConstants.textPrimary,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Perbarui saldo',
                                    style: TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 11,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Card Stats: Rata-rata per hari & Target (Modul 3 Stub)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppConstants.border),
                  ),
                  child: Row(
                    children: [
                      // Sisi Kiri: Rata-rata harian aktual
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rata-rata',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 11,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              avgDaily != null ? '${AppFormatters.formatKwh(avgDaily)} kWh' : '-',
                              style: const TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'per hari (aktual)',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 10,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: AppConstants.borderLight,
                      ),
                      const SizedBox(width: 16),

                      // Sisi Kanan: Target Penghematan (Modul 3 Empty State / Stub)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Target (Modul 3)',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 11,
                                fontFamily: 'Inter',
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Belum ada target',
                              style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Segera hadir',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 10,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Konsumsi 7 Hari Header & Grafik Batang Figma
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Konsumsi 7 hari',
                      style: TextStyle(
                        color: AppConstants.textPrimary,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (widget.onTabChange != null) {
                          widget.onTabChange!(4); // Tab Riwayat
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        }
                      },
                      child: const Text(
                        'Lihat detail',
                        style: TextStyle(
                          color: AppConstants.primaryGreen,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Grafik Batang 7 Hari persis Figma
                _buildSevenDayChart(electricity.sevenDayConsumption),
                const SizedBox(height: 8),

                // Subtext Perbandingan
                Row(
                  children: const [
                    Icon(Icons.trending_down, size: 16, color: AppConstants.primaryGreen),
                    SizedBox(width: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pola konsumsi ',
                            style: TextStyle(
                              color: AppConstants.primaryGreen,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'berdasarkan catatan meter aktual',
                            style: TextStyle(
                              color: AppConstants.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Kartu Peluang Hemat Minggu Ini (Kuning Sesuai Figma)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.warningBg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppConstants.warningBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE984),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lightbulb_outline, color: Color(0xFF8C6500), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Peluang hemat minggu ini',
                              style: TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kurangi pemakaian AC 1 jam per hari.',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 11,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF8C6500), size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun grafik batang 7 hari vertikal sesuai visual Figma Screen 04
  Widget _buildSevenDayChart(Map<DateTime, double> sevenDays) {
    const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    // Cari nilai maksimum untuk normalisasi tinggi
    double maxVal = 0.0;
    for (final val in sevenDays.values) {
      if (val > maxVal) maxVal = val;
    }
    if (maxVal <= 0) maxVal = 1.0;

    final sortedEntries = sevenDays.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      width: double.infinity,
      height: 130,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedEntries.map((entry) {
          final date = entry.key;
          final value = entry.value;
          final dayLabel = dayNames[date.weekday % 7];

          // Tinggi batang maksimal 70
          final double barHeight = max(6.0, (value / maxVal) * 70.0);
          final bool isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Batang pill vertikal
              Container(
                width: 14,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF1ED),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 14,
                  height: value > 0 ? barHeight : 4,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppConstants.warningYellow
                        : (value > 0 ? AppConstants.primaryGreen : Colors.transparent),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Label Nama Hari
              Text(
                dayLabel,
                style: TextStyle(
                  color: isToday ? AppConstants.textPrimary : AppConstants.textSecondary,
                  fontSize: 10,
                  fontFamily: 'Inter',
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Notifikasi Lokal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Icon(Icons.notifications_active, color: AppConstants.primaryGreen, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Aplikasi Hemat Energi siap mengingatkan Anda saat saldo listrik diperkirakan tersisa 2 hari atau kurang.',
                style: TextStyle(fontSize: 12, color: AppConstants.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppConstants.primaryGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Semua notifikasi diproses 100% lokal di perangkat tanpa menggunakan server atau Firebase.',
                        style: TextStyle(fontSize: 11, color: AppConstants.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
