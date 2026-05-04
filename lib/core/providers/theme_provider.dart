import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/app_theme.dart' show setActiveThemeKey;

/// Riverpod provider for the active theme key.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, String>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<String> {
  ThemeNotifier() : super('solaire') {
    _load();
  }

  static const _key = 'theme_key';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? 'solaire';
    setActiveThemeKey(state);
  }

  Future<void> setTheme(String key) async {
    state = key;
    setActiveThemeKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, key);
  }
}
