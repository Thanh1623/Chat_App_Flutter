class NewsBlock {
  const NewsBlock.paragraph(this.text)
    : type = NewsBlockType.paragraph,
      imageId = null,
      caption = '';

  const NewsBlock.heading(this.text)
    : type = NewsBlockType.heading,
      imageId = null,
      caption = '';

  const NewsBlock.image({required this.imageId, this.caption = ''})
    : type = NewsBlockType.image,
      text = null;

  final NewsBlockType type;
  final String? text;
  final String? imageId;
  final String caption;

  Map<String, dynamic> toJson() {
    return switch (type) {
      NewsBlockType.paragraph => {'type': 'paragraph', 'text': text ?? ''},
      NewsBlockType.heading => {'type': 'heading', 'text': text ?? ''},
      NewsBlockType.image => {
        'type': 'image',
        'imageId': imageId ?? '',
        'caption': caption,
      },
    };
  }
}

enum NewsBlockType { paragraph, heading, image }
