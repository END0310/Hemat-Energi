import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/dummy/saving_dummy_data.dart';
import '../../data/models/saving_target.dart';
import '../../data/repositories/saving_repository.dart';
import 'saving_widgets.dart';
import 'target_form_screen.dart';

/// FR-09 — Layar Target Penghematan (Layar 14 pada desain).
/// Mendukung CRUD penuh: Buat, Lihat, Ubah, dan Hapus target.
class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  final _repo = SavingRepository.instance;

  Future<void> _bukaForm({SavingTarget? target}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TargetFormScreen(existingTarget: target)),
    );
    setState(() {});
  }

  void _konfirmasiHapus(SavingTarget target) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus target?', style: SavingText.subheading),
        content: const Text(
          'Target penghematan bulan ini akan dihapus.',
          style: SavingText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              minimumSize: const Size(80, 44),
            ),
            onPressed: () {
              _repo.deleteTarget(target.id!);
              Navigator.of(dialogCtx).pop();
              setState(() {});
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targets = _repo.getTargets(SavingDummyData.userId);
    final active = _repo.getActiveTarget(SavingDummyData.userId) ??
        (targets.isNotEmpty ? targets.first : null);

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: SavingAppBar(
        title: 'Target penghematan',
        trailing: active != null
            ? TextButton(
                onPressed: () => _bukaForm(target: active),
                child: const Text(
                  'Ubah',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryGreen,
                  ),
                ),
              )
            : null,
      ),
      body: active == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_outlined, size: 48, color: AppConstants.textMuted),
                    const SizedBox(height: 12),
                    const Text('Belum ada target penghematan', style: SavingText.subheading),
                    const SizedBox(height: 6),
                    const Text(
                      'Buat target bulanan untuk memantau pemakaian listrikmu.',
                      textAlign: TextAlign.center,
                      style: SavingText.bodyMuted,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _bukaForm(),
                      child: const Text('Buat target'),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(active),
    );
  }

  Widget _buildContent(SavingTarget target) {
    final p = _repo.hitungProgress(target);
    final persen = (p.persenTerpakai * 100).round();
    final maxKwh = (target.targetKonsumsi > p.konsumsiAktual
            ? target.targetKonsumsi
            : p.konsumsiAktual)
        .clamp(1.0, double.infinity);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu hijau utama: Target konsumsi bulan ini
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppConstants.primaryGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Target konsumsi bulan ini',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: AppFormatters.formatKwh(target.targetKonsumsi),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text: ' kWh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: p.persenTerpakai,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  color: AppConstants.warningYellow,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$persen%',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${p.hariBerjalan} hari berjalan · ${p.sisaHari} hari tersisa',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dua kartu berdampingan: Konsumsi saat ini & Sisa target
        Row(
          children: [
            Expanded(
              child: SavingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Konsumsi saat ini', style: SavingText.caption),
                    const SizedBox(height: 6),
                    Text(
                      '${AppFormatters.formatKwh(p.konsumsiAktual)} kWh',
                      style: SavingText.subheading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SavingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sisa target', style: SavingText.caption),
                    const SizedBox(height: 6),
                    Text(
                      '${AppFormatters.formatKwh(p.sisaTarget)} kWh',
                      style: SavingText.subheading,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kartu Batas harian + Target mingguan (FR-09)
        SavingCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Batas harian', style: SavingText.caption),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.formatKwh(p.batasHarian)} kWh',
                      style: SavingText.subheading,
                    ),
                    const SizedBox(height: 2),
                    const Text('agar target tercapai', style: SavingText.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Acuan mingguan', style: SavingText.caption),
                  const SizedBox(height: 4),
                  Text(
                    '${AppFormatters.formatKwh(p.targetMingguan)} kWh',
                    style: SavingText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Banner status target
        StatusBanner.fromStatus(
          p.status,
          customSubtitle:
              'Dengan pola saat ini, estimasi konsumsi akhir bulan adalah '
              '${AppFormatters.formatKwh(p.proyeksi)} kWh.',
        ),
        const SizedBox(height: 20),

        // Grafik perbandingan sederhana: Actual vs Target
        const Text('Actual vs Target', style: SavingText.subheading),
        const SizedBox(height: 10),
        SavingCard(
          child: Column(
            children: [
              _BarCompareRow(
                label: 'Aktual',
                value: p.konsumsiAktual,
                max: maxKwh,
                color: AppConstants.primaryGreen,
              ),
              const SizedBox(height: 12),
              _BarCompareRow(
                label: 'Target',
                value: target.targetKonsumsi,
                max: maxKwh,
                color: AppConstants.warningYellow,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol hapus target (untuk melengkapi CRUD FR-09)
        TextButton.icon(
          onPressed: () => _konfirmasiHapus(target),
          style: TextButton.styleFrom(foregroundColor: AppConstants.errorRed),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Hapus target ini'),
        ),
      ],
    );
  }
}

class _BarCompareRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;

  const _BarCompareRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: SavingText.caption),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppConstants.borderLight,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            AppFormatters.formatKwh(value),
            textAlign: TextAlign.right,
            style: SavingText.caption.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
