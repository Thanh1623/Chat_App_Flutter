class User {
  const User({
    required this.id,
    required this.displayName,
    this.email,
  });

  final String id;
  final String displayName;
  final String? email;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['name']?.toString() ??
          json['email']?.toString() ??
          '',
      email: json['email']?.toString(),
    );
  }
}
