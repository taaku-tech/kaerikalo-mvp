import 'package:hive/hive.dart';

part 'activity_log.g.dart';

@HiveType(typeId: 2)
enum ActivityType {
  @HiveField(0)
  walk,
  @HiveField(1)
  stairs,
  @HiveField(2)
  highKnee,
  @HiveField(3)
  calfRaise,
  @HiveField(4)
  other,
}

@HiveType(typeId: 11)
class ActivityLog {
  @HiveField(0)
  final String id;          // UUID推奨
  @HiveField(1)
  final DateTime date;      // 実施日・集計キー
  @HiveField(2)
  final String actionId;    // MicroAction.id（将来ActivityTypeと併用可）
  @HiveField(3)
  final num amount;         // 実施量（回/分/フライト等）
  @HiveField(4)
  final double estKcal;     // 記録時点の推定消費kcal
  @HiveField(5)
  final String? note;       // メモ
  @HiveField(6)
  final DateTime timestamp; // 記録時刻

  const ActivityLog({
    required this.id,
    required this.date,
    required this.actionId,
    required this.amount,
    required this.estKcal,
    this.note,
    required this.timestamp,
  });

  String get ymd => _ymd(date);

  ActivityLog copyWith({
    String? id,
    DateTime? date,
    String? actionId,
    num? amount,
    double? estKcal,
    String? note,
    DateTime? timestamp,
  }) =>
      ActivityLog(
        id: id ?? this.id,
        date: date ?? this.date,
        actionId: actionId ?? this.actionId,
        amount: amount ?? this.amount,
        estKcal: estKcal ?? this.estKcal,
        note: note ?? this.note,
        timestamp: timestamp ?? this.timestamp,
      );
}

typedef ActionLog = ActivityLog; // 互換のため

String _ymd(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  return "${d.year.toString().padLeft(4, '0')}-"
         "${d.month.toString().padLeft(2, '0')}-"
         "${d.day.toString().padLeft(2, '0')}";
}

