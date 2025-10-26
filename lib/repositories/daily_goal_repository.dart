import 'package:hive/hive.dart';

import '../data/repo.dart';
import '../models/daily_goal.dart';

class DailyGoalRepository {
  static const String boxName = 'daily_goals';

  static Box<DailyGoal> get _box => Hive.box<DailyGoal>(boxName);

  static Future<void> put(DailyGoal goal) async {
    await _box.put(goal.ymd, goal);
  }

  static DailyGoal? getByDate(DateTime date) {
    return _box.get(Repo.ymd(date));
  }
}

