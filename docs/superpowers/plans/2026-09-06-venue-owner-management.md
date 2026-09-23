# SportHub Partner - Venue Owner Management Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement SportHub Partner (Venue Owner Management) featuring flexible Player/Owner mode switching, a real-time court schedule matrix with 1-tap lock and manual walk-in reservations, QR check-in & booking management, and revenue/occupancy analytics.

**Architecture:** A reactive singleton `VenueOwnerStore` managing `isOwnerMode`, active venue, court slot items, and check-in states. An `OwnerNavigationScreen` replacing the consumer navigation bar when owner mode is active, containing 4 specialized management tabs.

**Tech Stack:** Flutter 3.x, Dart 3.x, ValueNotifier reactive state, Sporty Dark Luxury styling.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Design Theme: Sporty Dark Luxury (AppColors.background #0B0F19, surface #161F30, primary #10B981, secondary #06B6D4, accent #F59E0B).
- Backward Compatibility: Keep all existing 135 tests passing.

---

### Task 1: Domain Entities & VenueOwnerStore Reactive State

**Files:**
- Create: `lib/domain/entities/court_slot_item.dart`
- Create: `lib/core/state/venue_owner_store.dart`
- Modify: `lib/core/utils/seed_data.dart` (add partner owner user `user_owner_01`)
- Create: `test/core/state/venue_owner_store_test.dart`

**Interfaces:**
- Produces:
  - `enum CourtSlotStatus { available, bookedApp, reservedManual, maintenance }`
  - `class CourtSlotItem { slotId, courtName, timeRange, status, customerName, customerPhone, ticketId, price }`
  - `class VenueOwnerStore { static final instance; isOwnerModeNotifier; slotsNotifier; toggleOwnerMode(); reserveSlot(); lockMaintenance(); unlockSlot(); checkInTicket(); reset(); }`

- [ ] **Step 1: Write failing unit test for VenueOwnerStore**

Create `test/core/state/venue_owner_store_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/domain/entities/court_slot_item.dart';

void main() {
  late VenueOwnerStore store;

  setUp(() {
    store = VenueOwnerStore.instance;
    store.reset();
  });

  test('initial state has owner mode disabled and pre-seeded court slots', () {
    expect(store.isOwnerMode, isFalse);
    expect(store.slots.isNotEmpty, isTrue);
    expect(store.activeVenueName, contains('Tao Đàn'));
  });

  test('toggleOwnerMode switches owner mode state', () {
    store.toggleOwnerMode(true);
    expect(store.isOwnerMode, isTrue);

    store.toggleOwnerMode(false);
    expect(store.isOwnerMode, isFalse);
  });

  test('reserveSlot changes slot status to reservedManual with customer info', () {
    final target = store.slots.firstWhere((s) => s.status == CourtSlotStatus.available);
    store.reserveSlot(
      target.slotId,
      customerName: 'Anh Tuấn (Khách quen)',
      customerPhone: '0912 345 678',
    );

    final updated = store.slots.firstWhere((s) => s.slotId == target.slotId);
    expect(updated.status, equals(CourtSlotStatus.reservedManual));
    expect(updated.customerName, equals('Anh Tuấn (Khách quen)'));
  });

  test('lockMaintenance and unlockSlot cycle slot availability', () {
    final target = store.slots.firstWhere((s) => s.status == CourtSlotStatus.available);
    store.lockMaintenance(target.slotId);

    var current = store.slots.firstWhere((s) => s.slotId == target.slotId);
    expect(current.status, equals(CourtSlotStatus.maintenance));

    store.unlockSlot(target.slotId);
    current = store.slots.firstWhere((s) => s.slotId == target.slotId);
    expect(current.status, equals(CourtSlotStatus.available));
  });

  test('checkInTicket marks checkin timestamp on ticket', () {
    final result = store.checkInTicket('SH-8291');
    expect(result, isTrue);
    expect(store.isCheckedIn('SH-8291'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/state/venue_owner_store_test.dart`
Expected: FAIL (files missing).

- [ ] **Step 3: Implement CourtSlotItem and VenueOwnerStore**

Create `lib/domain/entities/court_slot_item.dart`:
Define `CourtSlotStatus` and `CourtSlotItem` with immutable properties and `copyWith`.

Create `lib/core/state/venue_owner_store.dart`:
Implement singleton with `isOwnerModeNotifier`, `slotsNotifier`, sample initial schedule for Tao Đàn (courts 1-8, morning to evening slots with a mix of available, booked, and maintenance), methods for `reserveSlot`, `lockMaintenance`, `unlockSlot`, `checkInTicket`, `isCheckedIn`, and `reset`.

Update `SeedData.demoUsers` in `lib/core/utils/seed_data.dart`:
Add `user_owner_01` (Trần Văn Chủ Sân, `0988 888 777`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/state/venue_owner_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: 135+ passed, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/domain/entities/court_slot_item.dart lib/core/state/venue_owner_store.dart lib/core/utils/seed_data.dart test/core/state/venue_owner_store_test.dart
git commit -m "feat: implement CourtSlotItem entity, VenueOwnerStore, and partner owner seed user"
```

---

### Task 2: Mode Switcher & Owner Navigation Scaffold

**Files:**
- Create: `lib/presentation/screens/owner_navigation_screen.dart`
- Modify: `lib/main.dart` (`ProfileScreen`, `_SportHubShellState`)
- Create: `test/presentation/screens/owner_mode_switcher_test.dart`

**Interfaces:**
- Consumes: `VenueOwnerStore.instance`
- Produces:
  - `ProfileScreen` contains `Key('switch_to_owner_mode_button')`.
  - `OwnerNavigationScreen` with tabs `owner_tab_schedule`, `owner_tab_checkin`, `owner_tab_revenue`, `owner_tab_settings`.
  - `OwnerNavigationScreen` settings contains `Key('exit_owner_mode_button')`.

- [ ] **Step 1: Write failing widget test for Mode Switcher**

Create `test/presentation/screens/owner_mode_switcher_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    VenueOwnerStore.instance.reset();
  });

  testWidgets('Can switch from ProfileScreen to Owner Mode and switch back', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Navigate to Profile tab
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    // Find and tap switch to owner mode button
    final switchBtn = find.byKey(const Key('switch_to_owner_mode_button'));
    await tester.ensureVisible(switchBtn);
    await tester.tap(switchBtn);
    await tester.pumpAndSettle();

    // Verify Owner Navigation Screen is shown with owner tabs
    expect(VenueOwnerStore.instance.isOwnerMode, isTrue);
    expect(find.byKey(const Key('owner_tab_schedule')), findsOneWidget);
    expect(find.byKey(const Key('owner_tab_checkin')), findsOneWidget);
    expect(find.byKey(const Key('owner_tab_revenue')), findsOneWidget);
    expect(find.byKey(const Key('owner_tab_settings')), findsOneWidget);

    // Switch to Settings tab in Owner mode
    await tester.tap(find.byKey(const Key('owner_tab_settings')));
    await tester.pumpAndSettle();

    // Tap exit owner mode button
    final exitBtn = find.byKey(const Key('exit_owner_mode_button'));
    await tester.ensureVisible(exitBtn);
    await tester.tap(exitBtn);
    await tester.pumpAndSettle();

    // Back to normal player mode
    expect(VenueOwnerStore.instance.isOwnerMode, isFalse);
    expect(find.byIcon(Icons.sports_tennis_rounded), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/owner_mode_switcher_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement OwnerNavigationScreen and wire into lib/main.dart**

Create `lib/presentation/screens/owner_navigation_screen.dart`:
- A 4-tab scaffold with bottom navigation:
  1. `Lịch sân` (`Key('owner_tab_schedule')`)
  2. `Soát vé` (`Key('owner_tab_checkin')`)
  3. `Doanh thu` (`Key('owner_tab_revenue')`)
  4. `Cài đặt` (`Key('owner_tab_settings')`)
- In settings tab, render venue information and `[🔄 Quay lại Chế độ Người Chơi]` (`Key('exit_owner_mode_button')`) calling `VenueOwnerStore.instance.toggleOwnerMode(false)`.

In `lib/main.dart`:
- In `_SportHubShellState`: listen to `VenueOwnerStore.instance.isOwnerModeNotifier`. If `true`, render `const OwnerNavigationScreen()`.
- In `ProfileScreen`: add partner promo card with `[⚡ Chuyển sang Chế độ Chủ Sân]` (`Key('switch_to_owner_mode_button')`) calling `VenueOwnerStore.instance.toggleOwnerMode(true)`.
- In `AuthScreen`: add quick login for `Trần Văn (Chủ sân)` (`Key('quick_login_user_owner_01')`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/owner_mode_switcher_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/screens/owner_navigation_screen.dart lib/main.dart test/presentation/screens/owner_mode_switcher_test.dart
git commit -m "feat: implement OwnerNavigationScreen scaffold and player/owner mode switching"
```

---

### Task 3: Tab 1 - Live Court Schedule Matrix & Quick Action Sheet

**Files:**
- Create: `lib/presentation/screens/owner_tabs/owner_schedule_tab.dart`
- Modify: `lib/presentation/screens/owner_navigation_screen.dart`
- Create: `test/presentation/screens/owner_schedule_matrix_test.dart`

**Interfaces:**
- Consumes: `VenueOwnerStore.instance`
- Produces: `OwnerScheduleTab` with Keys:
  - `owner_slot_action_sheet`
  - `action_manual_reserve`, `action_lock_maintenance`, `action_unlock_slot`
  - `slot_tile_${slot.slotId}`

- [ ] **Step 1: Write failing widget test for Schedule Matrix & Quick Actions**

Create `test/presentation/screens/owner_schedule_matrix_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/domain/entities/court_slot_item.dart';
import 'package:sporthub/presentation/screens/owner_navigation_screen.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
  });

  testWidgets('OwnerScheduleTab displays court matrix and allows manual reservation and locking', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find first available slot
    final availableSlot = VenueOwnerStore.instance.slots.firstWhere(
      (s) => s.status == CourtSlotStatus.available,
    );
    final slotFinder = find.byKey(Key('slot_tile_${availableSlot.slotId}'));
    expect(slotFinder, findsOneWidget);

    // Tap available slot to open action sheet
    await tester.tap(slotFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('owner_slot_action_sheet')), findsOneWidget);
    expect(find.byKey(const Key('action_lock_maintenance')), findsOneWidget);

    // Tap lock maintenance
    await tester.tap(find.byKey(const Key('action_lock_maintenance')));
    await tester.pumpAndSettle();

    // Verify slot is now locked
    final updated = VenueOwnerStore.instance.slots.firstWhere((s) => s.slotId == availableSlot.slotId);
    expect(updated.status, equals(CourtSlotStatus.maintenance));

    // Tap locked slot to unlock
    await tester.tap(slotFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('action_unlock_slot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('action_unlock_slot')));
    await tester.pumpAndSettle();

    final reverted = VenueOwnerStore.instance.slots.firstWhere((s) => s.slotId == availableSlot.slotId);
    expect(reverted.status, equals(CourtSlotStatus.available));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/owner_schedule_matrix_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement OwnerScheduleTab with visual matrix and action sheet**

Create `lib/presentation/screens/owner_tabs/owner_schedule_tab.dart`:
- Shift filters (`Tất cả ca`, `Ca Sáng`, `Ca Tối`) and sport filters (`Tất cả`, `Cầu lông`, `Pickleball`).
- Interactive slot grid with visual color coding:
  - 🟢 Green: `bookedApp` (Shows customer name & ticket ID).
  - 🟡 Amber: `reservedManual` (Shows customer name & phone).
  - 🔴 Red: `maintenance` (Shows "Đang bảo trì").
  - ⚪ Dark with border: `available` (Shows price & "Trống").
- Tap action sheet `Key('owner_slot_action_sheet')`:
  - For `available`: `[📞 Giữ chỗ khách gọi điện]` (`Key('action_manual_reserve')`) with name/phone dialog, and `[🔒 Khóa sân bảo trì]` (`Key('action_lock_maintenance')`).
  - For `reservedManual` / `maintenance`: `[🔓 Mở khóa sân (Trả lại sân trống)]` (`Key('action_unlock_slot')`).

Integrate into Tab 0 of `OwnerNavigationScreen`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/owner_schedule_matrix_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/screens/owner_tabs/owner_schedule_tab.dart lib/presentation/screens/owner_navigation_screen.dart test/presentation/screens/owner_schedule_matrix_test.dart
git commit -m "feat: implement live court schedule matrix and quick slot actions for venue owner"
```

---

### Task 4: Tab 2 & 3 - Check-in Manager & Revenue Analytics

**Files:**
- Create: `lib/presentation/screens/owner_tabs/owner_checkin_tab.dart`
- Create: `lib/presentation/screens/owner_tabs/owner_revenue_tab.dart`
- Modify: `lib/presentation/screens/owner_navigation_screen.dart`
- Create: `test/presentation/screens/owner_checkin_and_revenue_test.dart`

**Interfaces:**
- Consumes: `VenueOwnerStore.instance`
- Produces:
  - `OwnerCheckinTab`: search input `checkin_search_input`, confirm check-in button `confirm_checkin_SH-8291`, QR scan button `open_qr_scanner_button`.
  - `OwnerRevenueTab`: metrics display, add-ons list, 7-day trend.

- [ ] **Step 1: Write failing widget test for Checkin and Revenue tabs**

Create `test/presentation/screens/owner_checkin_and_revenue_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/presentation/screens/owner_navigation_screen.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
  });

  testWidgets('OwnerCheckinTab displays bookings and handles check-in action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Check-in tab
    await tester.tap(find.byKey(const Key('owner_tab_checkin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkin_search_input')), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsWidgets);

    // Tap confirm checkin for ticket SH-8291
    final checkinBtn = find.byKey(const Key('confirm_checkin_SH-8291'));
    if (checkinBtn.evaluate().isNotEmpty) {
      await tester.tap(checkinBtn);
      await tester.pumpAndSettle();
      expect(find.text('Đã nhận sân'), findsWidgets);
    }
  });

  testWidgets('OwnerRevenueTab displays revenue metrics and occupancy stats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Revenue tab
    await tester.tap(find.byKey(const Key('owner_tab_revenue')));
    await tester.pumpAndSettle();

    expect(find.text('Tổng doanh thu hôm nay'), findsOneWidget);
    expect(find.text('Tỷ lệ lấp đầy'), findsOneWidget);
    expect(find.text('Dịch vụ bán kèm (Add-ons)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/owner_checkin_and_revenue_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement OwnerCheckinTab and OwnerRevenueTab**

Create `lib/presentation/screens/owner_tabs/owner_checkin_tab.dart`:
- Search bar for customer name, phone, or ticket code.
- Ticket cards with customer info, court name, slot, price, addons, status pill.
- Button `[✅ Xác nhận Check-in]` (`Key('confirm_checkin_${ticket.id}')`).
- Button `[📷 Quét mã QR]` (`Key('open_qr_scanner_button')`) with a simulation modal allowing picking or entering a code to check in instantly.

Create `lib/presentation/screens/owner_tabs/owner_revenue_tab.dart`:
- Metric cards: Total revenue today, Court fees vs Add-on revenue, Occupancy rate, Total players.
- Add-on breakdown (Pocari Sweat, Aquafina, Quấn cán vợt).
- 7-day revenue trend bar representation.

Integrate into Tabs 1 and 2 of `OwnerNavigationScreen`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/owner_checkin_and_revenue_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/screens/owner_tabs/owner_checkin_tab.dart lib/presentation/screens/owner_tabs/owner_revenue_tab.dart lib/presentation/screens/owner_navigation_screen.dart test/presentation/screens/owner_checkin_and_revenue_test.dart
git commit -m "feat: implement check-in manager and revenue analytics tabs for venue owner"
```

---

### Task 5: Full Suite Verification, Web Hot Restart & Demo Handoff

**Files:**
- None (verification and demo)

- [ ] **Step 1: Run static analyzer**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run full test suite**
Run: `flutter test`
Expected: All 140+ tests pass across all test suites.

- [ ] **Step 3: Hot restart web server**
Send hot restart `R\n` to background task `task-673`.

- [ ] **Step 4: Demo handoff**
Present complete feature walkthrough in Vietnamese with link `http://localhost:46477/`.
