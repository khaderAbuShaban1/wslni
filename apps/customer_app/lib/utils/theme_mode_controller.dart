import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'app_theme_mode';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

Future<void> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(_themeModeKey);
  appThemeMode.value = switch (value) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };
}

Future<void> setDarkMode(bool enabled) async {
  final mode = enabled ? ThemeMode.dark : ThemeMode.light;
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModeKey, mode.name);
}
