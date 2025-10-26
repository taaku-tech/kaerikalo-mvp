import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';
import '../screens/log_screen.dart';
import '../ui/report/weekly_report_page.dart';
import '../screens/settings_screen.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';

class RootTabs extends StatelessWidget {
  const RootTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isAuthenticated) {
          return const _MainAppView();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class _MainAppView extends StatefulWidget {
  const _MainAppView();

  @override
  State<_MainAppView> createState() => _MainAppViewState();
}

class _MainAppViewState extends State<_MainAppView> {
  int _idx = 0;
  final _pages = const [HomeScreen(), LogScreen(), WeeklyReportPage(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
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
