import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import '../providers/daily_goal_provider.dart';
import '../providers/activity_provider.dart';
import '../models/daily_goal.dart';
import '../data/presets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final TextEditingController _kcalCtrl;
  bool _kcalInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final goalProv = context.read<DailyGoalProvider>();
    Future.microtask(() => goalProv.today());
    _kcalCtrl = TextEditingController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kcalCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDateRollOver();
    }
  }

  Future<void> _checkDateRollOver() async {
    final goalProv = context.read<DailyGoalProvider>();
    final current = goalProv.current;
    final now = DateTime.now();
    if (current == null) {
      await goalProv.today();
      return;
    }
    final isSameDay = current.date.year == now.year &&
        current.date.month == now.month &&
        current.date.day == now.day;
    if (!isSameDay) {
      await goalProv.resetToday();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalProv = context.watch<DailyGoalProvider>();
    final target = goalProv.current?.targetKcal ?? 300;

    final planned = _plannedKcalSum();
    final remain = (target - planned).clamp(0, 999999);

    if (!_kcalInitialized && target > 0) {
      _kcalCtrl.text = target.toString();
      _kcalInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('カエリカロ：帰り道で、ついでに運動')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 本日の目標
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('本日の目標', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('クリア'),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final activity = context.read<ActivityProvider>();
                          final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('実績をクリア'),
                                  content: const Text('今日の実績（実際消費）を0に戻します。よろしいですか？'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => navigator.pop(false),
                                        child: const Text('キャンセル')),
                                    FilledButton(
                                        onPressed: () => navigator.pop(true),
                                        child: const Text('OK')),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!ok) return;
                          await activity.clearTodayAndRecalc();
                          // 計画消費もリセット（当日キーを削除）
                          final box = Hive.box<int>('activity_targets');
                          final ymd = _ymd(DateTime.now());
                          final keys = box.keys.whereType<String>().where((k) => k.startsWith(ymd)).toList();
                          for (final k in keys) {
                            await box.delete(k);
                          }
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('今日の実績をクリアしました')),
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final f in defaultFoods)
                        ActionChip(
                          label: Text('${f.name}（${f.kcal}kcal）'),
                          onPressed: () async {
                            final now = DateTime.now();
                            final messenger = ScaffoldMessenger.of(context);
                            await goalProv.save(
                              (goalProv.current ??
                                      DailyGoal(
                                        date: DateTime(now.year, now.month, now.day),
                                        targetKcal: f.kcal,
                                        source: GoalSource.custom,
                                      ))
                                  .copyWith(targetKcal: f.kcal),
                            );
                            if (!mounted) return;
                            _kcalCtrl.text = f.kcal.toString();
                            messenger.showSnackBar(const SnackBar(content: Text('目標を更新しました')));
                          },
                        ),
                      ActionChip(
                        label: const Text('200kcal'),
                        onPressed: () async {
                          final now = DateTime.now();
                          final messenger = ScaffoldMessenger.of(context);
                          await goalProv.save(
                            (goalProv.current ??
                                    DailyGoal(
                                      date: DateTime(now.year, now.month, now.day),
                                      targetKcal: 200,
                                      source: GoalSource.custom,
                                    ))
                                .copyWith(targetKcal: 200),
                          );
                          if (!mounted) return;
                          _kcalCtrl.text = '200';
                          messenger.showSnackBar(const SnackBar(content: Text('目標を更新しました')));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _kcalCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: '目標kcal',
                            suffixText: 'kcal',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final txt = _kcalCtrl.text.trim();
                          final v = int.tryParse(txt);
                          if (v == null) {
                            messenger.showSnackBar(const SnackBar(content: Text('数値を入力してください')));
                            return;
                          }
                          final now = DateTime.now();
                          await goalProv.save(
                            (goalProv.current ??
                                    DailyGoal(
                                      date: DateTime(now.year, now.month, now.day),
                                      targetKcal: v,
                                      source: GoalSource.custom,
                                    ))
                                .copyWith(targetKcal: v),
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(const SnackBar(content: Text('目標を更新しました')));
                        },
                        child: const Text('更新'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('目標 $target kcal / 計画消費 $planned kcal'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: target == 0 ? 0 : (planned / target).clamp(0, 1).toDouble(),
                  ),
                  const SizedBox(height: 8),
                  Text('残り ${remain}kcal'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 今日のおすすめ（計画）
          Text('今日のおすすめ「ちょい運動」', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // 追加: 選択済み一覧（ある場合のみ）
          Builder(
            builder: (context) {
              final ymd = _ymd(DateTime.now());
              final box = Hive.box<int>('activity_targets');
              final entries = <(String id, String title)>[
                ('walk', '遠回りで帰宅（歩行）'),
                ('highKnee', 'もも上げ'),
                ('walk_fast', '早歩き'),
                ('stairs', '階段'),
                ('calfRaise', 'かかと上げ'),
              ];
              // 単位
              String unitFor(String id) {
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

              // 表示用: kcal→単位換算（最後に丸め）
              int kcalToUnits(String id, int kcal) {
                switch (id) {
                  case 'walk':
                    return (kcal / 4).round();
                  case 'walk_fast':
                    return (kcal * 12).round();
                  case 'stairs':
                    return (kcal * 5).round();
                  case 'highKnee':
                    return (kcal * (10 / 3)).round();
                  case 'calfRaise':
                    return (kcal * 5).round();
                  default:
                    return kcal;
                }
              }

              final selected = <Widget>[];
              for (final e in entries) {
                final id = e.$1;
                final title = e.$2;
                final pk = box.get('$ymd:${_planKeyForId(id)}', defaultValue: 0) ?? 0;
                if (pk > 0) {
                  final unit = unitFor(id);
                  final units = kcalToUnits(id, pk);
                  selected.add(Text('$title: $units$unit（${pk}kcal）'));
                }
              }

              if (selected.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('今日のおすすめ（選択済みの計画）', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...selected,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // 遠回りで帰宅（計画に追加）
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text('遠回りで帰宅'),
              subtitle: const Text('＋10〜30分程度、大回りして帰る'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final minutes = await showModalBottomSheet<int>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 地図プレースホルダー
                          Container(
                            height: 140,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('自宅までの経路（地図は今後実装予定）'),
                          ),
                          const SizedBox(height: 16),
                          const Text('大回りの時間を選択', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final m in [10, 20, 30])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: FilledButton(
                                      onPressed: () => Navigator.of(ctx).pop(m),
                                      child: Text('+$m分（約${(m * 4).toStringAsFixed(0)}kcal）'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (minutes == null) return;
                final box = Hive.box<int>('activity_targets');
                final add = minutes * 4;
                // 遠回りは detour_kcal のみに反映（plan_total には書かない）
                final detourKey = '${_ymd(DateTime.now())}:detour_kcal';
                final detourVal = (box.get(detourKey) ?? 0) + add;
                await box.put(detourKey, detourVal);
                if (!mounted) return;
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(content: Text('計画に +$add kcal を追加しました')),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 他の4項目（計画に追加）
          ...['high_knee', 'walk_fast', 'stairs', 'calf_raise'].map((id) {
            final a = microActions.firstWhere((e) => e.id == id);
            final add = a.kcalPerUnit.round();
            return Card(
              child: ListTile(
                title: Text(a.name),
                subtitle: Text(a.exampleText),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final box = Hive.box<int>('activity_targets');
                  final key = '${_ymd(DateTime.now())}:${id}_kcal';
                  final v = (box.get(key) ?? 0) + add;
                  await box.put(key, v);
                  if (!mounted) return;
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(content: Text('計画に +${add}kcal を追加しました（${a.name}）')),
                  );
                },
              ),
            );
          }),

          const SizedBox(height: 12),

          // 別途追加（任意のショートカット）
          Text('別途追加', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final box = Hive.box<int>('activity_targets');
                    // 遠回りは detour_kcal のみに反映
                    final detourKey = '${_ymd(DateTime.now())}:detour_kcal';
                    final dv = (box.get(detourKey) ?? 0) + 4;
                    await box.put(detourKey, dv);
                    if (!mounted) return;
                    setState(() {});
                    messenger.showSnackBar(
                      const SnackBar(content: Text('計画に +4kcal を追加しました（遠回り）')),
                    );
                  },
                  child: const Text('遠回り：+100歩(+4kcal)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final box = Hive.box<int>('activity_targets');
                    final key = '${_ymd(DateTime.now())}:stairs_kcal';
                    final v = (box.get(key) ?? 0) + 3;
                    await box.put(key, v);
                    if (!mounted) return;
                    setState(() {});
                    messenger.showSnackBar(
                      const SnackBar(content: Text('計画に +3kcal を追加しました（階段）')),
                    );
                  },
                  child: const Text('階段：+15段(+3kcal)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final box = Hive.box<int>('activity_targets');
                    final key = '${_ymd(DateTime.now())}:walk_fast_kcal';
                    final v = (box.get(key) ?? 0) + 2;
                    await box.put(key, v);
                    if (!mounted) return;
                    setState(() {});
                    messenger.showSnackBar(
                      const SnackBar(content: Text('計画に +2kcal を追加しました（早歩き）')),
                    );
                  },
                  child: const Text('早歩き：+30秒(+2kcal)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 当日キー
String _ymd(DateTime dt) {
  final d = DateTime(dt.year, dt.month, dt.day);
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// 計画の保存キー（HOME/LOGで共通の規則を使用）
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

// 計画消費（合計）
int _plannedKcalSum() {
  if (!Hive.isBoxOpen('activity_targets')) return 0;
  final box = Hive.box<int>('activity_targets');
  final ymd = _ymd(DateTime.now());
  // 当日の全キーを合計（plan_total があっても他キーと合算）
  int sum = 0;
  for (final k in box.keys.whereType<String>()) {
    if (k.startsWith(ymd)) {
      sum += box.get(k, defaultValue: 0) ?? 0;
    }
  }
  return sum;
}
