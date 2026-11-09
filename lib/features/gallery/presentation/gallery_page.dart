import 'package:chat_app/features/gallery/presentation/providers/gallery_providers.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_albums_tab.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_my_photos_tab.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_review_tab.dart';
import 'package:chat_app/features/gallery/presentation/widgets/gallery_submit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(galleryAccessProvider);
    final access = accessAsync.value;

    if (access == null) {
      return accessAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Thư viện ảnh')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Thư viện ảnh')),
          body: Center(child: Text('$e')),
        ),
        data: (_) => const SizedBox.shrink(),
      );
    }

    final canReview = access.canReview;
    final length = canReview ? 3 : 2;
    _tabs ??= TabController(length: length, vsync: this)
      ..addListener(() {
        if (_tabs?.indexIsChanging ?? true) return;
        if (canReview && _tabs?.index == 2) {
          ref.read(galleryPhotoFeedProvider('review').notifier).refresh();
        }
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện ảnh'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'Album'),
            const Tab(text: 'Ảnh của tôi'),
            if (canReview) const Tab(text: 'Duyệt ảnh'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGallerySubmitSheet(context, ref),
        icon: const Icon(Icons.upload_outlined),
        label: const Text('Gửi ảnh'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          GalleryAlbumsTab(canReview: canReview),
          const GalleryMyPhotosTab(),
          if (canReview) const GalleryReviewTab(),
        ],
      ),
    );
  }
}
