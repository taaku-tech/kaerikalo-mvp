import 'package:hive/hive.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  static const String boxName = 'user_profile';
  static const String key = 'profile';

  static Box<UserProfile> get _box => Hive.box<UserProfile>(boxName);

  static UserProfile? get() {
    return _box.get(key);
  }

  static Future<void> save(UserProfile profile) async {
    await _box.put(key, profile);
  }

  static Future<void> clear() async {
    await _box.delete(key);
  }
}

