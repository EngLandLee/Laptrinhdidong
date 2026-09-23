# Comprehensive Venue Details & Add-on Services Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the Venue Detail Screen into a realistic, feature-packed sports booking experience with global smartphone viewport framing, photo carousel, operating hotline, amenities, date picker, equipment rentals, retail refreshments, house rules, reviews, and dynamic VietQR grand total calculation.

**Architecture:** Flutter M3 with Clean Architecture, global `ResponsiveMobileWrapper` via `MaterialApp.builder`, reactive add-on item counters, and BLoC time-slot selection.

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_bloc, intl, qr_flutter.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame for Web/Desktop.
- UI Language & Messages: Vietnamese (Tiếng Việt).
- Architecture Pattern: Clean Architecture + BLoC pattern.
- Design Theme: Sporty Dark Luxury (Obsidian `#0B0F19`, Slate Surface `#161F30`, Neon Emerald `#10B981` & `#00E676`, Cyber Cyan `#06B6D4`, Radiant Amber `#F59E0B`).

---

### Task 1: Global Viewport Wrapper & Venue Add-on Domain Entity

**Files:**
- Create: `lib/domain/entities/venue_addon.dart`
- Modify: `lib/core/utils/seed_data.dart`
- Modify: `lib/main.dart:18-47`
- Create: `test/domain/entities/venue_addon_test.dart`

**Interfaces:**
- Consumes: Dart core
- Produces: `VenueAddonItem`, `AddonCategory`, `SeedData.sampleAddons`, `MaterialApp.builder` global framing

- [ ] **Step 1: Write failing test for VenueAddonItem entity and catalog**

```dart
// test/domain/entities/venue_addon_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/venue_addon.dart';
import 'package:sporthub/core/utils/seed_data.dart';

void main() {
  test('VenueAddonItem instantiates correctly and is present in SeedData', () {
    const item = VenueAddonItem(
      id: 'a1',
      name: 'Vợt Cầu Lông Yonex',
      description: 'Dòng Astrox 88D chuyên công',
      price: 30000,
      unit: 'cây',
      category: AddonCategory.rental,
      icon: '🏸',
    );

    expect(item.id, 'a1');
    expect(item.price, 30000);
    expect(SeedData.sampleAddons.length, greaterThanOrEqualTo(6));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/entities/venue_addon_test.dart`  
Expected: FAIL (file or class not found)

- [ ] **Step 3: Implement `venue_addon.dart`, update `seed_data.dart`, and configure `MaterialApp.builder`**

Create `lib/domain/entities/venue_addon.dart`:
```dart
enum AddonCategory { rental, beverage, gear }

class VenueAddonItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final AddonCategory category;
  final String icon;

  const VenueAddonItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.icon,
  });
}
```

Add `SeedData.sampleAddons` to `lib/core/utils/seed_data.dart`.

Update `lib/main.dart` to use `builder: (context, child) => ResponsiveMobileWrapper(child: child!)` on `MaterialApp`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/entities/venue_addon_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/venue_addon.dart lib/core/utils/seed_data.dart lib/main.dart test/domain/entities/venue_addon_test.dart
git commit -m "feat: add VenueAddonItem entity and configure global ResponsiveMobileWrapper via MaterialApp.builder"
```

---

### Task 2: Build VenueAddonSelector Widget

**Files:**
- Create: `lib/presentation/widgets/venue_addon_selector.dart`
- Create: `test/presentation/widgets/venue_addon_selector_test.dart`

**Interfaces:**
- Consumes: `List<VenueAddonItem> items`, `Map<String, int> selectedCounts`, `void Function(VenueAddonItem, int) onQuantityChanged`
- Produces: Visual category tabs (Thuê Dụng Cụ, Nước Uống, Phụ Kiện) with `[-] quantity [+]` stepper controls and subtotal calculation.

- [ ] **Step 1: Write test for `VenueAddonSelector`**

```dart
// test/presentation/widgets/venue_addon_selector_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/venue_addon.dart';
import 'package:sporthub/presentation/widgets/venue_addon_selector.dart';

