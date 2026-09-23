# Design Spec: Multi-Sport Zone Architecture & Tiered Pricing in Consumer Booking

## 1. Context & Motivation
In multi-sport venues (such as *Khu Liên Hợp Thể Thao Tân Bình Arena* which combines Badminton, Pickleball, and Football across 10 courts):
1. **Flat / Inaccurate Pricing**: Currently, `ShiftSlotGenerator` applies a flat rate (`150,000đ/slot` for evening) across ALL courts regardless of sport. In reality:
   - Badminton: 80k (off-peak) - 160k (peak).
   - Pickleball: 120k (off-peak) - 220k (peak).
   - Football (Mini 5-7 players, FIFA grass): 240k (off-peak) - 420k (peak).
   Displaying a 5-player FIFA football pitch at the same 150k price as a single badminton court is unrealistic.
2. **Lack of Physical Spatial Zoning**: In actual sports complexes, courts are separated into distinct physical zones:
   - **Khu A**: Indoor Badminton Hall (Courts 1 - 4, BWF mat, Air-conditioned).
   - **Khu B**: Covered Outdoor Pickleball (Courts 5 - 7, USAPA surface).
   - **Khu C**: Outdoor Football Complex (Courts 8 - 10, FIFA artificial turf, floodlights).
   Listing all 10 courts in a continuous ungrouped vertical list creates confusion and visual dissonance.

---

## 2. Core Architecture

### 2.1 Sport-Aware & Time-Aware Pricing in `ShiftSlotGenerator`
Extend `ShiftSlotGenerator.generateSlots` to calculate realistic slot prices per court based on:
- The court's sport type via `CourtSportPartition.getSportForCourt(venue: venue, courtNumber: courtNumber)`.
- The slot start hour $H \in [6, 23]$.
- Formula:
  ```dart
  static double calculateSlotPrice({
    required String sportType,
    required String startTime,
    required double venueBaseRate,
  }) {
    final startHour = int.tryParse(startTime.split(':').first) ?? 12;
    final isFootball = sportType.contains('football') || sportType.contains('bóng đá');
    final isPickleball = sportType.contains('pickleball');
    final isBadminton = !isFootball && !isPickleball;

    if (isFootball) {
      // 5-player artificial turf football pitch
      if (startHour >= 6 && startHour < 8) return 280000.0;
      if (startHour >= 8 && startHour < 16) return 250000.0; // Daytime off-peak
      if (startHour >= 16 && startHour < 17) return 320000.0;
      if (startHour >= 17 && startHour < 21) return 420000.0; // Peak hours
      return 300000.0; // Late night
    } else if (isPickleball) {
      // USAPA Pickleball court
      if (startHour >= 6 && startHour < 8) return 160000.0;
      if (startHour >= 8 && startHour < 16) return 130000.0; // Daytime off-peak
      if (startHour >= 16 && startHour < 17) return 170000.0;
      if (startHour >= 17 && startHour < 21) return 220000.0; // Peak hours
      return 150000.0;
    } else {
      // Badminton court scaled by venueBaseRate
      final base = venueBaseRate > 0 ? venueBaseRate : 160000.0;
      if (startHour >= 6 && startHour < 8) return (base * 0.75 / 5000).round() * 5000.0;
      if (startHour >= 8 && startHour < 16) return (base * 0.50 / 5000).round() * 5000.0;
      if (startHour >= 16 && startHour < 17) return (base * 0.85 / 5000).round() * 5000.0;
      if (startHour >= 17 && startHour < 21) return (base * 1.125 / 5000).round() * 5000.0;
      return (base * 0.75 / 5000).round() * 5000.0;
    }
  }
  ```

