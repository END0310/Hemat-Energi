import 'package:flutter/material.dart';

import '../core/saving_colors.dart';
import '../data/saving_repository.dart';
import '../models/saving_target_model.dart';
import '../widgets/saving_widgets.dart';
import '../widgets/surface_card.dart';
import 'saving_target_form_screen.dart';

class SavingTargetScreen extends StatefulWidget {
  final SavingRepository repository;
  const SavingTargetScreen({super.key, required this.repository});
  @override
  State<SavingTargetScreen> createState() => _SavingTargetScreenState();
}

class _SavingTargetScreenState extends State<SavingTargetScreen> {
  late Future<List<SavingTarget>> _targets;
  bool _deleting = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _targets = widget.repository.targets();
  }

  Future<void> _edit([SavingTarget? target]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InheritedTheme.captureAll(
          context,
          SavingTargetFormScreen(repository: widget.repository, target: target),
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _delete(SavingTarget target) async {
    if (!await confirmSavingDelete(
      context,
      'target ${savingMonth(target.month)}',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.deleteTarget(target.id!);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target gagal dihapus. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: savingAppBar('Target penghematan'),
    body: FutureBuilder<List<SavingTarget>>(
      future: _targets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SavingFailure(retry: () => setState(_reload));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SavingNotice(
              'Target bulanan • baseline contoh 150 kWh\nKonsumsi aktual dan progres mingguan menunggu integrasi data meter dari Modul 1.',
            ),
            const SizedBox(height: 16),
            if (snapshot.data!.isEmpty)
              const SurfaceCard(
                child: Text('Belum ada target. Buat target bulanan pertamamu.'),
              ),
            for (final target in snapshot.data!) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SavingColors.primaryGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      savingMonth(target.month),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${savingNumber(target.targetKwh)} kWh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Target hemat ${savingNumber(target.savingPercent)}% dari ${savingNumber(target.baselineKwh)} kWh',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acuan mingguan: ${savingNumber(target.weeklyReferenceKwh)} kWh',
                    ),
                    Text('Target bulanan ÷ ${target.periodDays} hari × 7'),
                    const SizedBox(height: 12),
                    const Text(
                      'Aktual vs Target: data aktual bulanan belum tersedia.',
                      style: TextStyle(color: SavingColors.textSecondary),
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: _deleting ? null : () => _edit(target),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Ubah'),
                        ),
                        TextButton.icon(
                          onPressed: _deleting ? null : () => _delete(target),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            FilledButton.icon(
              onPressed: _deleting ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Buat target'),
            ),
          ],
        );
      },
    ),
  );
}
