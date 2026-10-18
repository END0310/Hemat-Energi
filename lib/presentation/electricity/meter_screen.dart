import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/meter_reading.dart';
import '../auth/auth_provider.dart';
import 'electricity_provider.dart';
import 'meter_form_screen.dart';

class MeterScreen extends StatelessWidget {
  const MeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final electricity = context.watch<ElectricityProvider>();
    final readings = electricity.meterReadings;
    final latestReading = electricity.latestMeterReading;
    final periods = electricity.consumptionPeriods;
    final latestPeriod = periods.isNotEmpty ? periods.last : null;

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppConstants.borderLight, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Catatan meter',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Saldo Meter Terakhir
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD3E7DC)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Saldo meter terakhir',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: latestReading != null
                              ? AppFormatters.formatKwh(latestReading.saldoKwh)
                              : '0',
                          style: const TextStyle(
                            color: AppConstants.primaryDarkGreen,
                            fontSize: 32,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: ' kWh',
                          style: TextStyle(
                            color: AppConstants.primaryDarkGreen,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    latestReading != null
                        ? AppFormatters.formatRecordedTime(latestReading.tanggalWaktu)
                        : 'Belum ada catatan meter',
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card Tren Konsumsi Periode Terakhir
            if (latestPeriod != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      latestPeriod.isNegative
                          ? Icons.warning_amber_rounded
                          : Icons.trending_down,
                      color: latestPeriod.isNegative
                          ? AppConstants.warningYellow
                          : AppConstants.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: latestPeriod.isNegative
                                  ? 'Data tidak wajar '
                                  : '${AppFormatters.formatKwh(latestPeriod.consumptionKwh)} kWh terpakai ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: latestPeriod.isNegative
                                  ? '(periksa input saldo)'
                                  : 'sejak pencatatan sebelumnya',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: latestPeriod.isNegative
                            ? AppConstants.warningBg
                            : AppConstants.primaryLightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        latestPeriod.isNegative ? 'Peringatan' : 'Aktual',
                        style: TextStyle(
                          color: latestPeriod.isNegative
                              ? const Color(0xFF8C6500)
                              : AppConstants.primaryDarkGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section Catatan Terbaru
            const Text(
              'Catatan terbaru',
              style: TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            if (readings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.speed_outlined, size: 40, color: AppConstants.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada catatan meter',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ketuk tombol "Catat Meter" untuk memperbarui saldo kWh Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppConstants.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: readings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final reading = readings[index];
                  // Cari apakah ada periode yang berakhir di reading ini
                  final matchingPeriod = periods.where((p) => p.currentReading.id == reading.id).toList();
                  final periodInfo = matchingPeriod.isNotEmpty ? matchingPeriod.first : null;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: reading.fotoPath != null && File(reading.fotoPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(reading.fotoPath!),
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryLightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.speed_outlined,
                                color: AppConstants.primaryGreen,
                                size: 18,
                              ),
                            ),
                      title: Text(
                        '${AppFormatters.formatKwh(reading.saldoKwh)} kWh',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        AppFormatters.formatDateTime(reading.tanggalWaktu),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (periodInfo != null)
                            Text(
                              periodInfo.isNegative
                                  ? 'Salah input'
                                  : '-${AppFormatters.formatKwh(periodInfo.consumptionKwh)} kWh',
                              style: TextStyle(
                                color: periodInfo.isNegative
                                    ? AppConstants.errorRed
                                    : AppConstants.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppConstants.textMuted),
                            onSelected: (action) {
                              if (action == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MeterFormScreen(existingReading: reading),
                                  ),
                                );
                              } else if (action == 'delete') {
                                _confirmDelete(context, reading);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Ubah'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus', style: TextStyle(color: AppConstants.errorRed)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppConstants.background,
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MeterFormScreen()),
              );
            },
            icon: const Icon(Icons.speed, size: 18),
            label: const Text('Catat Meter'),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MeterReading reading) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Catatan Meter?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus catatan saldo ${AppFormatters.formatKwh(reading.saldoKwh)} kWh ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorRed,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final auth = context.read<AuthProvider>();
              final electricity = context.read<ElectricityProvider>();
              await electricity.deleteMeterReading(reading.id!, auth.currentUser!.id!);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
