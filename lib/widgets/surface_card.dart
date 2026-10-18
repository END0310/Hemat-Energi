import 'package:flutter/material.dart';

import '../core/saving_colors.dart';

/// Kartu putih yang dipakai kalkulator dan modul penghematan.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SavingColors.cardBorder),
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}
