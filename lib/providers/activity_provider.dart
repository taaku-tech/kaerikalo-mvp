import 'package:flutter/foundation.dart';

import '../models/activity_log.dart';
import '../models/daily_summary.dart';
import '../repositories/activity_repository.dart';
import '../repositories/daily_goal_repository.dart';
import '../repositories/daily_summary_repository.dart';

class ActivityProvider extends ChangeNotifier {
  /// 係数マップ（暫定）
  static const double _kcalPerStep = 0.04; // walk
  static const double _kcalPerStair = 0.3; // stairs (per step)
  static const double _kcalPerMicro = 10.0; // highKnee/calfRaise/other per count

  Future<void> add(ActivityType type, int amount, {String? note}) async {
    final now = DateTime.now();
    final est = _estimate(type, amount);
    final log = ActivityLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime(now.year, now.month, now.day),
      actionId: type.name,
      amount: amount,
      estKcal: est,
      note: note,
      timestamp: now,
    );

    await ActivityRepository.addLog(log);

    // 再計算して DailySummary を upsert
    await _recalculateAndUpsertSummary(now);

    notifyListeners();
  }

  Future<void> addFixedKcal(String actionId, double kcal, {String? note}) async {
    final now = DateTime.now();
    final log = ActivityLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime(now.year, now.month, now.day),
      actionId: actionId,
      amount: 1,
      estKcal: kcal,
      note: note,
      timestamp: now,
    );
    await ActivityRepository.addLog(log);
    await _recalculateAndUpsertSummary(now);
    notifyListeners();
  }

  double progressToday() {
    final now = DateTime.now();
    final goal = DailyGoalRepository.getByDate(now);
    final target = goal?.targetKcal ?? 300;
    final burned = ActivityRepository
        .fetchByDate(now)
        .fold<double>(0.0, (s, e) => s + e.estKcal);
    if (target <= 0) return 0.0;
    final r = burned / target;
    return r.clamp(0.0, 1.0);
  }

  Future<void> clearTodayAndRecalc() async {
    final today = DateTime.now();
    await ActivityRepository.deleteByDate(today);
    await _recalculateAndUpsertSummary(today);
    notifyListeners();
  }

  double _estimate(ActivityType type, int amount) {
    switch (type) {
      case ActivityType.walk:
        return amount * _kcalPerStep;
      case ActivityType.stairs:
        return amount * _kcalPerStair;
      case ActivityType.highKnee:
      case ActivityType.calfRaise:
      case ActivityType.other:
        return amount * _kcalPerMicro / 10 * 2.5;
    }
  }

  Future<void> _recalculateAndUpsertSummary(DateTime when) async {
    final dateOnly = DateTime(when.year, when.month, when.day);
    final burned = ActivityRepository
        .fetchByDate(dateOnly)
        .fold<double>(0.0, (s, e) => s + e.estKcal);
    final target = (DailyGoalRepository.getByDate(dateOnly)?.targetKcal) ?? 300;
    final summary = DailySummary(
      date: dateOnly,
      targetKcal: target,
      burnedKcal: burned,
    );
    await DailySummaryRepository.upsert(summary);
  }
}
