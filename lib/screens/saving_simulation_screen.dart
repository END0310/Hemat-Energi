import 'package:flutter/material.dart';

import '../core/saving_colors.dart';
import '../data/saving_repository.dart';
import '../models/saving_device_model.dart';
import '../models/saving_simulation_model.dart';
import '../services/saving_calculator_service.dart';
import '../widgets/saving_widgets.dart';
import '../widgets/surface_card.dart';

class SavingSimulationScreen extends StatefulWidget {
  final SavingRepository repository;
  final int? initialDeviceId;
  const SavingSimulationScreen({
    super.key,
    required this.repository,
    this.initialDeviceId,
  });
  @override
  State<SavingSimulationScreen> createState() => _SavingSimulationScreenState();
}

class _SavingSimulationScreenState extends State<SavingSimulationScreen> {
  List<SavingDevice> _devices = [];
  List<SavingSimulation> _saved = [];
  SavingDevice? _device;
  double? _tariff;
  double _hours = 0;
  int? _editingId;
  bool _loading = true;
  bool _failed = false;
  bool _busy = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final inputs = await widget.repository.inputs();
      final saved = await widget.repository.simulations();
      if (!mounted) return;
      setState(() {
        _devices = inputs.devices
            .where(
              (d) =>
                  d.id != null &&
                  d.powerWatt.isFinite &&
                  d.powerWatt > 0 &&
                  d.quantity > 0 &&
                  d.dailyHours.isFinite &&
                  d.dailyHours > 0 &&
                  d.dailyHours <= 24,
            )
            .toList();
        _tariff = inputs.tariffPerKwh;
        _saved = saved;
        final matching = _devices.where((d) => d.id == widget.initialDeviceId);
        _select(
          matching.isNotEmpty
              ? matching.first
              : (_devices.isEmpty ? null : _devices.first),
        );
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _select(SavingDevice? device) {
    _device = device;
    _hours = device == null
        ? 0
        : (device.dailyHours - 1).clamp(0, device.dailyHours);
    _editingId = null;
    _notice = null;
  }

  SavingSimulation? get _result {
    if (_device == null || _tariff == null) return null;
    return SavingCalculatorService.simulate(
      id: _editingId,
      userId: widget.repository.userId,
      device: _device!,
      proposedHours: _hours,
      tariffPerKwh: _tariff!,
    );
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null || result.monthlySavedKwh <= 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.saveSimulation(result);
      final saved = await widget.repository.simulations();
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _editingId = result.id ?? saved.first.id;
        _notice = 'Simulasi tersimpan di perangkat. Durasi perangkat asli tidak berubah.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Simulasi belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(SavingSimulation item) {
    final matches = _devices.where((d) => d.id == item.deviceId);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Perangkat asal sudah dihapus atau tidak valid. Buat simulasi baru dengan perangkat yang tersedia.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _device = matches.first;
      _hours = item.proposedHours.clamp(0, _device!.dailyHours);
      _editingId = item.id;
      _notice =
          'Mengubah ${item.deviceName}. Hasil dihitung ulang dengan spesifikasi dan tarif saat ini.';
    });
  }

  Future<void> _delete(SavingSimulation item) async {
    if (!await confirmSavingDelete(context, 'simulasi ${item.deviceName}')) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.deleteSimulation(item.id!);
      final saved = await widget.repository.simulations();
      if (mounted) {
        setState(() {
          _saved = saved;
          if (_editingId == item.id) _editingId = null;
          _notice = 'Simulasi dihapus.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Simulasi gagal dihapus. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: savingAppBar('Simulasi penghematan'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
          ? SavingFailure(retry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Simulasi dengan perangkat dan tarif contoh. Hasil belum memakai data konsumsi aktual.',
                  style: TextStyle(
                    color: SavingColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (_devices.isEmpty)
                  const SavingNotice(
                    'Belum ada perangkat yang dapat disimulasikan. Data perangkat contoh belum tersedia. Kembali dan coba buka simulasi lagi.',
                  )
                else ...[
                  DropdownButtonFormField<int>(
                    key: ValueKey(_device?.id),
                    initialValue: _device?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih perangkat',
                      border: OutlineInputBorder(),
                    ),
                    items: _devices
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              '${d.name} • ${savingNumber(d.powerWatt, 0)} W',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (id) => setState(
                            () =>
                                _select(_devices.firstWhere((d) => d.id == id)),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Penggunaan saat ini: ${savingNumber(_device!.dailyHours)} jam / hari • ${_device!.quantity} unit',
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kurangi menjadi'),
                        const SizedBox(height: 8),
                        Text(
                          '${savingNumber(_hours)} jam / hari',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Slider(
                          value: _hours,
                          min: 0,
                          max: _device!.dailyHours,
                          divisions: (_device!.dailyHours * 10).ceil().clamp(
                            1,
                            240,
                          ),
                          label: '${savingNumber(_hours)} jam',
                          onChanged: _busy
                              ? null
                              : (value) => setState(() {
                                  _hours = value;
                                  _notice = null;
                                }),
                        ),
                        Text(
                          '0 sampai ${savingNumber(_device!.dailyHours)} jam per hari',
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_tariff == null)
                  const SavingNotice(
                    'Tarif belum tersedia untuk profil contoh ini. Simulasi baru bisa dihitung setelah konfigurasi tarif tersedia.',
                  ),
                if (result != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SavingColors.lightGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.savings_outlined,
                          color: SavingColors.primaryGreen,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        const Text('Potensi penghematan • Estimasi'),
                        Text(
                          '${savingNumber(result.monthlySavedKwh)} kWh / bulan',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: SavingColors.primaryGreen,
                          ),
                        ),
                        const Divider(height: 28),
                        Text(
                          'Estimasi hemat biaya: Rp ${savingNumber(result.monthlySavedCost, 0)} / bulan',
                        ),
                        Text(
                          'Tarif konfigurasi: Rp ${savingNumber(result.tariffPerKwh, 2)} / kWh',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Estimasi memakai 30 hari, daya, jumlah perangkat, dan pengurangan durasi. Hasil ini bukan konsumsi aktual atau nominal token.',
                  style: TextStyle(
                    fontSize: 12,
                    color: SavingColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SavingNotice(_notice!),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      _busy || result == null || result.monthlySavedKwh <= 0
                      ? null
                      : _save,
                  child: Text(
                    _busy
                        ? 'Menyimpan…'
                        : _editingId == null
                        ? 'Simpan simulasi'
                        : 'Simpan perubahan',
                  ),
                ),
                if (_editingId != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _select(_device)),
                    child: const Text('Buat simulasi baru'),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Simulasi tersimpan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (_saved.isEmpty) const Text('Belum ada simulasi tersimpan.'),
                for (final item in _saved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.deviceName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${savingNumber(item.originalHours)} → ${savingNumber(item.proposedHours)} jam / hari',
                          ),
                          Text(
                            'Estimasi ${savingNumber(item.monthlySavedKwh)} kWh • Rp ${savingNumber(item.monthlySavedCost, 0)} / 30 hari',
                          ),
                          const Text(
                            'Snapshot saat disimpan',
                            style: TextStyle(
                              fontSize: 12,
                              color: SavingColors.textSecondary,
                            ),
                          ),
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: _busy ? null : () => _edit(item),
                                child: const Text('Ubah'),
                              ),
                              TextButton(
                                onPressed: _busy ? null : () => _delete(item),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
