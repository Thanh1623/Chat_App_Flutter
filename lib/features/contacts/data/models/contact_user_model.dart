import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';

class ContactUserModel {
  const ContactUserModel({
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

  ContactUser toEntity() => ContactUser(
    id: id,
    name: name,
    email: email,
    avatarUrl: avatarUrl,
    team: team,
    department: department,
    departmentGroup: departmentGroup,
  );

  factory ContactUserModel.fromJson(Map<String, dynamic> json) {
    return ContactUserModel(
      id: json['id']?.toString() ?? '',
      name: json['displayName']?.toString() ??
          json['name']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      team: json['team']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      departmentGroup: json['departmentGroup']?.toString() ?? '',
    );
  }
}
