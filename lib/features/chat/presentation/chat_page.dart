import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/core/widgets/confirm_dialog.dart';
import 'package:chat_app/core/widgets/error_view.dart';
import 'package:chat_app/features/chat/domain/entities/chat_message.dart';
import 'package:chat_app/features/chat/presentation/chat_file_format.dart';
import 'package:chat_app/features/chat/presentation/chat_file_send.dart';
import 'package:chat_app/features/chat/presentation/chat_image_send.dart';
import 'package:chat_app/features/chat/presentation/providers/chat_controller.dart';
import 'package:chat_app/features/chat/presentation/widgets/chat_message_avatar.dart';
import 'package:chat_app/features/chat/presentation/widgets/group_members_sheet.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMemberAvatars());
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

  Future<void> _openMembers() async {
    await showGroupMembersSheet(
      context: context,
      roomId: widget.conversationId,
      canManage: widget.canDelete,
      onChanged: _loadMemberAvatars,
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
          onTap: widget.isGroup ? null : _openDirectPeerProfile,
          child: Text(
            appBarTitle?.isNotEmpty == true ? appBarTitle! : 'Chat',
          ),
        ),
        actions: [
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
                if (value == 'members') _openMembers();
                if (value == 'delete') _confirmDeleteGroup();
              },
              itemBuilder: (context) => [
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
                  onOpenSenderProfile: _openUserProfile,
                  onRetry: () =>
                      ref.read(chatControllerProvider(roomId).notifier).load(),
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
                    onSend: _send,
                    onPickImage: _pickImage,
                    onPickFile: _pickFile,
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

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.chat,
    required this.myId,
    required this.myAvatarUrl,
    required this.avatarByUserId,
    required this.showSenderNames,
    required this.onOpenSenderProfile,
    required this.onRetry,
  });

  final ChatController chat;
  final String? myId;
  final String myAvatarUrl;
  final Map<String, String> avatarByUserId;
  final bool showSenderNames;
  final void Function(String userId) onOpenSenderProfile;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (chat.isLoading && chat.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.error != null && chat.messages.isEmpty) {
      return ErrorView(message: chat.error!, onRetry: onRetry);
    }
    if (chat.messages.isEmpty) {
      return const Center(child: Text('Chưa có tin nhắn'));
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        final isMine = myId != null && message.userId == myId;
        return _MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMine: isMine,
          avatarUrl: _resolveAvatarUrl(
            message: message,
            isMine: isMine,
            myAvatarUrl: myAvatarUrl,
            avatarByUserId: avatarByUserId,
          ),
          showSenderName: showSenderNames,
          onOpenSenderProfile: onOpenSenderProfile,
        );
      },
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
    required this.isMine,
    required this.avatarUrl,
    required this.showSenderName,
    required this.onOpenSenderProfile,
  });

  final ChatMessage message;
  final bool isMine;
  final String avatarUrl;
  final bool showSenderName;
  final void Function(String userId) onOpenSenderProfile;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal());
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final showAvatar = !isMine && !message.isAgent;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                  _BubbleBody(message: message, isMine: isMine),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Text(
                      timeLabel,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black45),
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

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
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

class _MessageComposer extends StatefulWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;

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
    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
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
                    hintText: 'Tin nhắn',
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
      ),
    );
  }
}
