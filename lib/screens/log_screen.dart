import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/daily_goal_provider.dart';
import '../models/activity_log.dart';
import '../repositories/activity_repository.dart';
import '../providers/auth_provider.dart';
import '../services/calorie_service.dart';

// 日付キー（YYYY-MM-DD）
String _ymd(DateTime dt) {
final d = DateTime(dt.year, dt.month, dt.day);
return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// 単位（運動IDごとの表示単位）
String _unitForId(String id) {
switch (id) {
case 'walk':
return '分';
case 'walk_fast':
return '秒';
case 'stairs':
return '段';
case 'highKnee':
case 'calfRaise':
return '回';
default:
return '回';
}
}

/// kcal → 単位へ換算（int 表示用）
int _kcalToUnits(String id, int kcal, {double? weightKg}) {
switch (id) {
case 'walk': return CalorieService.kcalToDetourMinutes(kcal.toDouble(), weightKg: weightKg); // 4kcal/分
case 'walk_fast': return CalorieService.kcalToFastWalkSeconds(kcal.toDouble(), weightKg: weightKg); // 5kcal/分 ⇒ 12秒/1kcal
case 'stairs': return CalorieService.kcalToStairsSteps(kcal.toDouble(), weightKg: weightKg); // 6kcal/30段 ⇒ 1kcal=5段
case 'highKnee': return CalorieService.kcalToHighKneeReps(kcal.toDouble(), weightKg: weightKg); // 3kcal/10回
case 'calfRaise': return CalorieService.kcalToCalfRaiseReps(kcal.toDouble(), weightKg: weightKg); // 2kcal/10回
default: return kcal;
}
}

// kcal(double) → 単位へ換算（int 表示用）
int _unitsFromKcalDouble(String id, double kcal, {double? weightKg}) {
switch (id) {
case 'walk': return CalorieService.kcalToDetourMinutes(kcal, weightKg: weightKg);
case 'walk_fast': return CalorieService.kcalToFastWalkSeconds(kcal, weightKg: weightKg);
case 'stairs': return CalorieService.kcalToStairsSteps(kcal, weightKg: weightKg);
case 'highKnee': return CalorieService.kcalToHighKneeReps(kcal, weightKg: weightKg);
case 'calfRaise': return CalorieService.kcalToCalfRaiseReps(kcal, weightKg: weightKg);
default: return kcal.round();
}
}

// 単位 → kcal（逆変換）
double _unitsToKcal(String id, int units, {double? weightKg}) {
switch (id) {
case 'walk_fast': return CalorieService.fastWalkSecondsToKcal(units, weightKg: weightKg); // 5kcal/分
case 'stairs': return CalorieService.stairsStepsToKcal(units, weightKg: weightKg); // 6kcal/30段
case 'highKnee': return CalorieService.highKneeRepsToKcal(units, weightKg: weightKg); // 3kcal/10回
case 'calfRaise': return CalorieService.calfRaiseRepsToKcal(units, weightKg: weightKg); // 2kcal/10回
default: return 0.0;
}
}

// プランキー（Home画面と連携用）
String _planKeyForId(String id) {
switch (id) {
case 'walk':
return 'detour_kcal';
case 'highKnee':
return 'high_knee_kcal';
case 'calfRaise':
return 'calf_raise_kcal';
default:
return '${id}_kcal';
}
}

/// 指定運動（同日同一actionIdのログを削除 → desiredKcalを1件登録）
Future<void> _replaceActual(String ymd, DateTime today, String actionId, double desiredKcal, {String? note}) async {
final box = Hive.box<ActivityLog>('activity_logs');
final keysToDelete = <dynamic>[];
box.toMap().cast<dynamic, ActivityLog>().forEach((key, value) {
if (value.ymd == ymd && value.actionId == actionId) {
keysToDelete.add(key);
}
});
if (keysToDelete.isNotEmpty) {
await box.deleteAll(keysToDelete);
}
final log = ActivityLog(
id: DateTime.now().microsecondsSinceEpoch.toString(),
date: DateTime(today.year, today.month, today.day),
actionId: actionId,
amount: 1,
estKcal: desiredKcal,
note: note,
timestamp: DateTime.now(),
);
await Hive.box<ActivityLog>('activity_logs').put(log.id, log);
}

class LogScreen extends StatelessWidget {
const LogScreen({super.key});

@override
Widget build(BuildContext context) {
  final goalProv = context.watch<DailyGoalProvider>();
  final target = goalProv.current?.targetKcal ?? 200;
final today = DateTime.now();
final ymd = _ymd(today);

return Scaffold(
  appBar: AppBar(title: const Text('本日の進捗')),
  body: ValueListenableBuilder<Box<ActivityLog>>(
    valueListenable: Hive.box<ActivityLog>('activity_logs').listenable(),
    builder: (context, _, __) {
      final targetsBox = Hive.box<int>('activity_targets');

      // プラン（当日kcal合計）
      final plannedKcal = targetsBox.keys
          .whereType<String>()
          .where((k) => k.startsWith(ymd))
          .map((k) => targetsBox.get(k, defaultValue: 0) ?? 0)
          .fold<int>(0, (s, v) => s + v);

      // 実績（当日kcal合計, double）
      final actualKcalDouble = ActivityRepository
          .fetchByDate(today)
          .fold<double>(0.0, (s, e) => s + e.estKcal);

      // 達成率（プランに対する実績）, 最大100%
      final pct = plannedKcal <= 0
          ? '0.0'
          : ((actualKcalDouble / plannedKcal) * 100).toStringAsFixed(1);

      // 1アクションごとの表示（プラン/実績/達成率）
      List<Widget> perAction(String id, String title) {
        final planKcal = targetsBox.get('$ymd:${_planKeyForId(id)}', defaultValue: 0) ?? 0;
        final actualKcalDoubleById = ActivityRepository
            .fetchByDate(today)
            .where((e) => e.actionId == id)
            .fold<double>(0.0, (s, e) => s + e.estKcal);

        final unit = _unitForId(id);
        final planUnits = _kcalToUnits(id, planKcal, weightKg: context.read<AuthProvider>().profile?.weightKg);
        final actualUnits = _unitsFromKcalDouble(id, actualKcalDoubleById, weightKg: context.read<AuthProvider>().profile?.weightKg);
        final rate = planKcal == 0 ? 0.0 : (actualKcalDoubleById / planKcal).clamp(0, 1).toDouble();
        final ratePct = planKcal <= 0
            ? '0.0'
            : ((actualKcalDoubleById / planKcal) * 100).toStringAsFixed(1);

        return [
          Text('$title の達成状況: プラン $planUnits$unit（${planKcal}kcal） / 実績 $actualUnits$unit（${actualKcalDoubleById.toStringAsFixed(1)}kcal）[$ratePct%]'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: rate),
          const SizedBox(height: 8),
        ];
      }


      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 今日の目標に対するサマリー
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('目標に対する進捗', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('目標 $target kcal / プラン合計 $plannedKcal kcal / 実績合計 ${actualKcalDouble.toStringAsFixed(1)} kcal（達成率 $pct%）'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: plannedKcal == 0 ? 0 : (actualKcalDouble / plannedKcal).clamp(0, 1)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 実績クリア / プラン→実績 反映
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('実績クリア'),
                            content: const Text('本日の実績（記録）を0に戻します。よろしいですか？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
                              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
                            ],
                          ),
                        ) ??
                        false;
                    if (!ok) return;
                    // 本日のログをまとめて削除
                    final boxLog = Hive.box<ActivityLog>('activity_logs');
                    final keysToDelete = <dynamic>[];
                    boxLog.toMap().cast<dynamic, ActivityLog>().forEach((key, value) {
                      if (value.ymd == ymd) {
                        keysToDelete.add(key);
                      }
                    });
                    if (keysToDelete.isNotEmpty) {
                      await boxLog.deleteAll(keysToDelete);
                    }
                    if (!context.mounted) return;
                    messenger.showSnackBar(const SnackBar(content: Text('本日の実績をクリアしました')));
                  },
                  child: const Text('実績クリア'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    // 各プラン値で、本日の実績を置き換えて登録
                    final ids = ['walk', 'highKnee', 'walk_fast', 'stairs', 'calfRaise'];
                    for (final id in ids) {
                      final plan = (targetsBox.get('$ymd:${_planKeyForId(id)}', defaultValue: 0) ?? 0).toDouble();
                      await _replaceActual(ymd, today, id, plan);
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('プランどおりに実績を登録しました')),
                    );
                  },
                  child: const Text('プランをそのまま実績に反映'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 種目ごとの達成状況
          ...perAction('walk',      '寄り道で歩く（分）'),
          ...perAction('highKnee',  'もも上げ'),
          ...perAction('walk_fast', '早歩き'),
          ...perAction('stairs',    '階段'),
          ...perAction('calfRaise', 'かかと上げ'),

          const SizedBox(height: 12),

          // 入力カード：寄り道（ログ置換で1件登録）
          _DetourInputCard(
            onReplace: (double desiredKcal) async {
              await _replaceActual(ymd, today, 'walk', desiredKcal);
            },
          ),
          const SizedBox(height: 8),

          // 入力カード（4種目）：単位→kcalでログ置換して登録
          _ActionReplaceCard(
            title: 'もも上げ',
            actionId: 'highKnee',
            unit: '回',
            toKcal: (units) => units * 3.0 / 10.0,
            planKey: '$ymd:high_knee_kcal',
          ),
          const SizedBox(height: 8),
          _ActionReplaceCard(
            title: '早歩き',
            actionId: 'walk_fast',
            unit: '秒',
            toKcal: (units) => units * 5.0 / 60.0,
            planKey: '$ymd:walk_fast_kcal',
          ),
          const SizedBox(height: 8),
          _ActionReplaceCard(
            title: '階段',
            actionId: 'stairs',
            unit: '段',
            toKcal: (units) => units * 6.0 / 30.0,
            planKey: '$ymd:stairs_kcal',
          ),
          const SizedBox(height: 8),
          _ActionReplaceCard(
            title: 'かかと上げ',
            actionId: 'calfRaise',
            unit: '回',
            toKcal: (units) => units * 2.0 / 10.0,
            planKey: '$ymd:calf_raise_kcal',
          ),        ],
      );
    },
  ),
);
}
}

