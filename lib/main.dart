import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/goal_provider.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/weekly_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalProvider()),
      ],
      child: const KaerikaroApp(),
    ),
  );
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

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});
  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int idx = 0;
  final pages = const [
    HomeScreen(),
    LogScreen(),
    WeeklyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Log'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Weekly'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
