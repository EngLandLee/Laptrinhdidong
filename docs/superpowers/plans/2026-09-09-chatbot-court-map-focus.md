# Chatbot Court Map Navigation & Visual Focus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable the "🔍 Xem trên sơ đồ" button in the AI Chatbot's recommended booking card to navigate to the venue's detail screen, automatically switch to the court diagram view (`court_map`), smoothly scroll to the recommended court, highlight it with a pulsing visual badge ("🎯 Sân AI gợi ý"), and pre-select the recommended slot in `BookingBloc`.

**Architecture:** 
1. Pass `actionCard` data through `ChatBookingCard` and `ChatMessageBubble` to `ChatbotBottomSheet`.
2. Extract court number, venue ID/name, sport, and time slot in `ChatbotBottomSheet`, resolve the venue, and navigate to `VenueDetailScreen` with target parameters.
3. Enhance `VenueDetailScreen` to accept target court/slot parameters, switch `_viewMode = 'court_map'`, auto-scroll via `GlobalKey` & `Scrollable.ensureVisible`, pre-select the slot in `BookingBloc`, and render a pulsing highlight border and badge.

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_bloc, Flutter Test framework.

## Global Constraints
- All existing 262 Flutter tests and 74 Admin Web Vitest tests must continue passing.
- Animations must be safely disposed in `dispose()` to prevent memory leaks.
- Null-safety must be strictly followed; fallback safely if court number or slot is not found.
- Vietnamese copy: "🎯 Sân AI gợi ý".

---

### Task 1: Update ChatBookingCard and ChatMessageBubble to Propagate ActionCard

**Files:**
- Modify: `lib/presentation/widgets/chat/chat_booking_card.dart`
- Modify: `lib/presentation/widgets/chat/chat_message_bubble.dart`
- Test: `test/presentation/widgets/chat/chat_booking_card_test.dart`

**Interfaces:**
- `ChatBookingCard`:
  - Modify: `final void Function(Map<String, dynamic> actionCard)? onViewCourtMap;`
  - Button `btn_chat_view_court_map` calls: `onViewCourtMap?.call(actionCard)`
- `ChatMessageBubble`:
  - Modify: `final void Function(Map<String, dynamic> actionCard)? onViewCourtMap;`

- [ ] **Step 1: Write failing test in `test/presentation/widgets/chat/chat_booking_card_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/presentation/widgets/chat/chat_booking_card.dart';

void main() {
  testWidgets('ChatBookingCard passes actionCard when Xem trên sơ đồ is tapped',
      (tester) async {
    final actionCardData = {
      'venueId': 'venue_01',
      'venueName': 'CLB Cầu Lông Tao Đàn',
      'sport': 'Cầu lông',
      'court': 'Sân 2',
      'startTime': '19:00',
      'endTime': '20:00',
      'price': 120000,
    };

    Map<String, dynamic>? receivedCard;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBookingCard(
            actionCard: actionCardData,
            onViewCourtMap: (card) {
              receivedCard = card;
            },
          ),
        ),
      ),
    );

    final viewMapButton = find.byKey(const Key('btn_chat_view_court_map'));
    expect(viewMapButton, findsOneWidget);

    await tester.tap(viewMapButton);
    await tester.pump();

    expect(receivedCard, isNotNull);
    expect(receivedCard!['court'], equals('Sân 2'));
    expect(receivedCard!['venueId'], equals('venue_01'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/chat/chat_booking_card_test.dart`
Expected: FAIL (type mismatch: `VoidCallback` vs `void Function(Map<String, dynamic>)`).

- [ ] **Step 3: Update `ChatBookingCard` and `ChatMessageBubble`**

In `lib/presentation/widgets/chat/chat_booking_card.dart`:
```dart
class ChatBookingCard extends StatelessWidget {
  final Map<String, dynamic> actionCard;
  final VoidCallback? onBookNow;
  final void Function(Map<String, dynamic> actionCard)? onViewCourtMap;

  const ChatBookingCard({
    super.key,
    required this.actionCard,
    this.onBookNow,
    this.onViewCourtMap,
  });
```
And inside `ElevatedButton`/`OutlinedButton`:
```dart
  OutlinedButton(
    key: const Key('btn_chat_view_court_map'),
    onPressed: onViewCourtMap != null ? () => onViewCourtMap!(actionCard) : null,
...
```

