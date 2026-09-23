# SportHub Mobile UI Overhaul (Sporty Dark Luxury) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform SportHub into a premium "Sporty Dark Luxury" mobile experience, fixing wide desktop stretching via a centered smartphone viewport frame, fixing missing Material icon glyphs, and elevating cards and navigation to professional Dribbble standards.

**Architecture:** Flutter M3 Dark Theme with Clean Architecture, wrapping the application in a `ResponsiveMobileWrapper` that provides an authentic smartphone frame when viewed on desktop browsers while rendering 100% native on mobile devices.

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_bloc, google_generative_ai, sqflite, qr_flutter.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with responsive smartphone viewport frame for Web/Desktop.
- UI Language & Messages: Vietnamese (Tiếng Việt).
- Architecture Pattern: Clean Architecture + BLoC pattern.
- Design Theme: Sporty Dark Luxury (Obsidian `#0B0F19`, Slate Surface `#161F30`, Neon Emerald `#10B981` & `#00E676`, Cyber Cyan `#06B6D4`, Radiant Amber `#F59E0B`).

---

### Task 1: Fix Material Design Icons & Upgrade AppColors to Sporty Dark Luxury

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/constants/app_colors.dart`
- Modify/Create: `test/core/constants/app_colors_test.dart`

**Interfaces:**
- Consumes: Flutter standard material library
- Produces: `AppColors.background`, `AppColors.surface`, `AppColors.cardBorder`, `AppColors.primary`, `AppColors.secondary`, `AppColors.accent`, `AppColors.warning`, `AppColors.error`, `AppColors.textPrimary`, `AppColors.textSecondary`

- [ ] **Step 1: Write failing test for new Dark Luxury AppColors**

```dart
// test/core/constants/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';

