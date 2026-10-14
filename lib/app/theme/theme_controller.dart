import 'package:chat_app/app/theme/app_accent.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeControllerProvider =
    ChangeNotifierProvider<ThemeController>((ref) {
  final controller = ThemeController(ref);
  controller.load();
  return controller;
});

class ThemeController extends ChangeNotifier {
  ThemeController(this._ref);

  final Ref _ref;

  AppAccent _accent = AppAccent.blue;

  AppAccent get accent => _accent;

  SessionStorage get _session => _ref.read(sessionStorageProvider);

  Future<void> load() async {
    _accent = await _session.loadThemeAccent();
    notifyListeners();
  }

  Future<void> setAccent(AppAccent accent) async {
    if (_accent == accent) return;
    _accent = accent;
    notifyListeners();
    await _session.saveThemeAccent(accent);
  }
}
