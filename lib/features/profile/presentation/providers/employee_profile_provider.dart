import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/domain/entities/employee_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ponytail: preview từ user session — sau này đổi sang repository/API.
final employeeProfilePreviewProvider = Provider<EmployeeProfile>((ref) {
  final user = ref.watch(authControllerProvider).user;
  return EmployeeProfile.preview(user);
});
