class UserAchievement {
  final String id;
  final String userId;
  final String achievementType;
  final String achievementName;
  final String? achievementDescription;
  final DateTime achievedDate;
  final String? badgeIcon;
  final DateTime createdAt;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementType,
    required this.achievementName,
    this.achievementDescription,
    required this.achievedDate,
    this.badgeIcon,
    required this.createdAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementType: json['achievement_type'],
      achievementName: json['achievement_name'],
      achievementDescription: json['achievement_description'],
      achievedDate: DateTime.parse(json['achieved_date']),
      badgeIcon: json['badge_icon'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_type': achievementType,
      'achievement_name': achievementName,
      'achievement_description': achievementDescription,
      'achieved_date': achievedDate.toIso8601String().split('T')[0],
      'badge_icon': badgeIcon,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
