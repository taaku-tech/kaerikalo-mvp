import 'package:hive/hive.dart';

part 'app_prefs.g.dart';

@HiveType(typeId: 13)
class AppPrefs {
  @HiveField(0)
  final int defaultTargetKcal;
  @HiveField(1)
  final bool notificationsEnabled;
  @HiveField(2)
  final DateTime? lastOpened;
  // added fields (backward compatible)
  @HiveField(3)
  final int? dailyHour;
  @HiveField(4)
  final int? dailyMinute;
  @HiveField(5)
  final int? weeklyWeekday; // 1=Mon..7=Sun
  @HiveField(6)
  final int? weeklyHour;
  @HiveField(7)
  final int? weeklyMinute;
  @HiveField(8)
  final int weekStartWeekday; // 1=Mon..7=Sun
  @HiveField(9)
  final bool migratedToHive;

  const AppPrefs({
    this.defaultTargetKcal = 200,
    this.notificationsEnabled = true,
    this.lastOpened,
    this.dailyHour,
    this.dailyMinute,
    this.weeklyWeekday,
    this.weeklyHour,
    this.weeklyMinute,
    this.weekStartWeekday = 1,
    this.migratedToHive = false,
  });

  AppPrefs copyWith({
    int? defaultTargetKcal,
    bool? notificationsEnabled,
    DateTime? lastOpened,
    int? dailyHour,
    int? dailyMinute,
    int? weeklyWeekday,
    int? weeklyHour,
    int? weeklyMinute,
    int? weekStartWeekday,
    bool? migratedToHive,
  }) => AppPrefs(
        defaultTargetKcal:
            defaultTargetKcal ?? this.defaultTargetKcal,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
        lastOpened: lastOpened ?? this.lastOpened,
        dailyHour: dailyHour ?? this.dailyHour,
        dailyMinute: dailyMinute ?? this.dailyMinute,
        weeklyWeekday: weeklyWeekday ?? this.weeklyWeekday,
        weeklyHour: weeklyHour ?? this.weeklyHour,
        weeklyMinute: weeklyMinute ?? this.weeklyMinute,
        weekStartWeekday: weekStartWeekday ?? this.weekStartWeekday,
        migratedToHive: migratedToHive ?? this.migratedToHive,
      );
}
