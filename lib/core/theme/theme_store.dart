import 'package:flutter/material.dart';

class ThemeStore {
  ThemeStore._();
  static final ThemeStore instance = ThemeStore._();

  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  ThemeMode get themeMode => themeModeNotifier.value;
  bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;
  bool get isLightMode => themeModeNotifier.value == ThemeMode.light;

  void toggleTheme() {
    themeModeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  void reset() {
    themeModeNotifier.value = ThemeMode.light;
  }
}
