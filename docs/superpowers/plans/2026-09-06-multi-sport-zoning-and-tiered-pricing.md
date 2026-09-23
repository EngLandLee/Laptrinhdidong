# Multi-Sport Zone Architecture & Tiered Pricing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Partition multi-sport venues (like Tân Bình Arena) into physical sport zones (Khu Cầu Lông, Khu Pickleball, Khu Bóng Đá Mini) with sport-aware tiered hourly pricing (Bóng đá 250k-420k, Pickleball 130k-220k, Cầu lông 80k-180k) and prominent zone headers.

**Architecture:** Extend `ShiftSlotGenerator` and `CourtSportPartition` to compute sport-specific tiered hourly rates and provide `SportZone` definitions. Update `VenueDetailScreen` to visually group courts by Zone, display Zone Header cards, and show exact slot prices with peak/off-peak tags.

**Tech Stack:** Flutter 3.x, Dart 3.x, Clean Architecture, Sporty Dark Luxury design tokens.

## Global Constraints
- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + ValueNotifier / BLoC reactive pattern.
- Design Theme: Sporty Dark Luxury (`AppColors.background #0B0F19`, `surface #161F30`, `primary #10B981`, `secondary #06B6D4`, `warning #F59E0B`).
- Backward Compatibility: Keep existing unit, widget, and integration tests passing.

---

### Task 1: Sport-Aware Pricing in `ShiftSlotGenerator` & `SportZone` Model

**Files:**
- Create: `lib/domain/entities/sport_zone.dart`
- Modify: `lib/core/utils/court_sport_partition.dart`
- Modify: `lib/core/utils/shift_slot_generator.dart`
- Create: `test/core/utils/shift_slot_generator_test.dart`

**Interfaces:**
- `SportZone`:
  - `final String zoneId;`
  - `final String sportType;`
  - `final String zoneName;`
  - `final String facilityDescription;`
  - `final String badgeText;`
  - `final List<int> courtNumbers;`
  - `final String priceRangeDisplay;`
- `CourtSportPartition`:
  - `static List<SportZone> getZonesForVenue(Venue venue)`
- `ShiftSlotGenerator`:
  - `static double calculateSlotPrice({required String sportType, required String startTime, double venueBaseRate = 160000.0})`
  - Update `generateSlots` signature to accept `Venue? venue` or `double? venueBaseRate`.

- [ ] **Step 1: Write failing unit test for Sport-Aware Pricing & Zones**

