import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import 'electricity_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Token, 2: Meter, 3: Penghematan

  final List<String> _filters = ['Semua', 'Token', 'Meter', 'Penghematan'];

  @override
  Widget build(BuildContext context) {
    final electricity = context.watch<ElectricityProvider>();
    final tokens = electricity.tokenPurchases;
    final readings = electricity.meterReadings;
    final periods = electricity.consumptionPeriods;

    // Gabungkan seluruh aktivitas menjadi daftar terurut kronologis (terbaru di atas)
    final List<Map<String, dynamic>> allActivities = [];

    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
      for (final t in tokens) {
        allActivities.add({
          'type': 'token',
          'title': 'Pembelian token ${AppFormatters.formatRupiah(t.nominal)}',
          'subtitle': 'Token • ${AppFormatters.formatDateShort(t.tanggalWaktu)}',
          'value': '+${AppFormatters.formatKwh(t.kwhToken)} kWh',
          'isPositive': true,
          'date': t.tanggalWaktu,
          'icon': Icons.confirmation_number_outlined,
        });
      }
    }

    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
      for (final m in readings) {
        allActivities.add({
          'type': 'meter',
          'title': 'Catat saldo meter',
          'subtitle': 'Meter • ${AppFormatters.formatDateShort(m.tanggalWaktu)}',
          'value': '${AppFormatters.formatKwh(m.saldoKwh)} kWh',
          'isPositive': false,
          'date': m.tanggalWaktu,
          'icon': Icons.speed_outlined,
        });
      }

      for (final p in periods) {
        if (!p.isNegative) {
          allActivities.add({
            'type': 'consumption',
            'title': 'Konsumsi aktual periode',
            'subtitle': 'Konsumsi • ${AppFormatters.formatDateShort(p.currentReading.tanggalWaktu)}',
            'value': '-${AppFormatters.formatKwh(p.consumptionKwh)} kWh',
            'isPositive': false,
            'date': p.currentReading.tanggalWaktu,
            'icon': Icons.bolt_outlined,
          });
        }
      }
    }

    // Urutkan aktivitas berdasarkan tanggal terbaru
    allActivities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76.5),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppConstants.borderLight, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Riwayat',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 19,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.38,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Semua aktivitas listrik',
                    style: TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs (Semua, Token, Meter, Penghematan)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        }
                      },
                      selectedColor: AppConstants.primaryGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppConstants.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppConstants.primaryGreen : AppConstants.border,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Daftar Aktivitas
          Expanded(
            child: _selectedFilterIndex == 3
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.savings_outlined, size: 48, color: AppConstants.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'Riwayat Penghematan (Modul 3)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Fitur penghematan dan evaluasi target akan hadir pada pembaruan Modul 3.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : allActivities.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.history, size: 48, color: AppConstants.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada riwayat aktivitas',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Mulai dengan menambahkan token listrik atau mencatat saldo meter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: allActivities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = allActivities[index];
                          final isPositive = item['isPositive'] as bool;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryLightGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  color: AppConstants.primaryGreen,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                item['subtitle'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                              trailing: Text(
                                item['value'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isPositive
                                      ? AppConstants.primaryGreen
                                      : AppConstants.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
