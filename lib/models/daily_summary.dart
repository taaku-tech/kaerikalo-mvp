class DailySummary {
  final DateTime date;
  final int targetKcal;
  final double burnedKcal;

  const DailySummary({
    required this.date,
    required this.targetKcal,
    required this.burnedKcal,
  });

  String get ymd => _ymd(date);

  /// 0.0〜1.0 の達成率（クリップ）
  double get achievedRate {
    if (targetKcal <= 0) return 0;
    final r = burnedKcal / targetKcal;
    return r.clamp(0.0, 1.0);
  }

  DailySummary copyWith({
    DateTime? date,
    int? targetKcal,
    double? burnedKcal,
  }) =>
      DailySummary(
        date: date ?? this.date,
        targetKcal: targetKcal ?? this.targetKcal,
        burnedKcal: burnedKcal ?? this.burnedKcal,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'targetKcal': targetKcal,
        'burnedKcal': burnedKcal,
      };

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        date: DateTime.parse(json['date'] as String),
        targetKcal: (json['targetKcal'] as num).toInt(),
        burnedKcal: (json['burnedKcal'] as num).toDouble(),
      );
}

String _ymd(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  return "${d.year.toString().padLeft(4, '0')}-"
         "${d.month.toString().padLeft(2, '0')}-"
         "${d.day.toString().padLeft(2, '0')}";
}
