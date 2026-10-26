import 'dart:async';

import 'package:chat_app/app/router/routes.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/work/domain/entities/task_notice.dart';
import 'package:chat_app/features/work/presentation/providers/work_tasks_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IncomingTaskBannerHost extends ConsumerStatefulWidget {
  const IncomingTaskBannerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingTaskBannerHost> createState() =>
      _IncomingTaskBannerHostState();
}

class _IncomingTaskBannerHostState
    extends ConsumerState<IncomingTaskBannerHost> {
  TaskNotice? _visible;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _show(TaskNotice notice) {
    _hide?.cancel();
    setState(() => _visible = notice);
    _hide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = null);
    });
  }

  void _open(TaskNotice notice) {
    _hide?.cancel();
    setState(() => _visible = null);
    if (notice.roomId.isEmpty) return;
    var path = AppRoutes.chatPath(notice.roomId);
    final messageId = notice.messageId?.trim() ?? '';
    if (messageId.isNotEmpty) path = '$path?m=$messageId';
    context.push(path, extra: notice.roomName);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TaskNotice?>(taskNoticeProvider, (previous, next) {
      if (next == null) return;
      final myId = ref.read(sessionStorageProvider).user?.id;
      if (!next.shouldShowBanner(myId)) return;
      final path = GoRouter.of(context).state.uri.path;
      if (noticeIsCurrentChat(path, next.roomId)) return;
      _show(next);
    });

    final notice = _visible;
    return Stack(
      children: [
        widget.child,
        if (notice != null)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: _IncomingMessageCard(
                notice: notice,
                onTap: () => _open(notice),
                onDismiss: () {
                  _hide?.cancel();
                  setState(() => _visible = null);
                },
              ),
            ),
          ),
      ],
    );
  }
}

bool noticeIsCurrentChat(String path, String roomId) {
  if (roomId.isEmpty) return false;
  return path == AppRoutes.chatPath(roomId) ||
      path.startsWith('${AppRoutes.chatPath(roomId)}?');
}

class _IncomingMessageCard extends StatelessWidget {
  const _IncomingMessageCard({
    required this.notice,
    required this.onTap,
    required this.onDismiss,
  });

  final TaskNotice notice;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final name = notice.actorName.isEmpty ? 'Thành viên' : notice.actorName;
    return Material(
      elevation: 8,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: notice.actorAvatarUrl.trim().isEmpty
                    ? null
                    : NetworkImage(notice.actorAvatarUrl),
                child: notice.actorAvatarUrl.trim().isEmpty
                    ? Text(
                        name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notice.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
