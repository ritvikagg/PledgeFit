/// Local-only session. Replace with tokens from a real auth backend later.
class AuthSession {
  final String userId;
  final String email;
  final String fullName;
  /// e.g. `email`, `google` — used for UI and future provider-specific logic.
  final String authProvider;
  final DateTime loginAt;

  const AuthSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.authProvider,
    required this.loginAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'authProvider': authProvider,
        'loginAt': loginAt.toIso8601String(),
      };

  static AuthSession fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      authProvider: json['authProvider'] as String,
      loginAt: DateTime.parse(json['loginAt'] as String),
    );
  }
}
