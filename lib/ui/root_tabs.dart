import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/home_screen.dart';
import '../screens/log_screen.dart';
import '../ui/report/weekly_report_page.dart';
import '../screens/settings_screen.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';

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
    WeeklyReportPage(),
    SettingsScreen(),
  ];

  bool _checkedAuth = false;

  @override
  void initState() {
    super.initState();
    // Initial auth check -> navigate to login if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _checkedAuth) return;
      _checkedAuth = true;
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.loadPersisted();
        if (!auth.isAuthenticated && mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, a, __) => const LoginScreen(),
              transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
            ),
          );
        }
      } catch (_) {}
    });
  }

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

