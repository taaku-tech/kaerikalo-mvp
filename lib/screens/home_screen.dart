import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../data/presets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalProvider>();
    final ratePct = (goal.achievedRate * 100).toStringAsFixed(0);
    final remain = (goal.targetKcal - goal.burnedKcal).clamp(0, 9999);

    // 提案を3件ランダムに
    final rnd = microActions.toList()..shuffle(Random());
    final suggestions = rnd.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('今日の目標1')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 目標カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本日の目標2', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in defaultFoods.take(3))
                        ActionChip(
                          label: Text('${f.name}(${f.kcal}kcal)'),
                          onPressed: () => context.read<GoalProvider>().setTarget(f.kcal),
                        ),
                      ActionChip(
                        label: const Text('200kcal'),
                        onPressed: () => context.read<GoalProvider>().setTarget(200),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('目標 ${goal.targetKcal} kcal / 消費 ${goal.burnedKcal} kcal'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: goal.achievedRate),
                  const SizedBox(height: 8),
                  Text('達成率 $ratePct%　残り ${remain}kcal'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 提案カード
          Text('今日のおすすめ「ついで運動」', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final a in suggestions)
            Card(
              child: ListTile(
                title: Text(a.name),
                subtitle: Text(a.exampleText),
                trailing: Text('≈${a.kcalPerUnit.toStringAsFixed(0)}kcal/${a.unitLabel}'),
                onTap: () {
                  // 1単位分を即加算（MVP）
                  context.read<GoalProvider>().addBurned(a.kcalPerUnit.round());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${a.name} を1${a.unitLabel}記録しました')),
                  );
                },
              ),
            ),

          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.read<GoalProvider>().resetToday(),
            child: const Text('今日の消費をリセット'),
          ),
        ],
      ),
    );
  }
}
