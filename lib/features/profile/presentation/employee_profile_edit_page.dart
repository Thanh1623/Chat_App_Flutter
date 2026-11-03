import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/profile/domain/entities/employee_profile.dart';
import 'package:chat_app/features/profile/presentation/providers/employee_profile_provider.dart';
import 'package:chat_app/features/profile/presentation/widgets/employee_profile_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

const _genderOptions = ['Nam', 'Nữ', 'Khác'];
const _maritalOptions = ['Đã kết hôn', 'Chưa kết hôn'];

/// Chỉnh sửa hồ sơ nhân sự của chính mình.
/// Chỉ sửa thông tin cá nhân; dữ liệu công việc do HR quản lý.
class EmployeeProfileEditPage extends ConsumerStatefulWidget {
  const EmployeeProfileEditPage({super.key});

  @override
  ConsumerState<EmployeeProfileEditPage> createState() =>
      _EmployeeProfileEditPageState();
}

class _EmployeeProfileEditPageState
    extends ConsumerState<EmployeeProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _c = <String, TextEditingController>{};
  String? _gender;
  String? _marital;
  String? _frontUrl;
  String? _backUrl;
  String? _uploadingSide;
  bool _saving = false;
  bool _initialized = false;

  TextEditingController _ctl(String key) =>
      _c.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(EmployeeProfile p) {
    if (_initialized) return;
    _initialized = true;
    void set(String key, String? v) => _ctl(key).text = v ?? '';
    set('fullName', p.fullName);
    set('dateOfBirth', p.dateOfBirth);
    set('phone', p.phone);
    set('ethnicity', p.ethnicity);
    set('religion', p.religion);
    set('address', p.address);
    set('permanentAddress', p.permanentAddress);
    set('educationLevel', p.educationLevel);
    set('schoolName', p.schoolName);
    set('citizenIdNumber', p.citizenIdNumber);
    set('citizenIdIssuedPlace', p.citizenIdIssuedPlace);
    set('socialInsuranceNumber', p.socialInsuranceNumber);
    set('emergencyName', p.emergencyContact?.name);
    set('emergencyRelationship', p.emergencyContact?.relationship);
    set('emergencyPhone', p.emergencyContact?.phone);
    set('fatherName', p.guardianFather?.name);
    set('fatherPhone', p.guardianFather?.phone);
    set('motherName', p.guardianMother?.name);
    set('motherPhone', p.guardianMother?.phone);
    set('bankName', p.bankAccount?.bankName);
    set('bankAccountNumber', p.bankAccount?.accountNumber);
    set('bankBranch', p.bankAccount?.branch);
    set('vehicles', p.vehicles);
    _gender = p.gender;
    _marital = p.maritalStatus;
    _frontUrl = p.citizenIdFrontUrl;
    _backUrl = p.citizenIdBackUrl;
  }

  String _t(String key) => _ctl(key).text.trim();

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(text)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(employeeProfileWriterProvider).update({
        'fullName': _t('fullName'),
        'gender': _gender ?? '',
        'dateOfBirth': _t('dateOfBirth'),
        'phone': _t('phone'),
        'maritalStatus': _marital ?? '',
        'ethnicity': _t('ethnicity'),
        'religion': _t('religion'),
        'address': _t('address'),
        'permanentAddress': _t('permanentAddress'),
        'educationLevel': _t('educationLevel'),
        'schoolName': _t('schoolName'),
        'citizenIdNumber': _t('citizenIdNumber'),
        'citizenIdIssuedPlace': _t('citizenIdIssuedPlace'),
        'socialInsuranceNumber': _t('socialInsuranceNumber'),
        'emergencyContact': {
          'name': _t('emergencyName'),
          'relationship': _t('emergencyRelationship'),
          'phone': _t('emergencyPhone'),
        },
        'guardianFather': {
          'name': _t('fatherName'),
          'phone': _t('fatherPhone'),
        },
        'guardianMother': {
          'name': _t('motherName'),
          'phone': _t('motherPhone'),
        },
        'bankAccount': {
          'bankName': _t('bankName'),
          'accountNumber': _t('bankAccountNumber'),
          'branch': _t('bankBranch'),
        },
        'vehicles': _t('vehicles'),
      });
      ref.invalidate(employeeProfileProvider);
      // Tên hiển thị có thể đổi — đồng bộ lại user đăng nhập.
      await ref.read(authControllerProvider).refreshProfile();
      if (!mounted) return;
      _snack('Đã lưu hồ sơ');
      context.pop();
    } on Failure catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCitizenId(String side) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
    } catch (e) {
      _snack('Không mở được thư viện ảnh: $e');
      return;
    }
    if (file == null) return;
    setState(() => _uploadingSide = side);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref
          .read(employeeProfileWriterProvider)
          .uploadCitizenId(
            side: side,
            bytes: bytes,
            filename: file.name.isNotEmpty ? file.name : 'citizen-id.jpg',
          );
      if (!mounted) return;
      setState(() {
        if (side == 'front') {
          _frontUrl = url;
        } else {
          _backUrl = url;
        }
      });
      ref.invalidate(employeeProfileProvider);
      _snack('Đã tải ảnh lên');
    } on Failure catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploadingSide = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(employeeProfileProvider);
    return Scaffold(
      backgroundColor: employeeProfilePageBg,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          TextButton(
            onPressed: _saving || !async.hasValue ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          _init(profile);
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          ProfileSectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            subtitle: 'Liên hệ và thông tin cơ bản',
            children: [
              _field(
                'fullName',
                'Họ và tên',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
              _dropdown(
                'Giới tính',
                _genderOptions,
                _gender,
                (v) => setState(() => _gender = v),
              ),
              _field('dateOfBirth', 'Ngày sinh', hint: 'dd/mm/yyyy'),
              _field('phone', 'Số điện thoại', type: TextInputType.phone),
              _dropdown(
                'Tình trạng hôn nhân',
                _maritalOptions,
                _marital,
                (v) => setState(() => _marital = v),
              ),
              _field('ethnicity', 'Dân tộc'),
              _field('religion', 'Tôn giáo'),
              _field('address', 'Địa chỉ hiện tại', lines: 2),
              _field('permanentAddress', 'Hộ khẩu thường trú', lines: 2),
            ],
          ),
          ProfileSectionCard(
            icon: Icons.school_outlined,
            title: 'Học vấn',
            subtitle: 'Trình độ và đơn vị đào tạo',
            children: [
              _field('educationLevel', 'Trình độ học vấn'),
              _field('schoolName', 'Trường / cơ sở đào tạo'),
            ],
          ),
          ProfileSectionCard(
            icon: Icons.assignment_ind_outlined,
            title: 'Giấy tờ & bảo hiểm',
            subtitle: 'CCCD và số sổ BHXH',
            children: [
              _field('citizenIdNumber', 'Số CCCD', type: TextInputType.number),
              _field('citizenIdIssuedPlace', 'Nơi cấp'),
              _field('socialInsuranceNumber', 'Số sổ bảo hiểm'),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CitizenIdSlot(
                    label: 'Mặt trước CCCD',
                    url: _frontUrl,
                    uploading: _uploadingSide == 'front',
                    onTap: _uploadingSide == null
                        ? () => _pickCitizenId('front')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  _CitizenIdSlot(
                    label: 'Mặt sau CCCD',
                    url: _backUrl,
                    uploading: _uploadingSide == 'back',
                    onTap: _uploadingSide == null
                        ? () => _pickCitizenId('back')
                        : null,
                  ),
                ],
              ),
            ],
          ),
          ProfileSectionCard(
            icon: Icons.family_restroom_outlined,
            title: 'Gia đình & liên hệ',
            subtitle: 'Liên hệ khẩn cấp và người giám hộ',
            children: [
              const _SubTitle('Liên hệ khẩn cấp'),
              _field('emergencyName', 'Họ tên'),
              _field('emergencyRelationship', 'Quan hệ'),
              _field(
                'emergencyPhone',
                'Số điện thoại',
                type: TextInputType.phone,
              ),
              const _SubTitle('Người giám hộ'),
              _field('fatherName', 'Cha — họ tên'),
              _field('fatherPhone', 'Cha — SĐT', type: TextInputType.phone),
              _field('motherName', 'Mẹ — họ tên'),
              _field('motherPhone', 'Mẹ — SĐT', type: TextInputType.phone),
            ],
          ),
          ProfileSectionCard(
            icon: Icons.more_horiz_rounded,
            title: 'Tài chính & phương tiện',
            subtitle: 'Ngân hàng lương và phương tiện di chuyển',
            children: [
              _field('bankName', 'Ngân hàng'),
              _field(
                'bankAccountNumber',
                'Số tài khoản',
                type: TextInputType.number,
              ),
              _field('bankBranch', 'Chi nhánh'),
              _field('vehicles', 'Phương tiện', lines: 2),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Thông tin công việc (mã nhân viên, phòng ban, quản lý…) do bộ phận Nhân sự cập nhật.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    String? hint,
    int lines = 1,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ctl(key),
        minLines: lines,
        maxLines: lines,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> options,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final current = (value == null || value.isEmpty) ? null : value;
    // Giá trị cũ ngoài danh sách vẫn hiển thị, tránh assert của Dropdown.
    final items = [
      ...options,
      if (current != null && !options.contains(current)) current,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: current,
        items: [
          for (final o in items) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _CitizenIdSlot extends StatelessWidget {
  const _CitizenIdSlot({
    required this.label,
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  final String label;
  final String? url;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasImage = url != null && url!.isNotEmpty;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.58,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: hasImage
                      ? const Color(0xFFF0F2F5)
                      : primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasImage
                        ? const Color(0xFFD0D5DD)
                        : primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, color: primary),
                          const SizedBox(height: 6),
                          Text(
                            'Tải ảnh lên',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    if (hasImage && !uploading)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              'Đổi ảnh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (uploading)
                      const ColoredBox(
                        color: Color(0x66FFFFFF),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
