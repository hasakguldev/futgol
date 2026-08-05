class UserProfile {
  final String name;
  final String emoji;
  final DateTime createdAt;

  UserProfile({
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
