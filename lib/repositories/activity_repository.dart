import 'package:hive/hive.dart';

import '../data/repo.dart';
import '../models/activity_log.dart';

class ActivityRepository {
  static const String boxName = 'activity_logs';

  static Box<ActivityLog> get _box => Hive.box<ActivityLog>(boxName);

  static Future<void> addLog(ActivityLog log) async {
    await _box.put(log.id, log);
  }

  static List<ActivityLog> fetchByDate(DateTime date) {
    final key = Repo.ymd(date);
    final list = _box.values.where((e) => e.ymd == key).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  static List<ActivityLog> fetchBetween(DateTime start, DateTime end) {
    final startD = DateTime(start.year, start.month, start.day);
    final endD = DateTime(end.year, end.month, end.day);
    final res = _box.values.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(startD) && !d.isAfter(endD);
    }).toList();
    res.sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      return a.timestamp.compareTo(b.timestamp);
    });
    return res;
  }

  static Future<int> deleteByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDayExclusive = startOfDay.add(const Duration(days: 1));

    // Collect keys (ids) whose timestamp falls within the day
    final keys = _box.values
        .where((e) => !e.timestamp.isBefore(startOfDay) && e.timestamp.isBefore(endOfDayExclusive))
        .map((e) => e.id)
        .toList();

    if (keys.isEmpty) return 0;
    await _box.deleteAll(keys);
    return keys.length;
  }
}
