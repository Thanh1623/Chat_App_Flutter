import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';

/// Hồ sơ nhân sự — UI/mock trước khi có API BE.
class EmployeeProfile {
  const EmployeeProfile({
    required this.userId,
    this.startDate,
    this.employeeCode,
    this.employeeSeq,
    this.contractType,
    this.jobTitle,
    this.directManagerName,
    this.employmentStatus,
    this.cardColor,
    this.managementBlockCode,
    this.department,
    this.departmentGroup,
    this.specialtyPosition,
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.phone,
    this.email,
    this.address,
    this.permanentAddress,
    this.educationLevel,
    this.schoolName,
    this.citizenIdNumber,
    this.citizenIdIssuedPlace,
    this.citizenIdFrontUrl,
    this.citizenIdBackUrl,
    this.maritalStatus,
    this.ethnicity,
    this.religion,
    this.socialInsuranceNumber,
    this.children = const [],
    this.emergencyContact,
    this.guardianFather,
    this.guardianMother,
    this.bankAccount,
    this.vehicles,
  });

  final String userId;

  // Công việc & tổ chức
  final String? startDate;
  final String? employeeCode;
  final String? employeeSeq;
  final String? contractType;
  final String? jobTitle;
  final String? directManagerName;
  final String? employmentStatus;
  final Color? cardColor;
  final String? managementBlockCode;
  final String? department;
  final String? departmentGroup;
  final String? specialtyPosition;

  // Cá nhân
  final String? fullName;
  final String? gender;
  final String? dateOfBirth;
  final String? phone;
  final String? email;
  final String? address;
  final String? permanentAddress;
  final String? educationLevel;
  final String? schoolName;
  final String? citizenIdNumber;
  final String? citizenIdIssuedPlace;
  final String? citizenIdFrontUrl;
  final String? citizenIdBackUrl;
  final String? maritalStatus;
  final String? ethnicity;
  final String? religion;
  final String? socialInsuranceNumber;

  final List<EmployeeChild> children;
  final EmergencyContact? emergencyContact;
  final GuardianInfo? guardianFather;
  final GuardianInfo? guardianMother;
  final BankAccountInfo? bankAccount;
  final String? vehicles;

  /// ponytail: dữ liệu mẫu gắn user đăng nhập — thay bằng API sau.
  factory EmployeeProfile.preview(User? user) {
    final name = user?.displayName ?? 'Nguyễn Văn A';
    final email = user?.email ?? 'nhanvien@congty.vn';
    final team = user?.team ?? 'sale';

    return EmployeeProfile(
      userId: user?.id ?? '',
      startDate: '15/03/2022',
      employeeCode: 'NV-2022-0847',
      employeeSeq: '1284',
      contractType: 'Chính thức',
      jobTitle: 'Chuyên viên kinh doanh',
      directManagerName: 'Trần Minh Quân',
      employmentStatus: 'Đang làm việc',
      cardColor: const Color(0xFF0068FF),
      managementBlockCode: 'KD-01',
      department: _deptFromTeam(team),
      departmentGroup: 'Nhóm B2B Miền Bắc',
      specialtyPosition: 'Sales Executive',
      fullName: name,
      gender: 'Nam',
      dateOfBirth: '12/08/1996',
      phone: '0903 456 789',
      email: email,
      address: 'Tầng 8, Tòa nhà Landmark, Hà Nội',
      permanentAddress: 'Xã An Phú, Huyện Thủ Dầu Một, Bình Dương',
      educationLevel: 'Đại học',
      schoolName: 'ĐH Kinh tế Quốc dân',
      citizenIdNumber: '001096012345',
      citizenIdIssuedPlace: 'Cục Cảnh sát QLHC về TTXH',
      maritalStatus: 'Độc thân',
      ethnicity: 'Kinh',
      religion: 'Không',
      socialInsuranceNumber: '7912345678',
      children: const [
        EmployeeChild(fullName: 'Nguyễn Minh An', dateOfBirth: '05/01/2020'),
      ],
      emergencyContact: const EmergencyContact(
        name: 'Nguyễn Thị B',
        relationship: 'Chị gái',
        phone: '0912 888 999',
      ),
      guardianFather: const GuardianInfo(
        name: 'Nguyễn Văn C',
        phone: '0987 654 321',
        occupation: 'Hưu trí',
      ),
      guardianMother: const GuardianInfo(
        name: 'Trần Thị D',
        phone: '0976 543 210',
        occupation: 'Nội trợ',
      ),
      bankAccount: const BankAccountInfo(
        bankName: 'Vietcombank',
        accountNumber: '**** **** 4521',
        branch: 'Chi nhánh Hà Nội',
      ),
      vehicles: 'Xe máy — 29A1-123.45',
    );
  }
}

class EmployeeChild {
  const EmployeeChild({required this.fullName, this.dateOfBirth});

  final String fullName;
  final String? dateOfBirth;
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  final String name;
  final String relationship;
  final String phone;
}

class GuardianInfo {
  const GuardianInfo({
    required this.name,
    required this.phone,
    this.occupation,
  });

  final String name;
  final String phone;
  final String? occupation;
}

class BankAccountInfo {
  const BankAccountInfo({
    required this.bankName,
    required this.accountNumber,
    required this.branch,
  });

  final String bankName;
  final String accountNumber;
  final String branch;
}

String _deptFromTeam(String team) {
  switch (team.toLowerCase()) {
    case 'sale':
      return 'Phòng Kinh doanh';
    case 'traffic':
      return 'Phòng Marketing';
    case 'kho':
      return 'Phòng Kho vận';
    default:
      return team.isEmpty ? 'Phòng ban' : team;
  }
}
