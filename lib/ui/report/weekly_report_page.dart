import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/activity_log.dart';
import '../../models/daily_goal.dart';
import '../../services/weekly_report_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/calorie_service.dart';

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = WeeklyReportService.weekStartOf(DateTime.now());
  }

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('週次レポート'),
        actions: [
          Builder(builder: (context) {
            final report = WeeklyReportService.generate(
              _weekStart,
              weightKg: context.read<AuthProvider>().profile?.weightKg,
            );
            final rangeText = _formatRange(report.start, report.end);
            return IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final msg = _shareText(report, rangeText);
                Share.share(msg);
              },
            );
          })
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ActivityLog>('activity_logs').listenable(),
        builder: (context, _, __) {
          return ValueListenableBuilder(
            valueListenable: Hive.box<DailyGoal>('daily_goals').listenable(),
            builder: (context, __, ___) {
              final report = WeeklyReportService.generate(
                _weekStart,
                weightKg: context.read<AuthProvider>().profile?.weightKg,
              );
              final rangeText = _formatRange(report.start, report.end);
              final maxKcal = (report.trend
                      .map((e) => e.kcal)
                      .fold<double>(0, (p, e) => e > p ? e : p))
                  .clamp(1, double.infinity);

              // 直近1年/半年の合計kcal
              final logsBox = Hive.box<ActivityLog>('activity_logs');
              final now = DateTime.now();
              final yearAgo = DateTime(now.year - 1, now.month, now.day);
              final halfYearAgo = now.subtract(const Duration(days: 182));
              final monthAgo = now.subtract(const Duration(days: 30));
              double sumKcalInRange(DateTime from, DateTime to) {
                return logsBox.values
                    .whereType<ActivityLog>()
                    .where((e) => !e.date.isBefore(from) && !e.date.isAfter(to))
                    .fold<double>(0.0, (s, e) => s + e.estKcal);
              }
              final yearKcal = sumKcalInRange(yearAgo, now);
              final halfYearKcal = sumKcalInRange(halfYearAgo, now);
              final monthKcal = sumKcalInRange(monthAgo, now);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevWeek,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            rangeText,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextWeek,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 合計
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('合計',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('遠回り（分）：${report.stepsTotal}'),
                          Text('もも上げ（回）：${report.highKneeTotal}'),
                          Text('早歩き（秒）：${report.walkFastTotal}'),
                          Text('階段（段）：${report.stairsTotal}'),
                          Text('かかと上げ（回）：${report.calfRaiseTotal}'),
                          const SizedBox(height: 8),
                          Text('今週の合計：${report.kcalTotal.toStringAsFixed(1)} kcal'),
                          Text('直近1ヶ月の合計：${monthKcal.toStringAsFixed(1)} kcal'),
                          Text('直近半年の合計：${halfYearKcal.toStringAsFixed(1)} kcal'),
                          Text('直近1年の合計：${yearKcal.toStringAsFixed(1)} kcal'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 1週間の推移（バー + 日別）
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('1週間の推移 (kcal)'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // 縦軸（最大/0）
                            Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(maxKcal.toStringAsFixed(1)),
                                    SizedBox(height: 120),
                                    const Text('0'),
                                  ],
                                ),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      for (final d in report.trend)
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                // ツールチップで詳細を表示
                                                Tooltip(
                                                  message: _buildTooltipMessage(context, d),
                                                  padding: const EdgeInsets.all(8),
                                                  margin: const EdgeInsets.all(8),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      // 当日の実績kcal（小数1桁）
                                                      Text(d.kcal.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                                                      const SizedBox(height: 2),
                                                      Container(
                                                        height: (d.kcal / maxKcal) * 120 + 1,
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // 日付 M/D + 曜日 と 当日の達成率
                                                Builder(builder: (context) {
                                                  final goalsBox = Hive.box<DailyGoal>('daily_goals');
                                                  final g = goalsBox.get(_ymd(d.date));
                                                  final tgt = g?.targetKcal ?? 300;
                                                  final dayPct = tgt <= 0 ? 0.0 : (d.kcal / tgt) * 100.0;
                                                  return Text('${_dateWithWeekday(d.date)}\n(${dayPct.toStringAsFixed(1)}%)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11));
                                                }),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _buildTooltipMessage(BuildContext context, DailyTrendEntry d) {
    final logsBox = Hive.box<ActivityLog>('activity_logs');
    double sumK(String id) => logsBox.values
        .whereType<ActivityLog>()
        .where((e) => _ymd(e.date) == _ymd(d.date) && e.actionId == id)
        .fold<double>(0.0, (s, e) => s + e.estKcal);

    final w = context.read<AuthProvider>().profile?.weightKg;
    final walkMin = CalorieService.kcalToDetourMinutes(sumK('walk'), weightKg: w);
    final hkReps = CalorieService.kcalToHighKneeReps(sumK('highKnee'), weightKg: w);
    final wfSec = CalorieService.kcalToFastWalkSeconds(sumK('walk_fast'), weightKg: w);
    final stSteps = CalorieService.kcalToStairsSteps(sumK('stairs'), weightKg: w);
    final crReps = CalorieService.kcalToCalfRaiseReps(sumK('calfRaise'), weightKg: w);

    final details = <String>[];
    if (walkMin > 0) details.add('遠回り: $walkMin分');
    if (hkReps > 0) details.add('もも上げ: $hkReps回');
    if (wfSec > 0) details.add('早歩き: $wfSec秒');
    if (stSteps > 0) details.add('階段: $stSteps段');
    if (crReps > 0) details.add('かかと上げ: $crReps回');

    if (details.isEmpty) {
      return 'アクティビティの記録がありません';
    }

    return details.join('\n');
  }

  String _formatRange(DateTime s, DateTime e) {
    return '${_ymd(s)} ~ ${_ymd(e)}';
  }

  String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _dateWithWeekday(DateTime d) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    final yobi = labels[d.weekday - 1];
    return '${d.month}/${d.day}\n($yobi)';
  }

  String _shareText(WeeklyReportResult r, String rangeText) {
    final buf = StringBuffer();
    buf.writeln('【週次レポート】 $rangeText');
    buf.writeln(
        '遠回り:${r.stepsTotal}分  もも上げ:${r.highKneeTotal}回  早歩き:${r.walkFastTotal}秒  階段:${r.stairsTotal}段  かかと上げ:${r.calfRaiseTotal}回');
    buf.writeln(
        '合計:${r.kcalTotal.toStringAsFixed(1)}kcal  平均達成率:${(r.avgProgress * 100).toStringAsFixed(1)}%');
    for (final d in r.trend) {
      buf.writeln('${_ymd(d.date)} kcal:${d.kcal.toStringAsFixed(1)}');
    }
    return buf.toString();
  }
}