In `lib/presentation/widgets/chat/chat_message_bubble.dart`:
```dart
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onBookNow;
  final void Function(Map<String, dynamic> actionCard)? onViewCourtMap;
```
Pass `onViewCourtMap: onViewCourtMap` to `ChatBookingCard`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/chat/chat_booking_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/widgets/chat/chat_booking_card.dart lib/presentation/widgets/chat/chat_message_bubble.dart test/presentation/widgets/chat/chat_booking_card_test.dart
git commit -m "feat(chat): propagate actionCard on court map view tap"
```

---

### Task 2: Implement Navigation and Parameter Parsing in ChatbotBottomSheet

**Files:**
- Modify: `lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`
- Test: `test/presentation/widgets/chat/chatbot_bottom_sheet_test.dart`

**Interfaces:**
- `ChatbotBottomSheet`:
  - Modify: `final Function(Map<String, dynamic> actionCard)? onViewCourtMapAction;`
  - Modify: `_handleViewCourtMap(Map<String, dynamic> actionCard)`
    - Parse `courtNumber` (e.g. `'Sân 1'` -> `1`).
    - Parse `venueId`, `venueName`, `startTime`, `endTime`, `sport`.
    - If `widget.onViewCourtMapAction != null`: call it.
    - Else: find `venue` from `SeedData.sampleVenues`, pop bottom sheet, and push `VenueDetailScreen`.

- [ ] **Step 1: Write test in `test/presentation/widgets/chat/chatbot_bottom_sheet_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/chatbot_service.dart';
import 'package:mobile/domain/entities/chat_message.dart';
import 'package:mobile/presentation/widgets/chat/chatbot_bottom_sheet.dart';

