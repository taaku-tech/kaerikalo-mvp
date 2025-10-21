import 'action_unit.dart';

/// 小さな運動アクション（提案カードの元データ）
class MicroAction {
  final String id;            // 例: "stairs"
  final String name;          // 例: "階段"
  final ActionUnit unit;      // 例: ActionUnit.flight
  final double kcalPerUnit;   // 単位あたりの推定消費kcal
  final String exampleText;   // 表示例: "20段×2往復"

  const MicroAction({
    required this.id,
    required this.name,
    required this.unit,
    required this.kcalPerUnit,
    required this.exampleText,
  });

  double estimateKcal(num amount) => kcalPerUnit * amount;

  MicroAction copyWith({
    String? id,
    String? name,
    ActionUnit? unit,
    double? kcalPerUnit,
    String? exampleText,
  }) =>
      MicroAction(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        kcalPerUnit: kcalPerUnit ?? this.kcalPerUnit,
        exampleText: exampleText ?? this.exampleText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit.name,
        'kcalPerUnit': kcalPerUnit,
        'exampleText': exampleText,
      };

  factory MicroAction.fromJson(Map<String, dynamic> json) => MicroAction(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: ActionUnit.values.firstWhere((e) => e.name == json['unit']),
        kcalPerUnit: (json['kcalPerUnit'] as num).toDouble(),
        exampleText: (json['exampleText'] as String?) ?? '',
      );
}
