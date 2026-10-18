class SavingTarget {
  final int? id;
  final String userId;
  final DateTime month;
  final double baselineKwh;
  final double savingPercent;

  const SavingTarget({
    this.id,
    required this.userId,
    required this.month,
    required this.baselineKwh,
    required this.savingPercent,
  });

  int get periodDays => DateTime(month.year, month.month + 1, 0).day;
  double get targetKwh => baselineKwh * (1 - savingPercent / 100);
  double get weeklyReferenceKwh => targetKwh / periodDays * 7;
  String get periodKey =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  void validate() {
    if (userId.trim().isEmpty ||
        !baselineKwh.isFinite ||
        baselineKwh <= 0 ||
        !savingPercent.isFinite ||
        savingPercent <= 0 ||
        savingPercent > 100) {
      throw ArgumentError(
        'Baseline harus positif dan target hemat > 0 sampai 100%.',
      );
    }
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'period': periodKey,
    'baseline_kwh': baselineKwh,
    'saving_percent': savingPercent,
    'target_kwh': targetKwh,
  };

  factory SavingTarget.fromMap(Map<String, Object?> map) => SavingTarget(
    id: map['id'] as int,
    userId: map['user_id'] as String,
    month: DateTime.parse('${map['period']}-01'),
    baselineKwh: (map['baseline_kwh'] as num).toDouble(),
    savingPercent: (map['saving_percent'] as num).toDouble(),
  );
}
