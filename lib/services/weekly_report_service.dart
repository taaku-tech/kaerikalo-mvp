import '../repositories/activity_repository.dart';
import '../repositories/daily_goal_repository.dart';
import '../data/repo.dart';
import 'calorie_service.dart';

/// 週次レポートの集計結果
class WeeklyReportResult {
  final DateTime start;
  final DateTime end;

  // 1週間合計（単位換算後の合計）
  final int stepsTotal;       // 遠回りで歩く（walk）→ 分
  final int stairsTotal;      // 階段（stairs）→ 段
  final int microTotal;       // その他（後方互換／現状未使用）
  final int highKneeTotal;    // もも上げ（highKnee）→ 回
  final int walkFastTotal;    // 早歩き（walk_fast）→ 秒
  final int calfRaiseTotal;   // かかと上げ（calfRaise）→ 回

  // 進捗（合計）
  final double avgProgress;   // 0..1（1週間の平均達成率）
  final double kcalTotal;     // 1週間の実績kcal合計

  // 日別トレンド（kcalはdouble）
  final List<DailyTrendEntry> trend;

  const WeeklyReportResult({
    required this.start,
    required this.end,
    required this.stepsTotal,
    required this.stairsTotal,
    required this.microTotal,
    required this.highKneeTotal,
    required this.walkFastTotal,
    required this.calfRaiseTotal,
    required this.avgProgress,
    required this.kcalTotal,
    required this.trend,
  });
}

/// 日別の表示用エントリ（従来互換の簡易カラム）
class DailyTrendEntry {
  final DateTime date;
  final int steps;     // 表示用途（従来互換）：ここでは「分」（walk）
  final int stairs;    // 表示用途（従来互換）：ここでは「段」（stairs）
  final int micro;     // 表示用途（従来互換）：その他の数え上げ
  final double kcal;   // 当日kcal合計
  const DailyTrendEntry({
    required this.date,
    required this.steps,
    required this.stairs,
    required this.micro,
    required this.kcal,
  });
}

