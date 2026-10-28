import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/dummy/saving_dummy_data.dart';
import '../../data/repositories/saving_repository.dart';
import '../../domain/services/saving_calculator.dart';
import '../../domain/services/saving_notification_service.dart';
import 'recommendation_screen.dart';
import 'saving_widgets.dart';
import 'simulation_screen.dart';
import 'target_form_screen.dart';
import 'target_screen.dart';

/// Halaman utama Modul 3 (tab "Hemat" di bottom navigation — Layar 13 Penghematan).
class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  final _repo = SavingRepository.instance;

  String get _bulanBerjalan {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
    } catch (_) {
      return DateFormat('MMMM yyyy').format(DateTime.now());
    }
  }

  /// Buka halaman lain, lalu refresh ringkasan saat kembali.
  Future<void> _buka(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    setState(() {});
  }

  Future<void> _cekNotifikasi() async {
    final target = _repo.getActiveTarget(SavingDummyData.userId);
    if (target == null) return;
    final status = await SavingNotificationService.instance.cekTarget(target);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifikasi dicek — status: ${statusInfo(status).label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: SavingAppBar(
        title: 'Penghematan',
        subtitle: _bulanBerjalan,
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTargetAktif(),
          const SizedBox(height: 20),
          const Text('Kelola penghematan', style: SavingText.subheading),
          const SizedBox(height: 10),
          SavingCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.flag_outlined,
                  title: 'Target penghematan',
                  subtitle: 'Pantau target bulan ini',
                  onTap: () => _buka(const TargetScreen()),
                ),
                const Divider(height: 1, color: AppConstants.borderLight),
                _MenuTile(
                  icon: Icons.tune_rounded,
                  title: 'Simulasi penghematan',
                  subtitle: 'Coba skenario pemakaian',
                  onTap: () => _buka(const SimulationScreen()),
                ),
                const Divider(height: 1, color: AppConstants.borderLight),
                _MenuTile(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Insight penghematan',
                  subtitle: 'Saran praktis berdasarkan data',
                  onTap: () => _buka(const RecommendationScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAktif() {
    final target = _repo.getActiveTarget(SavingDummyData.userId);

    // Belum ada target untuk periode ini.
    if (target == null) {
      return SavingCard(
        child: Column(
          children: [
            const Icon(Icons.flag_outlined, size: 40, color: AppConstants.textMuted),
            const SizedBox(height: 8),
            const Text('Belum ada target bulan ini', style: SavingText.subheading),
            const SizedBox(height: 4),
            const Text(
              'Buat target agar konsumsi listrik lebih terukur.',
              textAlign: TextAlign.center,
              style: SavingText.caption,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _buka(const TargetFormScreen()),
              child: const Text('Buat target'),
            ),
          ],
        ),
      );
    }

    final p = _repo.hitungProgress(target);
    final persen = (p.persenTerpakai * 100).round();
    final selisihProyeksi = (target.targetKonsumsi - p.proyeksi).abs();
    final diBawahTarget = p.proyeksi <= target.targetKonsumsi;

    return Column(
      children: [
        // Kartu 1: Target bulan ini
        SavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Target bulan ini', style: SavingText.caption),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.warningBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppConstants.warningBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF8A6500)),
                        SizedBox(width: 4),
                        Text(
                          'Berjalan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A6500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppFormatters.formatKwh(p.konsumsiAktual),
                      style: SavingText.heading.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' dari ${AppFormatters.formatKwh(target.targetKonsumsi)} kWh',
                      style: SavingText.bodyMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.persenTerpakai,
                  minHeight: 8,
                  backgroundColor: AppConstants.borderLight,
                  color: p.persenTerpakai >= 1 ? AppConstants.errorRed : AppConstants.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$persen% terpakai',
                      style: SavingText.caption.copyWith(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Sisa ${AppFormatters.formatKwh(p.sisaTarget)} kWh',
                    style: SavingText.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Kartu 2: Estimasi akhir bulan (ketuk untuk cek notifikasi target)
        SavingCard(
          onTap: _cekNotifikasi,
          color: AppConstants.primaryLightGreen,
          borderColor: AppConstants.primaryLightGreen,
          child: Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppConstants.primaryGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimasi akhir bulan', style: SavingText.caption),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.formatKwh(p.proyeksi)} kWh',
                      style: SavingText.subheading,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormatters.formatKwh(selisihProyeksi)} kWh '
                      '${diBawahTarget ? 'di bawah' : 'di atas'} target',
                      style: SavingText.caption,
                    ),
                  ],
                ),
              ),
              Text(
                p.status == TargetStatus.berisiko ? 'Berisiko' : 'Aman',
                style: SavingText.caption.copyWith(
                  color: p.status == TargetStatus.berisiko
                      ? const Color(0xFF8A6500)
                      : AppConstants.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryGreen, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SavingText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: SavingText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppConstants.textMuted),
          ],
        ),
      ),
    );
  }
}
