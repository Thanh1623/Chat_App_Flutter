import 'package:flutter/material.dart';

const employeeProfilePageBg = Color(0xFFF4F5F7);

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileFieldGrid extends StatelessWidget {
  const ProfileFieldGrid({super.key, required this.fields});

  final List<ProfileField> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 340;
        if (!twoCol) {
          return Column(
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                ProfileFieldTile(field: fields[i]),
                if (i < fields.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < fields.length; i += 2) {
          final left = fields[i];
          final right = i + 1 < fields.length ? fields[i + 1] : null;
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ProfileFieldTile(field: left)),
                const SizedBox(width: 12),
                Expanded(
                  child: right == null
                      ? const SizedBox.shrink()
                      : ProfileFieldTile(field: right),
                ),
              ],
            ),
          );
          if (i + 2 < fields.length) {
            rows.add(const SizedBox(height: 12));
          }
        }
        return Column(children: rows);
      },
    );
  }
}

class ProfileField {
  const ProfileField({
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;
}

class ProfileFieldTile extends StatelessWidget {
  const ProfileFieldTile({super.key, required this.field});

  final ProfileField field;

  @override
  Widget build(BuildContext context) {
    final display = field.value.trim().isEmpty ? '—' : field.value;
    final outline = Theme.of(context).colorScheme.outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: field.highlight
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
            : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: field.highlight
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : const Color(0xFFE8EAED),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (field.icon != null) ...[
                Icon(field.icon, size: 14, color: outline),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(fontSize: 11, color: outline, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            display,
            style: TextStyle(
              fontSize: 14,
              fontWeight: field.highlight ? FontWeight.w600 : FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePersonRow extends StatelessWidget {
  const ProfilePersonRow({
    super.key,
    required this.label,
    required this.name,
    this.leadingIcon = Icons.person_outline,
  });

  final String label;
  final String name;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final display = name.trim().isEmpty ? '—' : name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: primary.withValues(alpha: 0.12),
            child: Icon(leadingIcon, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class ProfileStatusChip extends StatelessWidget {
  const ProfileStatusChip({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: c.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDocumentPlaceholder extends StatelessWidget {
  const ProfileDocumentPlaceholder({
    super.key,
    required this.label,
    this.imageUrl,
  });

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: outline),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD0D5DD),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(imageUrl!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 32,
                          color: outline.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa tải ảnh',
                          style: TextStyle(fontSize: 12, color: outline),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSubBlock extends StatelessWidget {
  const ProfileSubBlock({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ProfileSensitiveBanner extends StatelessWidget {
  const ProfileSensitiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5D565)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: Colors.amber.shade900,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin nhạy cảm chỉ hiển thị với bạn và bộ phận nhân sự.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
