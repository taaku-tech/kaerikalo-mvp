// 目標のソース：食べ物プリセット or 手入力kcal
import 'package:hive/hive.dart';

part 'daily_goal.g.dart';

@HiveType(typeId: 1)
enum GoalSource {
  @HiveField(0)
  food,
  @HiveField(1)
  custom,
}

@HiveType(typeId: 10)
class DailyGoal {
  @HiveField(0)
  final DateTime date;        // 当日
  @HiveField(1)
  final int targetKcal;       // 例: 300
  @HiveField(2)
  final GoalSource source;    // food / custom
  @HiveField(3)
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
