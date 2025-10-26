import 'package:hive/hive.dart';

import '../models/app_prefs.dart';
import '../models/daily_goal.dart';
import '../models/activity_log.dart';
import '../models/daily_summary.dart';
import '../repositories/app_prefs_repository.dart';
import '../repositories/daily_goal_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/daily_summary_repository.dart';
import '../providers/goal_provider.dart';

class BootstrapService {
  static Future<void> migrateIfNeeded(GoalProvider legacy) async {
    final prefs = AppPrefsRepository.get();
    if (prefs?.migratedToHive == true) return;

    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    // Migrate DailyGoal from legacy target
    final target = legacy.targetKcal;
    final goal = DailyGoal(date: dateOnly, targetKcal: target, source: GoalSource.custom);
    await DailyGoalRepository.put(goal);

    // Migrate burnedKcal into a synthetic ActivityLog if any
    if (legacy.burnedKcal > 0) {
      final log = ActivityLog(
        id: 'migrated_${DateTime.now().microsecondsSinceEpoch}',
        date: dateOnly,
        actionId: 'other',
        amount: 1,
        estKcal: legacy.burnedKcal.toDouble(),
        note: 'migrated',
        timestamp: today,
      );
      await ActivityRepository.addLog(log);
    }

    // Upsert DailySummary for today
    final burned = ActivityRepository
        .fetchByDate(dateOnly)
        .fold<double>(0.0, (s, e) => s + e.estKcal);
    final summary = DailySummary(date: dateOnly, targetKcal: target, burnedKcal: burned);
    await DailySummaryRepository.upsert(summary);

    // Set migrated flag
    final updated = (prefs ?? const AppPrefs()).copyWith(migratedToHive: true);
    await AppPrefsRepository.save(updated);
  }

  static Future<void> clearAllBoxes() async {
    // Best-effort clear open boxes
    final futures = <Future<void>>[];
    for (final name in const ['daily_goals', 'activity_logs', 'daily_summaries', 'app_prefs']) {
      if (Hive.isBoxOpen(name)) {
        futures.add(Hive.box(name).clear());
      } else if (await Hive.boxExists(name)) {
        final box = await Hive.openBox(name);
        futures.add(box.clear());
      }
    }
    await Future.wait(futures);
  }
}
