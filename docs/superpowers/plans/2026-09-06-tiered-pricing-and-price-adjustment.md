# Tiered Pricing by Time Slot & Owner Price Adjustment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement realistic tiered hourly pricing (Early Bird, Off-peak daytime discount, Peak / Giờ vàng after-work hours) and a 1-tap price adjustment modal for venue owners in SportHub Partner.

**Architecture:** Extend `CourtSlotItem` with peak/off-peak helpers, update `VenueOwnerStore` to initialize Tao Đàn with realistic tiered prices and expose `updateSlotPrice(slotId, newPrice)`. Enhance `OwnerScheduleTab` with visual badges and an action sheet price adjustment tool.

**Tech Stack:** Flutter 3.x, Dart 3.x, ValueNotifier reactive state, Sporty Dark Luxury design tokens.

## Global Constraints
- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + ValueNotifier reactive pattern.
- Design Theme: Sporty Dark Luxury (`AppColors.background #0B0F19`, `surface #161F30`, `primary #10B981`, `secondary #06B6D4`, `warning #F59E0B`, `error #EF4444`).
- Backward Compatibility: Keep existing unit, widget, and integration tests passing.

---

### Task 1: Tiered Pricing Model & Store Price Modification

**Files:**
- Modify: `lib/domain/entities/court_slot_item.dart`
- Modify: `lib/core/state/venue_owner_store.dart`
- Modify: `test/core/state/venue_owner_store_test.dart`

**Interfaces:**
- `CourtSlotItem`:
  - `int get startHour`
  - `bool get isPeakHour`
  - `bool get isOffPeakHour`
- `VenueOwnerStore`:
  - `static double calculateDefaultSlotPrice({required String sportType, required int startHour})`
  - `void updateSlotPrice(String slotId, double newPrice)`

- [ ] **Step 1: Write failing unit test for Tiered Pricing and updateSlotPrice**

Modify `test/core/state/venue_owner_store_test.dart` to add tests:
```dart
test('Tao Đàn slots have tiered pricing according to peak and off-peak hours', () {
  final store = VenueOwnerStore.instance;
  // Hour 8 (08:00 - 09:00) is off-peak: 80k for badminton, 130k for pickleball
  final bdmOffPeak = store.slots.firstWhere((s) => s.slotId == 'court_01_08_00');
  expect(bdmOffPeak.price, equals(80000.0));
  expect(bdmOffPeak.isOffPeakHour, isTrue);
  expect(bdmOffPeak.isPeakHour, isFalse);

  final pkbOffPeak = store.slots.firstWhere((s) => s.slotId == 'court_05_08_00');
  expect(pkbOffPeak.price, equals(130000.0));
  expect(pkbOffPeak.isOffPeakHour, isTrue);

  // Hour 18 (18:00 - 19:00) is peak: 180k for badminton, 240k for pickleball
  final bdmPeak = store.slots.firstWhere((s) => s.slotId == 'court_01_18_00');
  expect(bdmPeak.price, equals(180000.0));
  expect(bdmPeak.isPeakHour, isTrue);

  final pkbPeak = store.slots.firstWhere((s) => s.slotId == 'court_05_18_00');
  expect(pkbPeak.price, equals(240000.0));
  expect(pkbPeak.isPeakHour, isTrue);
});

test('updateSlotPrice updates slot price and notifies listeners', () {
  final store = VenueOwnerStore.instance;
  final targetSlot = store.slots.firstWhere((s) => s.slotId == 'court_01_06_00');
  final originalPrice = targetSlot.price;

  store.updateSlotPrice('court_01_06_00', 95000.0);

  final updatedSlot = store.slots.firstWhere((s) => s.slotId == 'court_01_06_00');
  expect(updatedSlot.price, equals(95000.0));
  expect(updatedSlot.price, isNot(equals(originalPrice)));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/state/venue_owner_store_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement Tiered Pricing in CourtSlotItem and VenueOwnerStore**

In `lib/domain/entities/court_slot_item.dart`, add:
```dart
  int get startHour {
    final parts = timeRange.split(':');
    return parts.isNotEmpty ? (int.tryParse(parts[0].trim()) ?? 0) : 0;
  }

  bool get isPeakHour => startHour >= 17 && startHour < 21;
  bool get isOffPeakHour => startHour >= 8 && startHour < 16;
```

In `lib/core/state/venue_owner_store.dart`:
Add `calculateDefaultSlotPrice`:
```dart
  static double calculateDefaultSlotPrice({
    required String sportType,
    required int startHour,
  }) {
    final isBadminton = sportType == 'badminton';
    if (startHour >= 6 && startHour < 8) {
      return isBadminton ? 120000.0 : 160000.0;
    } else if (startHour >= 8 && startHour < 16) {
      return isBadminton ? 80000.0 : 130000.0;
    } else if (startHour >= 16 && startHour < 17) {
      return isBadminton ? 130000.0 : 170000.0;
    } else if (startHour >= 17 && startHour < 21) {
      return isBadminton ? 180000.0 : 240000.0;
    } else {
      return isBadminton ? 120000.0 : 150000.0;
    }
  }
