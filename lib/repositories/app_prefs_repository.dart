import 'package:hive/hive.dart';

import '../models/app_prefs.dart';

class AppPrefsRepository {
  static const String boxName = 'app_prefs';
  static const String key = 'prefs';

  static Box<AppPrefs> get _box => Hive.box<AppPrefs>(boxName);

  static AppPrefs? get() {
    return _box.get(key);
  }

  static Future<void> save(AppPrefs prefs) async {
    await _box.put(key, prefs);
  }
}