/// 寄り道（歩く）— ログ置換で1件登録
class _DetourInputCard extends StatefulWidget {
final Future<void> Function(double desiredKcal) onReplace;
const _DetourInputCard({required this.onReplace});

@override
State<_DetourInputCard> createState() => _DetourInputCardState();
}

class _DetourInputCardState extends State<_DetourInputCard> {
final TextEditingController _noteCtrl = TextEditingController();
int _value = 0;
bool _init = false;

@override
void dispose() {
_noteCtrl.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final today = DateTime.now();
final ymd = _ymd(today);
final box = Hive.box<int>('activity_targets');
final targetKey = '$ymd:detour_kcal';
final targetKcal = box.get(targetKey, defaultValue: 0) ?? 0;
final targetMinutes = CalorieService.kcalToDetourMinutes(targetKcal.toDouble(), weightKg: context.read<AuthProvider>().profile?.weightKg);
if (!_init) {
_value = targetMinutes;
_init = true;
}

final messenger = ScaffoldMessenger.of(context);

return Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('寄り道で歩く', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('今日の目標: $targetMinutes 分'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => _value = (_value - 1).clamp(0, 999999)),
            ),
            Text('$_value 分', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _value = (_value + 1).clamp(0, 999999)),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final m = _value;
                if (m <= 0) {
                  messenger.showSnackBar(const SnackBar(content: Text('分数を1以上にしてください')));
                  return;
                }
                await widget.onReplace(CalorieService.detourMinutesToKcal(m, weightKg: context.read<AuthProvider>().profile?.weightKg)); // 4kcal/分
                if (!mounted) return;
                messenger.showSnackBar(
                SnackBar(content: Text('寄り道 +$m 分（約 ${(m * 4).toStringAsFixed(1)}kcal）を記録しました')),
                );
              },
              child: const Text('記録'),
            ),
          ],
        ),
      ],
    ),
  ),
);
}
}

