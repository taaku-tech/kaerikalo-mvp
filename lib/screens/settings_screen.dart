import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goal_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final goal = context.watch<GoalProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('初期目標（暫定）: ${goal.targetKcal} kcal'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => context.read<GoalProvider>().setTarget(300),
              child: const Text('初期目標を300kcalに'),
            ),
          ],
        ),
      ),
    );
  }
}
