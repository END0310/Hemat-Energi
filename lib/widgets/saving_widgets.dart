import 'package:flutter/material.dart';

import '../core/saving_colors.dart';

String savingNumber(double value, [int decimals = 1]) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

String savingMonth(DateTime date) {
  const names = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${names[date.month - 1]} ${date.year}';
}

class SavingNotice extends StatelessWidget {
  final String text;
  const SavingNotice(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: SavingColors.lightGreen,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: SavingColors.primaryGreen,
        fontSize: 13,
        height: 1.5,
      ),
    ),
  );
}

AppBar savingAppBar(String title, {List<Widget>? actions}) => AppBar(
  title: Text(
    title,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  ),
  backgroundColor: Colors.white,
  foregroundColor: SavingColors.textDark,
  centerTitle: false,
  actions: actions,
);

class SavingFailure extends StatelessWidget {
  final VoidCallback retry;
  const SavingFailure({super.key, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Data penghematan belum dapat dimuat. Silakan coba lagi.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Coba lagi')),
        ],
      ),
    ),
  );
}

Future<bool> confirmSavingDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus $name?'),
        content: const Text('Data ini akan dihapus dari perangkat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ??
    false;
