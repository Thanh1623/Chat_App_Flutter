import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/domain/entities/room_read.dart';
import 'package:chat_app/features/chat/presentation/files/chat_file_format.dart';
import 'package:chat_app/features/chat/presentation/files/chat_file_send.dart';
import 'package:chat_app/features/chat/presentation/images/chat_image_send.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/chat/presentation/widgets/group_members_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/group_settings_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/pinned_messages_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/room_media_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/message_seen_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/reaction_users_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/create_task_sheet.dart';
import 'package:chat_app/features/chat/presentation/widgets/work_task_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chat_app/features/conversations/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    this.title,
    this.canDelete = false,
    this.isGroup = false,
    this.peerUserId,
  });

  final String conversationId;
  final String? title;
  final bool canDelete;
  final bool isGroup;
  final String? peerUserId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  Map<String, String> _avatarByUserId = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMemberAvatars();
      final messageId = GoRouterState.of(context).uri.queryParameters['m'];
      if (messageId != null && messageId.isNotEmpty) {
        ref
            .read(chatControllerProvider(widget.conversationId).notifier)
            .flashMessage(messageId);
      }
    });
  }

  Future<void> _loadMemberAvatars() async {
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .fetchRoomMembers(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _avatarByUserId = {
          for (final m in members) m.id: m.avatarUrl,
        };
      });
    } catch (_) {
      // ponytail: avatar fallback từ message.authorAvatarUrl
    }
  }

  @override
  void dispose() {
    _composerFocus.dispose();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();
    await ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .send(text);
  }

  Future<void> _pickImage() async {
    final caption = _composer.text.trim();
    if (caption.isNotEmpty) {
      _composer.clear();
    }
    await pickAndSendChatImage(
      context,
      ref,
      widget.conversationId,
      caption: caption.isEmpty ? null : caption,
    );
  }

  Future<void> _createTask() async {
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .fetchRoomMembers(widget.conversationId);
      if (!mounted) return;
      final draft = await showCreateTaskSheet(
        context: context,
        members: members,
        suggestedAssigneeId: widget.isGroup ? null : _directPeerUserId(),
      );
      if (draft == null || !mounted) return;
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .createTask(
            title: draft.title,
            assigneeId: draft.assigneeId,
            notes: draft.notes,
            dueAt: draft.dueAt,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _pickFile() async {
    final caption = _composer.text.trim();
    if (caption.isNotEmpty) {
      _composer.clear();
    }
    await pickAndSendChatFiles(
      context,
      ref,
      widget.conversationId,
      caption: caption.isEmpty ? null : caption,
    );
  }

  void _openUserProfile(String? userId) {
    final id = userId?.trim() ?? '';
    if (id.isEmpty) return;
    context.push(AppRoutes.userProfilePath(id));
  }

  String? _directPeerUserId() {
    final fromInbox = ref
        .read(conversationsInboxProvider)
        .valueOrNull
        ?.items
        .where((c) => c.id == widget.conversationId)
        .map((c) => c.peerUserId)
        .whereType<String>();
    if (fromInbox != null && fromInbox.isNotEmpty) {
      final id = fromInbox.first.trim();
      if (id.isNotEmpty) return id;
    }
    final fromRoute = widget.peerUserId?.trim();
    if (fromRoute != null && fromRoute.isNotEmpty) return fromRoute;
    return null;
  }

  Future<void> _openDirectPeerProfile() async {
    if (widget.isGroup) return;

    final peerId = _directPeerUserId();
    if (peerId != null) {
      _openUserProfile(peerId);
      return;
    }

    final myId = ref.read(authControllerProvider).user?.id ??
        ref.read(sessionStorageProvider).user?.id;
    final myIdNorm = myId?.trim() ?? '';
    try {
      final members = await ref
          .read(conversationsRepositoryProvider)
          .fetchRoomMembers(widget.conversationId);
      if (!mounted) return;

      final others = myIdNorm.isEmpty
          ? members
          : members.where((m) => m.id.trim() != myIdNorm).toList();
      if (others.length == 1) {
        _openUserProfile(others.first.id);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy hồ sơ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _openGroupSettings() async {
    final inbox = ref
        .read(conversationsInboxProvider)
        .valueOrNull
        ?.items
        .where((c) => c.id == widget.conversationId);
    final fromInbox = inbox == null || inbox.isEmpty ? null : inbox.first;
    await showGroupSettingsSheet(
      context: context,
      roomId: widget.conversationId,
      name: (fromInbox?.title ?? widget.title ?? '').trim(),
      avatarUrl: fromInbox?.avatarUrl ?? '',
    );
  }

  Future<void> _openMembers() async {
    await showGroupMembersSheet(
      context: context,
      roomId: widget.conversationId,
      canManage: widget.canDelete,
      onChanged: _loadMemberAvatars,
    );
  }

  void _togglePin(ChatMessage message) {
    final chat =
        ref.read(chatControllerProvider(widget.conversationId).notifier);
    final myId = ref.read(sessionStorageProvider).user?.id;
    final mine = myId != null && message.userId == myId && !message.isAgent;
    showPinMessageActions(
      context: context,
      message: message,
      myId: myId,
      onSetPinned: (pinned) => chat.setPinned(message, pinned: pinned),
      onReact: (emoji) => chat.toggleReaction(message, emoji),
      onReply: () {
        chat.startReply(message);
        _composerFocus.requestFocus();
      },
      onRecall: mine && !message.recalled
          ? () => _confirmRecall(chat, message)
          : null,
      onHide: () => _confirmHide(chat, message),
      onSeenDetails: widget.isGroup && mine
          ? () => _showSeenDetails(message)
          : null,
    );
  }

  Future<void> _confirmRecall(ChatController chat, ChatMessage message) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Thu hồi tin nhắn?',
      message: 'Mọi người trong phòng sẽ thấy tin đã được thu hồi.',
      confirmLabel: 'Thu hồi',
    );
    if (!ok) return;
    await chat.recallMessage(message);
  }

  Future<void> _confirmHide(ChatController chat, ChatMessage message) async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Xóa phía tôi?',
      message: 'Tin sẽ biến khỏi máy bạn. Người khác vẫn thấy.',
      confirmLabel: 'Xóa',
    );
    if (!ok) return;
    await chat.hideMessage(message);
  }

  void _showReactors(ChatMessage message, String emoji) {
    showReactionUsersSheet(
      context: context,
      message: message,
      initialEmoji: emoji,
      onOpenUser: _openUserProfile,
    );
  }

  void _showSeenDetails(ChatMessage message) {
    showMessageSeenSheet(
      context: context,
      roomId: widget.conversationId,
      message: message,
      onOpenUser: _openUserProfile,
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
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionStorageProvider).user?.id;
    final roomId = widget.conversationId;
    final primary = Theme.of(context).colorScheme.primary;
    final inboxMatches = ref
        .watch(conversationsInboxProvider)
        .valueOrNull
        ?.items
        .where((c) => c.id == roomId);
    final inboxTitle =
        inboxMatches == null || inboxMatches.isEmpty ? null : inboxMatches.first.title;
    final appBarTitle = (inboxTitle?.trim().isNotEmpty == true
            ? inboxTitle
            : widget.title)
        ?.trim();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(conversationsInboxProvider.notifier).refreshInbox();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: InkWell(
          onTap: widget.isGroup ? _openGroupSettings : _openDirectPeerProfile,
          child: Text(
            appBarTitle?.isNotEmpty == true ? appBarTitle! : 'Chat',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Ảnh, file, link',
            onPressed: () => showRoomMediaSheet(
              context: context,
              roomId: widget.conversationId,
            ),
            icon: const Icon(Icons.perm_media_outlined),
          ),
          if (!widget.isGroup)
            IconButton(
              tooltip: 'Xem hồ sơ',
              onPressed: _openDirectPeerProfile,
              icon: const Icon(Icons.person_outline),
            ),
          if (widget.isGroup)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'settings') _openGroupSettings();
                if (value == 'members') _openMembers();
                if (value == 'delete') _confirmDeleteGroup();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Đổi tên / ảnh nhóm'),
                ),
                const PopupMenuItem(
                  value: 'members',
                  child: Text('Thành viên'),
                ),
                if (widget.canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa nhóm'),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          PinnedMessagesBanner(roomId: roomId),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final chat = ref.watch(chatControllerProvider(roomId));
                final myAvatar =
                    ref.watch(authControllerProvider).user?.avatarUrl ?? '';
                return _MessageList(
                  chat: chat,
                  myId: myId,
                  myAvatarUrl: myAvatar,
                  avatarByUserId: _avatarByUserId,
                  showSenderNames: widget.isGroup,
                  isGroup: widget.isGroup,
                  onOpenSenderProfile: _openUserProfile,
                  onPinToggle: _togglePin,
                  onShowReactors: _showReactors,
                  onShowSeenDetails: _showSeenDetails,
                  onRetry: () =>
                      ref.read(chatControllerProvider(roomId).notifier).load(),
                  onLoadMore: () => ref
                      .read(chatControllerProvider(roomId).notifier)
                      .loadMore(),
                  onToggleTask: (message) => ref
                      .read(chatControllerProvider(roomId).notifier)
                      .toggleTaskStatus(message),
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final chat = ref.watch(chatControllerProvider(roomId));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chat.error != null && chat.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: Text(
                        chat.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  _MessageComposer(
                    controller: _composer,
                    focusNode: _composerFocus,
                    sending: chat.isSending,
                    replyingTo: chat.replyingTo,
                    onClearReply: () => ref
                        .read(chatControllerProvider(roomId).notifier)
                        .clearReply(),
                    onSend: _send,
                    onPickImage: _pickImage,
                    onPickFile: _pickFile,
                    onCreateTask: _createTask,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({
    required this.chat,
    required this.myId,
    required this.myAvatarUrl,
    required this.avatarByUserId,
    required this.showSenderNames,
    required this.isGroup,
    required this.onOpenSenderProfile,
    required this.onPinToggle,
    required this.onShowReactors,
    required this.onShowSeenDetails,
    required this.onRetry,
    required this.onLoadMore,
    required this.onToggleTask,
  });

  final ChatController chat;
  final String? myId;
  final String myAvatarUrl;
  final Map<String, String> avatarByUserId;
  final bool showSenderNames;
  final bool isGroup;
  final void Function(String userId) onOpenSenderProfile;
  final void Function(ChatMessage message) onPinToggle;
  final void Function(ChatMessage message, String emoji) onShowReactors;
  final void Function(ChatMessage message) onShowSeenDetails;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final void Function(ChatMessage message) onToggleTask;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _scroll = ScrollController();
  final _itemKeys = <String, GlobalKey>{};
  String? _lastFlashId;
  bool _showJumpLatest = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final flashId = widget.chat.flashMessageId;
    if (flashId != null && flashId != _lastFlashId) {
      _lastFlashId = flashId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(flashId);
      });
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) =>
      _itemKeys.putIfAbsent(id, GlobalKey.new);

  void _scrollToMessage(String id) {
    final ctx = _keyFor(id).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.35,
    );
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    // reverse: true — pixels=0 là tin mới nhất; kéo lên trên thì pixels tăng.
    final showJump = position.pixels > 240;
    if (showJump != _showJumpLatest) {
      setState(() => _showJumpLatest = showJump);
    }
    if (position.pixels < position.maxScrollExtent - 240) return;
    widget.onLoadMore();
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;
    if (chat.isLoading && chat.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.error != null && chat.messages.isEmpty) {
      return ErrorView(message: chat.error!, onRetry: widget.onRetry);
    }
    if (chat.messages.isEmpty) {
      return const Center(child: Text('Chưa có tin nhắn'));
    }

    final extra = chat.isLoadingMore ? 1 : 0;
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: chat.messages.length + extra,
          itemBuilder: (context, index) {
            if (index >= chat.messages.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final message = chat.messages[index];
            final isMine = widget.myId != null && message.userId == widget.myId;
            return _MessageBubble(
              key: _keyFor(message.id),
              message: message,
              myId: widget.myId,
              highlighted: widget.chat.flashMessageId == message.id,
              isMine: isMine,
              avatarUrl: _resolveAvatarUrl(
                message: message,
                isMine: isMine,
                myAvatarUrl: widget.myAvatarUrl,
                avatarByUserId: widget.avatarByUserId,
              ),
              showSenderName: widget.showSenderNames,
              onOpenSenderProfile: widget.onOpenSenderProfile,
              onPinToggle: widget.onPinToggle,
              onShowReactors: widget.onShowReactors,
              onShowSeenDetails: widget.onShowSeenDetails,
              onOpenReply: widget.chat.flashMessage,
              onToggleTask: widget.onToggleTask,
              readers: chat.readersOf(message.id),
              isGroup: widget.isGroup,
            );
          },
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: IgnorePointer(
            ignoring: !_showJumpLatest,
            child: AnimatedOpacity(
              opacity: _showJumpLatest ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Material(
                color: Colors.white,
                elevation: 3,
                shadowColor: Colors.black26,
                shape: const CircleBorder(),
                child: Tooltip(
                  message: 'Tin mới nhất',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _jumpToLatest,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _resolveAvatarUrl({
    required ChatMessage message,
    required bool isMine,
    required String myAvatarUrl,
    required Map<String, String> avatarByUserId,
  }) {
    final fromMessage = message.authorAvatarUrl.trim();
    if (fromMessage.isNotEmpty) return fromMessage;
    if (isMine) return myAvatarUrl.trim();
    final uid = message.userId?.trim() ?? '';
    if (uid.isEmpty) return '';
    return avatarByUserId[uid]?.trim() ?? '';
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.myId,
    required this.highlighted,
    required this.isMine,
    required this.avatarUrl,
    required this.showSenderName,
    required this.onOpenSenderProfile,
    required this.onPinToggle,
    required this.onShowReactors,
    required this.onShowSeenDetails,
    required this.onOpenReply,
    required this.onToggleTask,
    required this.readers,
    required this.isGroup,
  });

  final ChatMessage message;
  final String? myId;
  final bool highlighted;
  final bool isMine;
  final String avatarUrl;
  final bool showSenderName;
  final void Function(String userId) onOpenSenderProfile;
  final void Function(ChatMessage message) onPinToggle;
  final void Function(ChatMessage message, String emoji) onShowReactors;
  final void Function(ChatMessage message) onShowSeenDetails;
  final void Function(String messageId) onOpenReply;
  final void Function(ChatMessage message) onToggleTask;
  final List<RoomRead> readers;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal());
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final showAvatar = !isMine && !message.isAgent;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar) ...[
            ChatMessageAvatar(
              displayName: message.authorName,
              avatarUrl: avatarUrl,
              onTap: message.userId == null
                  ? null
                  : () => onOpenSenderProfile(message.userId!),
            ),
            const SizedBox(width: 8),
          ] else if (!isMine) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showSenderName && !isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: InkWell(
                        onTap: () => onOpenSenderProfile(message.userId ?? ''),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 1,
                          ),
                          child: Text(
                            message.authorName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onLongPress: () => onPinToggle(message),
                        child: _BubbleBody(
                          message: message,
                          isMine: isMine,
                          myId: myId,
                          onOpenReply: onOpenReply,
                          onToggleTask: onToggleTask,
                        ),
                      ),
                      if (message.pinned && !message.recalled)
                        Positioned(
                          top: -5,
                          right: isMine ? -5 : null,
                          left: isMine ? null : -5,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: 0.55,
                                child: const Icon(
                                  Icons.push_pin,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!message.recalled && message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        alignment: isMine
                            ? WrapAlignment.end
                            : WrapAlignment.start,
                        children: [
                          for (final reaction in message.reactions)
                            _ReactionChip(
                              reaction: reaction,
                              mine: reaction.isMine(myId),
                              onTap: () =>
                                  onShowReactors(message, reaction.emoji),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  if (isMine && readers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _ReadReceipt(
                        readers: readers,
                        isGroup: isGroup,
                        onShowDetails: isGroup
                            ? () => onShowSeenDetails(message)
                            : null,
                      ),
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

class _ReadReceipt extends StatelessWidget {
  const _ReadReceipt({
    required this.readers,
    required this.isGroup,
    this.onShowDetails,
  });

  final List<RoomRead> readers;
  final bool isGroup;
  final VoidCallback? onShowDetails;

  @override
  Widget build(BuildContext context) {
    if (!isGroup) {
      return const Text(
        'Đã xem',
        style: TextStyle(fontSize: 11, color: Colors.black45),
      );
    }

    final shown = readers.take(3).toList();
    final extra = readers.length - shown.length;
    return Tooltip(
      message: readers.map((r) => r.name).join(', '),
      child: InkWell(
        onTap: onShowDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < shown.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                  child: ChatMessageAvatar(
                    displayName: shown[i].name,
                    avatarUrl: shown[i].avatarUrl,
                    radius: 8,
                  ),
                ),
              if (extra > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '+$extra',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text(
                  'Chi tiết',
                  style: TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.message,
    required this.isMine,
    required this.myId,
    required this.onOpenReply,
    required this.onToggleTask,
  });

  final ChatMessage message;
  final bool isMine;
  final String? myId;
  final void Function(String messageId) onOpenReply;
  final void Function(ChatMessage message) onToggleTask;

  @override
  Widget build(BuildContext context) {
    if (message.isTask) {
      return WorkTaskCard(
        message: message,
        myId: myId,
        onToggle: () => onToggleTask(message),
      );
    }

    if (message.recalled) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : const Color(0xFFE8EAED),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(
            'Tin nhắn đã được thu hồi',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    final bg = isMine
        ? primary
        : message.isAgent
            ? const Color(0xFFFFF3E0)
            : Colors.white;
    final textColor = isMine ? Colors.white : Colors.black87;
    final hasText = message.content.trim().isNotEmpty;
    final url = message.imageUrl?.trim() ?? '';
    final fileUrl = message.fileUrl?.trim() ?? '';
    final mediaOnly = (message.hasImage || message.hasFile) && !hasText;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: mediaOnly && message.hasImage ? Colors.white : bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMine ? 16 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo != null)
              _InBubbleReplyQuote(
                reply: message.replyTo!,
                isMine: isMine,
                onTap: () => onOpenReply(message.replyTo!.id),
              ),
            if (fileUrl.isNotEmpty)
              Material(
                color: isMine ? Colors.white.withValues(alpha: 0.12) : Colors.black12,
                child: InkWell(
                  onTap: () => _openFile(context, fileUrl),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.62,
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMine ? Colors.white : primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.fileName?.trim().isNotEmpty == true
                                      ? message.fileName!.trim()
                                      : 'Tệp đính kèm',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        isMine ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (message.fileSizeBytes != null &&
                                    message.fileSizeBytes! > 0)
                                  Text(
                                    formatFileSize(message.fileSizeBytes!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMine
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: isMine ? Colors.white70 : Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (url.isNotEmpty)
              GestureDetector(
                onTap: () => _openImage(context, url),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 120,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  message.content,
                  style: TextStyle(color: textColor, height: 1.35),
                  softWrap: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được tệp')),
      );
    }
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.reaction,
    required this.mine,
    required this.onTap,
  });

  final MessageReaction reaction;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: mine ? primary.withValues(alpha: 0.14) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: mine ? primary.withValues(alpha: 0.45) : Colors.black12,
            ),
          ),
          child: Text(
            '${reaction.emoji} ${reaction.count}',
            style: const TextStyle(fontSize: 12, height: 1.1),
          ),
        ),
      ),
    );
  }
}

class _InBubbleReplyQuote extends StatelessWidget {
  const _InBubbleReplyQuote({
    required this.reply,
    required this.isMine,
    required this.onTap,
  });

  final MessageReplyTo reply;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bar = isMine ? Colors.white : Theme.of(context).colorScheme.primary;
    final nameColor = isMine ? Colors.white : Theme.of(context).colorScheme.primary;
    final textColor = isMine ? Colors.white70 : Colors.black54;
    final fill = isMine
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.05);
    final thumb = reply.imageUrl?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: bar, width: 3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      reply.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.25, color: textColor),
                    ),
                  ],
                ),
              ),
              if (thumb.isNotEmpty) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    thumb,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    this.onCreateTask,
    this.replyingTo,
    this.onClearReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback? onCreateTask;
  final ChatMessage? replyingTo;
  final VoidCallback? onClearReply;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  bool _actionsExpanded = true;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _collapseActions();
    } else if (widget.controller.text.isEmpty) {
      _expandActions();
    }
  }

  void _onTextChange() {
    if (widget.controller.text.isNotEmpty) _collapseActions();
  }

  void _collapseActions() {
    if (!_actionsExpanded) return;
    setState(() => _actionsExpanded = false);
  }

  void _expandActions() {
    if (_actionsExpanded) return;
    setState(() => _actionsExpanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final reply = widget.replyingTo;
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reply != null)
              _ComposerReplyBar(
                message: reply,
                onClear: widget.onClearReply,
              ),
            Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: _actionsExpanded
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed:
                                widget.sending ? null : widget.onPickImage,
                            icon: Icon(Icons.image_outlined, color: primary),
                            tooltip: 'Gửi ảnh',
                          ),
                          IconButton(
                            onPressed:
                                widget.sending ? null : widget.onPickFile,
                            icon: Icon(Icons.attach_file, color: primary),
                            tooltip: 'Gửi tệp',
                          ),
                          IconButton(
                            onPressed:
                                widget.sending ? null : widget.onCreateTask,
                            icon: Icon(Icons.checklist_outlined, color: primary),
                            tooltip: 'Giao việc',
                          ),
                        ],
                      )
                    : IconButton(
                        onPressed: _expandActions,
                        icon: Icon(Icons.chevron_right, color: primary),
                        tooltip: 'Thêm',
                      ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onTap: _collapseActions,
                  onSubmitted: (_) => widget.onSend(),
                  decoration: InputDecoration(
                    hintText: reply == null
                        ? 'Tin nhắn'
                        : 'Trả lời ${reply.authorName}',
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.sending ? null : widget.onSend,
                icon: widget.sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: primary),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerReplyBar extends StatelessWidget {
  const _ComposerReplyBar({
    required this.message,
    this.onClear,
  });

  final ChatMessage message;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final thumb = message.imageUrl?.trim() ?? '';
    final preview = message.content.trim().isEmpty
        ? (message.hasImage
            ? 'Ảnh'
            : message.hasFile
                ? 'Tệp'
                : 'Tin nhắn')
        : message.content;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 38,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang trả lời ${message.authorName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (thumb.isNotEmpty) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    thumb,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              IconButton(
                tooltip: 'Hủy trả lời',
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
      ],
    );
  }
}
