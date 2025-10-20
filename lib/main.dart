import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaeriKaloApp());
}

class KaeriKaloApp extends StatelessWidget {
  const KaeriKaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カエリカロ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2EC4B6), // ミント
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
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
    _PlaceholderPage('Home（今日の目標・達成率・提案）'),
    _PlaceholderPage('Log（アクション記録）'),
    _PlaceholderPage('Weekly（週レポート）'),
    _PlaceholderPage('Settings（設定）'),
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

class _PlaceholderPage extends StatelessWidget {
  final String text;
  const _PlaceholderPage(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text));
  }
}