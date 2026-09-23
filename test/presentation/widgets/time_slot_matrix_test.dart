import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/widgets/time_slot_matrix.dart';
import 'package:sporthub/presentation/widgets/visual_court_header.dart';
import 'package:sporthub/presentation/widgets/visual_court_slot_cell.dart';

void main() {
  const slots = [
    TimeSlot(
      id: '1',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '18:00',
      endTime: '19:00',
      price: 150000,
      status: SlotStatus.available,
    ),
    TimeSlot(
      id: '2',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '19:00',
      endTime: '20:00',
      price: 150000,
      status: SlotStatus.booked,
    ),
    TimeSlot(
      id: '3',
      date: '2026-09-06',
      courtNumber: 2,
      startTime: '20:00',
      endTime: '21:00',
      price: 180000,
      status: SlotStatus.available,
    ),
  ];

  testWidgets('TimeSlotMatrix renders 2D matrix with court headers, time rows, and slot statuses', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeSlotMatrix(
          slots: slots,
          selectedSlotIds: const {},
          onSlotTapped: (_) {},
        ),
      ),
    ));

    // Court Headers in Header Row
    expect(find.text('Khung giờ'), findsOneWidget);
    expect(find.text('SÂN 1'), findsOneWidget);
    expect(find.text('SÂN 2'), findsOneWidget);
    expect(find.byType(VisualCourtHeader), findsNWidgets(2));
    expect(find.text('Thảm BWF'), findsNWidgets(2));

    // Time frame rows
    expect(find.text('18:00 - 19:00'), findsOneWidget);
    expect(find.text('19:00 - 20:00'), findsOneWidget);
    expect(find.text('20:00 - 21:00'), findsOneWidget);

    // Status texts
    expect(find.text('Còn trống'), findsNWidgets(2));
    expect(find.text('Đã đặt'), findsOneWidget);

    // Prices
    expect(find.text('150.000 đ'), findsNWidgets(2));
    expect(find.text('180.000 đ'), findsOneWidget);

    // Verify 2D scroll views exist (vertical + horizontal)
    expect(find.byType(SingleChildScrollView), findsNWidgets(2));
  });

  testWidgets('TimeSlotMatrix forwards sportType to VisualCourtHeader', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeSlotMatrix(
          slots: slots,
          selectedSlotIds: const {},
          onSlotTapped: (_) {},
          sportType: 'football',
        ),
      ),
    ));

    expect(find.byType(VisualCourtHeader), findsNWidgets(2));
    expect(find.text('Cỏ FIFA'), findsNWidgets(2));
  });

  testWidgets('TimeSlotMatrix renders selected slot state and triggers callback on tap', (tester) async {
    TimeSlot? tappedSlot;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeSlotMatrix(
          slots: slots,
          selectedSlotIds: const {'1'},
          onSlotTapped: (slot) {
            tappedSlot = slot;
          },
        ),
      ),
    ));

    // Selected state
    expect(find.text('Đang chọn'), findsOneWidget);
    expect(find.text('Còn trống'), findsOneWidget);
    expect(find.text('Đã đặt'), findsOneWidget);

    // Tap available slot (Slot 3: Sân 2, 20:00 - 21:00)
    await tester.tap(find.byKey(const Key('slot_3')));
    await tester.pump();
    expect(tappedSlot?.id, '3');

    // Tap booked slot (Slot 2: Sân 1, 19:00 - 20:00) - should not trigger callback
    tappedSlot = null;
    await tester.tap(find.byKey(const Key('slot_2')));
    await tester.pump();
    expect(tappedSlot, isNull);
  });

  testWidgets('TimeSlotMatrix renders empty state when slot list is empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeSlotMatrix(
          slots: const [],
          selectedSlotIds: const {},
          onSlotTapped: (_) {},
        ),
      ),
    ));

    expect(find.text('Không có khung giờ nào'), findsOneWidget);
  });

  testWidgets('TimeSlotMatrix renders VisualCourtSlotCell for each slot in the grid', (tester) async {
    final sampleSlots = [
      const TimeSlot(
        id: 'c1_1700_1800',
        date: '2026-09-06',
        venueId: 'v1',
        courtNumber: 1,
        startTime: '17:00',
        endTime: '18:00',
        price: 150000,
        status: SlotStatus.available,
      ),
      const TimeSlot(
        id: 'c2_1700_1800',
        date: '2026-09-06',
        venueId: 'v1',
        courtNumber: 2,
        startTime: '17:00',
        endTime: '18:00',
        price: 150000,
        status: SlotStatus.booked,
      ),
    ];

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

  testWidgets('TimeSlotMatrix renders court navigation toolbar and scrolls on button tap when > 2 courts', (tester) async {
    final multiCourtSlots = List.generate(6, (index) {
      final court = index + 1;
      return TimeSlot(
        id: 'slot_c${court}_1800',
        date: '2026-09-06',
        courtNumber: court,
        startTime: '18:00',
        endTime: '19:00',
        price: 150000,
        status: SlotStatus.available,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: TimeSlotMatrix(
              slots: multiCourtSlots,
              selectedSlotIds: const {},
              onSlotTapped: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tổng 6 sân (Sân 1 - 6)'), findsOneWidget);
    expect(find.byKey(const Key('court_scroll_left')), findsOneWidget);
    expect(find.byKey(const Key('court_scroll_right')), findsOneWidget);

    await tester.tap(find.byKey(const Key('court_scroll_right')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('court_scroll_left')));
    await tester.pumpAndSettle();
  });
}
