class MockUser {
  final String id;
  final DateTime createdAt;
  final bool lastResultShown;

  const MockUser({
    required this.id,
    required this.createdAt,
    required this.lastResultShown,
  });

  /// Placeholder when no user is signed in (router should keep users off main tabs).
  static final MockUser guest = MockUser(
    id: 'guest',
    createdAt: DateTime.utc(1970),
    lastResultShown: true,
  );

  MockUser copyWith({bool? lastResultShown}) {
    return MockUser(
      id: id,
      createdAt: createdAt,
      lastResultShown: lastResultShown ?? this.lastResultShown,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'lastResultShown': lastResultShown,
      };

  static MockUser fromJson(Map<String, dynamic> json) {
    return MockUser(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastResultShown: json['lastResultShown'] as bool,
    );
  }
}

