import 'package:flutter/material.dart';

import '../data/saving_repository.dart';
import '../models/saving_target_model.dart';
import '../widgets/saving_widgets.dart';
import '../widgets/surface_card.dart';

class SavingTargetFormScreen extends StatefulWidget {
  final SavingRepository repository;
  final SavingTarget? target;
  const SavingTargetFormScreen({
    super.key,
    required this.repository,
    this.target,
  });
  @override
  State<SavingTargetFormScreen> createState() => _SavingTargetFormScreenState();
}

class _SavingTargetFormScreenState extends State<SavingTargetFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _percent;
  late DateTime _month;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _month =
        widget.target?.month ??
        DateTime(DateTime.now().year, DateTime.now().month);
    _percent = TextEditingController(
      text: '${widget.target?.savingPercent ?? 10}',
    );
  }

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  SavingTarget get _draft => SavingTarget(
    id: widget.target?.id,
    userId: widget.repository.userId,
    month: _month,
    baselineKwh: widget.target?.baselineKwh ?? 150,
    savingPercent: double.tryParse(_percent.text.replaceAll(',', '.')) ?? 0,
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveTarget(_draft);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Target belum tersimpan. Pastikan belum ada target pada bulan ini, lalu coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final valid =
        draft.savingPercent.isFinite &&
        draft.savingPercent > 0 &&
        draft.savingPercent <= 100;
    return Scaffold(
      appBar: savingAppBar(
        widget.target == null ? 'Buat target' : 'Ubah target',
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SavingNotice(
              'Demo Progress Report 1\nBaseline 150 kWh adalah contoh konsumsi bulan sebelumnya. Integrasi catatan meter bulanan menyusul.',
            ),
            const SizedBox(height: 20),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Periode target bulanan'),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Bulan sebelumnya',
                        onPressed: _saving
                            ? null
                            : () => setState(
                                () => _month = DateTime(
                                  _month.year,
                                  _month.month - 1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          savingMonth(_month),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bulan berikutnya',
                        onPressed: _saving
                            ? null
                            : () => setState(
                                () => _month = DateTime(
                                  _month.year,
                                  _month.month + 1,
                                ),
                              ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _percent,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target hemat',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (text) {
                      final value = double.tryParse(
                        (text ?? '').replaceAll(',', '.'),
                      );
                      return value != null &&
                              value.isFinite &&
                              value > 0 &&
                              value <= 100
                          ? null
                          : 'Isi persentase lebih dari 0 sampai 100.';
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SavingNotice(
              valid
                  ? 'Target konsumsi: ${savingNumber(draft.targetKwh)} kWh\nAcuan mingguan: ${savingNumber(draft.weeklyReferenceKwh)} kWh\n${draft.periodDays} hari dalam periode ini.'
                  : 'Masukkan persentase yang valid untuk melihat target.',
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan…' : 'Simpan target'),
            ),
          ],
        ),
      ),
    );
  }
}
