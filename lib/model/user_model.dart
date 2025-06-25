class User {
  final String id;
  final String username;
  final String email;
  final String? profilePhoto;
  final String themePreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePhoto,
    this.themePreference = 'light',
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profilePhoto: json['profile_photo'],
      themePreference: json['theme_preference'] ?? 'light',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_photo': profilePhoto,
      'theme_preference': themePreference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? username,
    String? email,
    String? passwordHash,
    String? profilePhoto,
    String? themePreference,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      themePreference: themePreference ?? this.themePreference,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
