import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/widgets/visual_court_slot_cell.dart';

void main() {
  final testSlot = TimeSlot(
    id: 'court1_1800_1900',
    date: '2026-09-06',
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
    expect(find.text('150.000 đ'), findsOneWidget);
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

  testWidgets('VisualCourtSlotCell renders football pitch when sportType is football', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisualCourtSlotCell(
            slot: testSlot,
            sportType: 'football',
            isSelected: false,
            onTap: () {},
            width: 140,
            height: 80,
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('150.000 đ'), findsOneWidget);
    expect(find.text('Còn trống'), findsOneWidget);
  });
}
