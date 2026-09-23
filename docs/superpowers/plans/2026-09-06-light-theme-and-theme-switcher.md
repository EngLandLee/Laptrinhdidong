# Fresh Athletic Light Theme & Dynamic Theme Switcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide a complete Fresh Athletic Light Theme defaulting to Light Mode with an instant Light/Dark switcher button across the SportHub mobile app (both Consumer and Partner).

**Architecture:** A reactive `ThemeStore` singleton with a `ValueNotifier<ThemeMode>` (defaulting to `ThemeMode.light`) powers dynamic getters in `AppColors` and rebuilds the root `MaterialApp` in `SportHubApp`. Quick switcher buttons (☀️ / 🌙) in the Consumer header, Partner header, and settings screens allow effortless 1-tap toggling between Light and Dark modes.

**Tech Stack:** Flutter 3.x, Dart 3.x, Flutter Material Design 3, ValueNotifier reactive state.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + ValueNotifier reactive pattern.
- Design Theme: Fresh Athletic Light Theme default (background `#F8FAFC`, surface `#FFFFFF`, cardBorder `#E2E8F0`, textPrimary `#0F172A`, textSecondary `#64748B`, primary `#059669`), retaining Sporty Dark Luxury theme (`#0B0F19`, `#161F30`, `#223049`, `#F8FAFC`, `#94A3B8`, `#10B981`) on toggle.
- Backward Compatibility: Keep all existing unit, widget, and integration tests passing.

---

### Task 1: Core Theme State & Dynamic Color Palette

**Files:**
- Create: `lib/core/theme/theme_store.dart`
- Modify: `lib/core/constants/app_colors.dart`
- Modify: Non-const usages of `AppColors` in `lib/main.dart`, `lib/presentation/screens/auth_screen.dart`, `lib/presentation/screens/owner_navigation_screen.dart`, `lib/presentation/screens/owner_tabs/owner_checkin_tab.dart`, `lib/presentation/screens/owner_tabs/owner_revenue_tab.dart`, `lib/presentation/screens/owner_tabs/owner_schedule_tab.dart`
- Test: `test/core/theme/theme_store_test.dart`
- Test: `test/core/constants/app_colors_test.dart`

**Interfaces:**
- Consumes: Flutter `Material` (`ThemeMode`, `Color`, `ValueNotifier`).
- Produces:
  - `ThemeStore.instance`: `themeModeNotifier`, `isDarkMode`, `isLightMode`, `toggleTheme()`, `setThemeMode(ThemeMode)`, `reset()`.
  - `AppColors`: `darkBackground`, `lightBackground`, `darkSurface`, `lightSurface`, `darkCardBorder`, `lightCardBorder`, dynamic `background`, `surface`, `cardBorder`, `textPrimary`, `textSecondary`, `primary`.

- [ ] **Step 1: Write failing unit test for ThemeStore and AppColors**

```dart
// test/core/theme/theme_store_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/theme/theme_store.dart';

void main() {
  setUp(() {
    ThemeStore.instance.reset();
  });

  test('ThemeStore defaults to Light Mode as requested by user', () {
    expect(ThemeStore.instance.themeMode, ThemeMode.light);
    expect(ThemeStore.instance.isLightMode, isTrue);
    expect(ThemeStore.instance.isDarkMode, isFalse);
  });

  test('toggleTheme alternates between light and dark mode', () {
    expect(ThemeStore.instance.themeMode, ThemeMode.light);

    ThemeStore.instance.toggleTheme();
    expect(ThemeStore.instance.themeMode, ThemeMode.dark);
    expect(ThemeStore.instance.isDarkMode, isTrue);

    ThemeStore.instance.toggleTheme();
    expect(ThemeStore.instance.themeMode, ThemeMode.light);
    expect(ThemeStore.instance.isLightMode, isTrue);
  });

  test('setThemeMode directly sets mode and notifies listeners', () {
    ThemeMode? captured;
    ThemeStore.instance.themeModeNotifier.addListener(() {
      captured = ThemeStore.instance.themeMode;
    });

    ThemeStore.instance.setThemeMode(ThemeMode.dark);
    expect(captured, ThemeMode.dark);

    ThemeStore.instance.reset();
    expect(ThemeStore.instance.themeMode, ThemeMode.light);
  });
}
```

