# Design Spec: Chatbot Court Map Navigation & Visual Focus

## 1. Overview & Objective
When an AI Chatbot recommends a court and time slot via an interactive action card (`ChatBookingCard`), the user has the option to click **"🔍 Xem trên sơ đồ"** (View on court diagram).
Currently, this action merely closes the bottom sheet (`Navigator.pop()`) without passing the court or slot context, leaving the user on whatever screen they were on without any visual indication of where the court is.

The goal of this feature is to deliver a seamless, high-engagement user experience:
1. When **"🔍 Xem trên sơ đồ"** is tapped, extract the target court and slot details from `actionCard`.
2. Transition to the appropriate venue's detail screen (`VenueDetailScreen`).
3. Automatically switch to **Sơ đồ cụm sân** (`_viewMode = 'court_map'`).
4. **Auto-scroll** smoothly to bring the target court card directly into view.
5. **Visual Highlight**: Display a pulsing glow effect on the court card for 3 seconds with a badge **"🎯 Sân AI gợi ý"**.
6. **Pre-select Slot**: Automatically select the recommended time slot in `BookingBloc` so the user immediately sees the slot active, the pricing calculated, and the bottom booking bar ready.

---

## 2. Architecture & Data Flow

```
[Chatbot User Message]
         │
         ▼
[ChatBookingCard]
   - Button: "🔍 Xem trên sơ đồ"
   - Calls onViewCourtMap(actionCard)
         │
         ▼
[ChatbotBottomSheet]
   - _handleViewCourtMap(actionCard)
   - Checks currentRoute & currentVenue:
       * If already on VenueDetailScreen for this venue:
           - Pops bottom sheet.
           - Invokes callback on existing screen to focus target court.
       * If on /home or another venue:
           - Pops bottom sheet.
           - Resolves target Venue (via SeedData or VenueSyncService).
           - Pushes VenueDetailScreen(venue, targetCourtNumber, targetStartTime, targetEndTime, initialViewMode: 'court_map').
         │
         ▼
[VenueDetailScreen]
   - Sets _viewMode = 'court_map'
   - Pre-selects matching TimeSlot in BookingBloc
   - Attaches GlobalKey to target court card
   - Post-frame callback: Scrollable.ensureVisible(key.currentContext)
   - Triggers 3-second pulsing highlight animation & "🎯 Sân AI gợi ý" badge
```

---

## 3. Detailed Component Modifications

### 3.1. `ChatBookingCard` & `ChatMessageBubble`
- Update `onViewCourtMap` signature from `VoidCallback?` to `void Function(Map<String, dynamic> actionCard)?`.
- When the button is pressed, invoke `onViewCourtMap?.call(actionCard)`.

### 3.2. `ChatbotBottomSheet`
- Update `onViewCourtMapAction` signature: `Function(Map<String, dynamic> actionCard)?`.
- In `_handleViewCourtMap(Map<String, dynamic> actionCard)`:
  - Extract:
    - `courtStr`: e.g. `"Sân 1"` -> parse integer `courtNumber = 1`.
    - `venueId`: e.g. `"venue_01"`.
    - `venueName`: e.g. `"CLB Cầu Lông Tao Đàn"`.
    - `startTime`: e.g. `"19:00"`.
    - `endTime`: e.g. `"20:00"`.
    - `sport`: e.g. `"Cầu lông"` -> `'badminton'`.
  - If `widget.onViewCourtMapAction != null`: execute it with `actionCard`.
  - Otherwise, resolve `Venue` matching `venueId` or `venueName` from `SeedData.sampleVenues`.
  - Pop bottom sheet with `Navigator.of(context).pop()`.
  - Push `VenueDetailScreen`:
    ```dart
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => VenueDetailScreen(
          venue: targetVenue,
          targetCourtNumber: courtNumber,
          targetStartTime: startTime,
          targetEndTime: endTime,
          targetSport: sport,
          initialViewMode: 'court_map',
        ),
      ),
    );
    ```

### 3.3. `VenueDetailScreen` & `_VenueDetailScreenState` in `lib/main.dart`
- New constructor parameters:
  - `final int? targetCourtNumber;`
  - `final String? targetStartTime;`
  - `final String? targetEndTime;`
  - `final String? targetSport;`
  - `final String? initialViewMode;`
- State variables:
  - `int? _highlightedCourtNumber;`
  - `AnimationController? _pulseAnimationController;`
  - `final Map<int, GlobalKey> _courtKeys = {};`
- In `initState()`:
  - If `widget.initialViewMode != null`, set `_viewMode = widget.initialViewMode!`.
  - If `widget.targetSport != null && widget.targetSport!.isNotEmpty`:
    - Set `_selectedSportFilter = widget.targetSport!`.
  - If `widget.targetCourtNumber != null`:
    - Set `_highlightedCourtNumber = widget.targetCourtNumber`.
    - Initialize `_pulseAnimationController` (repeating reverse animation for 3 seconds, then stopped).
    - Find the slot in `_slots` where `courtNumber == widget.targetCourtNumber` and `startTime == widget.targetStartTime`.
    - Dispatch `ToggleSlotEvent(matchingSlot)` to `BookingBloc` if not already selected.
    - Add post-frame callback with slight delay (350ms) to allow layout completion:
      ```dart
      final key = _courtKeys[widget.targetCourtNumber!];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      }
      ```
- In `_buildCourtCard(int courtNumber, Set<String> selectedIds)`:
  - Assign key: `key: _courtKeys.putIfAbsent(courtNumber, () => GlobalKey())`.
  - If `courtNumber == _highlightedCourtNumber`:
    - Wrap or animate decoration border and box shadow with pulsing primary color.
    - Display a badge:
      ```dart
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('🎯 Sân AI gợi ý', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      )
      ```

---

## 4. Edge Cases & Error Handling
1. **Target Court Not in Current Sport Filter**:
   - If the venue is multi-sport (e.g. Tao Đàn with badminton and pickleball), ensure `_selectedSportFilter` is set to the sport specified in `actionCard` (or `'all'`) so the court card is rendered and not filtered out.
2. **Missing or Non-numeric Court Number**:
   - Fallback safely to court 1 if regex match fails.
3. **Target Slot Already Booked**:
   - If the slot is marked inactive or already reserved, highlight the court card without forcing an invalid slot selection into `BookingBloc`.
4. **Animation Lifecycle**:
   - Properly dispose `_pulseAnimationController` in `dispose()` to prevent memory leaks.

---

## 5. Testing & Verification Plan
1. **Unit & Widget Tests**:
   - Test that clicking "🔍 Xem trên sơ đồ" triggers `onViewCourtMap` with the `actionCard` map.
   - Test that `_handleViewCourtMap` parses the court number and triggers navigation.
   - Verify that passing `targetCourtNumber` sets `_viewMode = 'court_map'`, renders the `🎯 Sân AI gợi ý` badge, and selects the matching slot.
2. **End-to-End Regression Verification**:
   - Run `flutter test` to ensure all existing tests pass.
   - Hot reload Flutter web application on Chrome.
