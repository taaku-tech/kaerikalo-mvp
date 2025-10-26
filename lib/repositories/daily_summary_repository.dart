import 'package:hive/hive.dart';

import '../data/repo.dart';
import '../models/daily_summary.dart';

class DailySummaryRepository {
  static const String boxName = 'daily_summaries';

  static Box<DailySummary> get _box => Hive.box<DailySummary>(boxName);

  static Future<void> upsert(DailySummary summary) async {
    await _box.put(Repo.ymd(summary.date), summary);
  }

  static DailySummary? getByDate(DateTime date) {
    return _box.get(Repo.ymd(date));
  }

  static List<DailySummary> fetchLastDays(int days) {
    final list = _box.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date)); // 昇順
    if (days >= list.length) return list;
    return list.sublist(list.length - days);
  }
}

