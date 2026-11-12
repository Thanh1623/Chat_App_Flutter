import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/diary/presentation/diary_post_detail_page.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_compose_provider.dart';
import 'package:chat_app/features/diary/presentation/providers/diary_feed_provider.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_avatar.dart';
import 'package:chat_app/features/diary/presentation/widgets/diary_tokens.dart';
import 'package:chat_app/features/news/domain/entities/news_image.dart';
import 'package:chat_app/features/news/domain/news_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class DiaryComposePage extends ConsumerStatefulWidget {
  const DiaryComposePage({super.key, this.editPostId});

  final String? editPostId;

  @override
  ConsumerState<DiaryComposePage> createState() => _DiaryComposePageState();
}

class _DiaryComposePageState extends ConsumerState<DiaryComposePage> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _picker = ImagePicker();
  var _draftRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureDraft();
      if (mounted && ref.read(diaryComposeProvider).post != null) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _editing => widget.editPostId != null;

  Future<void> _ensureDraft() async {
    if (_draftRequested) return;
    _draftRequested = true;
    final compose = ref.read(diaryComposeProvider);
    if (compose.post != null || compose.busy) return;

    final editId = widget.editPostId;
    final ok = editId != null
        ? await ref.read(diaryComposeProvider.notifier).loadExisting(editId)
        : await ref.read(diaryComposeProvider.notifier).startDraft();
    if (!ok || !mounted) return;

    if (editId != null) {
      final post = ref.read(diaryComposeProvider).post;
      if (post != null) {
        _text.text = postToCompose(title: post.title, blocks: post.blocks);
        setState(() {});
      }
    }
  }

  Future<void> _pickImages() async {
    final compose = ref.read(diaryComposeProvider);
    final room = NewsLimits.images - compose.images.length;
    if (room <= 0) {
      _toast('Mỗi bài tối đa ${NewsLimits.images} ảnh.');
      return;
    }
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    final notifier = ref.read(diaryComposeProvider.notifier);
    for (final file in files.take(room)) {
      final bytes = await file.readAsBytes();
      final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
      await notifier.uploadBytes(bytes, name);
    }
  }

  Future<void> _submit() async {
    final notifier = ref.read(diaryComposeProvider.notifier);
    final ok = _editing
        ? await notifier.saveEdits(_text.text)
        : await notifier.publish(_text.text);
    if (!mounted) return;
    if (ok) {
      await ref.read(diaryFeedProvider.notifier).refresh();
      final editId = widget.editPostId;
      if (editId != null) {
        ref.invalidate(diaryPostDetailProvider(editId));
      }
      if (!mounted) return;
      context.pop(true);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _close() {
    if (ref.read(diaryComposeProvider).busy) return;
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final compose = ref.watch(diaryComposeProvider);
    final user = ref.watch(authControllerProvider).user;
    final name = user?.displayName ?? 'Bạn';
    final avatar = user?.avatarUrl;

    ref.listen(diaryComposeProvider, (prev, next) {
      final err = next.error;
      if (err != null && err != prev?.error) {
        _toast(err);
        ref.read(diaryComposeProvider.notifier).clearError();
      }
    });

    final loadingDraft = compose.post == null && compose.busy;
    final canPost = compose.post != null &&
        !compose.busy &&
        compose.uploading == 0 &&
        (_text.text.trim().isNotEmpty || compose.images.isNotEmpty);

    return PopScope(
      canPop: !compose.busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(diaryComposeProvider.notifier).reset();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: compose.busy ? null : _close,
          ),
          title: Text(
            _editing ? 'Sửa bài viết' : 'Tạo bài viết',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: canPost ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: DiaryTokens.moment,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                ),
                child: compose.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_editing ? 'Lưu' : 'Đăng'),
              ),
            ),
          ],
        ),
        body: loadingDraft
            ? const Center(child: CircularProgressIndicator())
            : compose.post == null
            ? _ErrorBody(
                message: compose.error ??
                    (_editing
                        ? 'Không tải được bài viết.'
                        : 'Không tạo được bản nháp. Bạn cần quyền đăng bài (news.publish).'),
                onRetry: () {
                  _draftRequested = false;
                  _ensureDraft();
                },
                onClose: _close,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        Row(
                          children: [
                            DiaryAvatar(
                              name: name,
                              url: avatar,
                              radius: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Bài viết trên Nhật ký',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _text,
                          focusNode: _focus,
                          enabled: !compose.busy,
                          onChanged: (_) => setState(() {}),
                          maxLines: null,
                          minLines: 6,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 17, height: 1.45),
                          decoration: const InputDecoration(
                            hintText: 'Hôm nay bạn thế nào?',
                            hintStyle: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        if (compose.images.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _ComposePhotoGrid(
                            busy: compose.busy || compose.uploading > 0,
                            images: compose.images,
                            onRemove: (id) => ref
                                .read(diaryComposeProvider.notifier)
                                .removeImage(id),
                          ),
                        ],
                        if (compose.uploading > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Đang tải ảnh (${compose.uploading})…',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Material(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            _ToolChip(
                              icon: Icons.photo_library_rounded,
                              label: 'Ảnh',
                              color: DiaryTokens.photo,
                              enabled: !compose.busy &&
                                  compose.uploading == 0 &&
                                  compose.images.length < NewsLimits.images,
                              onTap: _pickImages,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${compose.images.length}/${NewsLimits.images} ảnh',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color.withValues(alpha: 0.12) : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: enabled ? color : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: enabled ? const Color(0xFF424242) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposePhotoGrid extends StatelessWidget {
  const _ComposePhotoGrid({
    required this.images,
    required this.onRemove,
    required this.busy,
  });

  final List<NewsImage> images;
  final bool busy;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const cols = 3;
        final cell = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < images.length; i++)
              SizedBox(
                width: cell,
                height: cell,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        images[i].thumbUrl.isNotEmpty
                            ? images[i].thumbUrl
                            : images[i].displayUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE0E0E0),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    if (!busy)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onRemove(images[i].id),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          TextButton(onPressed: onClose, child: const Text('Đóng')),
        ],
      ),
    );
  }
}
