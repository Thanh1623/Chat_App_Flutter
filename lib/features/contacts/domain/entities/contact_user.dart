class ContactUser {
  const ContactUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.team = '',
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String team;
}
