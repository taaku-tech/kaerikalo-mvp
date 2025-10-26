import 'package:hive/hive.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  static const String boxName = 'user_profile';

  static Box<UserProfile> get _box => Hive.box<UserProfile>(boxName);

  static UserProfile? get(String key) {
    return _box.get(key);
  }

  static Future<void> save(String key, UserProfile profile) async {
    await _box.put(key, profile);
  }

  static Future<void> delete(String key) async {
    await _box.delete(key);
  }
}
