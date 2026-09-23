# Visual Court Slot Graphics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render realistic sports court graphics (badminton BWF mat lines and football FIFA pitch markings) directly inside every individual slot cell in `TimeSlotMatrix`.

**Architecture:** Create a dedicated `VisualCourtSlotCell` widget combining `BadmintonCourtPainter` / `FootballPitchPainter` with state-specific overlays (Available, Selected, Booked), high-contrast semi-transparent pill badges for price and status labels, and integrate it into `TimeSlotMatrix`.

**Tech Stack:** Flutter SDK 3.x, Dart 3.x, CustomPainter, BLoC pattern, Sporty Dark Luxury theme tokens.

## Global Constraints
- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + BLoC pattern.
- Design Theme: Sporty Dark Luxury.

---

### Task 1: Create `VisualCourtSlotCell` Component

**Files:**
- Create: `lib/presentation/widgets/visual_court_slot_cell.dart`
- Test: `test/presentation/widgets/visual_court_slot_cell_test.dart`

**Interfaces:**
- Consumes:
  - `TimeSlot` from `lib/domain/entities/time_slot.dart`
  - `BadmintonCourtPainter`, `FootballPitchPainter` from `lib/presentation/widgets/visual_court_header.dart`
  - `AppColors` from `lib/core/constants/app_colors.dart`
- Produces:
  - `VisualCourtSlotCell({required TimeSlot slot, required String sportType, required bool isSelected, required VoidCallback? onTap, double width = 120, double height = 74})`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/widgets/visual_court_slot_cell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/widgets/visual_court_slot_cell.dart';

