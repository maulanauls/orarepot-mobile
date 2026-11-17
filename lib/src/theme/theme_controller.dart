import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists light/dark preference — same role as orappob theme toggle.
class ThemeController extends ChangeNotifier {
  ThemeController();

  static const _key = 'orarepot-theme';

  ThemeMode _mode = ThemeMode.dark;
  bool _loaded = false;

  ThemeMode get mode => _mode;
  bool get isLight => _mode == ThemeMode.light;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLight(bool light) async {
    _mode = light ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, light ? 'light' : 'dark');
  }

  Future<void> toggle() => setLight(!isLight);
}
