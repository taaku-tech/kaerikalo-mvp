/// 目標のソース：食べ物プリセット or 手入力kcal
enum GoalSource { food, custom }

class DailyGoal {
  final DateTime date;        // 当日
  final int targetKcal;       // 例: 300
  final GoalSource source;    // food / custom
  final String? foodPresetId; // source==food のとき

  const DailyGoal({
    required this.date,
    required this.targetKcal,
    this.source = GoalSource.custom,
    this.foodPresetId,
  });

  String get ymd => _ymd(date);

  DailyGoal copyWith({
    DateTime? date,
    int? targetKcal,
    GoalSource? source,
    String? foodPresetId,
  }) =>
      DailyGoal(
        date: date ?? this.date,
        targetKcal: targetKcal ?? this.targetKcal,
        source: source ?? this.source,
        foodPresetId: foodPresetId ?? this.foodPresetId,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'targetKcal': targetKcal,
        'source': source.name,
        'foodPresetId': foodPresetId,
      };

  factory DailyGoal.fromJson(Map<String, dynamic> json) => DailyGoal(
        date: DateTime.parse(json['date'] as String),
        targetKcal: (json['targetKcal'] as num).toInt(),
        source: GoalSource.values.firstWhere((e) => e.name == json['source']),
        foodPresetId: json['foodPresetId'] as String?,
      );
}

String _ymd(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  return "${d.year.toString().padLeft(4, '0')}-"
         "${d.month.toString().padLeft(2, '0')}-"
         "${d.day.toString().padLeft(2, '0')}";
}
