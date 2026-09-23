import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/theme/theme_store.dart';

void main() {
  setUp(() {
    ThemeStore.instance.reset();
  });

  tearDown(() {
    ThemeStore.instance.reset();
  });

  group('ThemeStore', () {
    test('initial state defaults to light theme mode', () {
      expect(ThemeStore.instance.themeMode, ThemeMode.light);
      expect(ThemeStore.instance.isLightMode, isTrue);
      expect(ThemeStore.instance.isDarkMode, isFalse);
    });

    test('toggleTheme alternates between light and dark modes', () {
      expect(ThemeStore.instance.isDarkMode, isFalse);

      ThemeStore.instance.toggleTheme();
      expect(ThemeStore.instance.themeMode, ThemeMode.dark);
      expect(ThemeStore.instance.isDarkMode, isTrue);
      expect(ThemeStore.instance.isLightMode, isFalse);

      ThemeStore.instance.toggleTheme();
      expect(ThemeStore.instance.themeMode, ThemeMode.light);
      expect(ThemeStore.instance.isDarkMode, isFalse);
      expect(ThemeStore.instance.isLightMode, isTrue);
    });

    test('setThemeMode updates themeMode and notifies listeners', () {
      var notificationCount = 0;
      ThemeStore.instance.themeModeNotifier.addListener(() {
        notificationCount++;
      });

      ThemeStore.instance.setThemeMode(ThemeMode.dark);
      expect(ThemeStore.instance.themeMode, ThemeMode.dark);
      expect(notificationCount, 1);

      ThemeStore.instance.setThemeMode(ThemeMode.light);
      expect(ThemeStore.instance.themeMode, ThemeMode.light);
      expect(notificationCount, 2);
    });

    test('reset restores default light mode', () {
      ThemeStore.instance.setThemeMode(ThemeMode.dark);
      expect(ThemeStore.instance.isDarkMode, isTrue);

      ThemeStore.instance.reset();
      expect(ThemeStore.instance.themeMode, ThemeMode.light);
      expect(ThemeStore.instance.isLightMode, isTrue);
    });
  });
}
