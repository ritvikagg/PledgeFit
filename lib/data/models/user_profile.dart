/// Local mock profile — replace with real auth + API later.
class UserProfile {
  final String fullName;
  final String username;
  final String email;
  /// Placeholder avatar (emoji) until real image upload exists.
  final String avatarEmoji;

  const UserProfile({
    required this.fullName,
    required this.username,
    required this.email,
    required this.avatarEmoji,
  });

  static const UserProfile empty = UserProfile(
    fullName: '',
    username: '',
    email: '',
    avatarEmoji: '👤',
  );

  UserProfile copyWith({
    String? fullName,
    String? username,
    String? email,
    String? avatarEmoji,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'username': username,
        'email': email,
        'avatarEmoji': avatarEmoji,
      };

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarEmoji: json['avatarEmoji'] as String? ?? '👤',
    );
  }
}
