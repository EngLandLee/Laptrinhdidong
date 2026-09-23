import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/chat/chat_booking_card.dart';

void main() {
  testWidgets('ChatBookingCard passes actionCard when Xem trên sơ đồ is tapped',
      (tester) async {
    final actionCardData = {
      'venueId': 'venue_01',
      'venueName': 'CLB Cầu Lông Tao Đàn',
      'sport': 'Cầu lông',
      'court': 'Sân 2',
      'startTime': '19:00',
      'endTime': '20:00',
      'price': 120000,
    };

    Map<String, dynamic>? receivedCard;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBookingCard(
            actionCard: actionCardData,
            onViewCourtMap: (card) {
              receivedCard = card;
            },
          ),
        ),
      ),
    );

    final viewMapButton = find.byKey(const Key('btn_chat_view_court_map'));
    expect(viewMapButton, findsOneWidget);

    await tester.tap(viewMapButton);
    await tester.pump();

    expect(receivedCard, isNotNull);
    expect(receivedCard!['court'], equals('Sân 2'));
    expect(receivedCard!['venueId'], equals('venue_01'));
  });
}
