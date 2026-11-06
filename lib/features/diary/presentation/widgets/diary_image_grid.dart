import 'package:flutter/material.dart';

class DiaryImageGrid extends StatelessWidget {
  const DiaryImageGrid({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    if (urls.length == 1) {
      return _Tile(
        url: urls.first,
        aspectRatio: 16 / 10,
        onTap: () => _open(context, 0),
      );
    }

    return AspectRatio(
      aspectRatio: 1.05,
      child: Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: _Tile(url: urls[i], onTap: () => _open(context, i)),
            ),
          ],
        ],
      ),
    );
  }

  void _open(BuildContext context, int index) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _DiaryImageViewer(urls: urls, initialIndex: index),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.url, required this.onTap, this.aspectRatio});

  final String url;
  final VoidCallback onTap;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE0E0E0),
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );

    return Material(
      color: const Color(0xFFE0E0E0),
      child: InkWell(
        onTap: onTap,
        child: aspectRatio == null
            ? image
            : AspectRatio(aspectRatio: aspectRatio!, child: image),
      ),
    );
  }
}

class _DiaryImageViewer extends StatefulWidget {
  const _DiaryImageViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_DiaryImageViewer> createState() => _DiaryImageViewerState();
}

class _DiaryImageViewerState extends State<_DiaryImageViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.urls.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.urls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
