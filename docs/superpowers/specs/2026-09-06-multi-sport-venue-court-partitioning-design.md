# Design Specification: Multi-Sport Complex Court Partitioning & Sport Filtering

- **Date:** 2026-09-06
- **Status:** Approved
- **Target Branch/Codebase:** Mobile (Flutter 3.x / Dart 3.x)

---

## 1. Problem Statement

In `VenueDetailScreen`, both the booking matrix (`TimeSlotMatrix`) and the 2D court overview map (`_buildCourtOverviewMap`) currently use:
```dart
widget.venue.sportTypes.isNotEmpty ? widget.venue.sportTypes.first : 'badminton'
```
For multi-sport complexes like **Khu Liên Hợp Thể Thao Tân Bình Arena** (`sportTypes: ['badminton', 'football', 'pickleball']` with 10 courts):
1. All 10 courts are forcibly rendered with Badminton BWF court graphics.
2. Football (FIFA artificial turf) and Pickleball courts are never rendered or distinguished.
3. Users have no way to filter or select their intended sport when booking slots at a multi-sport facility.

---

## 2. Goals & Success Criteria

1. **Realistic Court Partitioning:**
   - Courts in multi-sport venues are logically partitioned across the venue's sport types.
   - For **Khu Liên Hợp Thể Thao Tân Bình Arena** (10 courts):
     - **Sân 1 – 4 (4 courts):** 🏸 Cầu lông (`badminton`) — Thảm BWF.
     - **Sân 5 – 7 (3 courts):** 🏓 Pickleball (`pickleball`) — Mặt sân USAPA.
     - **Sân 8 – 10 (3 courts):** ⚽ Bóng đá mini (`football`) — Cỏ nhân tạo FIFA.
   - Single-sport venues (e.g., CLB Cầu Lông Bình Thạnh) keep 100% of their courts mapped to their single sport.

2. **Sport Partition Filter Bar:**
   - Display horizontal filter chips above the Matrix / 2D Map controls:
     `[🔥 Tất cả (10)]` | `[🏸 Cầu lông (4)]` | `[🏓 Pickleball (3)]` | `[⚽ Bóng đá (3)]`.
   - Hidden when venue has only 1 sport (avoids clutter).
   - Selecting a sport filters both Matrix columns and 2D Court cards to only the courts belonging to that sport.

3. **Per-Court Authentic Visual Graphics:**
   - When "All" is active, each court card/column renders its respective sport painter (Courts 1-4: Badminton, Courts 5-7: Pickleball, Courts 8-10: Football).
   - Add `PickleballCourtPainter` for authentic USAPA court markings (kitchen line, center service line, non-volley zone, two-tone navy/cyan palette).

4. **Relevant Addons Filtering:**
   - When a specific sport is selected, the Addon selector prioritizes/filters add-on gear relevant to that sport (e.g., football bibs/balls for football, pickleball paddles/balls for pickleball).

---

## 3. Architecture & Data Model

### 3.1 Court-to-Sport Mapping Helper

Create a deterministic partitioning helper:
```dart
class CourtSportPartition {
  static String getSportForCourt({
    required Venue venue,
    required int courtNumber,
  }) {
    if (venue.sportTypes.isEmpty) return 'badminton';
    if (venue.sportTypes.length == 1) return venue.sportTypes.first;

    // Multi-sport partition logic:
    // Tân Bình Arena (10 courts, 3 sports: badminton, football, pickleball)
    if (venue.id == 'venue_tb_05' || venue.courtCount == 10) {
      if (courtNumber <= 4) return 'badminton';
      if (courtNumber <= 7) return 'pickleball';
      return 'football';
    }

    // Generic multi-sport proportional distribution
    final count = venue.sportTypes.length;
    final index = ((courtNumber - 1) * count ~/ venue.courtCount).clamp(0, count - 1);
    return venue.sportTypes[index];
  }

  static List<int> getCourtsForSport({
    required Venue venue,
    required String sportType,
  }) {
    if (sportType == 'all') {
      return List.generate(venue.courtCount, (i) => i + 1);
    }
    return List.generate(venue.courtCount, (i) => i + 1)
        .where((c) => getSportForCourt(venue: venue, courtNumber: c) == sportType)
        .toList();
  }
}
```

---

## 4. UI/UX Design

### 4.1 Sport Partition Selector Bar in `VenueDetailScreen`
- Rendered only if `venue.sportTypes.length > 1`.
- Placed immediately above `_buildViewModeToggle()`.
- Segmented pills:
  - `key: Key('venue_sport_filter_all')` — Label: `'🔥 Tất cả (${venue.courtCount})'`
  - `key: Key('venue_sport_filter_$sport')` — Label: `'$label (${courtCount})'`
- Active pill styling: Neon glow border (`AppColors.primary` or sport accent), dark surface background.

### 4.2 TimeSlotMatrix Court-Sport Awareness
- `TimeSlotMatrix` receives an optional `courtSportMap` or computes court sport dynamically per column.
- Filter displayed court columns to only `activeCourts`.
- Each column header (`VisualCourtHeader`) and slot cell (`VisualCourtSlotCell`) uses the court's actual sport type.

### 4.3 2D Court Overview Map
- `_buildCourtOverviewMap` iterates only through `activeCourts`.
- Renders `VisualCourtHeader(courtNumber: courtNumber, sportType: courtSport)`.

### 4.4 Authentic `PickleballCourtPainter`
- Markings:
  - Outer boundary line (20x44 ft proportional).
  - Center net line.
  - Non-Volley Zone lines (Kitchen) at 7 ft from net on both sides.
  - Centerline dividing left and right service courts from kitchen to baseline.
- Colors:
  - Base: Deep Navy Blue (`#0F172A` / `#0284C7`).
  - Kitchen area: Emerald/Teal tinted tint.
  - White high-contrast boundary lines (0.6 alpha).

---

## 5. Testing Strategy

1. **Unit Tests (`test/core/utils/court_sport_partition_test.dart`):**
   - Verify court 1-4 returns `badminton`, 5-7 returns `pickleball`, 8-10 returns `football` for Tân Bình Arena.
   - Verify single-sport venues return uniform sport.
2. **Widget Tests (`test/presentation/screens/multi_sport_venue_test.dart`):**
   - Open `VenueDetailScreen` with `venue_tb_05`.
   - Verify Sport Partition Filter Bar is displayed with 4 chips.
   - Tap `[⚽ Bóng đá]`: verify only Courts 8, 9, 10 are visible in 2D Map and Matrix.
   - Verify slot cells and headers reflect Football turf.
   - Tap `[🏓 Pickleball]`: verify Courts 5, 6, 7 are visible with USAPA badge.
   - Tap `[🔥 Tất cả]`: verify all 10 courts visible with respective sport types.
3. **Regression Tests:**
   - Ensure existing 92 tests continue to pass with 0 analyzer diagnostics.
