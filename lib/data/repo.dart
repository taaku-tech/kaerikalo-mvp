import 'package:hive/hive.dart';

import '../models/daily_goal.dart';
import '../models/action_log.dart';

class Repo {
  static const String dailyGoalBoxName = 'daily_goals';
  static const String actionLogsBoxName = 'activity_logs';

  static Box<DailyGoal> get _goals => Hive.box<DailyGoal>(dailyGoalBoxName);
  static Box<ActionLog> get _logs => Hive.box<ActionLog>(actionLogsBoxName);

  static String ymd(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // Goal CRUD
  static DailyGoal? getGoalByYmd(String ymd) {
    return _goals.get(ymd);
  }

  static Future<void> putGoal(DailyGoal goal) async {
    await _goals.put(goal.ymd, goal);
  }

  // Logs CRUD
  static Future<void> addLog(ActionLog log) async {
    await _logs.put(log.id, log);
  }

  static Future<void> removeLog(String id) async {
    await _logs.delete(id);
  }

  static Iterable<ActionLog> listLogsByYmd(String ymd) {
    return _logs.values.where((e) => e.ymd == ymd);
  }

  static double sumBurnedByYmd(String ymd) {
    return listLogsByYmd(ymd).fold<double>(0.0, (sum, e) => sum + e.estKcal);
  }
}
