import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/dummy/saving_dummy_data.dart';
import '../../data/models/saving_target.dart';
import '../../data/repositories/saving_repository.dart';
import '../../domain/services/saving_calculator.dart';
import 'saving_widgets.dart';

/// FR-09 — Form tambah / ubah target penghematan.
class TargetFormScreen extends StatefulWidget {
  final SavingTarget? existingTarget; // null = tambah baru

  const TargetFormScreen({super.key, this.existingTarget});

  @override
  State<TargetFormScreen> createState() => _TargetFormScreenState();
}

class _TargetFormScreenState extends State<TargetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _persenController = TextEditingController();

  late DateTime _mulai;
  late DateTime _selesai;
  late double _konsumsiSebelumnya;

  bool get _isEdit => widget.existingTarget != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTarget;
    final now = DateTime.now();

    // Default: periode = bulan berjalan.
    _mulai = t?.periodeMulai ?? DateTime(now.year, now.month, 1);
    _selesai = t?.periodeSelesai ?? DateTime(now.year, now.month + 1, 0);
    // Baseline diambil dari konsumsi AKTUAL periode sebelumnya.
    _konsumsiSebelumnya = t?.konsumsiSebelumnya ?? SavingDummyData.konsumsiPeriodeSebelumnya;
    _persenController.text = t != null ? AppFormatters.formatKwh(t.persenHemat) : '10';
  }

  @override
  void dispose() {
    _persenController.dispose();
    super.dispose();
  }

  double get _persen => double.tryParse(_persenController.text.replaceAll(',', '.')) ?? 0;

  Future<void> _pilihPeriode() async {
    final hasil = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _mulai, end: _selesai),
    );
    if (hasil != null) {
      setState(() {
        _mulai = hasil.start;
        _selesai = hasil.end;
      });
    }
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final target = SavingTarget(
      id: widget.existingTarget?.id,
      userId: SavingDummyData.userId,
      periodeMulai: _mulai,
      periodeSelesai: _selesai,
      konsumsiSebelumnya: _konsumsiSebelumnya,
      persenHemat: _persen,
      targetKonsumsi: SavingCalculator.targetKonsumsi(_konsumsiSebelumnya, _persen),
    );

    final repo = SavingRepository.instance;
    _isEdit ? repo.updateTarget(target) : repo.insertTarget(target);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Target diperbarui' : 'Target disimpan')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Pratinjau hasil hitung (berubah setiap persen diketik).
    final targetKonsumsi = SavingCalculator.targetKonsumsi(_konsumsiSebelumnya, _persen);
    final jumlahHari = SavingCalculator.jumlahHari(_mulai, _selesai);
    final targetMingguan = SavingCalculator.targetMingguan(targetKonsumsi, jumlahHari);

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: SavingAppBar(title: _isEdit ? 'Ubah target' : 'Tambah target'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Periode
            const Text('Periode target', style: SavingText.caption),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pilihPeriode,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_month_rounded),
                ),
                child: Text(
                  '${AppFormatters.formatDateShort(_mulai)} – ${AppFormatters.formatDateShort(_selesai)}'
                  '  ($jumlahHari hari)',
                  style: SavingText.body,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Baseline (read-only, dari data aktual)
            SavingCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Konsumsi periode sebelumnya', style: SavingText.bodyMuted),
                  ),
                  Text(
                    '${AppFormatters.formatKwh(_konsumsiSebelumnya)} kWh',
                    style: SavingText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const KonsumsiBadge(estimasi: false),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Persen hemat
            const Text('Target hemat', style: SavingText.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: _persenController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Contoh: 10',
                suffixText: '%',
              ),
              onChanged: (_) => setState(() {}),
              validator: (_) {
                if (_persen <= 0 || _persen >= 100) return 'Isi angka antara 1 dan 99';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 20].map((p) {
                return ChoiceChip(
                  label: Text('$p%'),
                  selected: _persen == p,
                  selectedColor: AppConstants.primaryLightGreen,
                  onSelected: (_) => setState(() => _persenController.text = '$p'),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Pratinjau
            SavingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hasil target', style: SavingText.subheading),
                  const SizedBox(height: 8),
                  InfoRow(
                    label: 'Target konsumsi bulanan',
                    value: '${AppFormatters.formatKwh(targetKonsumsi)} kWh',
                  ),
                  InfoRow(
                    label: 'Target mingguan (acuan)',
                    value: '${AppFormatters.formatKwh(targetMingguan)} kWh',
                  ),
                  InfoRow(
                    label: 'Hemat dari sebelumnya',
                    value: '${AppFormatters.formatKwh(_konsumsiSebelumnya - targetKonsumsi)} kWh',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _simpan,
            child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan target'),
          ),
        ),
      ),
    );
  }
}