Create `test/core/utils/shift_slot_generator_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/court_sport_partition.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/core/utils/shift_slot_generator.dart';

void main() {
  test('calculateSlotPrice gives realistic sport-specific rates', () {
    // Football pitch: Daytime off-peak ~250k, Peak ~420k
    final fbOffPeak = ShiftSlotGenerator.calculateSlotPrice(
      sportType: 'football',
      startTime: '10:00',
    );
    expect(fbOffPeak, equals(250000.0));

    final fbPeak = ShiftSlotGenerator.calculateSlotPrice(
      sportType: 'football',
      startTime: '18:00',
    );
    expect(fbPeak, equals(420000.0));

    // Pickleball: Daytime off-peak ~130k, Peak ~220k
    final pbOffPeak = ShiftSlotGenerator.calculateSlotPrice(
      sportType: 'pickleball',
      startTime: '14:00',
    );
    expect(pbOffPeak, equals(130000.0));

    final pbPeak = ShiftSlotGenerator.calculateSlotPrice(
      sportType: 'pickleball',
      startTime: '19:00',
    );
    expect(pbPeak, equals(220000.0));

    // Badminton at Tao Đàn (base 160k): Off-peak 80k, Peak 180k
    final bdmOffPeak = ShiftSlotGenerator.calculateSlotPrice(
      sportType: 'badminton',
      startTime: '09:00',
      venueBaseRate: 160000.0,
    );
    expect(bdmOffPeak, equals(80000.0));

    final bdmPeak = ShiftSlotGenerator.calculateSlotPrice(
      sportType: 'badminton',
      startTime: '18:00',
      venueBaseRate: 160000.0,
    );
    expect(bdmPeak, equals(180000.0));
  });

  test('Tân Bình Arena generates distinct prices for badminton, pickleball, and football courts', () {
    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    final slots = ShiftSlotGenerator.generateSlots(
      date: '2026-09-06',
      courtCount: tanBinhVenue.courtCount,
      shift: 'evening',
      minuteOffset: ':00',
      venue: tanBinhVenue,
    );

    // Court 1 (Badminton) at 18:00
    final bdmSlot = slots.firstWhere((s) => s.courtNumber == 1 && s.startTime == '18:00');
    expect(bdmSlot.price, equals(200000.0)); // 180k base * 1.125 = ~200k

    // Court 5 (Pickleball) at 18:00
    final pbSlot = slots.firstWhere((s) => s.courtNumber == 5 && s.startTime == '18:00');
    expect(pbSlot.price, equals(220000.0));

    // Court 8 (Football) at 18:00
    final fbSlot = slots.firstWhere((s) => s.courtNumber == 8 && s.startTime == '18:00');
    expect(fbSlot.price, equals(420000.0));
  });

  test('CourtSportPartition.getZonesForVenue groups Tân Bình Arena into 3 physical zones', () {
    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    final zones = CourtSportPartition.getZonesForVenue(tanBinhVenue);

    expect(zones.length, equals(3));
    expect(zones[0].sportType, equals('badminton'));
    expect(zones[0].courtNumbers, equals([1, 2, 3, 4]));
    expect(zones[1].sportType, equals('pickleball'));
    expect(zones[1].courtNumbers, equals([5, 6, 7]));
    expect(zones[2].sportType, equals('football'));
    expect(zones[2].courtNumbers, equals([8, 9, 10]));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/shift_slot_generator_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement SportZone, calculateSlotPrice, and getZonesForVenue**

1. Create `lib/domain/entities/sport_zone.dart`:
```dart
class SportZone {
  final String zoneId;
  final String sportType;
  final String zoneName;
  final String facilityDescription;
  final String badgeText;
  final List<int> courtNumbers;
  final String priceRangeDisplay;

