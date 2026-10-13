class ChatRouteArgs {
  const ChatRouteArgs({
    required this.title,
    this.canDelete = false,
  });

  final String title;
  final bool canDelete;
}
