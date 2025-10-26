import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/goal_provider.dart';
import 'providers/daily_goal_provider.dart';
import 'providers/activity_provider.dart';

import 'ui/root_tabs.dart';
import 'ui/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'models/user_profile.dart';
import 'repositories/user_profile_repository.dart';

import 'models/daily_goal.dart';
import 'models/activity_log.dart';
import 'models/daily_summary.dart';
import 'models/app_prefs.dart';

import 'services/notification_service.dart';
import 'services/bootstrap_service.dart';
import 'services/auth_service.dart';
import 'services/fake_auth_service.dart';
import 'services/auth_client.dart';
import 'config/app_config.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

await Hive.initFlutter();
await _cleanupLegacyBoxes();

// Register Hive adapters
Hive.registerAdapter(GoalSourceAdapter());
Hive.registerAdapter(DailyGoalAdapter());
Hive.registerAdapter(ActivityTypeAdapter());
Hive.registerAdapter(ActivityLogAdapter());
Hive.registerAdapter(DailySummaryAdapter());
Hive.registerAdapter(AppPrefsAdapter());
Hive.registerAdapter(UserProfileAdapter());

// Open boxes
await Hive.openBox<DailyGoal>('daily_goals');
await Hive.openBox<ActivityLog>('activity_logs');
await Hive.openBox<DailySummary>('daily_summaries');
await Hive.openBox<AppPrefs>('app_prefs');
// Per-action targets (kcal) for today
await Hive.openBox<int>('activity_targets');
await Hive.openBox<UserProfile>(UserProfileRepository.boxName);

// Notifications (skip on Web)
if (!kIsWeb) {
await NotificationService.instance.init();
}

final goalProvider = GoalProvider();
// One-time migration from legacy in-memory values
await BootstrapService.migrateIfNeeded(goalProvider);
await goalProvider.loadToday();

runApp(
MultiProvider(
providers: [
ChangeNotifierProvider.value(value: goalProvider),
ChangeNotifierProvider<DailyGoalProvider>(create: (_) => DailyGoalProvider()),
ChangeNotifierProvider<ActivityProvider>(create: (_) => ActivityProvider()),
ChangeNotifierProvider<AuthProvider>(create: (_) {
  final AuthClient client = AppConfig.useFakeAuth
      ? FakeAuthService()
      : AuthService(baseUrl: AppConfig.apiBaseUrl);
  return AuthProvider(auth: client);
}),
],
child: const KaerikaroApp(),
),
);
}

Future<void> _cleanupLegacyBoxes() async {
if (await Hive.boxExists('action_logs')) {
await Hive.deleteBoxFromDisk('action_logs');
}
}

class KaerikaroApp extends StatelessWidget {
const KaerikaroApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'カエリカロ',
theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2EC4B6)),
home: const RootTabs(),
);
}
}

// RootTabs moved to ui/root_tabs.dart

