class User {
  final String id;
  final String name;
  final String email;
  final int totalXP;
  final int currentStreak;
  final int level;
  final DateTime? lastActiveDate;
  final int coins;
  final int gems;
  final int lives;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.totalXP,
    required this.currentStreak,
    required this.level,
    this.lastActiveDate,
    required this.coins,
    required this.gems,
    required this.lives,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    int? totalXP,
    int? currentStreak,
    int? level,
    DateTime? lastActiveDate,
    int? coins,
    int? gems,
    int? lives,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        totalXP: totalXP ?? this.totalXP,
        currentStreak: currentStreak ?? this.currentStreak,
        level: level ?? this.level,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        coins: coins ?? this.coins,
        gems: gems ?? this.gems,
        lives: lives ?? this.lives,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'totalXP': totalXP,
        'currentStreak': currentStreak,
        'level': level,
        'lastActiveDate': lastActiveDate?.toIso8601String(),
        'coins': coins,
        'gems': gems,
        'lives': lives,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        totalXP: json['totalXP'],
        currentStreak: json['currentStreak'],
        level: json['level'],
        lastActiveDate: json['lastActiveDate'] != null
            ? DateTime.parse(json['lastActiveDate'])
            : null,
        coins: json['coins'],
        gems: json['gems'],
        lives: json['lives'],
      );
}
