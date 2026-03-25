class MockUser {
  final String id;
  final DateTime createdAt;
  final bool lastResultShown;

  const MockUser({
    required this.id,
    required this.createdAt,
    required this.lastResultShown,
  });

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

