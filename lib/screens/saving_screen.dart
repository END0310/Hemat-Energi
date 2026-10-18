import 'package:flutter/material.dart';

import '../core/saving_colors.dart';
import '../data/saving_repository.dart';
import '../models/saving_target_model.dart';
import '../widgets/saving_widgets.dart';
import '../widgets/surface_card.dart';
import 'saving_target_screen.dart';
import 'saving_simulation_screen.dart';

class SavingScreen extends StatefulWidget {
  final SavingRepository? repository;
  const SavingScreen({super.key, this.repository});
  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  late final SavingRepository _repository;
  late Future<List<SavingTarget>> _targets;
  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ?? SavingRepository(userId: savingDemoUserId);
    _reload();
  }

  void _reload() {
    _targets = _repository.targets();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => InheritedTheme.captureAll(context, screen),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: savingAppBar(
      'Penghematan',
      actions: [
        IconButton(
          tooltip: 'Perbarui',
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          savingMonth(DateTime.now()),
          style: const TextStyle(color: SavingColors.textSecondary),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<SavingTarget>>(
          future: _targets,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SavingNotice(
                'Target gagal dimuat. Ketuk Perbarui untuk mencoba lagi.',
              );
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final now = DateTime.now();
            final current = snapshot.data!.where(
              (t) => t.month.year == now.year && t.month.month == now.month,
            );
            return SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target bulan ini'),
                  const SizedBox(height: 12),
                  Text(
                    current.isEmpty
                        ? 'Belum ada target'
                        : '${savingNumber(current.first.targetKwh)} kWh',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Progres aktual menunggu data meter bulanan.',
                    style: TextStyle(color: SavingColors.textSecondary),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const SavingNotice(
          'Demo Progress Report 1\nTarget memakai baseline contoh. Perangkat dan tarif memakai data contoh khusus simulasi. Integrasi data Modul 2 belum tersedia. Login belum terintegrasi.',
        ),
        const SizedBox(height: 24),
        const Text(
          'Kelola penghematan',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.flag_outlined,
                  color: SavingColors.primaryGreen,
                ),
                title: const Text('Target penghematan'),
                subtitle: const Text('Buat dan kelola target bulanan'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(SavingTargetScreen(repository: _repository)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.tune,
                  color: SavingColors.primaryGreen,
                ),
                title: const Text('Simulasi penghematan'),
                subtitle: const Text('Coba skenario pemakaian'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _open(SavingSimulationScreen(repository: _repository)),
              ),
              const Divider(height: 1),
              const ListTile(
                enabled: false,
                leading: Icon(Icons.lightbulb_outline),
                title: Text('Insight penghematan'),
                subtitle: Text(
                  'Tahap berikutnya • rekomendasi berbasis aturan',
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                enabled: false,
                leading: Icon(Icons.bar_chart),
                title: Text('Evaluasi'),
                subtitle: Text(
                  'Tahap berikutnya • perbandingan konsumsi aktual',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Notifikasi target akan ditambahkan setelah monitoring aktual tersedia.',
          style: TextStyle(fontSize: 12, color: SavingColors.textSecondary),
        ),
      ],
    ),
  );
}
