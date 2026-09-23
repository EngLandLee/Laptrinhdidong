# Explore Search, Filters, and District Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement full realtime search (`TextField`), interactive district selection bottom sheet modal, unified multi-criteria filtering (Sport + District + Search), and empty state handling on the main Explore feed.

**Architecture:** Enrich seed data with realistic multi-district venues; update `ExploreVenuesScreen` in `lib/main.dart` with `TextEditingController`, district selection bottom sheet modal, unified query logic, and clean empty state with filter reset; add comprehensive widget tests.

**Tech Stack:** Flutter SDK 3.x, Dart 3.x, BLoC pattern, Sporty Dark Luxury theme tokens.

## Global Constraints
- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + BLoC pattern.
- Design Theme: Sporty Dark Luxury.

---

### Task 1: Enrich Seed Data with Multi-District Venues

**Files:**
- Modify: `lib/core/utils/seed_data.dart:187-233`
- Test: `test/presentation/screens/main_ui_test.dart`

**Interfaces:**
- Consumes:
  - `Venue` entity from `lib/domain/entities/venue.dart`
- Produces:
  - Expanded `SeedData.sampleVenues` containing 5 realistic venues across Bình Thạnh, Thủ Đức, Quận 7, Quận 1, and Tân Bình.

- [ ] **Step 1: Write/verify unit test for enriched venues**

Add test case in `test/presentation/screens/main_ui_test.dart` asserting that sample venues contain multiple districts.

```dart
test('SeedData contains venues across diverse districts', () {
  final districts = SeedData.sampleVenues.map((v) => v.district).toSet();
  expect(districts.contains('Bình Thạnh'), isTrue);
  expect(districts.contains('Thủ Đức'), isTrue);
  expect(districts.contains('Quận 7'), isTrue);
  expect(districts.contains('Quận 1'), isTrue);
  expect(districts.contains('Tân Bình'), isTrue);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/main_ui_test.dart`
Expected: FAIL because Quận 1 and Tân Bình venues do not exist yet.

- [ ] **Step 3: Update `SeedData.sampleVenues`**

Add venues for Quận 1 and Tân Bình into `lib/core/utils/seed_data.dart`:
```dart
    Venue(
      id: 'venue_q1_04',
      name: 'CLB Cầu Lông Tao Đàn - Quận 1',
      sportTypes: ['badminton'],
      address: '1 Huyền Trân Công Chúa, Phường Bến Thành',
      district: 'Quận 1',
      courtCount: 5,
      hourlyRate: 160000.0,
      rating: 4.9,
      reviewCount: 180,
      imageUrls: [
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      ],
      amenities: ['Trung tâm Q1', 'Máy lạnh', 'Căn tin', 'Chỗ đậu xe máy'],
    ),
    Venue(
      id: 'venue_tb_05',
      name: 'Khu Liên Hợp Thể Thao Tân Bình Arena',
      sportTypes: ['badminton', 'football', 'pickleball'],
      address: '448 Hoàng Văn Thụ, Phường 4',
      district: 'Tân Bình',
      courtCount: 10,
      hourlyRate: 180000.0,
      rating: 4.8,
      reviewCount: 156,
      imageUrls: [
        'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800',
      ],
      amenities: ['Cụm 10 sân', 'Bãi đỗ ô tô', 'Căng tin thể thao', 'Tắm nóng lạnh'],
    ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/main_ui_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/seed_data.dart test/presentation/screens/main_ui_test.dart
git commit -m "feat: enrich SeedData with sample venues in Quan 1 and Tan Binh"
```

---

### Task 2: Implement Interactive Search, District Bottom Sheet, and Unified Filtering

**Files:**
- Modify: `lib/main.dart:170-435`
- Test: `test/presentation/screens/main_ui_test.dart`

**Interfaces:**
- Consumes:
  - `SeedData.sampleVenues`
  - `AppColors`
- Produces:
  - Interactive search `TextField` with clear button
  - District selection modal bottom sheet with venue counters
  - Unified filtering logic: `matchesSport && matchesDistrict && matchesQuery`
  - Empty state UI with "Đặt lại bộ lọc" reset button

- [ ] **Step 1: Write failing widget tests for search and district filter**

In `test/presentation/screens/main_ui_test.dart`, add widget tests:
1. `Searching by text filters the venue list in realtime`: Enters "Tao Đàn" into search field, verifies only Tao Đàn is visible, tapping clear button restores list.
2. `Selecting district from bottom sheet filters venue list`: Taps location pill `📍 Bình Thạnh, TP.HCM ▾`, bottom sheet opens, taps "Quận 7", verifies location pill updates to "Quận 7" and only Nam Sài Gòn venue is shown.
3. `Empty state displays when no venues match and resets cleanly`: Enters nonexistent query, verifies "Không tìm thấy sân nào phù hợp", taps "Đặt lại bộ lọc", verifies full list restored.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/presentation/screens/main_ui_test.dart`
Expected: FAIL because search is not editable and district selector is static.

- [ ] **Step 3: Update `ExploreVenuesScreen` in `lib/main.dart`**

1. Add state in `_ExploreVenuesScreenState`:
```dart
  String _selectedSport = 'all';
  String _selectedDistrict = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
```
2. Implement `_showDistrictBottomSheet(BuildContext context)`:
   - Lists: "Tất cả TP.HCM", "Bình Thạnh", "Thủ Đức", "Quận 7", "Quận 1", "Tân Bình".
   - Shows venue counts per district.
   - On tap: updates `_selectedDistrict`, pops bottom sheet.
3. Replace static search container with `TextField`:
   - Prefix: `Icon(Icons.search_rounded)`
   - Controller: `_searchController`
   - Suffix: clear button when `_searchQuery.isNotEmpty`
   - `onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase())`
4. Connect Location Pill to `_showDistrictBottomSheet`.
5. Apply unified filtering:
```dart
    final q = _searchQuery.toLowerCase();
    final venues = SeedData.sampleVenues.where((v) {
      final matchesSport = _selectedSport == 'all' || v.sportTypes.contains(_selectedSport);
      final matchesDistrict = _selectedDistrict == 'all' || v.district.toLowerCase() == _selectedDistrict.toLowerCase();
      final matchesQuery = q.isEmpty ||
          v.name.toLowerCase().contains(q) ||
          v.address.toLowerCase().contains(q) ||
          v.district.toLowerCase().contains(q) ||
          v.amenities.any((a) => a.toLowerCase().contains(q));
      return matchesSport && matchesDistrict && matchesQuery;
    }).toList();
```
6. Render Empty State when `venues.isEmpty` with "Đặt lại bộ lọc" button.

- [ ] **Step 4: Run all tests to verify they pass**

Run: `flutter test`
Expected: All 65+ tests pass cleanly.

- [ ] **Step 5: Verify static analysis**

Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart test/presentation/screens/main_ui_test.dart
git commit -m "feat: implement interactive search, district bottom sheet, and unified filtering in Explore feed"
```