```

Add `updateSlotPrice`:
```dart
  void updateSlotPrice(String slotId, double newPrice) {
    final index = _slots.indexWhere((s) => s.slotId == slotId);
    if (index != -1) {
      _slots[index] = _slots[index].copyWith(price: newPrice);
      slotsNotifier.value = List.unmodifiable(_slots);
    }
  }
```

In `_generateTaoDanSchedule()`:
Instead of flat `price = court['price'] as double;`, calculate:
```dart
final price = calculateDefaultSlotPrice(sportType: sport, startHour: hour);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/state/venue_owner_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/domain/entities/court_slot_item.dart lib/core/state/venue_owner_store.dart test/core/state/venue_owner_store_test.dart
git commit -m "feat: implement tiered slot pricing by hour and updateSlotPrice in VenueOwnerStore"
```

---

### Task 2: UI Visual Indicators & Custom Price Adjustment Action Sheet

**Files:**
- Modify: `lib/presentation/screens/owner_tabs/owner_schedule_tab.dart`
- Modify: `test/presentation/screens/owner_schedule_matrix_test.dart`

**Interfaces:**
- Produces:
  - `Key('action_update_slot_price')` in `Key('owner_slot_action_sheet')`
  - `Key('slot_price_input')` and `Key('confirm_update_price_button')` in price adjustment dialog
  - Peak and off-peak visual badges on slot cards.

- [ ] **Step 1: Write failing widget test for price visual and adjustment**

In `test/presentation/screens/owner_schedule_matrix_test.dart`, add tests:
```dart
testWidgets('OwnerScheduleTab displays tiered pricing and allows adjusting slot price', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: OwnerNavigationScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Find off-peak slot court_01_08_00
  final offPeakFinder = find.byKey(const Key('slot_tile_court_01_08_00'));
  expect(offPeakFinder, findsOneWidget);
  expect(find.descendant(of: offPeakFinder, matching: find.text('80k')), findsOneWidget);

  // Tap slot to open action sheet
  await tester.tap(offPeakFinder);
  await tester.pumpAndSettle();

  // Verify action_update_slot_price button exists
  final updatePriceBtn = find.byKey(const Key('action_update_slot_price'));
  expect(updatePriceBtn, findsOneWidget);

  // Tap update price button
  await tester.tap(updatePriceBtn);
  await tester.pumpAndSettle();

  // Enter new price 95000
  final priceInput = find.byKey(const Key('slot_price_input'));
  expect(priceInput, findsOneWidget);
  await tester.enterText(priceInput, '95000');
  await tester.tap(find.byKey(const Key('confirm_update_price_button')));
  await tester.pumpAndSettle();

  // Verify store and UI updated
  final updatedSlot = VenueOwnerStore.instance.slots.firstWhere((s) => s.slotId == 'court_01_08_00');
  expect(updatedSlot.price, equals(95000.0));
  expect(find.descendant(of: offPeakFinder, matching: find.text('95k')), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/owner_schedule_matrix_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement Visual Badges and Price Adjustment Modal**

In `lib/presentation/screens/owner_tabs/owner_schedule_tab.dart`:
1. In `_buildSlotTile`:
   - For `CourtSlotStatus.available`:
     - Show price `${(slot.price / 1000).toInt()}k`.
     - If `slot.isPeakHour`:
       - Show small orange/amber text or tag `🔥 Giờ vàng` (or `🔥 Vàng`).
       - Font color `AppColors.warning` or with subtle glow.
     - If `slot.isOffPeakHour`:
       - Show small cyan/emerald text `Ưu đãi` (or `Tiết kiệm`).
2. In `_SlotActionBottomSheet`:
   - For `CourtSlotStatus.available`:
     - Add action button `[💵 Đổi giá giờ này]` with `Key('action_update_slot_price')`.
     - When tapped, opens dialog or inline expansion:
       - Displays current price.
       - Quick preset chips: `80k`, `100k`, `120k`, `150k`, `180k`, `240k`.
       - Text input with `Key('slot_price_input')` pre-filled or accepting numeric input.
       - Button `[💾 Áp dụng giá mới]` with `Key('confirm_update_price_button')`.
       - Calling `VenueOwnerStore.instance.updateSlotPrice(slot.slotId, newPrice)`.
       - Closes sheet/dialog and shows confirmation SnackBar: `'Đã cập nhật giá sân thành công'`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/owner_schedule_matrix_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/screens/owner_tabs/owner_schedule_tab.dart test/presentation/screens/owner_schedule_matrix_test.dart
git commit -m "feat: render peak and off-peak price indicators and implement custom slot price adjustment"
```

---

### Task 3: Full Suite Verification, Web Hot Restart & Demo Handoff

**Files:**
- None (verification and live hot restart)

- [ ] **Step 1: Run static analysis**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run full test suite**
Run: `flutter test`
Expected: All 155+ tests pass across all test suites.

- [ ] **Step 3: Hot restart web server**
Send `R\n` to background task `10d90848-1bdd-4fbd-ac33-9241276d4939/task-673`.

- [ ] **Step 4: Present demo walkthrough**
Present full explanation and walkthrough in Vietnamese to the user.