void main() {
  testWidgets('VenueAddonSelector displays items and increments quantity', (tester) async {
    const items = [
      VenueAddonItem(
        id: 'r1',
        name: 'Vợt Cầu Lông Yonex',
        description: 'Chuyên công',
        price: 30000,
        unit: 'cây',
        category: AddonCategory.rental,
        icon: '🏸',
      ),
    ];

    int currentQty = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VenueAddonSelector(
                items: items,
                selectedCounts: {'r1': currentQty},
                onQuantityChanged: (item, qty) {
                  setState(() => currentQty = qty);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Vợt Cầu Lông Yonex'), findsOneWidget);
    expect(find.text('30000 đ/cây'), findsOneWidget);

    // Tap increment
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(currentQty, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/venue_addon_selector_test.dart`  
Expected: FAIL (widget not found)

- [ ] **Step 3: Implement `VenueAddonSelector`**

Implement in `lib/presentation/widgets/venue_addon_selector.dart` with category filter pills, steppers, and Dark Luxury styling.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/venue_addon_selector_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/venue_addon_selector.dart test/presentation/widgets/venue_addon_selector_test.dart
git commit -m "feat: implement VenueAddonSelector widget with category filters and quantity steppers"
```

---

### Task 3: Comprehensive Venue Detail Screen Redesign

**Files:**
- Modify: `lib/main.dart` (`VenueDetailScreen`)
- Create: `test/presentation/screens/venue_detail_test.dart`

**Interfaces:**
- Consumes: `Venue`, `BookingBloc`, `TimeSlotMatrix`, `VenueAddonSelector`, `SeedData.sampleAddons`, `VietQRGenerator`
- Produces: Rich Venue Detail screen with:
  1. Photo Carousel with indicators
  2. Quick actions: Call hotline `0909 123 456`, directions, operating hours
  3. Amenities chips (Aircon, Free Parking, Hot Shower, Canteen, BWF Mats)
  4. Horizontal Date Picker
  5. Pricing tier cards
  6. Interactive 2D TimeSlotMatrix
  7. Add-on services & equipment rental selector
  8. House rules & cancellation policy
  9. Player reviews & ratings
  10. Sticky bottom bar with Slot + Add-on totals
  11. Dynamic VietQR modal breakdown

- [ ] **Step 1: Write integration test for VenueDetailScreen**

```dart
// test/presentation/screens/venue_detail_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';

void main() {
  testWidgets('VenueDetailScreen renders gallery, amenities, date picker and addons', (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(venue.name), findsOneWidget);
    expect(find.text('Dịch vụ & Thuê dụng cụ'), findsOneWidget);
    expect(find.text('Quy định sân & Chính sách'), findsOneWidget);
    expect(find.text('Đánh giá từ người chơi'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/venue_detail_test.dart`  
Expected: FAIL (missing section titles)

- [ ] **Step 3: Implement rich VenueDetailScreen in `lib/main.dart`**

Add carousel, quick action buttons, amenities grid, date selector, price tiers, addon selector, rules, reviews, and enhanced VietQR dialog.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/venue_detail_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/presentation/screens/venue_detail_test.dart
git commit -m "feat: complete realistic VenueDetailScreen overhaul with photo gallery, amenities, addons, and house rules"
```

---

### Task 4: Full Test Suite Verification & Hot Restart

**Files:**
- Verification only

- [ ] **Step 1: Run complete automated test suite**

Run: `flutter test`  
Expected: All tests pass (0 failures)

- [ ] **Step 2: Verify `flutter analyze`**

Run: `flutter analyze`  
Expected: 0 issues found

- [ ] **Step 3: Trigger hot restart on running Chrome instance**

Verify that navigating into any venue displays the rich photo carousel, call hotline, amenities, equipment rentals (rackets, auto launcher), canteen items, and sticky grand total.