void main() {
  test('AppColors provides Sporty Dark Luxury palette constants', () {
    expect(AppColors.background, const Color(0xFF0B0F19));
    expect(AppColors.surface, const Color(0xFF161F30));
    expect(AppColors.cardBorder, const Color(0xFF223049));
    expect(AppColors.primary, const Color(0xFF10B981));
    expect(AppColors.accent, const Color(0xFF00E676));
    expect(AppColors.secondary, const Color(0xFF06B6D4));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/constants/app_colors_test.dart`  
Expected: FAIL (missing fields or mismatched color codes)

- [ ] **Step 3: Update `pubspec.yaml` and `app_colors.dart`**

Add `uses-material-design: true` under `flutter:` in `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true
```

Update `lib/core/constants/app_colors.dart`:
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Sporty Dark Luxury Theme
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF161F30);
  static const Color cardBorder = Color(0xFF223049);
  static const Color primary = Color(0xFF10B981);
  static const Color accent = Color(0xFF00E676);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Time-Slot Matrix Status Colors
  static const Color slotAvailable = Color(0xFF10B981);
  static const Color slotBooked = Color(0xFFEF4444);
  static const Color slotSelected = Color(0xFFF59E0B);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/constants/app_colors_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/core/constants/app_colors.dart test/core/constants/app_colors_test.dart
git commit -m "fix: enable uses-material-design and update AppColors to Sporty Dark Luxury"
```

---

### Task 2: Build Responsive Mobile Viewport Wrapper

**Files:**
- Create: `lib/presentation/widgets/responsive_mobile_wrapper.dart`
- Create: `test/presentation/widgets/responsive_mobile_wrapper_test.dart`

**Interfaces:**
- Consumes: Flutter standard layout widgets
- Produces: `ResponsiveMobileWrapper(child: Widget)` widget that wraps content in a smartphone container with max width 420px and phone styling on desktop, and 100% full screen on mobile screens.

- [ ] **Step 1: Write test for ResponsiveMobileWrapper**

```dart
// test/presentation/widgets/responsive_mobile_wrapper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/responsive_mobile_wrapper.dart';

void main() {
  testWidgets('ResponsiveMobileWrapper renders child widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: Text('Mobile Content Test'),
        ),
      ),
    );

    expect(find.text('Mobile Content Test'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/responsive_mobile_wrapper_test.dart`  
Expected: FAIL (class not defined)

- [ ] **Step 3: Implement `ResponsiveMobileWrapper`**

```dart
// lib/presentation/widgets/responsive_mobile_wrapper.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ResponsiveMobileWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop / Web Viewport: Center in a sleek smartphone frame
          return Container(
            color: const Color(0xFF030712), // Dark backdrop behind the phone
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 890),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 8,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: child,
                ),
              ),
            ),
          );
        }

        // Native Smartphone View: Fullscreen
        return child;
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/responsive_mobile_wrapper_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/responsive_mobile_wrapper.dart test/presentation/widgets/responsive_mobile_wrapper_test.dart
git commit -m "feat: implement ResponsiveMobileWrapper for smartphone frame preview on desktop"
```

---

### Task 3: Upgrade TimeSlotMatrix UI for Dark Luxury Styling

**Files:**
- Modify: `lib/presentation/widgets/time_slot_matrix.dart`
- Test: `test/presentation/widgets/time_slot_matrix_test.dart`

**Interfaces:**
- Consumes: `List<TimeSlot> slots`, `Set<String> selectedSlotIds`, `ValueChanged<TimeSlot> onSlotTapped`
- Produces: Polished 2D matrix with dark slate header, glowing status cells, and clear slot prices.

- [ ] **Step 1: Check existing test compatibility**

Run: `flutter test test/presentation/widgets/time_slot_matrix_test.dart`  
Expected: PASS (baseline check)

- [ ] **Step 2: Update `lib/presentation/widgets/time_slot_matrix.dart` styling**

Update cell colors, borders, and text colors to match `AppColors.surface`, `AppColors.cardBorder`, and glowing states:
- Available: background `Color(0xFF064E3B).withOpacity(0.4)`, border `AppColors.primary`, text `AppColors.primary`
- Booked: background `Color(0xFF450A0A).withOpacity(0.3)`, border `Colors.red.withOpacity(0.2)`, text `Colors.red.shade300`
- Selected: background `Color(0xFF78350F).withOpacity(0.5)`, border `AppColors.warning`, text `Colors.amber.shade300`

- [ ] **Step 3: Run widget test to verify compatibility**

Run: `flutter test test/presentation/widgets/time_slot_matrix_test.dart`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/time_slot_matrix.dart
git commit -m "feat: polish TimeSlotMatrix with dark luxury neon aesthetics"
```

---

### Task 4: Complete UI Overhaul in `lib/main.dart`

**Files:**
- Modify: `lib/main.dart`
- Create: `test/presentation/screens/main_ui_test.dart`

**Interfaces:**
- Consumes: `BookingBloc`, `SeedData`, `VietQRGenerator`, `ResponsiveMobileWrapper`, `TimeSlotMatrix`
- Produces: Complete 3-tab application wrapped in `ResponsiveMobileWrapper` with Sporty Dark Luxury Theme:
  1. `ExploreVenuesScreen`: Modern header, search bar, active glowing pill filters, 16:9 venue cards with rating badges.
  2. `VenueDetailScreen`: Detailed venue header, 2D matrix, sticky bottom bar, and VietQR modal.
  3. `MatchmakingScreen`: AI banner with cyber gradient, animated recommendation cards with match percentage pill badges.
  4. `MyTicketsScreen`: Sport boarding pass ticket card with QR code, match details, and offline badge.

- [ ] **Step 1: Write integration test for main UI elements**

```dart
// test/presentation/screens/main_ui_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/main.dart';

void main() {
  testWidgets('Main screen renders SportHub brand, tabs and venues', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    expect(find.text('SportHub'), findsWidgets);
    expect(find.text('Đặt sân'), findsOneWidget);
    expect(find.text('Ghép kèo AI'), findsOneWidget);
    expect(find.text('Vé của tôi'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify current state**

Run: `flutter test test/presentation/screens/main_ui_test.dart`  
Expected: PASS or minor text check

- [ ] **Step 3: Implement full Dark Luxury redesign in `lib/main.dart`**

Apply dark theme (`scaffoldBackgroundColor: AppColors.background`), wrap root home with `ResponsiveMobileWrapper`, add floating bottom navigation bar with capsule styling, redesign `ExploreVenuesScreen`, `VenueDetailScreen`, `MatchmakingScreen`, and `MyTicketsScreen`.

- [ ] **Step 4: Run all tests to verify no regressions**

Run: `flutter test`  
Expected: PASS (All tests pass)

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/presentation/screens/main_ui_test.dart
git commit -m "feat: overhaul main UI with Sporty Dark Luxury mobile design and responsive phone wrapper"
```

---

### Task 5: End-to-End Verification & Browser Hot Reload

**Files:**
- Verification only

- [ ] **Step 1: Run complete automated test suite**

Run: `flutter test`  
Expected: 100% tests pass (0 failures)

- [ ] **Step 2: Verify Flutter Web in Chrome**

Check the running web instance at `http://localhost:46477/`, trigger hot reload (`r`), and ensure:
1. Centered mobile viewport frame is rendered cleanly with dark background.
2. All Material icons (star, racket, ticket, QR, search, pin) are crisp without missing glyph boxes.
3. Card images, rating badges, chips, and VietQR modal render beautifully.