/// 4種目（単位→kcal換算で登録）：ログ置換で1件登録
class _ActionReplaceCard extends StatefulWidget {
final String title;
final String actionId;
final String unit;
final double Function(int units) toKcal;
final String planKey;
const _ActionReplaceCard({
required this.title,
required this.actionId,
required this.unit,
required this.toKcal,
required this.planKey,
});
@override
State<_ActionReplaceCard> createState() => _ActionReplaceCardState();
}

class _ActionReplaceCardState extends State<_ActionReplaceCard> {
final TextEditingController _noteCtrl = TextEditingController();
int _value = 0;
bool _init = false;

@override
void dispose() {
_noteCtrl.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final today = DateTime.now();
final ymd = _ymd(today);
final box = Hive.box<int>('activity_targets');
final targetKcal = box.get(widget.planKey, defaultValue: 0) ?? 0;

int kcalToUnits(int kcal) {
  final w = context.read<AuthProvider>().profile?.weightKg;
  switch (widget.actionId) {
    case 'walk_fast': return CalorieService.kcalToFastWalkSeconds(kcal.toDouble(), weightKg: w);
    case 'stairs':    return CalorieService.kcalToStairsSteps(kcal.toDouble(), weightKg: w);
    case 'highKnee':  return CalorieService.kcalToHighKneeReps(kcal.toDouble(), weightKg: w);
    case 'calfRaise': return CalorieService.kcalToCalfRaiseReps(kcal.toDouble(), weightKg: w);
    default:          return kcal;
  }
}

if (!_init) {
  _value = kcalToUnits(targetKcal);
  _init = true;
}

final messenger = ScaffoldMessenger.of(context);

return Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Row(
          children: [
                Text('今日の目標: ${kcalToUnits(targetKcal)} ${widget.unit}（${targetKcal.toString()}kcal）'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => _value = (_value - 1).clamp(0, 999999)),
            ),
            Text('$_value ${widget.unit}', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _value = (_value + 1).clamp(0, 999999)),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final n = _value;
                if (n <= 0) {
                  messenger.showSnackBar(const SnackBar(content: Text('数値を1以上にしてください')));
                  return;
                }
                final desired = _unitsToKcal(widget.actionId, n, weightKg: context.read<AuthProvider>().profile?.weightKg); // double kcal

                // 同日同種目の既存ログを削除 → desired で1件登録
                final boxLog = Hive.box<ActivityLog>('activity_logs');
                final keysToDelete = <dynamic>[];
                boxLog.toMap().cast<dynamic, ActivityLog>().forEach((key, value) {
                  if (value.ymd == ymd && value.actionId == widget.actionId) {
                    keysToDelete.add(key);
                  }
                });
                if (keysToDelete.isNotEmpty) {
                  await boxLog.deleteAll(keysToDelete);
                }
                // 登録（複数件ではなく1件）
                final log = ActivityLog(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  date: DateTime(today.year, today.month, today.day),
                  actionId: widget.actionId,
                  amount: 1,
                  estKcal: desired,
                  note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                  timestamp: DateTime.now(),
                );
                await Hive.box<ActivityLog>('activity_logs').put(log.id, log);

                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('${widget.title} を記録しました（i+${desired.toStringAsFixed(1)}kcal）')),
                );
              },
              child: const Text('記録'),
            ),
          ],
        ),
      ],
    ),
  ),
);
}
}
