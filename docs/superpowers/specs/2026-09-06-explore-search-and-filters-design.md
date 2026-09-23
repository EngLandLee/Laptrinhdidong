# Explore Screen Search, Filters, and District Selection Design Specification

## Overview
This document specifies the design and implementation for full interactive search, sport filtering, and district/area selection on the main Explore feed (`ExploreVenuesScreen`).

## Context & Problem Statement
Currently on the Explore screen:
- The search bar is a static placeholder `Text` widget rather than an interactive `TextField`.
- The location pill `📍 Bình Thạnh, TP.HCM ▾` is static and does not allow selecting different districts or "All TP.HCM".
- The venue feed only filters by `_selectedSport`, without taking into account search keywords or selected district.

## Key Requirements & User Experience
1. **Interactive Realtime Search Bar**:
   - Implemented with an editable `TextField` styled in the Sporty Dark Luxury palette (`#161F30`, neon focus border, placeholder `Tìm tên sân, địa chỉ, quận...`).
   - Suffix clear icon button `✕` shown when text is not empty to reset search query with 1 tap.
   - Realtime query filtering: Matches venue name, address, district, or amenities (case-insensitive and diacritic-tolerant).
2. **Interactive District Selection via Bottom Sheet**:
   - Tapping `📍 [District], TP.HCM ▾` opens a modal bottom sheet displaying:
     - Header: "Chọn khu vực / Quận" with close button.
     - Options:
       - `🏙️ Tất cả TP.HCM`
       - `📍 Bình Thạnh`
       - `📍 Thủ Đức`
       - `📍 Quận 7`
       - `📍 Quận 1`
       - `📍 Tân Bình`
     - Each option displays the district name, venue count badge, and a checkmark if currently selected.
   - Selecting a district updates the location pill header and filters the venue list accordingly.
3. **Unified Multi-Criteria Filtering**:
   - The venue list dynamically filters by:
     - Sport category: `_selectedSport == 'all' || venue.sportTypes.contains(_selectedSport)`
     - District: `_selectedDistrict == 'all' || venue.district.toLowerCase() == _selectedDistrict.toLowerCase()`
     - Search query: `_searchQuery.isEmpty || venue.name.toLowerCase().contains(q) || venue.address.toLowerCase().contains(q) || venue.district.toLowerCase().contains(q)`
   - Filter count badge / result counter: e.g. "Tìm thấy X cụm sân tại TP.HCM".
4. **Empty State Handling**:
   - When no venues match the combined criteria, show an aesthetic empty state:
     - Magnifying glass icon with neon accent.
     - Title: "Không tìm thấy sân nào phù hợp".
     - Subtitle: "Thử tìm kiếm với từ khóa khác hoặc xóa bớt bộ lọc".
     - Button: "Đặt lại bộ lọc" (resets query to empty, sport to 'all', district to 'all').
5. **Enriched Seed Data**:
   - Expand `SeedData.sampleVenues` with 2 additional realistic venues in Quận 1 and Tân Bình to provide a rich search experience across diverse districts and sports.

## Component & Architecture Impact
- `lib/core/utils/seed_data.dart`:
  - Add sample venues for `Quận 1` (badminton & pickleball) and `Tân Bình` (badminton & football).
- `lib/main.dart` (`ExploreVenuesScreen`):
  - Add state variables: `TextEditingController _searchController`, `String _selectedDistrict = 'all'`, `String _searchQuery = ''`.
  - Replace static search bar with interactive `TextField`.
  - Add `_showDistrictBottomSheet(BuildContext context)` method.
  - Apply unified filtering to `venues`.
  - Render empty state when `venues.isEmpty`.
- `test/presentation/screens/main_ui_test.dart`:
  - Add test cases verifying text search, district selection via bottom sheet, and sport filtering.

## Verification & Testing
1. Verify search query filters venue cards by name.
2. Verify district bottom sheet opens, selecting a district filters venues, and location pill updates.
3. Verify empty state renders and "Đặt lại bộ lọc" resets filters.
4. Verify all tests pass and `flutter analyze` reports 0 issues.
