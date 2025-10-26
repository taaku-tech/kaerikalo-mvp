import 'package:flutter/foundation.dart';
import '../data/repo.dart';
import '../models/daily_goal.dart';
import '../models/action_log.dart';

class GoalProvider extends ChangeNotifier {
  int targetKcal = 200; // デフォルト
  int burnedKcal = 0;

  void setTarget(int kcal) {
    targetKcal = kcal;
    notifyListeners();
  }

  void addBurned(int kcal) {
    burnedKcal += kcal;
    notifyListeners();
  }

  double get achievedRate =>
      targetKcal == 0 ? 0 : (burnedKcal / targetKcal).clamp(0, 1).toDouble();

   void resetToday() {
    burnedKcal = 0;
    notifyListeners();
  }

  Future<void> loadToday() async {
    final today = DateTime.now();
    final key = Repo.ymd(today);
    final saved = Repo.getGoalByYmd(key);
    if (saved != null) {
      targetKcal = saved.targetKcal;
    }
    final sum = Repo.sumBurnedByYmd(key);
    burnedKcal = sum.round();
    notifyListeners();
  }

  Future<void> saveToday() async {
    final today = DateTime.now();
    final goal = DailyGoal(
      date: DateTime(today.year, today.month, today.day),
      targetKcal: targetKcal,
      source: GoalSource.custom,
    );
    await Repo.putGoal(goal);
  }

  Future<void> appendLog(ActionLog log) async {
    await Repo.addLog(log);
    final key = Repo.ymd(DateTime.now());
    final sum = Repo.sumBurnedByYmd(key);
    burnedKcal = sum.round();
    notifyListeners();
  }
}