  const SportZone({
    required this.zoneId,
    required this.sportType,
    required this.zoneName,
    required this.facilityDescription,
    required this.badgeText,
    required this.courtNumbers,
    required this.priceRangeDisplay,
  });
}
```

2. In `lib/core/utils/court_sport_partition.dart`:
Add `getZonesForVenue(Venue venue)`:
```dart
  static List<SportZone> getZonesForVenue(Venue venue) {
    if (venue.sportTypes.length <= 1) {
      final sport = venue.sportTypes.isNotEmpty ? venue.sportTypes.first : 'badminton';
      final label = _sportLabel(sport);
      return [
        SportZone(
          zoneId: 'zone_${venue.id}_$sport',
          sportType: sport,
          zoneName: 'Cụm Sân $label',
          facilityDescription: 'Tiêu chuẩn thi đấu chất lượng cao',
          badgeText: 'Chuyên nghiệp',
          courtNumbers: List.generate(venue.courtCount, (i) => i + 1),
          priceRangeDisplay: '${(venue.hourlyRate * 0.55 / 1000).toInt()}k - ${(venue.hourlyRate * 1.125 / 1000).toInt()}k',
        ),
      ];
    }

    final List<SportZone> zones = [];
    final charA = 'A'.codeUnitAt(0);
    int index = 0;

    for (final sport in venue.sportTypes) {
      final courts = getCourtsForSport(venue: venue, sportType: sport);
      if (courts.isEmpty) continue;

      final zoneLetter = String.fromCharCode(charA + index);
      final String zoneName;
      final String facilityDesc;
      final String badgeText;
      final String priceRange;

      if (sport == 'football') {
        zoneName = 'Phân khu $zoneLetter: Cụm Sân Bóng Đá Mini';
        facilityDesc = 'Mặt cỏ nhân tạo FIFA Pro • Đèn cao áp • Lưới vây 8m';
        badgeText = 'Ngoài trời';
        priceRange = '250k - 420k';
      } else if (sport == 'pickleball') {
        zoneName = 'Phân khu $zoneLetter: Cụm Sân Pickleball Pro';
        facilityDesc = 'Mặt sơn USAPA giảm chấn • Mái che thoáng khí';
        badgeText = 'Có mái che';
        priceRange = '130k - 220k';
      } else {
        zoneName = 'Phân khu $zoneLetter: Cụm Sân Cầu Lông Tiêu Chuẩn';
        facilityDesc = 'Nhà thi đấu máy lạnh • Thảm BWF chống trượt';
        badgeText = 'Trong nhà';
        final base = venue.hourlyRate > 0 ? venue.hourlyRate : 160000.0;
        priceRange = '${(base * 0.5 / 1000).toInt()}k - ${(base * 1.125 / 1000).toInt()}k';
      }

      zones.add(
        SportZone(
          zoneId: 'zone_${venue.id}_$sport',
          sportType: sport,
          zoneName: zoneName,
          facilityDescription: facilityDesc,
          badgeText: badgeText,
          courtNumbers: courts,
          priceRangeDisplay: priceRange,
        ),
      );
      index++;
    }

    return zones;
  }

  static String _sportLabel(String sport) {
    switch (sport) {
      case 'badminton':
        return 'Cầu Lông';
      case 'pickleball':
        return 'Pickleball';
      case 'football':
        return 'Bóng Đá';
      default:
        return sport;
    }
  }
```

3. In `lib/core/utils/shift_slot_generator.dart`:
Add `calculateSlotPrice` and update `generateSlots` to accept `Venue? venue`:
```dart
  static double calculateSlotPrice({
    required String sportType,
    required String startTime,
    double venueBaseRate = 160000.0,
  }) {
    final startHour = int.tryParse(startTime.split(':').first) ?? 12;
    final isFootball = sportType.contains('football') || sportType.contains('bóng đá');
    final isPickleball = sportType.contains('pickleball');

    if (isFootball) {
      if (startHour >= 6 && startHour < 8) return 280000.0;
      if (startHour >= 8 && startHour < 16) return 250000.0;
      if (startHour >= 16 && startHour < 17) return 320000.0;
      if (startHour >= 17 && startHour < 21) return 420000.0;
      return 300000.0;
    } else if (isPickleball) {
      if (startHour >= 6 && startHour < 8) return 160000.0;
      if (startHour >= 8 && startHour < 16) return 130000.0;
      if (startHour >= 16 && startHour < 17) return 170000.0;
      if (startHour >= 17 && startHour < 21) return 220000.0;
      return 150000.0;
    } else {
      final base = venueBaseRate > 0 ? venueBaseRate : 160000.0;
      if (startHour >= 6 && startHour < 8) return (base * 0.75 / 5000).round() * 5000.0;
      if (startHour >= 8 && startHour < 16) return (base * 0.50 / 5000).round() * 5000.0;
      if (startHour >= 16 && startHour < 17) return (base * 0.85 / 5000).round() * 5000.0;
      if (startHour >= 17 && startHour < 21) return (base * 1.125 / 5000).round() * 5000.0;
      return (base * 0.75 / 5000).round() * 5000.0;
    }
  }
```

In `generateSlots`:
```dart
  static List<TimeSlot> generateSlots({
    required String date,
    required int courtCount,
    required String shift,
    required String minuteOffset,
    Venue? venue,
  })
```
Inside the loop for `court`:
```dart
final sportType = venue != null
    ? CourtSportPartition.getSportForCourt(venue: venue, courtNumber: court)
    : 'badminton';
