class ActionLog {
  final String id;          // UUID推奨
  final DateTime date;      // 実施日（集計キー）
  final String actionId;    // MicroAction.id
  final num amount;         // 実施量（回/分/フライト）
  final double estKcal;     // 記録時点の推定消費kcal
  final String? note;       // メモ
  final DateTime timestamp; // 記録時刻

  const ActionLog({
    required this.id,
    required this.date,
    required this.actionId,
    required this.amount,
    required this.estKcal,
    this.note,
    required this.timestamp,
  });

  String get ymd => _ymd(date);

  ActionLog copyWith({
    String? id,
    DateTime? date,
    String? actionId,
    num? amount,
    double? estKcal,
    String? note,
    DateTime? timestamp,
  }) =>
      ActionLog(
        id: id ?? this.id,
        date: date ?? this.date,
        actionId: actionId ?? this.actionId,
        amount: amount ?? this.amount,
        estKcal: estKcal ?? this.estKcal,
        note: note ?? this.note,
        timestamp: timestamp ?? this.timestamp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'actionId': actionId,
        'amount': amount,
        'estKcal': estKcal,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ActionLog.fromJson(Map<String, dynamic> json) => ActionLog(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        actionId: json['actionId'] as String,
        amount: json['amount'] as num,
        estKcal: (json['estKcal'] as num).toDouble(),
        note: json['note'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

String _ymd(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  return "${d.year.toString().padLeft(4, '0')}-"
         "${d.month.toString().padLeft(2, '0')}-"
         "${d.day.toString().padLeft(2, '0')}";
}