```dart
// test/core/constants/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/core/theme/theme_store.dart';

void main() {
  setUp(() {
    ThemeStore.instance.reset();
  });

  test('AppColors provides light palette in light mode', () {
    ThemeStore.instance.setThemeMode(ThemeMode.light);
    expect(AppColors.background, const Color(0xFFF8FAFC));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.cardBorder, const Color(0xFFE2E8F0));
    expect(AppColors.textPrimary, const Color(0xFF0F172A));
    expect(AppColors.textSecondary, const Color(0xFF64748B));
    expect(AppColors.primary, const Color(0xFF059669));
  });

  test('AppColors provides dark palette in dark mode', () {
    ThemeStore.instance.setThemeMode(ThemeMode.dark);
    expect(AppColors.background, const Color(0xFF0B0F19));
    expect(AppColors.surface, const Color(0xFF161F30));
    expect(AppColors.cardBorder, const Color(0xFF223049));
    expect(AppColors.textPrimary, const Color(0xFFF8FAFC));
    expect(AppColors.textSecondary, const Color(0xFF94A3B8));
    expect(AppColors.primary, const Color(0xFF10B981));
  });

  test('AppColors provides static brand and status constants', () {
    expect(AppColors.accent, const Color(0xFF00E676));
    expect(AppColors.secondary, const Color(0xFF06B6D4));
    expect(AppColors.warning, const Color(0xFFF59E0B));
    expect(AppColors.error, const Color(0xFFEF4444));
    expect(AppColors.slotAvailable, const Color(0xFF10B981));
    expect(AppColors.slotBooked, const Color(0xFFEF4444));
    expect(AppColors.slotSelected, const Color(0xFFF59E0B));
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/core/theme/theme_store_test.dart test/core/constants/app_colors_test.dart`
Expected: FAIL (`theme_store.dart` not found).

- [ ] **Step 3: Implement ThemeStore and update AppColors**

```dart
// lib/core/theme/theme_store.dart
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
    themeModeNotifier.value =
        isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  void reset() {
    themeModeNotifier.value = ThemeMode.light;
  }
}
```

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';
import '../theme/theme_store.dart';

class AppColors {
  // Dark Theme Palette Constants
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF161F30);
  static const Color darkCardBorder = Color(0xFF223049);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Palette Constants
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dynamic Getters driven by ThemeStore
  static bool get isDark => ThemeStore.instance.isDarkMode;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get cardBorder => isDark ? darkCardBorder : lightCardBorder;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  // Brand & Status Constants
  static const Color accent = Color(0xFF00E676);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Time-Slot Matrix Status Colors
  static const Color slotAvailable = Color(0xFF10B981);
  static const Color slotBooked = Color(0xFFEF4444);
  static const Color slotSelected = Color(0xFFF59E0B);

  // Backward compatibility aliases
  static const Color available = slotAvailable;
  static const Color booked = slotBooked;
  static const Color selected = slotSelected;
  static Color get backgroundLight => lightBackground;
  static Color get backgroundDark => darkBackground;
  static Color get cardLight => lightSurface;
  static Color get cardDark => darkSurface;
}
```

Remove `const` from any `const TextStyle(color: AppColors...)`, `const BorderSide(color: AppColors...)`, and `const Divider(color: AppColors...)` across the codebase so that they resolve the dynamic getter colors cleanly.

- [ ] **Step 4: Run unit tests and analyzer**

Run: `flutter test test/core/theme/theme_store_test.dart test/core/constants/app_colors_test.dart`
Expected: PASS (100% green).
Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/theme_store.dart lib/core/constants/app_colors.dart lib/ test/
git commit -m "feat: implement ThemeStore reactive state and dynamic AppColors palette"
```

---

