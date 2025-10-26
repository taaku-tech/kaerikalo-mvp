import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 14)
class UserProfile {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final String nickname;
  @HiveField(3)
  final double heightCm;
  @HiveField(4)
  final double weightKg;
  @HiveField(5)
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    required this.heightCm,
    required this.weightKg,
    this.avatarUrl,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? nickname,
    double? heightCm,
    double? weightKg,
    String? avatarUrl,
  }) => UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        nickname: nickname ?? this.nickname,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'avatarUrl': avatarUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String,
        nickname: (json['nickname'] ?? '') as String,
        heightCm: (json['heightCm'] as num).toDouble(),
        weightKg: (json['weightKg'] as num).toDouble(),
        avatarUrl: json['avatarUrl'] as String?,
      );
}

