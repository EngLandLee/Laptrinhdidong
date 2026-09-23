# Visual Court Graphics & Flexible Shifts (:00 vs :30) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide realistic visual court graphics with court markings (badminton mat / football pitch), full daily shifts (Morning, Afternoon, Evening), and a minute toggle for half-hours (:00 vs :30) so users can easily book odd hours like 18:30 and 19:30.

**Architecture:** CustomPainter visual sports court widgets, dynamic shift slot generation utility, reactive shift/minute state in `VenueDetailScreen`.

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_bloc, intl.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame for Web/Desktop.
- UI Language & Messages: Vietnamese (Tiếng Việt).
- Architecture Pattern: Clean Architecture + BLoC pattern.
- Design Theme: Sporty Dark Luxury.

---

### Task 1: Build Visual Court Markings & Header Widget

**Files:**
- Create: `lib/presentation/widgets/visual_court_header.dart`
- Create: `test/presentation/widgets/visual_court_header_test.dart`

**Interfaces:**
- Consumes: `int courtNumber`, `String sportType` ('badminton', 'pickleball', 'football')
- Produces: `VisualCourtHeader` widget with `CustomPainter` rendering authentic court markings (boundary lines, service lines, net / center circle, penalty box).

- [ ] **Step 1: Write widget test for VisualCourtHeader**

```dart
// test/presentation/widgets/visual_court_header_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/visual_court_header.dart';

void main() {
  testWidgets('VisualCourtHeader renders badminton court markings and court number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisualCourtHeader(courtNumber: 1, sportType: 'badminton'),
        ),
      ),
    );

    expect(find.text('SÂN 1'), findsOneWidget);
    expect(find.text('Thảm BWF'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('VisualCourtHeader renders football pitch markings and court number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisualCourtHeader(courtNumber: 2, sportType: 'football'),
        ),
      ),
    );

    expect(find.text('SÂN 2'), findsOneWidget);
    expect(find.text('Cỏ FIFA'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/visual_court_header_test.dart`  
Expected: FAIL (widget not found)

- [ ] **Step 3: Implement `VisualCourtHeader` with CustomPainter**

Implement in `lib/presentation/widgets/visual_court_header.dart`:
- Badminton: Green mat (`Color(0xFF047857)`), white court lines with Net representation.
- Football: Deep turf (`Color(0xFF15803D)`), center circle, penalty box lines.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/visual_court_header_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/visual_court_header.dart test/presentation/widgets/visual_court_header_test.dart
git commit -m "feat: implement VisualCourtHeader with authentic badminton and football court markings"
```

---

### Task 2: Build Dynamic Shift & Half-Hour Slot Generator Utility

**Files:**
- Create: `lib/core/utils/shift_slot_generator.dart`
- Create: `test/core/utils/shift_slot_generator_test.dart`

**Interfaces:**
- Consumes: `String date`, `int courtCount`, `String shift` ('morning', 'afternoon', 'evening'), `String minuteOffset` (':00' or ':30')
- Produces: `List<TimeSlot>` covering all courts for that specific shift and minute offset with proper pricing (120k for day, 150k for evening).

- [ ] **Step 1: Write unit test for ShiftSlotGenerator**

```dart
// test/core/utils/shift_slot_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/shift_slot_generator.dart';

void main() {
  test('ShiftSlotGenerator generates :00 evening slots with 150k price', () {
    final slots = ShiftSlotGenerator.generateSlots(
      date: '2026-09-06',
      courtCount: 3,
      shift: 'evening',
      minuteOffset: ':00',
    );

    expect(slots.isNotEmpty, true);
    expect(slots.any((s) => s.startTime == '18:00' && s.endTime == '19:00'), true);
    expect(slots.first.price, 150000);
  });

  test('ShiftSlotGenerator generates :30 odd slots like 18:30 and 19:30', () {
    final slots = ShiftSlotGenerator.generateSlots(
      date: '2026-09-06',
      courtCount: 3,
      shift: 'evening',
      minuteOffset: ':30',
    );

    expect(slots.any((s) => s.startTime == '18:30' && s.endTime == '19:30'), true);
    expect(slots.any((s) => s.startTime == '19:30' && s.endTime == '20:30'), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/shift_slot_generator_test.dart`  
Expected: FAIL (class not found)

- [ ] **Step 3: Implement `ShiftSlotGenerator`**

Implement in `lib/core/utils/shift_slot_generator.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/shift_slot_generator_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/shift_slot_generator.dart test/core/utils/shift_slot_generator_test.dart
git commit -m "feat: implement ShiftSlotGenerator for morning, afternoon, evening and :00 vs :30 minute offsets"
```

---

### Task 3: Integrate Shifts, :30 Toggle & Visual Court Headers into VenueDetailScreen & TimeSlotMatrix

**Files:**
- Modify: `lib/presentation/widgets/time_slot_matrix.dart`
- Modify: `lib/main.dart` (`VenueDetailScreen`)
- Update: `test/presentation/screens/venue_detail_test.dart`

**Interfaces:**
- Consumes: `ShiftSlotGenerator`, `VisualCourtHeader`, `TimeSlotMatrix`, `BookingBloc`
- Produces:
  1. Shift Selector: `🌅 Sáng`, `☀️ Chiều`, `🌙 Tối cao điểm`
  2. Minute Toggle: `[🕒 Giờ chẵn :00]` vs `[🕡 Giờ rưỡi :30]`
  3. Visual Court Headers with court mat graphics
  4. Sơ đồ cụm sân 2D Overview Map

- [ ] **Step 1: Check existing test baseline**

Run: `flutter test`  
Expected: PASS

- [ ] **Step 2: Update `TimeSlotMatrix` to accept `sportType` and render `VisualCourtHeader`**

Update `lib/presentation/widgets/time_slot_matrix.dart` so each court column displays the `VisualCourtHeader`.

- [ ] **Step 3: Wire Shift Filter and :00 vs :30 Toggle into `VenueDetailScreen` in `lib/main.dart`**

Add `_selectedShift` ('evening', 'morning', 'afternoon') and `_selectedMinute` (':00', ':30'). Generate slots dynamically via `ShiftSlotGenerator`. Add 2D overview map.

- [ ] **Step 4: Run all tests to verify**

Run: `flutter test`  
Expected: PASS (all tests pass)

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/time_slot_matrix.dart lib/main.dart test/presentation/screens/venue_detail_test.dart
git commit -m "feat: integrate shifts, half-hour toggle, and visual court markings into VenueDetailScreen"
```

---

### Task 4: Full Suite Verification & Hot Restart

- [ ] **Step 1: Run complete automated test suite**

Run: `flutter test`  
Expected: 100% tests pass (0 failures)

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`  
Expected: 0 issues found

- [ ] **Step 3: Hot restart running Flutter Web server**

Verify on `http://localhost:46477/`:
- Visual court mat markings on court headers (BWF for badminton, FIFA grass for football).
- Shift filters (Sáng, Chiều, Tối).
- Odd hour toggle (:30) showing 18:30 - 19:30, 19:30 - 20:30, etc.
