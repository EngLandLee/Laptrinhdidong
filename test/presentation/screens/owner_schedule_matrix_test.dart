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

  testWidgets('OwnerScheduleTab allows manual reservation of available slot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find an available slot
    final availableSlot = VenueOwnerStore.instance.slots.firstWhere(
      (s) => s.status == CourtSlotStatus.available,
    );
    final slotFinder = find.byKey(Key('slot_tile_${availableSlot.slotId}'));
    await tester.tap(slotFinder);
    await tester.pumpAndSettle();

    // Tap manual reserve action
    expect(find.byKey(const Key('action_manual_reserve')), findsOneWidget);
    await tester.tap(find.byKey(const Key('action_manual_reserve')));
    await tester.pumpAndSettle();

    // Fill customer name and phone
    final nameField = find.byKey(const Key('manual_reserve_name_input'));
    final phoneField = find.byKey(const Key('manual_reserve_phone_input'));
    expect(nameField, findsOneWidget);
    expect(phoneField, findsOneWidget);

    await tester.enterText(nameField, 'Nguyễn Khách Gọi Điện');
    await tester.enterText(phoneField, '0912 345 678');
    await tester.tap(find.byKey(const Key('manual_reserve_confirm_button')));
    await tester.pumpAndSettle();

    final updated = VenueOwnerStore.instance.slots.firstWhere((s) => s.slotId == availableSlot.slotId);
    expect(updated.status, equals(CourtSlotStatus.reservedManual));
    expect(updated.customerName, equals('Nguyễn Khách Gọi Điện'));
  });

  testWidgets('OwnerScheduleTab filtering by sport and shift works as expected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Filters should be visible
    expect(find.byKey(const Key('schedule_filter_sport_all')), findsOneWidget);
    expect(find.byKey(const Key('schedule_filter_sport_badminton')), findsOneWidget);
    expect(find.byKey(const Key('schedule_filter_sport_pickleball')), findsOneWidget);
    expect(find.byKey(const Key('schedule_filter_shift_all')), findsOneWidget);
    expect(find.byKey(const Key('schedule_filter_shift_morning')), findsOneWidget);
    expect(find.byKey(const Key('schedule_filter_shift_evening')), findsOneWidget);

    // Filter to Pickleball only
    await tester.tap(find.byKey(const Key('schedule_filter_sport_pickleball')));
    await tester.pumpAndSettle();

    // Badminton slot court_01_06_00 should NOT be present, but court_05_06_00 should
    expect(find.byKey(const Key('slot_tile_court_01_06_00')), findsNothing);
    expect(find.byKey(const Key('slot_tile_court_05_06_00')), findsOneWidget);

    // Filter to Evening shift (14:00 - 22:00)
    await tester.tap(find.byKey(const Key('schedule_filter_shift_evening')));
    await tester.pumpAndSettle();

    // Morning pickleball slot court_05_06_00 should NOT be present, but evening court_05_18_00 should
    expect(find.byKey(const Key('slot_tile_court_05_06_00')), findsNothing);
    expect(find.byKey(const Key('slot_tile_court_05_18_00')), findsOneWidget);
  });

  testWidgets('OwnerScheduleTab shows bookedApp details and can unlock manual reservation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap bookedApp slot court_01_18_00
    final bookedSlotFinder = find.byKey(const Key('slot_tile_court_01_18_00'));
    await tester.ensureVisible(bookedSlotFinder);
    expect(bookedSlotFinder, findsOneWidget);
    await tester.tap(bookedSlotFinder);
    await tester.pumpAndSettle();

    // Verify action sheet shows App booking details
    final actionSheetFinder = find.byKey(const Key('owner_slot_action_sheet'));
    expect(actionSheetFinder, findsOneWidget);
    expect(
      find.descendant(of: actionSheetFinder, matching: find.textContaining('SH-8291')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: actionSheetFinder, matching: find.textContaining('Nguyễn Văn An')),
      findsOneWidget,
    );

    // Close action sheet by tapping outside or back
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Tap manual reservation slot court_02_17_00
    final manualSlotFinder = find.byKey(const Key('slot_tile_court_02_17_00'));
    await tester.ensureVisible(manualSlotFinder);
    await tester.tap(manualSlotFinder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('action_unlock_slot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('action_unlock_slot')));
    await tester.pumpAndSettle();

    final unlockedSlot = VenueOwnerStore.instance.slots.firstWhere((s) => s.slotId == 'court_02_17_00');
    expect(unlockedSlot.status, equals(CourtSlotStatus.available));
    expect(unlockedSlot.customerName, isNull);
  });

  testWidgets('OwnerScheduleTab displays tiered pricing and allows adjusting slot price', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find off-peak slot court_01_08_00 (Sân Cầu Lông 01 lúc 08:00)
    final offPeakFinder = find.byKey(const Key('slot_tile_court_01_08_00'));
    expect(offPeakFinder, findsOneWidget);
    expect(find.descendant(of: offPeakFinder, matching: find.text('80k')), findsOneWidget);
    expect(find.descendant(of: offPeakFinder, matching: find.text('Ưu đãi')), findsOneWidget);

    // Find peak slot court_01_17_00 (Sân Cầu Lông 01 lúc 17:00)
    final peakFinder = find.byKey(const Key('slot_tile_court_01_17_00'));
    expect(peakFinder, findsOneWidget);
    expect(find.descendant(of: peakFinder, matching: find.text('180k')), findsOneWidget);
    expect(find.descendant(of: peakFinder, matching: find.text('🔥 Vàng')), findsOneWidget);

    // Tap off-peak slot to open action sheet
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
}