### 2.2 Sport Zone Entity Model (`SportZone`)
Create helper class or structure `SportZone`:
```dart
class SportZone {
  final String zoneId; // 'zone_badminton', 'zone_pickleball', 'zone_football'
  final String sportType; // 'badminton', 'pickleball', 'football'
  final String zoneName; // 'Khu A - Sân Cầu Lông Tiêu Chuẩn'
  final String facilityDescription; // 'Nhà thi đấu máy lạnh • Thảm BWF 5 lớp'
  final String badgeText; // 'Trong nhà' / 'Mái che' / 'Ngoài trời'
  final List<int> courtNumbers;
  final String priceRangeDisplay; // '80.000đ - 180.000đ'
}
```

Helper in `CourtSportPartition`:
`static List<SportZone> getZonesForVenue(Venue venue)`:
- Groups court numbers into zones based on partitioned sport types.
- If single sport, creates one single zone (e.g. "Khu Sân Cầu Lông").
- If multi-sport (e.g. Tân Bình Arena), creates:
  - Khu A: Cầu lông (Sân 1 - 4)
  - Khu B: Pickleball (Sân 5 - 7)
  - Khu C: Bóng đá mini (Sân 8 - 10)

---

## 3. UI/UX Specifications in `VenueDetailScreen`

### 3.1 Quick Zone Filter Bar (Sticky / Horizontal Header)
Replaces generic filter chips with dedicated Zone Switchers:
- `[🔥 Tất cả các khu (10 sân)]` (`Key('zone_filter_all')`)
- `[🏸 Khu A - Cầu Lông (4 sân)]` (`Key('zone_filter_badminton')`)
- `[🎾 Khu B - Pickleball (3 sân)]` (`Key('zone_filter_pickleball')`)
- `[⚽ Khu C - Sân Bóng Đá (3 sân)]` (`Key('zone_filter_football')`)

### 3.2 Zone Partitioned Layout in 2D Court Overview (`_buildCourtOverviewMap`)
When viewing courts:
- Courts are visually grouped by Zone!
- Each Zone starts with a distinct **Zone Header Card**:
  - Sport Icon + Zone Name + Badge (e.g. `Trong nhà • BWF`, `Mặt USAPA`, `Cỏ FIFA Pro`).
  - Price range badge for this specific sport (e.g. `80k - 180k/slot` for Badminton, `250k - 420k/slot` for Football).
- Followed by the court cards of that zone.
- Each slot chip inside the court card displays:
  - Time range: `18:00 - 19:00`
  - Exact price for that sport/hour: `${slot.price.toInt()}đ` (or `${(slot.price/1000).toInt()}k`)
  - Status / Peak tag: `🔥 Giờ vàng` if peak, `Ưu đãi` if off-peak.

### 3.3 2D Time Slot Matrix (`TimeSlotMatrix`)
When viewing in Matrix mode:
- If a specific sport filter is selected (e.g. Football), renders only football pitches with football dimensions and football pricing.
- If `all` is selected, provides an intuitive sub-tab switcher for the active zone (`🏸 Cầu lông`, `🎾 Pickleball`, `⚽ Bóng đá`) so courts of the same sport and dimension are aligned cleanly without horizontal layout mismatch.

---

## 4. Testing & Verification Plan

1. **Unit Tests (`test/core/utils/shift_slot_generator_test.dart`)**:
   - Verify football pitches in Tân Bình Arena produce football pricing (250k off-peak, 420k peak).
   - Verify pickleball courts produce pickleball pricing (130k off-peak, 220k peak).
   - Verify badminton courts produce tiered pricing based on venue base rate.
2. **Widget Tests (`test/presentation/screens/venue_zoning_test.dart`)**:
   - Verify `VenueDetailScreen` renders Zone Header Cards (`Khu A - Cầu Lông`, `Khu B - Pickleball`, `Khu C - Bóng Đá`).
   - Verify zone filter chips filter courts by sport zone.
   - Verify slot prices differ between badminton (80k/160k) and football (250k/420k).
3. **Full Regression**:
   - `flutter test` across all 158+ tests passing.
   - `flutter analyze` 0 issues found.
