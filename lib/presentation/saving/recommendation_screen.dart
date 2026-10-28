import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/dummy/saving_dummy_data.dart';
import '../../data/repositories/saving_repository.dart';
import '../../domain/services/recommendation_service.dart';
import 'saving_widgets.dart';
import 'simulation_screen.dart';

/// FR-11 — Rekomendasi Berbasis Aturan (layar "Insight penghematan" pada desain).
/// Semua saran dihasilkan dari aturan IF–THEN di [RecommendationService].
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SavingRepository.instance;
    final target = repo.getActiveTarget(SavingDummyData.userId);
    final progress = target != null ? repo.hitungProgress(target) : null;

    // Target proporsional sampai hari berjalan (untuk Aturan 2).
    final double? targetSampaiHariIni = (target != null && progress != null)
        ? target.targetKonsumsi / progress.jumlahHari * progress.hariBerjalan
        : null;

    // ATURAN 1: perangkat dengan estimasi konsumsi terbesar.
    final topInsight = RecommendationService.insightPerangkatTerbesar(
      SavingDummyData.perangkat,
    );

    // ATURAN 2 & 3: evaluasi konsumsi aktual terhadap target & rata-rata harian.
    final lainnya = RecommendationService.insightLainnya(
      namaPerangkatTerbesar: topInsight?.perangkat.nama,
      konsumsiAktual: progress?.konsumsiAktual ?? 0,
      targetSampaiHariIni: targetSampaiHariIni,
      konsumsiHariIni: SavingDummyData.konsumsiHariIni,
      rataRataHarian: SavingDummyData.rataRataHarian,
    );

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: const SavingAppBar(title: 'Insight penghematan'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Saran praktis berdasarkan catatan meter dan perangkatmu.',
            style: SavingText.bodyMuted,
          ),
          const SizedBox(height: 16),

          // Kartu kuning: Konsumsi terbesar (ATURAN 1)
          if (topInsight != null) _buildTopInsightCard(context, topInsight),

          const SizedBox(height: 24),
          const Text('Insight lainnya', style: SavingText.subheading),
          const SizedBox(height: 8),

          // Daftar insight dari ATURAN 2 & ATURAN 3
          ...lainnya.map(
            (item) => _InsightTile(
              icon: item.jenis == RecommendationType.peringatan
                  ? Icons.access_time_rounded
                  : Icons.lightbulb_outline_rounded,
              title: item.judul,
              subtitle: item.pesan,
            ),
          ),

          // Saran praktis tambahan berbasis perangkat dingin (kulkas)
          const _InsightTile(
            icon: Icons.kitchen_outlined,
            title: 'Periksa suhu kulkas',
            subtitle: 'Gunakan suhu sedang agar tetap dingin tanpa boros.',
          ),
        ],
      ),
    );
  }

  Widget _buildTopInsightCard(BuildContext context, TopDeviceInsight info) {
    final d = info.perangkat;
    return SavingCard(
      color: AppConstants.warningBg,
      borderColor: AppConstants.warningBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF8A6500)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Konsumsi terbesar (estimasi)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A6500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${d.nama} memakai sekitar ${info.persenDariTotal.toStringAsFixed(0)}% '
            'estimasi konsumsi perangkatmu.',
            style: SavingText.subheading,
          ),
          const SizedBox(height: 6),
          Text(
            'Coba kurangi penggunaan dari ${AppFormatters.formatKwh(d.jamPerHari)} '
            'menjadi ${AppFormatters.formatKwh(info.jamSaran)} jam per hari.',
            style: SavingText.bodyMuted,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Potensi hemat', style: SavingText.caption),
                ),
                Text(
                  '±${AppFormatters.formatKwh(info.hematBulanan)} kWh / bulan',
                  style: SavingText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SimulationScreen()),
              );
            },
            child: const Text('Coba Simulasi'),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppConstants.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppConstants.primaryLightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppConstants.primaryGreen),
          ),
          const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

