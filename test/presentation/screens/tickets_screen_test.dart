import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/ticket_store.dart';
import 'package:sporthub/data/models/ticket_model.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    TicketStore.instance.reset();
  });

  testWidgets('TicketsScreen displays sample tickets for Badminton, Pickleball, and Football with sport badges', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 venue names are displayed
    expect(find.textContaining(RegExp(r'Bình Thạnh', caseSensitive: false)), findsWidgets);
    expect(find.textContaining(RegExp(r'Thảo Điền', caseSensitive: false)), findsWidgets);
    expect(find.textContaining(RegExp(r'Nam Sài Gòn', caseSensitive: false)), findsWidgets);

    // Verify sport badges
    expect(find.text('🏸 CẦU LÔNG'), findsOneWidget);
    expect(find.text('🏓 PICKLEBALL'), findsOneWidget);
    expect(find.text('⚽ BÓNG ĐÁ'), findsOneWidget);
  });

  testWidgets('Adding a ticket to TicketStore dynamically updates TicketsScreen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TicketsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Tân Bình Arena'), findsNothing);

    TicketStore.instance.addTicket(
      TicketModel(
        id: 'ticket_new_tb',
        bookingId: 'BK-20260907-999',
        venueName: 'Khu Liên Hợp Tân Bình Arena',
        sportType: 'badminton',
        courtNumber: 4,
        matchDate: '07/09/2026',
        startTime: '20:00',
        endTime: '22:00',
        totalPrice: 200000,
        qrCodeData: 'SPORTHUB|BK-20260907-999|200000',
        status: 'paid',
        createdAt: '2026-09-07T12:00:00Z',
        district: 'Tân Bình',
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'Tân Bình Arena', caseSensitive: false)), findsWidgets);
  });
}
