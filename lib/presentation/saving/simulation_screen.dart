import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/dummy/saving_dummy_data.dart';
import '../../data/models/saving_simulation.dart';
import '../../data/repositories/saving_repository.dart';
import '../../domain/services/saving_calculator.dart';
import 'saving_widgets.dart';

/// FR-10 — Simulasi penghematan (Layar 15 pada desain).
/// Semua hasil simulasi berlabel estimasi.
class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final _repo = SavingRepository.instance;
  final _perangkat = SavingDummyData.perangkat; // TODO(merge): data Modul 2

  late DummyDevice _dipilih = _perangkat.first;
  late double _jamBaru = (_dipilih.jamPerHari - 1).clamp(0.5, _dipilih.jamPerHari);

  double get _jamDikurangi =>
      (_dipilih.jamPerHari - _jamBaru).clamp(0.0, _dipilih.jamPerHari);

  double get _hematHarian =>
      SavingCalculator.hematHarian(_dipilih.watt, _jamDikurangi, _dipilih.jumlah);
  double get _hematBulanan => SavingCalculator.hematBulanan(_hematHarian);
  double get _biayaHemat =>
      SavingCalculator.estimasiBiaya(_hematBulanan, SavingDummyData.tarifPerKwh);

  void _simpan() {
    if (_jamDikurangi <= 0) return;
    _repo.insertSimulation(SavingSimulation(
      userId: SavingDummyData.userId,
      deviceId: _dipilih.id,
      namaPerangkat: _dipilih.nama,
      jamDikurangi: _jamDikurangi,
      kwhHematBulanan: _hematBulanan,
      biayaHemat: _biayaHemat,
      dibuatPada: DateTime.now(),
    ));
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulasi disimpan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = _repo.getSimulations(SavingDummyData.userId);
    final maxJam = _dipilih.jamPerHari;
    final divisions = ((maxJam - 0.5) * 2).round().clamp(1, 48);

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: const SavingAppBar(title: 'Simulasi penghematan'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Lihat dampak perubahan kebiasaan sebelum menetapkan target.',
            style: SavingText.bodyMuted,
          ),
          const SizedBox(height: 16),

          // Pilih perangkat
          Text(
            'Pilih perangkat',
            style: SavingText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SavingCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DummyDevice>(
                value: _dipilih,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _perangkat.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.ac_unit_rounded,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              d.nama,
                              style: SavingText.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${AppFormatters.formatKwh(d.watt)} W · ${d.jumlah} unit',
                              style: SavingText.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (d) {
                  if (d == null) return;
                  setState(() {
                    _dipilih = d;
                    _jamBaru = (d.jamPerHari - 1).clamp(0.5, d.jamPerHari);
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Penggunaan saat ini
          Row(
            children: [
              const Expanded(
                child: Text('Penggunaan saat ini', style: SavingText.bodyMuted),
              ),
              Text(
                '${AppFormatters.formatKwh(_dipilih.jamPerHari)} jam / hari',
                style: SavingText.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kartu "Kurangi menjadi"
          SavingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kurangi menjadi', style: SavingText.caption),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: AppFormatters.formatKwh(_jamBaru),
                        style: SavingText.heading.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: ' jam / hari',
                        style: SavingText.body,
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _jamBaru.clamp(0.5, maxJam),
                  min: 0.5,
                  max: maxJam,
                  divisions: divisions,
                  activeColor: AppConstants.primaryGreen,
                  onChanged: (val) => setState(() => _jamBaru = val),
                ),
                Row(
                  children: [
                    const Text('0,5 jam', style: SavingText.caption),
                    const Spacer(),
                    Text('${AppFormatters.formatKwh(maxJam)} jam', style: SavingText.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Kartu hijau hasil simulasi (estimasi)
          SavingCard(
            color: AppConstants.primaryLightGreen,
            borderColor: AppConstants.primaryLightGreen,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppConstants.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Potensi penghematan', style: SavingText.caption),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '±${AppFormatters.formatKwh(_hematBulanan)} kWh',
                        style: SavingText.heading.copyWith(
                          color: AppConstants.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text: ' / bulan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFCFE6D8)),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Estimasi hemat biaya', style: SavingText.caption),
                    ),
                    Text(
                      '${AppFormatters.formatRupiah(_biayaHemat)} / bulan',
                      style: SavingText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hasil merupakan estimasi berdasarkan daya dan durasi penggunaan.',
            textAlign: TextAlign.center,
            style: SavingText.caption,
          ),
          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: _simpan,
            child: const Text('Simpan simulasi'),
          ),

          if (riwayat.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Simulasi tersimpan', style: SavingText.subheading),
            const SizedBox(height: 8),
            ...riwayat.map(_buildRiwayatItem),
          ],
        ],
      ),
    );
  }

  Widget _buildRiwayatItem(SavingSimulation s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SavingCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.namaPerangkat} · −${AppFormatters.formatKwh(s.jamDikurangi)} jam/hari',
                    style: SavingText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estimasi ±${AppFormatters.formatKwh(s.kwhHematBulanan)} kWh · '
                    '${AppFormatters.formatRupiah(s.biayaHemat)} / bulan',
                    style: SavingText.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.errorRed),
              onPressed: () {
                _repo.deleteSimulation(s.id!);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
