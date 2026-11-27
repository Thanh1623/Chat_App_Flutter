import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/features/chat/data/providers/chat_repository_provider.dart';
import 'package:chat_app/features/chat/domain/entities/room_media.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/chat/presentation/widgets/group_members_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/group_settings_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/pinned_messages_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/reminders_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/room_media_sheet.dart';
import 'package:chat_app/features/contacts/domain/entities/contact_user.dart';
import 'package:chat_app/features/conversations/domain/entities/conversation.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:chat_app/features/presence/presentation/presence_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationInfoPage extends ConsumerStatefulWidget {
  const ConversationInfoPage({
    super.key,
    required this.conversationId,
    this.title,
    this.canDelete = false,
    this.isGroup = false,
    this.peerUserId,
    this.onMembersChanged,
  });

  final String conversationId;
  final String? title;
  final bool canDelete;
  final bool isGroup;
  final String? peerUserId;
  final VoidCallback? onMembersChanged;

  @override
  ConsumerState<ConversationInfoPage> createState() =>
      _ConversationInfoPageState();
}

class _ConversationInfoPageState extends ConsumerState<ConversationInfoPage> {
  List<ContactUser> _members = const [];
  List<RoomMediaImage> _images = const [];
  bool _loadingHero = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .fetchRoomMembers(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loadingHero = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHero = false);
    }
    try {
      final images = await ref
          .read(chatRepositoryProvider)
          .fetchRoomImages(widget.conversationId);
      if (!mounted) return;
      setState(() => _images = images);
    } catch (_) {}
  }

  Future<void> _openMembers() async {
    await showGroupMembersSheet(
      context: context,
      roomId: widget.conversationId,
      canManage: widget.canDelete,
      onChanged: () {
        widget.onMembersChanged?.call();
        _load();
      },
    );
    if (mounted) _load();
  }

  Future<void> _openSettings() async {
    final inbox = _inboxConversation();
    await showGroupSettingsSheet(
      context: context,
      roomId: widget.conversationId,
      name: (inbox?.title ?? widget.title ?? '').trim(),
      avatarUrl: inbox?.avatarUrl ?? '',
    );
  }

  Future<void> _openMedia({int tab = 0}) {
    return showRoomMediaSheet(
      context: context,
      roomId: widget.conversationId,
      initialTab: tab,
    );
  }

  Future<void> _confirmDeleteGroup() async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Xóa nhóm?',
      message: 'Toàn bộ tin nhắn trong nhóm sẽ bị xóa. Không thể hoàn tác.',
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(conversationsRepositoryProvider)
          .deleteRoom(widget.conversationId);
      ref.read(conversationsInboxProvider.notifier).refreshInbox();
      if (!mounted) return;
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Conversation? _inboxConversation() {
    final matches = ref
        .read(conversationsInboxProvider)
        .valueOrNull
        ?.items
        .where((c) => c.id == widget.conversationId);
    if (matches == null || matches.isEmpty) return null;
    return matches.first;
  }

  void _openPeerProfile() {
    final id = _peerUserId();
    if (id != null) {
      context.push(AppRoutes.userProfilePath(id));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Không tìm thấy hồ sơ')));
  }

  String? _peerUserId() {
    final fromInbox = _inboxConversation()?.peerUserId?.trim();
    if (fromInbox != null && fromInbox.isNotEmpty) return fromInbox;
    final fromRoute = widget.peerUserId?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) return fromRoute;
    final myId = ref.read(sessionStorageProvider).user?.id.trim() ?? '';
    final others = myId.isEmpty
        ? _members
        : _members.where((m) => m.id.trim() != myId).toList();
    if (others.length == 1) return others.first.id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref
        .watch(conversationsInboxProvider)
        .valueOrNull
        ?.items
        .where((c) => c.id == widget.conversationId);
    final fromInbox = inbox == null || inbox.isEmpty ? null : inbox.first;
    final title = (fromInbox?.title ?? widget.title ?? '').trim().isEmpty
        ? (widget.isGroup ? 'Nhóm' : 'Chat')
        : (fromInbox?.title ?? widget.title)!.trim();
    final avatarUrl = fromInbox?.avatarUrl ?? '';
    final chat = ref.watch(chatControllerProvider(widget.conversationId));
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(
          widget.isGroup ? 'Thông tin nhóm' : 'Thông tin cuộc trò chuyện',
        ),
      ),
      body: ListView(
        children: [
          ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  ChatMessageAvatar(
                    displayName: title,
                    avatarUrl: avatarUrl,
                    radius: 44,
                    onTap: widget.isGroup ? _openSettings : _openPeerProfile,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _HeroSubtitle(
                    isGroup: widget.isGroup,
                    memberCount: _members.length,
                    loading: _loadingHero,
                    peerUserId: _peerUserId(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.isGroup)
                        _QuickAction(
                          icon: Icons.group_outlined,
                          label: 'Thành viên',
                          color: primary,
                          onTap: _openMembers,
                        )
                      else
                        _QuickAction(
                          icon: Icons.person_outline,
                          label: 'Hồ sơ',
                          color: primary,
                          onTap: _openPeerProfile,
                        ),
                      _QuickAction(
                        icon: Icons.photo_library_outlined,
                        label: 'Ảnh, file',
                        color: primary,
                        onTap: () => _openMedia(),
                      ),
                      _QuickAction(
                        icon: Icons.alarm_outlined,
                        label: 'Nhắc hẹn',
                        color: primary,
                        onTap: () => showRoomRemindersSheet(
                          context: context,
                          roomId: widget.conversationId,
                        ),
                      ),
                      if (widget.isGroup)
                        _QuickAction(
                          icon: Icons.edit_outlined,
                          label: 'Đổi tên',
                          color: primary,
                          onTap: _openSettings,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (widget.isGroup) ...[
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.groups_outlined,
                  title: 'Thành viên nhóm',
                  count: _members.isEmpty ? null : _members.length,
                  onTap: _openMembers,
                ),
                if (_members.isNotEmpty)
                  _MemberPreview(
                    members: _members,
                    onTap: _openMembers,
                    onOpenUser: (id) =>
                        context.push(AppRoutes.userProfilePath(id)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.photo_outlined,
                title: 'Ảnh/Video',
                count: _images.isEmpty ? null : _images.length,
                onTap: () => _openMedia(),
              ),
              if (_images.isNotEmpty)
                _PhotoPreview(images: _images, onOpenAll: () => _openMedia()),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.insert_drive_file_outlined,
                title: 'File',
                onTap: () => _openMedia(tab: 1),
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.link,
                title: 'Link',
                onTap: () => _openMedia(tab: 2),
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.push_pin_outlined,
                title: 'Tin đã ghim',
                count: chat.pinned.isEmpty ? null : chat.pinned.length,
                onTap: () => showPinnedMessagesSheet(
                  context: context,
                  roomId: widget.conversationId,
                ),
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.alarm_outlined,
                title: 'Nhắc hẹn',
                count: chat.reminders.isEmpty ? null : chat.reminders.length,
                onTap: () => showRoomRemindersSheet(
                  context: context,
                  roomId: widget.conversationId,
                ),
              ),
            ],
          ),
          if (widget.isGroup && widget.canDelete) ...[
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Giải tán nhóm',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _confirmDeleteGroup,
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeroSubtitle extends ConsumerWidget {
  const _HeroSubtitle({
    required this.isGroup,
    required this.memberCount,
    required this.loading,
    required this.peerUserId,
  });

  final bool isGroup;
  final int memberCount;
  final bool loading;
  final String? peerUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGroup) {
      if (loading && memberCount == 0) {
        return const Text(
          'Nhóm',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        );
      }
      return Text(
        '$memberCount thành viên',
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      );
    }
    final peerId = peerUserId;
    if (peerId == null) {
      return const Text(
        'Trò chuyện trực tiếp',
        style: TextStyle(fontSize: 13, color: Colors.black54),
      );
    }
    final online = ref.watch(isUserOnlineProvider(peerId));
    return Text(
      online ? 'Đang hoạt động' : 'Không hoạt động',
      style: TextStyle(
        fontSize: 13,
        color: online ? const Color(0xFF2E7D32) : Colors.black54,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.black45),
              ),
            ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _MemberPreview extends StatelessWidget {
  const _MemberPreview({
    required this.members,
    required this.onTap,
    required this.onOpenUser,
  });

  final List<ContactUser> members;
  final VoidCallback onTap;
  final void Function(String userId) onOpenUser;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(8).toList();
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 84,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          scrollDirection: Axis.horizontal,
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final user = shown[index];
            return SizedBox(
              width: 56,
              child: Column(
                children: [
                  ChatMessageAvatar(
                    displayName: user.name,
                    avatarUrl: user.avatarUrl,
                    radius: 22,
                    onTap: () => onOpenUser(user.id),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.images, required this.onOpenAll});

  final List<RoomMediaImage> images;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final shown = images.take(4).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: InkWell(
                  onTap: onOpenAll,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      shown[i].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFE8EAED),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          for (var i = shown.length; i < 4; i++) ...[
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        ],
      ),
    );
  }
}
