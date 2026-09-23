import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/data/models/time_slot_model.dart';
import 'package:sporthub/data/models/venue_model.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/domain/entities/venue.dart';

void main() {
  group('TimeSlot and TimeSlotModel', () {
    test('TimeSlotModel parses JSON and calculates availability correctly', () {
      final slot = TimeSlotModel(
        id: '2026-09-06_C1_18:00',
        date: '2026-09-06',
        courtNumber: 1,
        startTime: '18:00',
        endTime: '19:00',
        price: 150000.0,
        status: SlotStatus.available,
        lockedBy: null,
        lockedAt: null,
      );

      expect(slot.isAvailable, true);
      expect(slot.formattedPrice, '150.000 đ');
    });

    test('TimeSlotModel correctly identifies unavailable statuses', () {
      final lockedSlot = TimeSlotModel(
        id: '2026-09-06_C1_18:00',
        date: '2026-09-06',
        courtNumber: 1,
        startTime: '18:00',
        endTime: '19:00',
        price: 150000.0,
        status: SlotStatus.locked,
        lockedBy: 'user_123',
        lockedAt: DateTime.parse('2026-09-06T17:50:00.000Z'),
      );
      expect(lockedSlot.isAvailable, false);

      final bookedSlot = TimeSlotModel(
        id: '2026-09-06_C1_18:00',
        date: '2026-09-06',
        courtNumber: 1,
        startTime: '18:00',
        endTime: '19:00',
        price: 150000.0,
        status: SlotStatus.booked,
      );
      expect(bookedSlot.isAvailable, false);
    });

    test('TimeSlotModel serialization toMap and fromMap works correctly', () {
      final now = DateTime(2026, 9, 6, 18, 0);
      final model = TimeSlotModel(
        id: 'slot_101',
        date: '2026-09-06',
        courtNumber: 2,
        startTime: '19:00',
        endTime: '20:00',
        price: 200000.0,
        status: SlotStatus.locked,
        lockedBy: 'user_abc',
        lockedAt: now,
      );

      final map = model.toMap();
      expect(map['courtNumber'], 2);
      expect(map['status'], 'locked');
      expect(map['price'], 200000.0);

      final parsed = TimeSlotModel.fromMap(map, 'slot_101');
      expect(parsed.id, 'slot_101');
      expect(parsed.date, '2026-09-06');
      expect(parsed.courtNumber, 2);
      expect(parsed.startTime, '19:00');
      expect(parsed.endTime, '20:00');
      expect(parsed.price, 200000.0);
      expect(parsed.status, SlotStatus.locked);
      expect(parsed.lockedBy, 'user_abc');
      expect(parsed.lockedAt, now);
      expect(parsed.isAvailable, false);
    });
  });

  group('Venue and VenueModel', () {
    test('Venue entity instantiates correctly with given properties', () {
      const venue = Venue(
        id: 'venue_01',
        name: 'Sân Cầu Lông ABC',
        sportTypes: ['badminton'],
        address: '123 Đường Số 1',
        district: 'Quận 7',
        courtCount: 4,
        hourlyRate: 120000.0,
        rating: 4.9,
        reviewCount: 50,
        imageUrls: ['https://example.com/img.jpg'],
        amenities: ['WiFi', 'Máy lạnh'],
      );

      expect(venue.id, 'venue_01');
      expect(venue.name, 'Sân Cầu Lông ABC');
      expect(venue.sportTypes, contains('badminton'));
      expect(venue.courtCount, 4);
    });

    test('VenueModel serialization toMap and fromMap works correctly', () {
      const model = VenueModel(
        id: 'venue_02',
        name: 'Sân Pickleball XYZ',
        sportTypes: ['pickleball', 'tennis'],
        address: '456 Lê Lợi',
        district: 'Bình Thạnh',
        courtCount: 8,
        hourlyRate: 180000.0,
        rating: 4.7,
        reviewCount: 88,
        imageUrls: ['https://example.com/xyz.jpg'],
        amenities: ['Bãi giữ xe', 'Căn tin'],
      );

      final map = model.toMap();
      expect(map['id'], 'venue_02');
      expect(map['courtCount'], 8);
      expect(map['hourlyRate'], 180000.0);

      final parsed = VenueModel.fromMap(map);
      expect(parsed.id, 'venue_02');
      expect(parsed.name, 'Sân Pickleball XYZ');
      expect(parsed.sportTypes, ['pickleball', 'tennis']);
      expect(parsed.district, 'Bình Thạnh');
      expect(parsed.courtCount, 8);
      expect(parsed.hourlyRate, 180000.0);
      expect(parsed.rating, 4.7);
      expect(parsed.reviewCount, 88);
      expect(parsed.amenities, ['Bãi giữ xe', 'Căn tin']);
    });
  });
}
