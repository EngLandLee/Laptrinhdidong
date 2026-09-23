# Multi-Sport Complex Court Partitioning & Sport Filtering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Partition courts in multi-sport venues (e.g. Tân Bình Arena) by sport type, render authentic court markings (Badminton, Football turf, and newly added Pickleball USAPA), and provide a dynamic sport filter bar in `VenueDetailScreen`.

**Architecture:**
1. A dedicated `CourtSportPartition` utility maps court numbers to their respective sport types (Tân Bình Arena: Courts 1-4 Badminton, Courts 5-7 Pickleball, Courts 8-10 Football).
2. `PickleballCourtPainter` provides authentic USAPA vector court graphics (kitchen zone, centerline, non-volley boundary, navy/cyan contrast).
3. `VenueDetailScreen` introduces a segmented Sport Partition Filter Bar above the matrix/2D controls, filtering both `TimeSlotMatrix` columns and `_buildCourtOverviewMap` cards, while ensuring each court renders its authentic sport graphics even in "All" mode.

**Tech Stack:** Flutter 3.x, Dart 3.x, CustomPainter vector graphics, Flutter test framework.

## Global Constraints

- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + BLoC / reactive ValueNotifier pattern.
- Design Theme: Sporty Dark Luxury (`AppColors.background` #0B0F19, `surface` #161F30, `primary` #10B981, `secondary` #06B6D4, `accent` #F59E0B).
- Backward Compatibility: Keep existing 92 unit, widget, and integration tests passing.

---

### Task 1: Core Partitioning Helper & Authentic PickleballCourtPainter

**Files:**
- Create: `lib/core/utils/court_sport_partition.dart`
- Modify: `lib/presentation/widgets/visual_court_header.dart:25-75, 300-468` (Add `PickleballCourtPainter` and wire `_isPickleball`)
- Modify: `lib/presentation/widgets/visual_court_slot_cell.dart:23-50` (Wire `_isPickleball` and `PickleballCourtPainter`)
- Test: `test/core/utils/court_sport_partition_test.dart`

**Interfaces:**
- Consumes: `Venue` (`lib/domain/entities/venue.dart`)
- Produces:
  - `CourtSportPartition.getSportForCourt({required Venue venue, required int courtNumber}) -> String`
  - `CourtSportPartition.getCourtsForSport({required Venue venue, required String sportType}) -> List<int>`
  - `PickleballCourtPainter` class implementing authentic USAPA court layout

- [ ] **Step 1: Write failing unit test for `CourtSportPartition`**

Create `test/core/utils/court_sport_partition_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/court_sport_partition.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/venue.dart';

void main() {
  group('CourtSportPartition Tests', () {
    test('Tan Binh Arena (10 courts, 3 sports) partitions correctly', () {
      final venue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');

      // Courts 1-4: Badminton
      for (int c = 1; c <= 4; c++) {
        expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: c), 'badminton');
      }

      // Courts 5-7: Pickleball
      for (int c = 5; c <= 7; c++) {
        expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: c), 'pickleball');
      }

      // Courts 8-10: Football
      for (int c = 8; c <= 10; c++) {
        expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: c), 'football');
      }

      // Get courts for specific sport
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'badminton'), [1, 2, 3, 4]);
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'pickleball'), [5, 6, 7]);
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'football'), [8, 9, 10]);
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'all'), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Single-sport venue returns same sport for all courts', () {
      final venue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_01');
      expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: 1), 'badminton');
      expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: 6), 'badminton');
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'all'), [1, 2, 3, 4, 5, 6]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/court_sport_partition_test.dart`
Expected: FAIL (file does not exist).

- [ ] **Step 3: Implement `CourtSportPartition` and `PickleballCourtPainter`**

Create `lib/core/utils/court_sport_partition.dart`:
```dart
import '../../domain/entities/venue.dart';

class CourtSportPartition {
  CourtSportPartition._();

  static String getSportForCourt({
    required Venue venue,
    required int courtNumber,
  }) {
    if (venue.sportTypes.isEmpty) return 'badminton';
    if (venue.sportTypes.length == 1) return venue.sportTypes.first;

    // Specific partition for Tân Bình Arena
    if (venue.id == 'venue_tb_05' || venue.courtCount == 10) {
      if (courtNumber <= 4) return 'badminton';
      if (courtNumber <= 7) return 'pickleball';
      return 'football';
    }

    // Generic proportional partition
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

In `lib/presentation/widgets/visual_court_header.dart`:
- Add `PickleballCourtPainter` with authentic USAPA court layout: outer boundary, kitchen lines (non-volley zone), center service line, baseline.
- Update `VisualCourtHeader`:
  ```dart
  CustomPainter get _courtPainter {
    if (_isFootball) return const FootballPitchPainter();
    if (_isPickleball) return const PickleballCourtPainter();
    return const BadmintonCourtPainter();
  }
  ```
- In `VisualCourtSlotCell`: Update `courtPainter` selection to include `PickleballCourtPainter`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/court_sport_partition_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyzer and commit**

Run: `flutter analyze`
Run: `git add lib/core/utils/court_sport_partition.dart lib/presentation/widgets/visual_court_header.dart lib/presentation/widgets/visual_court_slot_cell.dart test/core/utils/court_sport_partition_test.dart`
Run: `git commit -m "feat: add CourtSportPartition and authentic PickleballCourtPainter"`

---

### Task 2: Sport Partition Filter Bar & Multi-Sport Matrix/2D Map in VenueDetailScreen

**Files:**
- Modify: `lib/main.dart` (Inside `_VenueDetailScreenState`, add `_selectedSportFilter = 'all'`, `_buildSportPartitionBar()`, filter courts for matrix & 2D map, dynamic sport rendering per court)
- Modify: `lib/presentation/widgets/time_slot_matrix.dart` (Support court-specific sport rendering or `Map<int, String> courtSportMap`)
- Test: `test/presentation/screens/multi_sport_venue_test.dart`

**Interfaces:**
- Consumes: `CourtSportPartition`, `Venue`, `TimeSlot`
- Produces:
  - Sport partition filter chips in `VenueDetailScreen`: `[🔥 Tất cả (10)]`, `[🏸 Cầu lông (4)]`, `[🏓 Pickleball (3)]`, `[⚽ Bóng đá (3)]`
  - Filtered matrix & 2D map showing only courts belonging to the selected sport
  - Authentic per-court sport graphics in both filtered and all-sports view

- [ ] **Step 1: Write widget test for multi-sport venue interaction**

Create `test/presentation/screens/multi_sport_venue_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/core/utils/seed_data.dart';

void main() {
  testWidgets('VenueDetailScreen displays Sport Partition Bar for multi-sport venue', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    await tester.pumpWidget(
      MaterialApp(
        home: VenueDetailScreen(venue: tanBinhVenue),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Sport Partition Bar exists
    expect(find.byKey(const Key('venue_sport_filter_all')), findsOneWidget);
    expect(find.byKey(const Key('venue_sport_filter_badminton')), findsOneWidget);
    expect(find.byKey(const Key('venue_sport_filter_pickleball')), findsOneWidget);
    expect(find.byKey(const Key('venue_sport_filter_football')), findsOneWidget);

    // Switch to 2D court overview map
    await tester.tap(find.text('Sơ đồ 2D'));
    await tester.pumpAndSettle();

    // In All mode: 10 courts
    expect(find.byKey(const Key('court_card_1')), findsOneWidget);
    expect(find.byKey(const Key('court_card_10')), findsOneWidget);

    // Filter to Football only
    await tester.tap(find.byKey(const Key('venue_sport_filter_football')));
    await tester.pumpAndSettle();

    // Only Courts 8, 9, 10 visible
    expect(find.byKey(const Key('court_card_1')), findsNothing);
    expect(find.byKey(const Key('court_card_5')), findsNothing);
    expect(find.byKey(const Key('court_card_8')), findsOneWidget);
    expect(find.byKey(const Key('court_card_9')), findsOneWidget);
    expect(find.byKey(const Key('court_card_10')), findsOneWidget);
    expect(find.text('Cỏ FIFA'), findsWidgets);

    // Filter to Pickleball only
    await tester.tap(find.byKey(const Key('venue_sport_filter_pickleball')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('court_card_5')), findsOneWidget);
    expect(find.byKey(const Key('court_card_6')), findsOneWidget);
    expect(find.byKey(const Key('court_card_7')), findsOneWidget);
    expect(find.byKey(const Key('court_card_8')), findsNothing);
    expect(find.text('Mặt USAPA'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/multi_sport_venue_test.dart`
Expected: FAIL (Sport partition filter keys not found).

- [ ] **Step 3: Implement Sport Partition Bar & Court Filtering in VenueDetailScreen**

In `lib/main.dart` (`_VenueDetailScreenState`):
1. Add `String _selectedSportFilter = 'all';`
2. Add helper method `Widget _buildSportPartitionBar()`:
   - If `widget.venue.sportTypes.length <= 1`, return `const SizedBox.shrink()`.
   - SingleChildScrollView horizontal row with:
     - All chip: `🔥 Tất cả (${widget.venue.courtCount})` (key: `Key('venue_sport_filter_all')`)
     - Sport chips: for each sport in `widget.venue.sportTypes`:
       - Count courts for that sport using `CourtSportPartition.getCourtsForSport(venue: widget.venue, sportType: sport).length`
       - Chip: `${_sportLabel(sport)} ($count)` (key: `Key('venue_sport_filter_$sport')`)
   - On tap: `setState(() => _selectedSportFilter = sport)`
3. Update `_buildCourtOverviewMap`:
   - Get `activeCourts = CourtSportPartition.getCourtsForSport(venue: widget.venue, sportType: _selectedSportFilter)`.
   - Generate court cards only for `activeCourts`.
   - For each court, compute its actual sport: `CourtSportPartition.getSportForCourt(venue: widget.venue, courtNumber: courtNumber)`.
   - Pass `sportType: courtSport` to `VisualCourtHeader`.
4. In `TimeSlotMatrix`:
   - Filter `displayedCourts` according to `activeCourts`.
   - For each court column header and slot cell, render the court's actual individual sport type.
5. In `_buildAddonSelectorSection`:
   - When `_selectedSportFilter != 'all'`, filter addons matching `_selectedSportFilter`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/multi_sport_venue_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: 100% tests passing, 0 analyzer diagnostics.

- [ ] **Step 6: Commit**

Run: `git add lib/main.dart lib/presentation/widgets/time_slot_matrix.dart test/presentation/screens/multi_sport_venue_test.dart`
Run: `git commit -m "feat: implement Sport Partition Bar and dynamic court filtering in VenueDetailScreen"`

---

### Task 3: Verification, Hot Restart & Demo Handoff

**Files:**
- Entire project verification

- [ ] **Step 1: Run full static analysis**
Run: `flutter analyze`
Confirm 0 issues found.

- [ ] **Step 2: Run full test suite**
Run: `flutter test`
Confirm all 94+ tests pass cleanly.

- [ ] **Step 3: Hot restart running web server**
Send `R` to running background task `task-673`.

- [ ] **Step 4: Present final work to user with live test instructions**
Present completed features in Vietnamese and provide link `http://localhost:46477/`.
