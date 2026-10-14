class User {
  const User({
    required this.id,
    required this.displayName,
    this.email,
    this.avatarUrl = '',
    this.team = '',
  });

  final String id;
  final String displayName;
  final String? email;
  final String avatarUrl;
  final String team;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'name': displayName,
        'email': email,
        'avatarUrl': avatarUrl,
        'team': team,
      };

  User copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? team,
  }) {
    return User(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      team: team ?? this.team,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['name']?.toString() ??
          json['email']?.toString() ??
          '',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      team: json['team']?.toString() ?? '',
    );
  }
}
