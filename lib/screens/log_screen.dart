import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';
import '../data/presets.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('実績入力')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('消費 ${goal.burnedKcal} / 目標 ${goal.targetKcal} kcal'),
          const SizedBox(height: 12),
          for (final a in microActions)
            Card(
              child: ListTile(
                title: Text(a.name),
                subtitle: Text(a.exampleText),
                trailing: Text('+${a.kcalPerUnit.toStringAsFixed(0)}kcal'),
                onTap: () => context.read<GoalProvider>().addBurned(a.kcalPerUnit.round()),
              ),
            ),
        ],
      ),
    );
  }
}
