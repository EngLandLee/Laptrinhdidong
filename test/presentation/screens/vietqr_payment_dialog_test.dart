import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/main.dart';

void main() {
  testWidgets('VietQrPaymentDialog renders formatted prices and counts down reservation timer', (tester) async {
    final venue = SeedData.sampleVenues.first;
    final slot = TimeSlot(
      id: 'slot_test_1',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '21:00',
      endTime: '22:00',
      price: 120000,
      status: SlotStatus.available,
    );

    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VietQrPaymentDialog(
            venue: venue,
            grandTotal: 145000, // 120k slot + 25k addon
            selectedSlots: [slot],
            addonCounts: const {'gear_grip': 1}, // 25k
            onConfirmed: () => confirmed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify formatted amounts
    expect(find.text('Tổng tiền: 145.000 đ'), findsOneWidget);
    expect(find.text('120.000 đ'), findsOneWidget);
    expect(find.text('25.000 đ'), findsOneWidget);

    // Verify initial timer state
    expect(find.text('⏱️ Giữ chỗ trong: 04:59'), findsOneWidget);

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('⏱️ Giữ chỗ trong: 04:58'), findsOneWidget);

    // Advance 10 seconds
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('⏱️ Giữ chỗ trong: 04:48'), findsOneWidget);

    // Tap Confirm button
    final confirmBtn = find.text('Xác nhận đã chuyển');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    expect(confirmed, isTrue);
  });

  testWidgets('VietQrPaymentDialog disables confirmation when hold timer expires', (tester) async {
    final venue = SeedData.sampleVenues.first;
    bool confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VietQrPaymentDialog(
            venue: venue,
            grandTotal: 100000,
            selectedSlots: const [],
            addonCounts: const {},
            onConfirmed: () => confirmed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('⏱️ Giữ chỗ trong: 04:59'), findsOneWidget);

    // Advance 300 seconds to expire
    await tester.pump(const Duration(seconds: 300));

    // Should display expired status
    expect(find.text('⏱️ Đã hết hạn giữ chỗ (00:00)'), findsOneWidget);

    // Tap confirm button when disabled
    final confirmBtn = find.widgetWithText(FilledButton, 'Xác nhận đã chuyển');
    expect(tester.widget<FilledButton>(confirmBtn).onPressed, isNull);
    await tester.tap(confirmBtn);
    expect(confirmed, isFalse);
  });
}
