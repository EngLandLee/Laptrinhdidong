import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/data/datasources/local/database_helper.dart';
import 'package:sporthub/data/models/ticket_model.dart';

void main() {
  group('TicketModel', () {
    test('TicketModel converts to and from Map correctly', () {
      final ticket = TicketModel(
        id: 'ticket_1',
        bookingId: 'BK-001',
        venueName: 'Sân Cầu Lông Bình Thạnh',
        sportType: 'badminton',
        courtNumber: 1,
        matchDate: '2026-09-06',
        startTime: '18:00',
        endTime: '19:00',
        totalPrice: 150000.0,
        qrCodeData: 'SPORTHUB|BK-001|150000',
        status: 'paid',
        createdAt: '2026-09-05T10:00:00Z',
      );

      final map = ticket.toMap();
      final reconstructed = TicketModel.fromMap(map);

      expect(reconstructed.id, ticket.id);
      expect(reconstructed.bookingId, ticket.bookingId);
      expect(reconstructed.venueName, ticket.venueName);
      expect(reconstructed.sportType, ticket.sportType);
      expect(reconstructed.courtNumber, ticket.courtNumber);
      expect(reconstructed.matchDate, ticket.matchDate);
      expect(reconstructed.startTime, ticket.startTime);
      expect(reconstructed.endTime, ticket.endTime);
      expect(reconstructed.totalPrice, 150000.0);
      expect(reconstructed.qrCodeData, ticket.qrCodeData);
      expect(reconstructed.status, ticket.status);
      expect(reconstructed.createdAt, ticket.createdAt);
    });

    test('TicketModel handles int total_price in fromMap', () {
      final map = {
        'id': 'ticket_2',
        'booking_id': 'BK-002',
        'venue_name': 'Sân Bóng Đá Quận 1',
        'sport_type': 'football',
        'court_number': 2,
        'match_date': '2026-09-07',
        'start_time': '19:00',
        'end_time': '20:00',
        'total_price': 200000,
        'qr_code_data': 'SPORTHUB|BK-002|200000',
        'status': 'confirmed',
        'created_at': '2026-09-05T11:00:00Z',
      };
      final ticket = TicketModel.fromMap(map);
      expect(ticket.totalPrice, 200000.0);
    });
  });

  group('DatabaseHelper', () {
    test('instance is a singleton', () {
      final instance1 = DatabaseHelper.instance;
      final instance2 = DatabaseHelper.instance;
      expect(identical(instance1, instance2), isTrue);
    });
  });
}
