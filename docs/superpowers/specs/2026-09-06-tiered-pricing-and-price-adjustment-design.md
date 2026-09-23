# Design Spec: Tiered Pricing by Time Slot & Owner Price Adjustment (SportHub Partner)

## 1. Overview
Currently, in `VenueOwnerStore._generateTaoDanSchedule()`, courts are initialized with a single flat hourly price (160k for Badminton, 200k for Pickleball) across all 16 operating hours (06:00 to 22:00). In reality, sports venues operate with tiered dynamic pricing (Early Bird, Off-peak discounts during daytime, and Peak/Giờ vàng during after-work hours).

This feature introduces:
1. **Tiered Hourly Pricing Model**: Default slot prices calculated by sport type and time of day reflecting realistic Vietnamese venue pricing patterns.
2. **Visual Badging on Matrix Grid**: Clear visual differentiation for Peak ("🔥 Giờ vàng") and Off-peak ("Tiết kiệm") slots in `OwnerScheduleTab`.
3. **Owner Slot Price Adjustment**: A direct 1-tap action sheet operation allowing venue owners to update the price of any available slot with preset chips and custom price input.

---

## 2. Architecture & Data Model

### 2.1 Pricing Rules
In `VenueOwnerStore`, define standard hourly price mapping based on `sportType` and start hour $H \in [6, 21]$:

```dart
static double calculateDefaultSlotPrice({
  required String sportType,
  required int startHour,
}) {
  final isBadminton = sportType == 'badminton';
  if (startHour >= 6 && startHour < 8) {
    // Early Bird
    return isBadminton ? 120000.0 : 160000.0;
  } else if (startHour >= 8 && startHour < 16) {
    // Off-Peak daytime discount
    return isBadminton ? 80000.0 : 130000.0;
  } else if (startHour >= 16 && startHour < 17) {
    // Transition
    return isBadminton ? 130000.0 : 170000.0;
  } else if (startHour >= 17 && startHour < 21) {
    // Peak hours (Giờ vàng sau giờ làm)
    return isBadminton ? 180000.0 : 240000.0;
  } else {
    // Late Night (21:00 - 22:00)
    return isBadminton ? 120000.0 : 150000.0;
  }
}
```

### 2.2 `CourtSlotItem` Helper Getters
In `lib/domain/entities/court_slot_item.dart`:
```dart
int get startHour {
  final parts = timeRange.split(':');
  return parts.isNotEmpty ? (int.tryParse(parts[0].trim()) ?? 0) : 0;
}

bool get isPeakHour => startHour >= 17 && startHour < 21;
bool get isOffPeakHour => startHour >= 8 && startHour < 16;
```

### 2.3 `VenueOwnerStore` Price Modification
In `lib/core/state/venue_owner_store.dart`:
```dart
void updateSlotPrice(String slotId, double newPrice) {
  final index = _slots.indexWhere((s) => s.slotId == slotId);
  if (index != -1) {
    _slots[index] = _slots[index].copyWith(price: newPrice);
    slotsNotifier.value = List.unmodifiable(_slots);
  }
}
```

---

## 3. UI/UX Specifications

### 3.1 Schedule Matrix Slot Cards (`OwnerScheduleTab`)
For `CourtSlotStatus.available`:
- Displays formatted price `${(slot.price / 1000).toInt()}k`.
- If `slot.isPeakHour`:
  - Visual accent: Tiny amber flame pill `🔥 Vàng` or text in `AppColors.warning` with bold style.
- If `slot.isOffPeakHour`:
  - Visual accent: Subtle cyan/green pill `Tiết kiệm` or text in `AppColors.secondary`.
- If standard hour:
  - Standard subtle price label.

### 3.2 Action Sheet Quick Price Adjustment (`_SlotActionBottomSheet`)
When tapping an `available` slot:
- Show action button: `[💵 Điều chỉnh giá giờ này]` with `Key('action_update_slot_price')`.
- Tapping opens inline section or sub-dialog `Key('price_adjustment_dialog')`:
  - Current price indicator: e.g., "Giá hiện tại: 80.000đ".
  - Quick preset chips: `80.000đ`, `100.000đ`, `130.000đ`, `160.000đ`, `180.000đ`, `220.000đ`.
  - Custom price TextField with `Key('slot_price_input')` accepting numbers.
  - Button `[💾 Áp dụng giá mới]` with `Key('confirm_update_price_button')`.
  - On confirm, calls `VenueOwnerStore.instance.updateSlotPrice(slot.slotId, newPrice)` and shows a confirmation toast/SnackBar.

---

## 4. Testing & Verification Plan

1. **Unit Tests (`test/core/state/venue_owner_store_test.dart`)**:
   - Verify that Tao Đàn default schedule initializes with tiered prices (08:00 has 80k for badminton, 18:00 has 180k for badminton, 18:00 has 240k for pickleball).
   - Verify `VenueOwnerStore.instance.updateSlotPrice(...)` updates the price and notifies listeners.
2. **Widget Tests (`test/presentation/screens/owner_schedule_matrix_test.dart`)**:
   - Verify that slot tiles render varying prices (80k, 180k, etc.) instead of all 160k.
   - Verify tapping `action_update_slot_price`, entering a new price (e.g. 95000), and confirming updates the slot price to 95k in the UI.
3. **Full Regression Test**:
   - Run `flutter test` across all suites (all 153+ tests passing).
   - Run `flutter analyze` (0 issues).
