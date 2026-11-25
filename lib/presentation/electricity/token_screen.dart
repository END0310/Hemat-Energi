import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/token_purchase.dart';
import '../auth/auth_provider.dart';
import '../shared/scroll_date_range_picker.dart';
import 'electricity_provider.dart';
import 'token_form_screen.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final picked = await ScrollDateRangePicker.show(
      context,
      initialRange: _selectedDateRange,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  List<TokenPurchase> _applyDateFilter(List<TokenPurchase> allTokens) {
    final range = _selectedDateRange;
    if (range == null) return allTokens;

    final startOfDay = DateTime(range.start.year, range.start.month, range.start.day);
    final endOfDay = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);

    return allTokens.where((t) {
      return !t.tanggalWaktu.isBefore(startOfDay) && !t.tanggalWaktu.isAfter(endOfDay);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final electricity = context.watch<ElectricityProvider>();
    final allTokens = electricity.tokenPurchases;
    final filteredTokens = _applyDateFilter(allTokens);
    final summary = electricity.monthlyTokenSummary;
    final allTimeSummary = electricity.allTimeTokenSummary;
    final latestReading = electricity.latestMeterReading;
    final remainingDays = electricity.remainingDays;

    final filteredNominal = filteredTokens.fold<double>(0.0, (sum, t) => sum + t.nominal);
    final filteredKwh = filteredTokens.fold<double>(0.0, (sum, t) => sum + t.kwhToken);

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
                    'Token listrik',
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
            // Card Saldo Saat Ini
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
                    'Saldo saat ini',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppConstants.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        remainingDays != null
                            ? 'Diperkirakan cukup untuk ± ${AppFormatters.formatKwh(remainingDays)} hari'
                            : 'Belum cukup data untuk estimasi hari',
                        style: const TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card Ringkasan Bulan Ini & Total Pengeluaran (FR-04)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bulan ini',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 11,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatRupiah(summary['total_nominal'] as num),
                              style: const TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${summary['count']} pembelian',
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 10,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: AppConstants.borderLight,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Token masuk (bulan ini)',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 11,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormatters.formatKwh(summary['total_kwh'] as double)} kWh',
                              style: const TextStyle(
                                color: AppConstants.textPrimary,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Bulan berjalan',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 10,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppConstants.borderLight),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Total seluruh pengeluaran',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${AppFormatters.formatRupiah(allTimeSummary['total_nominal'] as num)} '
                          '(${AppFormatters.formatKwh(allTimeSummary['total_kwh'] as double)} kWh)',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppConstants.primaryDarkGreen,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Header Riwayat Pembelian + Tombol Scroll Filter Rentang Tanggal (FR-04)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat pembelian',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(
                      color: _selectedDateRange != null
                          ? AppConstants.primaryGreen
                          : AppConstants.border,
                    ),
                    backgroundColor: _selectedDateRange != null
                        ? AppConstants.primaryLightGreen
                        : Colors.white,
                  ),
                  icon: Icon(
                    Icons.date_range_outlined,
                    size: 15,
                    color: _selectedDateRange != null
                        ? AppConstants.primaryDarkGreen
                        : AppConstants.textSecondary,
                  ),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Filter tanggal'
                        : '${AppFormatters.formatDateShort(_selectedDateRange!.start)} – ${AppFormatters.formatDateShort(_selectedDateRange!.end)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: _selectedDateRange != null
                          ? AppConstants.primaryDarkGreen
                          : AppConstants.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            // Info ringkasan hasil filter rentang tanggal jika aktif
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryLightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hasil filter (${filteredTokens.length} transaksi): '
                        '${AppFormatters.formatRupiah(filteredNominal)} • '
                        '+${AppFormatters.formatKwh(filteredKwh)} kWh',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryDarkGreen,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _selectedDateRange = null),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: AppConstants.errorRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Daftar Transaksi Token
            if (filteredTokens.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 40, color: AppConstants.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      _selectedDateRange != null
                          ? 'Tidak ada transaksi pada rentang tanggal ini'
                          : 'Belum ada pembelian token',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDateRange != null
                          ? 'Coba ubah atau tekan Reset pada filter tanggal di atas.'
                          : 'Ketuk tombol "+ Tambah Token" di bawah untuk mulai mencatat.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppConstants.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTokens.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final token = filteredTokens[index];
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
                        child: const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppConstants.primaryGreen,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        AppFormatters.formatRupiah(token.nominal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        AppFormatters.formatDate(token.tanggalWaktu),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${AppFormatters.formatKwh(token.kwhToken)} kWh',
                            style: const TextStyle(
                              color: AppConstants.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppConstants.textMuted),
                            onSelected: (action) {
                              if (action == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TokenFormScreen(existingToken: token),
                                  ),
                                );
                              } else if (action == 'delete') {
                                _confirmDelete(context, token);
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
                MaterialPageRoute(builder: (_) => const TokenFormScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('+ Tambah Token'),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TokenPurchase token) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Transaksi Token?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus pembelian token ${AppFormatters.formatRupiah(token.nominal)} (${AppFormatters.formatKwh(token.kwhToken)} kWh)?'),
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
              await electricity.deleteTokenPurchase(token.id!, auth.currentUser!.id!);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