class WeeklyReportService {
  /// 週の開始（月曜始まり）
  static DateTime weekStartOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final weekday = d.weekday; // 1(Mon) .. 7(Sun)
    return d.subtract(Duration(days: weekday - 1));
  }

  // 単位換算：kcal → 各単位
  static int _kcalToMinutes(double kcal, {double? weightKg}) =>
      CalorieService.kcalToDetourMinutes(kcal, weightKg: weightKg);
  static int _kcalToSeconds(double kcal, {double? weightKg}) =>
      CalorieService.kcalToFastWalkSeconds(kcal, weightKg: weightKg);
  static int _kcalToStairs(double kcal, {double? weightKg}) =>
      CalorieService.kcalToStairsSteps(kcal, weightKg: weightKg);
  static int _kcalToHighKnee(double kcal, {double? weightKg}) =>
      CalorieService.kcalToHighKneeReps(kcal, weightKg: weightKg);
  static int _kcalToCalfRaise(double kcal, {double? weightKg}) =>
      CalorieService.kcalToCalfRaiseReps(kcal, weightKg: weightKg);

  /// 指定週の集計を生成
  static WeeklyReportResult generate(DateTime forWeekStart, {double? weightKg}) {
    final start = DateTime(forWeekStart.year, forWeekStart.month, forWeekStart.day);
    final end = start.add(const Duration(days: 6));

    final logs = ActivityRepository.fetchBetween(start, end);

    int stepsTotal = 0;       // walk → 分
    int stairsTotal = 0;      // stairs → 段
    int microTotal = 0;       // その他（互換）
    int highKneeTotal = 0;    // highKnee → 回
    int walkFastTotal = 0;    // walk_fast → 秒
    int calfRaiseTotal = 0;   // calfRaise → 回
    double kcalTotal = 0.0;

    // 日別集計用マップ
    final dailyMap = <String, DailyTrendEntry>{};
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      dailyMap[Repo.ymd(d)] = DailyTrendEntry(
        date: d,
        steps: 0,
        stairs: 0,
        micro: 0,
        kcal: 0.0,
      );
    }

    // ログ反映
    for (final l in logs) {
      final key = l.ymd;
      final entry = dailyMap[key];
      if (entry == null) continue;

      final kcal = l.estKcal;

      switch (l.actionId) {
        case 'walk': {
          final minutes = _kcalToMinutes(kcal, weightKg: weightKg);
          stepsTotal += minutes;
          dailyMap[key] = DailyTrendEntry(
            date: entry.date,
            steps: entry.steps + minutes,
            stairs: entry.stairs,
            micro: entry.micro,
            kcal: entry.kcal + kcal,
          );
          break;
        }
        case 'stairs': {
          final stairs = _kcalToStairs(kcal, weightKg: weightKg);
          stairsTotal += stairs;
          dailyMap[key] = DailyTrendEntry(
            date: entry.date,
            steps: entry.steps,
            stairs: entry.stairs + stairs,
            micro: entry.micro,
            kcal: entry.kcal + kcal,
          );
          break;
        }
        case 'highKnee': {
          final repsHK = _kcalToHighKnee(kcal, weightKg: weightKg);
          highKneeTotal += repsHK;
          dailyMap[key] = DailyTrendEntry(
            date: entry.date,
            steps: entry.steps,
            stairs: entry.stairs,
            micro: entry.micro + repsHK, // micro列は「その他カウント」を簡易表示として流用
            kcal: entry.kcal + kcal,
          );
          break;
        }
        case 'walk_fast': {
          final secs = _kcalToSeconds(kcal, weightKg: weightKg);
          walkFastTotal += secs;
          dailyMap[key] = DailyTrendEntry(
            date: entry.date,
            steps: entry.steps,
            stairs: entry.stairs,
            micro: entry.micro + secs,
            kcal: entry.kcal + kcal,
          );
          break;
        }
        case 'calfRaise': {
          final repsCR = _kcalToCalfRaise(kcal, weightKg: weightKg);
          calfRaiseTotal += repsCR;
          dailyMap[key] = DailyTrendEntry(
            date: entry.date,
            steps: entry.steps,
            stairs: entry.stairs,
            micro: entry.micro + repsCR,
            kcal: entry.kcal + kcal,
          );
          break;
        }
        default: {
          // 従来仕様の互換用：未知のactionIdは amount をそのまま micro に積む
          final amt = (l.amount is int) ? (l.amount as int) : l.amount.toInt();
          microTotal += amt;
          dailyMap[key] = DailyTrendEntry(
            date: entry.date,
            steps: entry.steps,
            stairs: entry.stairs,
            micro: entry.micro + amt,
            kcal: entry.kcal + kcal,
          );
          break;
        }
      }

      kcalTotal += kcal;
    }

    // 平均達成率（計画に対する実績）※日毎に1.0で打ち止め
    double sumProgress = 0.0;
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      final key = Repo.ymd(d);
      final entry = dailyMap[key]!;
      final target = DailyGoalRepository.getByDate(d)?.targetKcal ?? 200;
      if (target <= 0) {
        sumProgress += 0.0;
      } else {
        sumProgress += (entry.kcal / target).clamp(0.0, 1.0);
      }
    }
    final avgProgress = sumProgress / 7.0;

    final trend = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return WeeklyReportResult(
      start: start,
      end: end,
      stepsTotal: stepsTotal,
      stairsTotal: stairsTotal,
      microTotal: microTotal,
      highKneeTotal: highKneeTotal,
      walkFastTotal: walkFastTotal,
      calfRaiseTotal: calfRaiseTotal,
      avgProgress: avgProgress,
      kcalTotal: kcalTotal,
      trend: trend,
    );
  }

  /// 日別トレンドのみ取り出し
  static List<DailyTrendEntry> dailyTrend(DateTime forWeekStart, {double? weightKg}) {
    return generate(forWeekStart, weightKg: weightKg).trend;
  }
}