void main() {
  testWidgets('ChatbotBottomSheet triggers onViewCourtMapAction with actionCard',
      (tester) async {
    Map<String, dynamic>? handledCard;

    ChatbotService.instance.resetMessages();
    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_1',
        text: 'Tìm thấy sân phù hợp',
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: {
          'venueId': 'venue_01',
          'venueName': 'CLB Cầu Lông Tao Đàn',
          'sport': 'Cầu lông',
          'court': 'Sân 3',
          'startTime': '19:00',
          'endTime': '20:00',
          'price': 120000,
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatbotBottomSheet(
            currentRoute: '/home',
            onViewCourtMapAction: (card) {
              handledCard = card;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewMapButton = find.byKey(const Key('btn_chat_view_court_map'));
    expect(viewMapButton, findsOneWidget);

    await tester.tap(viewMapButton);
    await tester.pumpAndSettle();

    expect(handledCard, isNotNull);
    expect(handledCard!['court'], equals('Sân 3'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/chat/chatbot_bottom_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 3: Update `ChatbotBottomSheet` implementation**

In `lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`:
Update `onViewCourtMapAction`:
```dart
final Function(Map<String, dynamic> actionCard)? onViewCourtMapAction;
```
Update `_handleViewCourtMap`:
```dart
  void _handleViewCourtMap(Map<String, dynamic> actionCard) {
    if (widget.onViewCourtMapAction != null) {
      widget.onViewCourtMapAction!(actionCard);
      return;
    }

    final courtStr = actionCard['court']?.toString() ?? 'Sân 1';
    final courtNumber = int.tryParse(RegExp(r'\d+').firstMatch(courtStr)?.group(0) ?? '1') ?? 1;
    final venueId = actionCard['venueId']?.toString() ?? 'venue_01';
    final venueName = actionCard['venueName']?.toString() ?? 'CLB Cầu Lông Tao Đàn';
    final startTime = actionCard['startTime']?.toString() ?? actionCard['time']?.toString() ?? '19:00';
    final endTime = actionCard['endTime']?.toString() ?? '20:00';
    final rawSport = actionCard['sport']?.toString() ?? 'badminton';
    final sport = rawSport.toLowerCase().contains('pickleball')
        ? 'pickleball'
        : (rawSport.toLowerCase().contains('football') || rawSport.toLowerCase().contains('bóng đá')
            ? 'football'
            : 'badminton');

    Navigator.of(context).pop();

    final targetVenue = SeedData.sampleVenues.firstWhere(
      (v) => v.id == venueId || v.name.toLowerCase().contains(venueName.toLowerCase()),
      orElse: () => widget.currentVenue ?? SeedData.sampleVenues.first,
    );

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
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/chat/chatbot_bottom_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/widgets/chat/chatbot_bottom_sheet.dart test/presentation/widgets/chat/chatbot_bottom_sheet_test.dart
git commit -m "feat(chat): implement court map navigation with parsed target parameters"
```

---

### Task 3: Enhance VenueDetailScreen with Highlighting, Auto-Scroll, and Slot Selection

**Files:**
- Modify: `lib/main.dart` (`VenueDetailScreen` & `_VenueDetailScreenState`)
- Test: `test/presentation/screens/venue_detail_highlight_test.dart`

**Interfaces:**
- `VenueDetailScreen`:
  - `final int? targetCourtNumber;`
  - `final String? targetStartTime;`
  - `final String? targetEndTime;`
  - `final String? targetSport;`
  - `final String? initialViewMode;`
- `_VenueDetailScreenState`:
  - `int? _highlightedCourtNumber;`
  - `AnimationController? _pulseController;`
  - `final Map<int, GlobalKey> _courtKeys = {};`
  - Auto-scroll to `_courtKeys[targetCourtNumber]` after build.
  - Auto-select target slot via `BookingBloc.add(ToggleSlotEvent(matchingSlot))`.
  - Render pulsing border and `🎯 Sân AI gợi ý` badge on matching court card.

- [ ] **Step 1: Write test in `test/presentation/screens/venue_detail_highlight_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/seed_data.dart';
import 'package:mobile/main.dart';
import 'package:mobile/presentation/blocs/booking/booking_bloc.dart';

void main() {
  testWidgets('VenueDetailScreen highlights court card and renders AI badge',
      (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>(create: (_) => BookingBloc()),
        ],
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: venue,
            targetCourtNumber: 1,
            targetStartTime: '19:00',
            targetEndTime: '20:00',
            initialViewMode: 'court_map',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify view mode is court_map
    expect(find.text('🎯 Sân AI gợi ý'), findsOneWidget);
    expect(find.byKey(const Key('court_card_1')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/venue_detail_highlight_test.dart`
Expected: FAIL (targetCourtNumber / initialViewMode parameters not found on `VenueDetailScreen`).

- [ ] **Step 3: Update `VenueDetailScreen` and `_VenueDetailScreenState` in `lib/main.dart`**

1. Add constructor arguments to `VenueDetailScreen`:
```dart
class VenueDetailScreen extends StatefulWidget {
  final Venue venue;
  final DateTime? initialDate;
  final int? targetCourtNumber;
  final String? targetStartTime;
  final String? targetEndTime;
  final String? targetSport;
  final String? initialViewMode;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    this.initialDate,
    this.targetCourtNumber,
    this.targetStartTime,
    this.targetEndTime,
    this.targetSport,
    this.initialViewMode,
  });
```

2. Add animation and keys to `_VenueDetailScreenState` with `SingleTickerProviderStateMixin`:
```dart
class _VenueDetailScreenState extends State<VenueDetailScreen>
    with SingleTickerProviderStateMixin {
  ...
  int? _highlightedCourtNumber;
  AnimationController? _pulseController;
  final Map<int, GlobalKey> _courtKeys = {};
```

3. In `initState()`:
```dart
    if (widget.initialViewMode != null) {
      _viewMode = widget.initialViewMode!;
    }
    if (widget.targetSport != null && widget.targetSport!.isNotEmpty) {
      _selectedSportFilter = widget.targetSport!;
    }
    if (widget.targetCourtNumber != null) {
      _highlightedCourtNumber = widget.targetCourtNumber;
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _pulseController?.stop();
          setState(() {
            _highlightedCourtNumber = null;
          });
        }
      });

      // Auto-select matching slot
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final matching = _slots.where((s) =>
            s.courtNumber == widget.targetCourtNumber &&
            (widget.targetStartTime == null || s.startTime == widget.targetStartTime)).toList();
        if (matching.isNotEmpty) {
          context.read<BookingBloc>().add(ToggleSlotEvent(matching.first));
        }

        // Auto-scroll
        Future.delayed(const Duration(milliseconds: 300), () {
          final targetKey = _courtKeys[widget.targetCourtNumber!];
          if (targetKey?.currentContext != null) {
            Scrollable.ensureVisible(
              targetKey!.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.2,
            );
          }
        });
      });
    }
```

4. In `dispose()`:
```dart
    _pulseController?.dispose();
```

5. In `_buildCourtCard(int courtNumber, Set<String> selectedIds)`:
Add key:
```dart
    final courtKey = _courtKeys.putIfAbsent(courtNumber, () => GlobalKey());
    final isHighlighted = _highlightedCourtNumber == courtNumber;
```
If highlighted, wrap container with animated pulsing glow border and render badge `🎯 Sân AI gợi ý`:
```dart
    Container(
      key: Key('court_card_$courtNumber'),
      ...
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/venue_detail_highlight_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/main.dart test/presentation/screens/venue_detail_highlight_test.dart
git commit -m "feat(venue): implement court card highlight, auto-scroll, and slot selection"
```

---

### Task 4: Full Suite Regression & Chrome Live Verification

**Files:**
- Test: all unit and widget tests
- Chrome Web app verification

- [ ] **Step 1: Run full Flutter test suite**

Run: `flutter test`
Expected: All tests pass (265+ tests).

- [ ] **Step 2: Trigger Hot Reload on Chrome session**

Send hot reload `r` to the running Flutter task terminal.

- [ ] **Step 3: Verification with curl and git status**

Ensure branch is clean and dev servers are responsive.
