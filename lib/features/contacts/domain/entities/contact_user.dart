class ContactUser {
  const ContactUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.team = '',
    this.department = '',
    this.departmentGroup = '',
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String team;
  final String department;
  final String departmentGroup;

  /// "Phòng ban · Nhóm" từ hồ sơ nhân sự; rỗng nếu chưa có.
  String get orgLabel => [department, departmentGroup]
      .where((e) => e.trim().isNotEmpty)
      .join(' · ');
}
