import 'package:flutter/material.dart';

import '../core/saving_colors.dart';
import 'saving_screen.dart';

/// Tema penghematan dibatasi ke Modul 3.
class SavingEntry extends StatelessWidget {
  const SavingEntry({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: SavingColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SavingColors.primaryGreen,
        primary: SavingColors.primaryGreen,
      ),
    ),
    child: const SavingScreen(),
  );
}
