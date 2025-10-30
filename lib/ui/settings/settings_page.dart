import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/app_prefs.dart';
import '../../repositories/app_prefs_repository.dart';
import '../../services/notification_service.dart';
import '../../models/daily_goal.dart';
import '../../models/daily_summary.dart';
import '../../models/activity_log.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../profile/user_profile_edit_screen.dart';
import '../auth/login_screen.dart';
// import '../../data/repo.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _enabled = true;
  TimeOfDay? _daily;
  int _weeklyDay = 1; // Monday
  TimeOfDay? _weekly;

  @override
  void initState() {
    super.initState();
    final p = AppPrefsRepository.get();
    _enabled = p?.notificationsEnabled ?? true;
    if (p?.dailyHour != null && p?.dailyMinute != null) {
      _daily = TimeOfDay(hour: p!.dailyHour!, minute: p.dailyMinute!);
    }
    _weeklyDay = p?.weeklyWeekday ?? 1;
    if (p?.weeklyHour != null && p?.weeklyMinute != null) {
      _weekly = TimeOfDay(hour: p!.weeklyHour!, minute: p.weeklyMinute!);
    }
  }

  Future<void> _pickDaily() async {
    final ctx = context;
    final init = _daily ?? const TimeOfDay(hour: 9, minute: 0);
    final t = await showTimePicker(context: ctx, initialTime: init);
    if (!mounted) return;
    if (t != null) setState(() => _daily = t);
  }

  Future<void> _pickWeekly() async {
    final ctx = context;
    final init = _weekly ?? const TimeOfDay(hour: 20, minute: 0);
    final t = await showTimePicker(context: ctx, initialTime: init);
    if (!mounted) return;
    if (t != null) setState(() => _weekly = t);
  }

  Future<void> _save() async {
    final old = AppPrefsRepository.get();
    final prefs = (old ?? const AppPrefs()).copyWith(
      notificationsEnabled: _enabled,
      dailyHour: _daily?.hour,
      dailyMinute: _daily?.minute,
      weeklyWeekday: _weeklyDay,
      weeklyHour: _weekly?.hour,
      weeklyMinute: _weekly?.minute,
    );
    await AppPrefsRepository.save(prefs);

    // Reschedule
    final ns = NotificationService.instance;
    await ns.cancelAll();
    if (_enabled) {
      if (_daily != null) {
        await ns.scheduleDaily(_daily!.hour, _daily!.minute);
      }
      if (_weekly != null) {
        await ns.scheduleWeekly(_weeklyDay, _weekly!.hour, _weekly!.minute);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定を保存しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          Builder(builder: (context) {
            final auth = context.watch<AuthProvider>();
            final p = auth.profile;
            return Column(children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('ユーザー情報'),
                subtitle: Text(p == null ? '未ログイン' : '${p.nickname} • ${p.email}'),
                onTap: () {
                  if (!auth.isAuthenticated) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (_, a, __) => const LoginScreen(),
                        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (_, a, __) => const UserProfileEditScreen(),
                        transitionsBuilder: (_, a, __, child) => SlideTransition(position: Tween(begin: const Offset(1,0), end: Offset.zero).animate(a), child: child),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('ログアウトしますか？'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('キャンセル')),
                            TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('ログアウト')),
                          ],
                        ),
                      ) ??
                      false;
                  if (!ok) return;
                  await auth.logOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (_, a, __) => const LoginScreen(),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                    ),
                    (_) => false,
                  );
                },
              ),
              const Divider(),
            ]);
          }),
          SwitchListTile(
            title: const Text('通知有効化（今後予定：今は何も起きません）'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const Divider(),
          ListTile(
            title: const Text('デイリー通知時刻'),
            subtitle: Text(_daily == null
                ? '未設定'
                : '${_daily!.hour.toString().padLeft(2, '0')}:${_daily!.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.access_time),
            onTap: _pickDaily,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: '週次通知曜日'),
                  initialValue: _weeklyDay,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('月')),
                    DropdownMenuItem(value: 2, child: Text('火')),
                    DropdownMenuItem(value: 3, child: Text('水')),
                    DropdownMenuItem(value: 4, child: Text('木')),
                    DropdownMenuItem(value: 5, child: Text('金')),
                    DropdownMenuItem(value: 6, child: Text('土')),
                    DropdownMenuItem(value: 7, child: Text('日')),
                  ],
                  onChanged: (v) => setState(() => _weeklyDay = v ?? 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  title: const Text('週次通知時刻'),
                  subtitle: Text(_weekly == null
                      ? '未設定'
                      : '${_weekly!.hour.toString().padLeft(2, '0')}:${_weekly!.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickWeekly,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            const Divider(),
            Text('初期化', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                // 型付きでクリア（開いてなければ開いてクリア）
                Future<void> clearTyped<T>(String name) async {
                  if (Hive.isBoxOpen(name)) {
                    await Hive.box<T>(name).clear();
                  } else if (await Hive.boxExists(name)) {
                    final box = await Hive.openBox<T>(name);
                    await box.clear();
                  }
                }

                await clearTyped<DailyGoal>('daily_goals');
                await clearTyped<ActivityLog>('activity_logs');
                await clearTyped<DailySummary>('daily_summaries');
                await clearTyped<AppPrefs>('app_prefs');

                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('全Boxをクリアしました')));
              },
              child: const Text('全Boxクリア'),
            ),
          ]
        ],
      ),
    );
  }
}
