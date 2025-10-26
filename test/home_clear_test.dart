import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kaerikalo_mvp/screens/home_screen.dart';
import 'package:kaerikalo_mvp/providers/activity_provider.dart';
import 'package:kaerikalo_mvp/providers/daily_goal_provider.dart';
import 'package:kaerikalo_mvp/models/daily_goal.dart';

class TestActivityProvider extends ActivityProvider {
  bool cleared = false;
  double _progress = 0.6; // initial non-zero

  @override
  double progressToday() => _progress;

  @override
  Future<void> clearTodayAndRecalc() async {
    cleared = true;
    _progress = 0.0;
    notifyListeners();
  }
}

class TestDailyGoalProvider extends DailyGoalProvider {
  @override
  Future<DailyGoal> today() async {
    // Return a dummy goal without touching Hive.
    final now = DateTime.now();
    return DailyGoal(
      date: DateTime(now.year, now.month, now.day),
      targetKcal: 300,
      source: GoalSource.custom,
    );
  }
}

void main() {
  testWidgets('Clear button resets progress to 0 and shows snackbar', (tester) async {
    final act = TestActivityProvider();
    final goal = TestDailyGoalProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ActivityProvider>.value(value: act),
            ChangeNotifierProvider<DailyGoalProvider>.value(value: goal),
          ],
          child: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the Clear button
    expect(find.text('クリア'), findsOneWidget);
    await tester.tap(find.text('クリア'));
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('実績をクリア'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pump();

    // Provider method called
    expect(act.cleared, isTrue);

    // Progress updated to 0
    final prog = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(prog.value, 0.0);

    // Snackbar shown
    await tester.pump();
    expect(find.text('今日の実績をクリアしました'), findsOneWidget);
  });
}

