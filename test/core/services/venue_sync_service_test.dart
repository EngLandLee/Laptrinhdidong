import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sporthub/core/services/venue_sync_service.dart';

void main() {
  group('VenueSyncService Tests', () {
    late VenueSyncService service;

    setUp(() {
      service = VenueSyncService.instance;
      service.reset();
    });

    tearDown(() {
      service.stopPolling();
    });

    test('initial state has Tao Dan Court 1 disabled by default', () {
      expect(
        service.isCourtActive(venueId: 'venue_01', courtNumber: 1),
        isFalse,
      );
      expect(
        service.isCourtActive(venueId: 'venue_q1_04', courtNumber: 1),
        isFalse,
      );
      expect(
        service.isCourtActive(
          venueId: 'any_id',
          courtNumber: 1,
          venueName: 'CLB Cầu Lông Tao Đàn - Quận 1',
        ),
        isFalse,
      );
      // Court 2 should be active
      expect(
        service.isCourtActive(venueId: 'venue_01', courtNumber: 2),
        isTrue,
      );
    });

    test('setCourtActive manually toggles court status and notifies listeners', () {
      var notified = false;
      service.inactiveCourtsNotifier.addListener(() {
        notified = true;
      });

      // Enable court 1
      service.setCourtActive(venueId: 'venue_01', courtNumber: 1, isActive: true);
      expect(notified, isTrue);
      expect(
        service.isCourtActive(venueId: 'venue_01', courtNumber: 1),
        isTrue,
      );
      expect(
        service.isCourtActive(venueId: 'venue_q1_04', courtNumber: 1),
        isTrue,
      );

      // Disable court 2
      service.setCourtActive(venueId: 'venue_01', courtNumber: 2, isActive: false);
      expect(
        service.isCourtActive(venueId: 'venue_01', courtNumber: 2),
        isFalse,
      );
    });

    test('syncWithServer parses server payload and updates inactiveCourtsNotifier', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/sync') {
          return http.Response(
            jsonEncode({
              'timestamp': 1788749000000,
              'inactiveCourtsByVenue': {
                'venue_01': [1, 3],
              },
              'courts': [
                {
                  'id': 'court_01',
                  'venueId': 'venue_01',
                  'courtNumber': 1,
                  'isActive': false,
                },
                {
                  'id': 'court_03',
                  'venueId': 'venue_01',
                  'courtNumber': 3,
                  'isActive': false,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final success = await service.syncWithServer(client: mockClient);
      expect(success, isTrue);
      expect(service.isCourtActive(venueId: 'venue_01', courtNumber: 1), isFalse);
      expect(service.isCourtActive(venueId: 'venue_01', courtNumber: 3), isFalse);
      expect(service.isCourtActive(venueId: 'venue_01', courtNumber: 2), isTrue);
      expect(service.lastSyncTimeNotifier.value, isNotNull);
    });

    test('syncWithServer updates venuesNotifier with synced venues from server', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/sync') {
          return http.Response(
            jsonEncode({
              'timestamp': 1788760000000,
              'inactiveCourtsByVenue': {},
              'courts': [],
              'venues': [
                {
                  'id': 'venue_q7_03',
                  'name': 'Sân Bóng Đá Mini Nam Sài Gòn',
                  'address': '78 Nguyễn Hữu Thọ, Q7',
                  'district': 'Quận 7',
                  'sports': ['football'],
                  'baseHourlyRate': 280000,
                  'imageUrl': 'https://example.com/football.jpg',
                  'totalCourts': 4,
                  'isActive': true,
                },
                {
                  'id': 'venue_01',
                  'name': 'CLB Cầu Lông Tao Đàn - Quận 1',
                  'address': 'Số 1 Huyền Trân Công Chúa',
                  'district': 'Quận 1',
                  'sports': ['badminton', 'pickleball'],
                  'baseHourlyRate': 160000,
                  'imageUrl': 'https://example.com/taodan.jpg',
                  'totalCourts': 8,
                  'isActive': true,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final success = await service.syncWithServer(client: mockClient);
      expect(success, isTrue);
      expect(service.venuesNotifier.value.length, 2);
      expect(service.venuesNotifier.value.first.id, 'venue_q7_03');
      expect(service.venuesNotifier.value.first.sportTypes, contains('football'));
      expect(service.venuesNotifier.value.last.id, 'venue_q1_04');
    });

    test('syncWithServer fails gracefully when network throws error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection refused');
      });

      final success = await service.syncWithServer(client: mockClient);
      expect(success, isFalse);
      // Previous state is preserved
      expect(service.isCourtActive(venueId: 'venue_01', courtNumber: 1), isFalse);
    });

    test('createBooking adds booking to bookingsNotifier and isSlotBooked returns true', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/bookings' && request.method == 'POST') {
          return http.Response(
            jsonEncode({'success': true, 'booking': jsonDecode(request.body)}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      expect(
        service.isSlotBooked(
          venueId: 'venue_01',
          courtNumber: 2,
          date: '2026-09-08',
          startTime: '18:00',
        ),
        isFalse,
      );

      final success = await service.createBooking(
        bookingId: 'BK-TEST-123',
        venueId: 'venue_01',
        courtNumber: 2,
        courtName: 'Sân Cầu Lông 02',
        venueName: 'CLB Cầu Lông Tao Đàn',
        sport: 'badminton',
        date: '2026-09-08',
        startTime: '18:00',
        endTime: '19:00',
        totalPrice: 180000,
        customerName: 'Nguyễn Văn An',
        customerPhone: '0908 111 222',
        client: mockClient,
      );

      expect(success, isTrue);
      expect(
        service.isSlotBooked(
          venueId: 'venue_01',
          courtNumber: 2,
          date: '2026-09-08',
          startTime: '18:00',
        ),
        isTrue,
      );
      // Tao Dan alias
      expect(
        service.isSlotBooked(
          venueId: 'venue_q1_04',
          courtNumber: 2,
          date: '2026-09-08',
          startTime: '18:00',
        ),
        isTrue,
      );
    });

    test('syncWithServer parses server bookings list', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/sync') {
          return http.Response(
            jsonEncode({
              'timestamp': 1788760000000,
              'inactiveCourtsByVenue': {},
              'courts': [],
              'venues': [],
              'bookings': [
                {
                  'id': 'BK-REMOTE-01',
                  'venueId': 'venue_01',
                  'courtNumber': 3,
                  'date': '2026-09-08',
                  'startTime': '19:00',
                  'timeSlot': '19:00 - 20:00',
                  'customerName': 'Lê Văn C',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final success = await service.syncWithServer(client: mockClient);
      expect(success, isTrue);
      expect(service.bookingsNotifier.value.length, 1);
      expect(
        service.isSlotBooked(
          venueId: 'venue_01',
          courtNumber: 3,
          date: '2026-09-08',
          startTime: '19:00',
        ),
        isTrue,
      );
    });

    test('booking with date "Hôm nay" is recognized as booked when checked with today yyyy-MM-dd', () async {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await service.createBooking(
        bookingId: 'BK-TODAY-01',
        venueId: 'venue_01',
        courtNumber: 1,
        courtName: 'Sân 1',
        venueName: 'CLB Cầu Lông Tao Đàn',
        sport: 'badminton',
        date: 'Hôm nay',
        startTime: '19:00',
        endTime: '20:00',
        totalPrice: 480000,
        customerName: 'Người dùng',
        customerPhone: '0901234567',
      );

      // Query with todayStr (e.g. 2026-09-19)
      expect(
        service.isSlotBooked(
          venueId: 'venue_01',
          courtNumber: 1,
          date: todayStr,
          startTime: '19:00',
          venueName: 'CLB Cầu Lông Tao Đàn',
        ),
        isTrue,
      );

      // Query with "Hôm nay"
      expect(
        service.isSlotBooked(
          venueId: 'venue_01',
          courtNumber: 1,
          date: 'Hôm nay',
          startTime: '19:00',
          venueName: 'CLB Cầu Lông Tao Đàn',
        ),
        isTrue,
      );
    });
  });
}