### Task 2: Root App Reactive Theme & Quick Switcher Buttons in Consumer and Partner UI

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/presentation/screens/owner_navigation_screen.dart`
- Test: `test/presentation/screens/theme_switcher_test.dart`

**Interfaces:**
- Consumes: `ThemeStore.instance`, `AppColors`.
- Produces:
  - Root `SportHubApp` wrapped in `ValueListenableBuilder<ThemeMode>` on `ThemeStore.instance.themeModeNotifier`.
  - Quick theme toggle button in `ExploreVenuesScreen` with `Key('theme_toggle_button')`.
  - Quick theme toggle button in `OwnerNavigationScreen` with `Key('theme_toggle_button_owner')`.
  - Theme switcher tile in `ProfileScreen` and `OwnerSettingsTab`.

- [ ] **Step 1: Write failing widget test for theme switcher**

```dart
// test/presentation/screens/theme_switcher_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    ThemeStore.instance.reset();
    AuthStore.instance.loginAsGuest();
    VenueOwnerStore.instance.reset();
  });

  testWidgets('Consumer Explore header displays quick theme toggle button and switches theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
    final toggleFinder = find.byKey(const Key('theme_toggle_button'));
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isDarkMode, isTrue);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isLightMode, isTrue);
  });

  testWidgets('Partner Owner header displays quick theme toggle button and switches theme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    VenueOwnerStore.instance.toggleOwnerMode(true);

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final ownerToggleFinder = find.byKey(const Key('theme_toggle_button_owner'));
    expect(ownerToggleFinder, findsOneWidget);

    await tester.tap(ownerToggleFinder);
    await tester.pumpAndSettle();

    expect(ThemeStore.instance.isDarkMode, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/presentation/screens/theme_switcher_test.dart`
Expected: FAIL (`theme_toggle_button` not found).

- [ ] **Step 3: Implement root reactive theme and switcher buttons**

1. In `SportHubApp` (`lib/main.dart`):
   Wrap `MaterialApp` in `ValueListenableBuilder<ThemeMode>` on `ThemeStore.instance.themeModeNotifier`. Set `themeMode: themeMode`, configure `theme: ThemeData.light(...)` and `darkTheme: ThemeData.dark(...)`.
2. In `ExploreVenuesScreen` (`lib/main.dart`):
   Add quick toggle button `Key('theme_toggle_button')` in top header row:
   ```dart
   IconButton(
     key: const Key('theme_toggle_button'),
     tooltip: 'Đổi giao diện sáng/tối',
     icon: Icon(
       ThemeStore.instance.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
       color: AppColors.primary,
     ),
     onPressed: () => ThemeStore.instance.toggleTheme(),
   ),
   ```
3. In `OwnerNavigationScreen` (`lib/presentation/screens/owner_navigation_screen.dart`):
   Add quick toggle button `Key('theme_toggle_button_owner')` in `AppBar` actions list.
4. In `ProfileScreen` (`lib/main.dart`) and `OwnerSettingsTab` (`owner_navigation_screen.dart`):
   Add a theme settings card with title "Giao diện hiển thị", subtitle (indicating Sáng / Tối), and a Switch / Button calling `ThemeStore.instance.toggleTheme()`.

- [ ] **Step 4: Run widget tests and analyzer**

Run: `flutter test test/presentation/screens/theme_switcher_test.dart`
Expected: PASS (100% green).
Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/presentation/screens/owner_navigation_screen.dart test/presentation/screens/theme_switcher_test.dart
git commit -m "feat: wire reactive theme in SportHubApp and add quick theme switcher buttons"
```

---

### Task 3: Full Suite Verification, Web Hot Restart & User Demo

**Files:**
- None (verification & runtime update)

**Interfaces:**
- Run full test suite: `flutter test`
- Run static analyzer: `flutter analyze`
- Send hot restart to background task `task-673`.

- [ ] **Step 1: Run full test suite and static analysis**

Run: `flutter test`
Expected: 166+ tests passing.
Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 2: Hot restart web server**

Send `'R\n'` to background task `10d90848-1bdd-4fbd-ac33-9241276d4939/task-673`.
Verify console output confirms hot restart completed.

- [ ] **Step 3: User walkthrough and visual presentation**

Provide concise report with link `http://localhost:46477/`, explaining the new Fresh Athletic Light Theme, its tokens, and how the quick switcher (☀️ / 🌙) works.
