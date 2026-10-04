import 'package:chat_app/app/app.dart';
import 'package:chat_app/app/bootstrap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  await bootstrap(
    () => const ProviderScope(child: App()),
  );
}
