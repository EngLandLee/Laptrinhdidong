# Fresh Athletic Light Theme & Dynamic Theme Switcher Design Spec

## 1. Context & Motivation
SportHub currently uses a **Sporty Dark Luxury** theme (`#0B0F19` background, `#161F30` surface).
The user requested: *"chắc tôi muốn giao diện sáng hơn á"* (I probably want a brighter interface / light mode).
In the brainstorming session, the user chose **Approach 1: Fresh Athletic Light Theme with dynamic Light/Dark Mode toggle (defaulting to Light Mode as requested)**, keeping full backward compatibility with Dark Mode through quick switcher buttons (☀️ / 🌙) in the app headers and settings.

---

## 2. Design Tokens & Color Palettes

### 2.1 Theme Palettes
SportHub maintains both a pristine **Fresh Athletic Light** palette and the existing **Sporty Dark Luxury** palette:

| Token | Light Theme (Default) | Dark Theme (Optional) | Semantic Usage |
|---|---|---|---|
| `background` | `#F8FAFC` (Pearl White) | `#0B0F19` (Deep Obsidian) | Main screen scaffold background |
| `surface` | `#FFFFFF` (Pure Crisp White) | `#161F30` (Navy Dark Slate) | Card containers, modal sheets, nav bars |
| `cardBorder` | `#E2E8F0` (Light Slate Border) | `#223049` (Dark Border) | Card outlines, dividers, input borders |
| `textPrimary` | `#0F172A` (Dark Slate) | `#F8FAFC` (Off-white) | Main headings, primary labels, values |
| `textSecondary` | `#64748B` (Cool Slate) | `#94A3B8` (Muted Slate) | Subtitles, hints, secondary metadata |
| `primary` | `#059669` (Athletic Emerald) | `#10B981` (Neon Emerald) | Brand CTAs, active states, badges |
| `secondary` | `#06B6D4` (Cyan) | `#06B6D4` (Cyan) | Secondary sport badges, chips |
| `accent` | `#00E676` (Mint Glow) | `#00E676` (Mint Glow) | Highlights, glow accents |
| `warning` | `#F59E0B` (Amber Peak) | `#F59E0B` (Amber Peak) | Peak hour badges, caution alerts |
| `error` | `#EF4444` (Crimson) | `#EF4444` (Crimson) | Booked slots, error notifications |

---

## 3. Architecture & State Management

### 3.1 `ThemeStore` Singleton
Location: `lib/core/theme/theme_store.dart`
- Pattern: Reactive Singleton with `ValueNotifier<ThemeMode>`.
- Default: `ThemeMode.light` (satisfying the user request).
- Properties:
  - `final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);`
  - `ThemeMode get themeMode => themeModeNotifier.value;`
  - `bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;`
  - `bool get isLightMode => themeModeNotifier.value == ThemeMode.light;`
- Methods:
  - `void toggleTheme()`: Switches between `ThemeMode.light` and `ThemeMode.dark`.
  - `void setThemeMode(ThemeMode mode)`: Sets specific theme mode.
  - `void reset()`: Reverts to `ThemeMode.light`.

### 3.2 Dynamic `AppColors`
Location: `lib/core/constants/app_colors.dart`
- Keeps static constants for dark palette (`darkBackground`, `darkSurface`, `darkCardBorder`, etc.) and light palette (`lightBackground`, `lightSurface`, `lightCardBorder`, etc.).
- Exposes dynamic getters:
  ```dart
  static bool get isDark => ThemeStore.instance.isDarkMode;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surface => isDark ? darkSurface : lightSurface;
  static Color get cardBorder => isDark ? darkCardBorder : lightCardBorder;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : lightTextSecondary;
  static Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  ```
- Any `const TextStyle(color: AppColors.textPrimary)` or `const BorderSide(color: AppColors.cardBorder)` will have `const` removed on the constructor invocation so that the color resolves dynamically at runtime.

### 3.3 Root App Shell Reactive Wrapper
Location: `lib/main.dart` -> `SportHubApp`
- Listens to `ThemeStore.instance.themeModeNotifier` with `ValueListenableBuilder<ThemeMode>`.
- Configures both `theme: ThemeData.light(...)` and `darkTheme: ThemeData.dark(...)`, with `themeMode: themeMode`.
- Entire app tree rebuilds instantly upon theme toggle with zero delay and smooth animation.

---

## 4. UI Switcher Components & Touchpoints

1. **Consumer Header (ExploreVenuesScreen)**:
   - Location: Right side of Top App Header in `ExploreVenuesScreen`, alongside the notification bell.
   - Key: `Key('theme_toggle_button')`.
   - Tooltip: `'Đổi giao diện sáng/tối'`.
   - Icon: `Icons.light_mode_rounded` (when in dark mode, tap for light) / `Icons.dark_mode_rounded` (when in light mode, tap for dark).

2. **Partner Header (OwnerNavigationScreen)**:
   - Location: App bar action buttons alongside `Icons.swap_horiz_rounded`.
   - Key: `Key('theme_toggle_button_owner')`.
   - Tooltip: `'Đổi giao diện sáng/tối'`.
   - Icon: Matches current mode.

3. **Profile Settings**:
   - Location: `ProfileScreen` account settings list and `OwnerSettingsTab`.
   - Item: "Giao diện hiển thị" with subtitle "Chế độ sáng / tối" and quick toggle or switcher tile.

---

## 5. Verification & Testing Strategy
1. **Unit Tests**:
   - `test/core/theme/theme_store_test.dart`:
     - Default theme is `ThemeMode.light`.
     - `toggleTheme()` flips from light to dark and vice versa.
     - `setThemeMode()` updates properly.
     - `reset()` reverts to light.
   - `test/core/constants/app_colors_test.dart`:
     - Verifies `AppColors.lightBackground` is `0xFFF8FAFC`.
     - Verifies `AppColors.darkBackground` is `0xFF0B0F19`.
     - Verifies dynamic `AppColors.background` resolves according to `ThemeStore.instance.isDarkMode`.
2. **Widget Tests**:
   - `test/presentation/screens/theme_switcher_test.dart`:
     - Tapping `Key('theme_toggle_button')` toggles theme mode and updates icons.
     - Tapping `Key('theme_toggle_button_owner')` in owner mode toggles theme mode.
3. **Full Regression**:
   - All 164 existing tests must remain green.
   - Hot restart web server running at `http://localhost:46477/`.
