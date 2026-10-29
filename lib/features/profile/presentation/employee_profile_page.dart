import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/domain/entities/employee_profile.dart';
import 'package:chat_app/features/profile/presentation/providers/employee_profile_provider.dart';
import 'package:chat_app/features/profile/presentation/widgets/employee_profile_ui.dart';
import 'package:chat_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmployeeProfilePage extends ConsumerStatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  ConsumerState<EmployeeProfilePage> createState() =>
      _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends ConsumerState<EmployeeProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = [
    'Công việc',
    'Cá nhân',
    'Học vấn',
    'Giấy tờ',
    'Gia đình',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onEditTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Text(
          'Chỉnh sửa hồ sơ sẽ kết nối API — đang làm giao diện trước.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(employeeProfilePreviewProvider);
    final user = ref.watch(authControllerProvider).user;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: employeeProfilePageBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 176,
            pinned: true,
            stretch: true,
            title: const Text('Hồ sơ nhân sự'),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: _ProfileHero(
                profile: profile,
                avatarUrl: user?.avatarUrl,
                displayName: profile.fullName ?? user?.displayName ?? '—',
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: _onEditTap,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: primary,
                unselectedLabelColor: Colors.black54,
                indicatorColor: primary,
                indicatorWeight: 3,
                dividerColor: const Color(0xFFE8EAED),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [for (final label in _tabLabels) Tab(text: label)],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProfileTabBody(
              children: [
                _WorkStatusRow(profile: profile),
                _WorkSection(profile: profile),
              ],
            ),
            _ProfileTabBody(children: [_PersonalSection(profile: profile)]),
            _ProfileTabBody(children: [_EducationSection(profile: profile)]),
            _ProfileTabBody(
              children: [
                const ProfileSensitiveBanner(),
                _IdentitySection(profile: profile),
              ],
            ),
            _ProfileTabBody(children: [_FamilySection(profile: profile)]),
            _ProfileTabBody(
              children: [
                const ProfileSensitiveBanner(),
                _OtherSection(profile: profile),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 28),
      children: children,
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: Colors.black26,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _WorkStatusRow extends StatelessWidget {
  const _WorkStatusRow({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          ProfileStatusChip(
            label: 'Hợp đồng',
            value: profile.contractType ?? '—',
            color: primary,
          ),
          const SizedBox(width: 8),
          ProfileStatusChip(
            label: 'Tình trạng làm việc',
            value: profile.employmentStatus ?? '—',
            color: primary,
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.avatarUrl,
    required this.displayName,
  });

  final EmployeeProfile profile;
  final String? avatarUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.15)!],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ProfileAvatar(
                  displayName: displayName,
                  avatarUrl: avatarUrl,
                  radius: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _HeroPill(
                          icon: Icons.badge_outlined,
                          text: profile.employeeCode ?? '—',
                        ),
                        if (profile.department != null &&
                            profile.department!.isNotEmpty)
                          _HeroPill(
                            icon: Icons.apartment_outlined,
                            text: profile.department!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkSection extends StatelessWidget {
  const _WorkSection({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.work_outline_rounded,
      title: 'Công việc & tổ chức',
      subtitle: 'Thông tin nội bộ và cấu trúc phòng ban',
      children: [
        ProfilePersonRow(
          label: 'Quản lý trực tiếp',
          name: profile.directManagerName ?? '—',
          leadingIcon: Icons.supervisor_account_outlined,
        ),
        const SizedBox(height: 4),
        ProfileFieldGrid(
          fields: [
            ProfileField(
              label: 'Ngày bắt đầu làm việc',
              value: profile.startDate ?? '',
              icon: Icons.event_outlined,
            ),
            ProfileField(
              label: 'Mã nhân viên',
              value: profile.employeeCode ?? '',
              icon: Icons.tag_outlined,
              highlight: true,
            ),
            ProfileField(
              label: 'Mã định danh NV',
              value: profile.employeeSeq ?? '',
              icon: Icons.numbers_outlined,
            ),
            ProfileField(
              label: 'Loại hợp đồng',
              value: profile.contractType ?? '',
            ),
            ProfileField(label: 'Vị trí (HĐ)', value: profile.jobTitle ?? ''),
            ProfileField(
              label: 'Vị trí chuyên môn',
              value: profile.specialtyPosition ?? '',
            ),
            ProfileField(
              label: 'Phòng ban',
              value: profile.department ?? '',
              icon: Icons.apartment_outlined,
            ),
            ProfileField(
              label: 'Nhóm (theo phòng ban)',
              value: profile.departmentGroup ?? '',
            ),
            ProfileField(
              label: 'Mã khối theo quản lý',
              value: profile.managementBlockCode ?? '',
            ),
            ProfileField(
              label: 'Tình trạng làm việc',
              value: profile.employmentStatus ?? '',
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonalSection extends StatelessWidget {
  const _PersonalSection({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Thông tin cá nhân',
      subtitle: 'Liên hệ và thông tin cơ bản',
      children: [
        ProfileFieldGrid(
          fields: [
            ProfileField(
              label: 'Họ và tên',
              value: profile.fullName ?? '',
              highlight: true,
            ),
            ProfileField(label: 'Giới tính', value: profile.gender ?? ''),
            ProfileField(
              label: 'Ngày sinh',
              value: profile.dateOfBirth ?? '',
              icon: Icons.cake_outlined,
            ),
            ProfileField(
              label: 'Số điện thoại',
              value: profile.phone ?? '',
              icon: Icons.phone_outlined,
            ),
            ProfileField(
              label: 'Email',
              value: profile.email ?? '',
              icon: Icons.mail_outline,
            ),
            ProfileField(
              label: 'Tình trạng hôn nhân',
              value: profile.maritalStatus ?? '',
            ),
            ProfileField(label: 'Dân tộc', value: profile.ethnicity ?? ''),
            ProfileField(label: 'Tôn giáo', value: profile.religion ?? ''),
          ],
        ),
        const SizedBox(height: 12),
        ProfileFieldTile(
          field: ProfileField(
            label: 'Địa chỉ hiện tại',
            value: profile.address ?? '',
            icon: Icons.home_outlined,
          ),
        ),
        const SizedBox(height: 12),
        ProfileFieldTile(
          field: ProfileField(
            label: 'Hộ khẩu thường trú',
            value: profile.permanentAddress ?? '',
            icon: Icons.location_on_outlined,
          ),
        ),
      ],
    );
  }
}

class _EducationSection extends StatelessWidget {
  const _EducationSection({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.school_outlined,
      title: 'Học vấn',
      subtitle: 'Trình độ và đơn vị đào tạo',
      children: [
        ProfileFieldGrid(
          fields: [
            ProfileField(
              label: 'Trình độ học vấn',
              value: profile.educationLevel ?? '',
            ),
            ProfileField(
              label: 'Trường / cơ sở đào tạo',
              value: profile.schoolName ?? '',
            ),
          ],
        ),
      ],
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final data = profile;

    return ProfileSectionCard(
      icon: Icons.assignment_ind_outlined,
      title: 'Giấy tờ & bảo hiểm',
      subtitle: 'CCCD và số sổ BHXH',
      children: [
        ProfileFieldGrid(
          fields: [
            ProfileField(label: 'Số CCCD', value: data.citizenIdNumber ?? ''),
            ProfileField(
              label: 'Nơi cấp',
              value: data.citizenIdIssuedPlace ?? '',
            ),
            ProfileField(
              label: 'Số sổ bảo hiểm',
              value: data.socialInsuranceNumber ?? '',
              icon: Icons.health_and_safety_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileDocumentPlaceholder(
              label: 'Mặt trước CCCD',
              imageUrl: data.citizenIdFrontUrl,
            ),
            const SizedBox(width: 12),
            ProfileDocumentPlaceholder(
              label: 'Mặt sau CCCD',
              imageUrl: data.citizenIdBackUrl,
            ),
          ],
        ),
      ],
    );
  }
}

class _FamilySection extends StatelessWidget {
  const _FamilySection({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final ec = profile.emergencyContact;
    final father = profile.guardianFather;
    final mother = profile.guardianMother;

    return ProfileSectionCard(
      icon: Icons.family_restroom_outlined,
      title: 'Gia đình & liên hệ',
      subtitle: 'Con cái, khẩn cấp và người giám hộ',
      children: [
        ProfileSubBlock(
          title: 'Liên hệ khẩn cấp',
          child: ProfileFieldGrid(
            fields: [
              ProfileField(label: 'Họ tên', value: ec?.name ?? ''),
              ProfileField(label: 'Quan hệ', value: ec?.relationship ?? ''),
              ProfileField(
                label: 'Số điện thoại',
                value: ec?.phone ?? '',
                icon: Icons.phone_in_talk_outlined,
              ),
            ],
          ),
        ),
        ProfileSubBlock(
          title: 'Thông tin con cái',
          child: profile.children.isEmpty
              ? ProfileFieldTile(
                  field: const ProfileField(
                    label: 'Danh sách',
                    value: 'Chưa khai báo',
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < profile.children.length; i++) ...[
                      ProfileFieldTile(
                        field: ProfileField(
                          label: 'Con ${i + 1}',
                          value: _childLabel(profile.children[i]),
                          icon: Icons.child_care_outlined,
                        ),
                      ),
                      if (i < profile.children.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
        ProfileSubBlock(
          title: 'Người giám hộ',
          child: ProfileFieldGrid(
            fields: [
              ProfileField(label: 'Cha', value: _guardianLabel(father)),
              ProfileField(label: 'Mẹ', value: _guardianLabel(mother)),
            ],
          ),
        ),
      ],
    );
  }

  String _childLabel(EmployeeChild c) {
    final dob = c.dateOfBirth;
    if (dob != null && dob.isNotEmpty) {
      return '${c.fullName} · sinh $dob';
    }
    return c.fullName;
  }

  String _guardianLabel(GuardianInfo? g) {
    if (g == null || g.name.isEmpty) return '—';
    final parts = <String>[g.name, g.phone];
    if (g.occupation != null && g.occupation!.isNotEmpty) {
      parts.add(g.occupation!);
    }
    return parts.join(' · ');
  }
}

class _OtherSection extends StatelessWidget {
  const _OtherSection({required this.profile});

  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final bank = profile.bankAccount;

    return ProfileSectionCard(
      icon: Icons.more_horiz_rounded,
      title: 'Tài chính & phương tiện',
      subtitle: 'Ngân hàng lương và phương tiện di chuyển',
      children: [
        ProfileSubBlock(
          title: 'Tài khoản ngân hàng',
          child: ProfileFieldGrid(
            fields: [
              ProfileField(label: 'Ngân hàng', value: bank?.bankName ?? ''),
              ProfileField(
                label: 'Số tài khoản',
                value: bank?.accountNumber ?? '',
                highlight: true,
              ),
              ProfileField(label: 'Chi nhánh', value: bank?.branch ?? ''),
            ],
          ),
        ),
        ProfileSubBlock(
          title: 'Phương tiện',
          child: ProfileFieldTile(
            field: ProfileField(
              label: 'Mô tả',
              value: profile.vehicles ?? '',
              icon: Icons.directions_car_outlined,
            ),
          ),
        ),
      ],
    );
  }
}
