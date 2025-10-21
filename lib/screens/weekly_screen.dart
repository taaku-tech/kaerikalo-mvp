import 'package:flutter/material.dart';

class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // MVPではダミー表示：後で履歴集計に差し替え
    return Scaffold(
      appBar: AppBar(title: const Text('週レポート')),
      body: const Center(child: Text('今週：達成3日 / 累計 950kcal（例）')),
    );
  }
}