void main() {
  final testSlot = TimeSlot(
    id: 'court1_1800_1900',
    venueId: 'venue_1',
    courtNumber: 1,
    startTime: '18:00',
    endTime: '19:00',
    price: 150000,
    status: SlotStatus.available,
  );

  testWidgets('VisualCourtSlotCell renders badminton court lines and available state', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisualCourtSlotCell(
            slot: testSlot,
            sportType: 'badminton',
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('150000 đ'), findsOneWidget);
    expect(find.text('Còn trống'), findsOneWidget);

    await tester.tap(find.byKey(const Key('slot_court1_1800_1900')));
    expect(tapped, isTrue);
  });

  testWidgets('VisualCourtSlotCell renders selected state with amber glow and tick icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisualCourtSlotCell(
            slot: testSlot,
            sportType: 'badminton',
            isSelected: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Đang chọn'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('VisualCourtSlotCell renders booked state with lock icon and disabled tap', (tester) async {
    final bookedSlot = testSlot.copyWith(status: SlotStatus.booked);
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisualCourtSlotCell(
            slot: bookedSlot,
            sportType: 'badminton',
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Đã đặt'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('slot_court1_1800_1900')));
    expect(tapped, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/visual_court_slot_cell_test.dart`
Expected: Compilation failure because `visual_court_slot_cell.dart` does not exist.

- [ ] **Step 3: Implement `VisualCourtSlotCell`**

```dart
// lib/presentation/widgets/visual_court_slot_cell.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/time_slot.dart';
import 'visual_court_header.dart';

class VisualCourtSlotCell extends StatelessWidget {
  final TimeSlot slot;
  final String sportType;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const VisualCourtSlotCell({
    super.key,
    required this.slot,
    required this.sportType,
    required this.isSelected,
    this.onTap,
    this.width = 120,
    this.height = 74,
  });

  bool get _isFootball {
    final lower = sportType.toLowerCase();
    return lower.contains('football') ||
        lower.contains('bóng đá') ||
        lower.contains('soccer');
  }

  Color get _courtBaseColor {
    if (_isFootball) {
      return const Color(0xFF15803D); // Deep pitch green
    }
    return const Color(0xFF047857); // Deep court green
  }

  @override
  Widget build(BuildContext context) {
    final isBooked = slot.status == SlotStatus.booked;
    final courtPainter = _isFootball
        ? const FootballPitchPainter()
        : const BadmintonCourtPainter();

    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow>? shadows;
    final Color overlayColor;
    final Widget statusWidget;

    if (isSelected) {
      borderColor = AppColors.slotSelected;
      borderWidth = 1.8;
      overlayColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
      shadows = [
        BoxShadow(
          color: AppColors.slotSelected.withValues(alpha: 0.4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            'Đang chọn',
            style: TextStyle(
              color: Colors.amber.shade200,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              shadows: const [
                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
              ],
            ),
          ),
        ],
      );
    } else if (isBooked) {
      borderColor = Colors.red.withValues(alpha: 0.4);
      borderWidth = 1.0;
      overlayColor = const Color(0xFF0F172A).withValues(alpha: 0.78);
      shadows = null;
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_rounded, size: 12, color: Colors.red.shade300),
          const SizedBox(width: 3),
          Text(
            'Đã đặt',
            style: TextStyle(
              color: Colors.red.shade200,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              shadows: const [
                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
              ],
            ),
          ),
        ],
      );
    } else {
      // Available
      borderColor = AppColors.slotAvailable.withValues(alpha: 0.85);
      borderWidth = 1.2;
      overlayColor = Colors.transparent;
      shadows = [
        BoxShadow(
          color: AppColors.slotAvailable.withValues(alpha: 0.2),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.slotAvailable,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Còn trống',
            style: TextStyle(
              color: AppColors.slotAvailable,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              shadows: [
                Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _courtBaseColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Realistic Court Vector Graphics
            Positioned.fill(
              child: CustomPaint(
                painter: courtPainter,
              ),
            ),

            // 2. Tinted overlay according to state
            if (overlayColor != Colors.transparent)
              Positioned.fill(
                child: Container(color: overlayColor),
              ),

            // 3. Center pill with high contrast readability
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.slotSelected.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${slot.price.toInt()} đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isBooked
                          ? AppColors.textSecondary.withValues(alpha: 0.6)
                          : Colors.white,
                      shadows: const [
                        Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  statusWidget,
                ],
              ),
            ),

            // 4. InkWell overlay for ripple effect
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('slot_${slot.id}'),
                onTap: slot.isAvailable ? onTap : null,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/visual_court_slot_cell_test.dart`
Expected: PASS (All 3 tests pass).

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/visual_court_slot_cell.dart test/presentation/widgets/visual_court_slot_cell_test.dart
git commit -m "feat: implement VisualCourtSlotCell with authentic sports court markings and state overlays"
```

---

### Task 2: Integrate `VisualCourtSlotCell` into `TimeSlotMatrix`

**Files:**
- Modify: `lib/presentation/widgets/time_slot_matrix.dart:228-263`
- Test: `test/presentation/widgets/time_slot_matrix_test.dart`
- Test: `test/presentation/screens/venue_detail_test.dart`

**Interfaces:**
- Consumes:
  - `VisualCourtSlotCell` from `lib/presentation/widgets/visual_court_slot_cell.dart`
- Produces:
  - Updated `TimeSlotMatrix` rendering `VisualCourtSlotCell` in place of plain slot containers.

- [ ] **Step 1: Write/update the failing widget test**

Update `test/presentation/widgets/time_slot_matrix_test.dart` to assert that `VisualCourtSlotCell` is rendered for slots in the matrix.

```dart
// test/presentation/widgets/time_slot_matrix_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/widgets/time_slot_matrix.dart';
import 'package:sporthub/presentation/widgets/visual_court_slot_cell.dart';

void main() {
  final sampleSlots = [
    TimeSlot(
      id: 'c1_1700_1800',
      venueId: 'v1',
      courtNumber: 1,
      startTime: '17:00',
      endTime: '18:00',
      price: 150000,
      status: SlotStatus.available,
    ),
    TimeSlot(
      id: 'c2_1700_1800',
      venueId: 'v1',
      courtNumber: 2,
      startTime: '17:00',
      endTime: '18:00',
      price: 150000,
      status: SlotStatus.booked,
    ),
  ];

  testWidgets('TimeSlotMatrix renders VisualCourtSlotCell for each slot in the grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeSlotMatrix(
            slots: sampleSlots,
            selectedSlotIds: const {'c1_1700_1800'},
            onSlotTapped: (_) {},
            sportType: 'badminton',
          ),
        ),
      ),
    );

    expect(find.byType(VisualCourtSlotCell), findsNWidgets(2));
    expect(find.text('Đang chọn'), findsOneWidget);
    expect(find.text('Đã đặt'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/time_slot_matrix_test.dart`
Expected: FAIL (`find.byType(VisualCourtSlotCell)` finds 0 widgets).

- [ ] **Step 3: Update `TimeSlotMatrix` to render `VisualCourtSlotCell`**

In `lib/presentation/widgets/time_slot_matrix.dart`:
1. Import `visual_court_slot_cell.dart`.
2. In the `matrix[timeFrame]?[court]` mapping:
```dart
                      ...courtNumbers.map((court) {
                        final slot = matrix[timeFrame]?[court];
                        if (slot == null) {
                          return Container(
                            width: 120,
                            height: 74,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.center,
                            child: const Text('-', style: TextStyle(color: AppColors.textSecondary)),
                          );
                        }

                        final isSelected = selectedSlotIds.contains(slot.id);

                        return Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: VisualCourtSlotCell(
                            slot: slot,
                            sportType: sportType,
                            isSelected: isSelected,
                            onTap: () => onSlotTapped(slot),
                            width: 120,
                            height: 74,
                          ),
                        );
                      }),
```

- [ ] **Step 4: Run all tests to verify they pass**

Run: `flutter test`
Expected: 58/58 tests pass.

- [ ] **Step 5: Verify static analysis**

Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/time_slot_matrix.dart test/presentation/widgets/time_slot_matrix_test.dart
git commit -m "feat: integrate VisualCourtSlotCell into TimeSlotMatrix for immersive court slots"
```
