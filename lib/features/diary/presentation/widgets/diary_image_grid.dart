import 'package:flutter/material.dart';

class DiaryImageGrid extends StatelessWidget {
  const DiaryImageGrid({super.key, required this.urls});

  final List<String> urls;

  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (urls.length == 1) {
          return _Tile(
            url: urls.first,
            height: width * 10 / 16,
            onTap: () => _open(context, 0),
          );
        }

        final visible = urls.length > 4 ? 4 : urls.length;
        final extra = urls.length - visible;
        final cell = (width - _gap) / 2;
        final rows = (visible + 1) ~/ 2;
        final height = rows * cell + (rows - 1) * _gap;

        return SizedBox(
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < rows; row++) ...[
                if (row > 0) const SizedBox(height: _gap),
                SizedBox(
                  height: cell,
                  child: Row(
                    children: [
                      Expanded(
                        child: _mosaicCell(context, row * 2, extra, visible),
                      ),
                      if (row * 2 + 1 < visible) ...[
                        const SizedBox(width: _gap),
                        Expanded(
                          child: _mosaicCell(
                            context,
                            row * 2 + 1,
                            extra,
                            visible,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _mosaicCell(
    BuildContext context,
    int index,
    int extra,
    int visible,
  ) {
    final isMore = index == visible - 1 && extra > 0;
    return Stack(
      fit: StackFit.expand,
      children: [
        _Tile(url: urls[index], onTap: () => _open(context, index)),
        if (isMore)
          ColoredBox(
            color: const Color(0x66000000),
            child: Center(
              child: Text(
                '+$extra',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
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
  const _Tile({required this.url, required this.onTap, this.height});

  final String url;
  final VoidCallback onTap;
  final double? height;

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

    final child = Material(
      color: const Color(0xFFE0E0E0),
      child: InkWell(onTap: onTap, child: image),
    );

    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: child);
    }
    return child;
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