final slotPrice = calculateSlotPrice(
  sportType: sportType,
  startTime: startTime,
  venueBaseRate: venue?.hourlyRate ?? 160000.0,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/shift_slot_generator_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/domain/entities/sport_zone.dart lib/core/utils/court_sport_partition.dart lib/core/utils/shift_slot_generator.dart test/core/utils/shift_slot_generator_test.dart
git commit -m "feat: implement SportZone model and sport-aware tiered slot pricing"
```

---

### Task 2: Zone Headers & Grouped Court Layout in `VenueDetailScreen`

**Files:**
- Modify: `lib/main.dart` (`VenueDetailScreen`)
- Create: `test/presentation/screens/venue_zoning_test.dart`

**Interfaces:**
- Produces:
  - `Key('zone_header_${zone.sportType}')`
  - Quick Zone Filter Chips: `Key('zone_filter_all')`, `Key('zone_filter_$sport')`
  - Formatted slot chip price with peak/off-peak label in each court card.

- [ ] **Step 1: Write failing widget test for Venue Zoning**

Create `test/presentation/screens/venue_zoning_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/bloc/booking_bloc.dart';

void main() {
  testWidgets('VenueDetailScreen renders Sport Zones for multi-sport venue Tân Bình Arena', (tester) async {
    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(venue: tanBinhVenue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Zone Headers exist
    expect(find.byKey(const Key('zone_header_badminton')), findsOneWidget);
    expect(find.byKey(const Key('zone_header_pickleball')), findsOneWidget);
    expect(find.byKey(const Key('zone_header_football')), findsOneWidget);

    // Verify Zone details
    expect(find.textContaining('Cụm Sân Bóng Đá Mini'), findsOneWidget);
    expect(find.textContaining('FIFA Pro'), findsOneWidget);
    expect(find.textContaining('420k'), findsWidgets); // Football peak price
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/venue_zoning_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement Grouped Zone Layout in VenueDetailScreen**

In `lib/main.dart`:
1. In `_getDynamicSlots()`:
   Pass `venue: widget.venue` to `ShiftSlotGenerator.generateSlots(...)`.
2. In `_buildCourtOverviewMap`:
   - Retrieve `final zones = CourtSportPartition.getZonesForVenue(widget.venue);`.
   - Filter zones by `_selectedSportFilter` (if not 'all').
   - For each zone:
     - Render **Zone Header Card** (`Key('zone_header_${zone.sportType}')`):
       - Gradient banner background based on sport (Badminton: Emerald gradient, Pickleball: Sky Blue gradient, Football: Grass Green gradient).
       - Header row: Sport icon + `zone.zoneName` + `zone.badgeText` tag.
       - Subtitle: `zone.facilityDescription`.
       - Price indicator tag: `zone.priceRangeDisplay / slot`.
     - Render the court cards belonging to that zone (`zone.courtNumbers`).
3. On each slot chip in the court card:
   - Display `${(slot.price / 1000).toInt()}k`.
   - Display small peak / off-peak pill:
     - Peak hour (17:00 - 21:00): `🔥 Vàng`
     - Off-peak hour (08:00 - 16:00): `Ưu đãi`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/venue_zoning_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/main.dart test/presentation/screens/venue_zoning_test.dart
git commit -m "feat: render physical sport zones, zone headers, and tiered prices in VenueDetailScreen"
```

---

### Task 3: Full Suite Verification, Web Hot Restart & Demo Walkthrough

**Files:**
- None (verification and hot reload)

- [ ] **Step 1: Run static analyzer**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run full test suite**
Run: `flutter test`
Expected: All 160+ tests pass across all test suites.

- [ ] **Step 3: Hot restart web server**
Send `R\n` to background task `task-673`.

- [ ] **Step 4: Present demo walkthrough**
Present full walkthrough in Vietnamese to the user.
