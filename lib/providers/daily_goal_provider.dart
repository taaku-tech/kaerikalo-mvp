import 'package:flutter/foundation.dart';

import '../models/daily_goal.dart';
import '../repositories/daily_goal_repository.dart';

class DailyGoalProvider extends ChangeNotifier {
  DailyGoal? _today;

  DailyGoal? get current => _today;

  /// 今日の DailyGoal を取得（なければ初期化）
  Future<DailyGoal> today() async {
    final now = DateTime.now();
    final existing = DailyGoalRepository.getByDate(now);
    if (existing != null) {
      _today = existing;
      return existing;
    }
    final created = DailyGoal(
      date: DateTime(now.year, now.month, now.day),
      targetKcal: 200,
      source: GoalSource.custom,
    );
    await DailyGoalRepository.put(created);
    _today = created;
    notifyListeners();
    return created;
  }

  Future<void> save(DailyGoal goal) async {
    await DailyGoalRepository.put(goal);
    _today = goal;
    notifyListeners();
  }

  /// 日跨ぎで今日のGoalを生成
  Future<DailyGoal> resetToday() async {
    _today = null;
    return today();
  }
}
