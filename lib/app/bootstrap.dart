import 'dart:async';

import 'package:chat_app/core/config/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap(AppBuilder builder) async {
  Env.load();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(builder());
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught: $error\n$stack');
      }
    },
  );
}
