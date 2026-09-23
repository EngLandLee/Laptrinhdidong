# Community Recruitment Feed & Smart Matchmaking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a live Community Recruitment Hub (`MatchmakingScreen`) allowing players to browse, filter, join matches, and post recruitment requests, integrated with 1-tap recruitment from booked tickets (`TicketsScreen`).

**Architecture:** Create `CommunityPost` domain entity; provide rich seed data; upgrade `MatchmakingScreen` with dual mode (Live Feed + AI Assistant), sport/district filters, slot progress bar, interactive join/contact actions, and create-post dialog; add 1-tap recruitment on tickets in `TicketsScreen`.

**Tech Stack:** Flutter SDK 3.x, Dart 3.x, BLoC pattern, Sporty Dark Luxury theme tokens.

## Global Constraints
- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + BLoC pattern.
- Design Theme: Sporty Dark Luxury.

---

### Task 1: Create `CommunityPost` Entity & Seed Data

**Files:**
- Create: `lib/domain/entities/community_post.dart`
- Modify: `lib/core/utils/seed_data.dart:270-340`
- Test: `test/domain/entities/community_post_test.dart`

**Interfaces:**
- Produces:
  - `CommunityPost` entity with: `id`, `title`, `authorName`, `authorAvatar`, `sportType`, `district`, `skillLevel`, `venueName`, `scheduledTime`, `requiredPlayers`, `currentPlayers`, `shareFee`, `note`, `isJoined`
  - `SeedData.sampleCommunityPosts` typed list of `CommunityPost`

- [ ] **Step 1: Write failing entity unit test**

```dart
// test/domain/entities/community_post_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/community_post.dart';

void main() {
  test('CommunityPost holds properties and copyWith correctly', () {
    const post = CommunityPost(
      id: 'post_01',
      title: 'Tuyển 2 bạn đánh cầu lông tối nay',
      authorName: 'Quốc Anh',
      authorAvatar: 'QA',
      sportType: 'badminton',
      district: 'Bình Thạnh',
      skillLevel: 'Trung bình',
      venueName: 'CLB Cầu Lông Bình Thạnh Sport',
      scheduledTime: '19:00 - 21:00 Hôm nay',
      requiredPlayers: 4,
      currentPlayers: 2,
      shareFee: 40000,
      note: 'Giao lưu vui vẻ, thiếu 2 chân đánh đôi.',
      isJoined: false,
    );

    expect(post.remainingSlots, 2);
    expect(post.isFull, isFalse);

    final joined = post.copyWith(isJoined: true, currentPlayers: 3);
    expect(joined.isJoined, isTrue);
    expect(joined.currentPlayers, 3);
    expect(joined.remainingSlots, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/entities/community_post_test.dart`
Expected: FAIL because `community_post.dart` does not exist.

- [ ] **Step 3: Implement `CommunityPost` and update `SeedData`**

In `lib/domain/entities/community_post.dart`:
```dart
class CommunityPost {
  final String id;
  final String title;
  final String authorName;
  final String authorAvatar;
  final String sportType;
  final String district;
  final String skillLevel;
  final String venueName;
  final String scheduledTime;
  final int requiredPlayers;
  final int currentPlayers;
  final double shareFee;
  final String note;
  final bool isJoined;

  const CommunityPost({
    required this.id,
    required this.title,
    required this.authorName,
    this.authorAvatar = 'QA',
    required this.sportType,
    required this.district,
    required this.skillLevel,
    required this.venueName,
    required this.scheduledTime,
    required this.requiredPlayers,
    required this.currentPlayers,
    required this.shareFee,
    required this.note,
    this.isJoined = false,
  });

  int get remainingSlots => (requiredPlayers - currentPlayers).clamp(0, requiredPlayers);
  bool get isFull => currentPlayers >= requiredPlayers;

  CommunityPost copyWith({
    String? id,
    String? title,
    String? authorName,
    String? authorAvatar,
    String? sportType,
    String? district,
    String? skillLevel,
    String? venueName,
    String? scheduledTime,
    int? requiredPlayers,
    int? currentPlayers,
    double? shareFee,
    String? note,
    bool? isJoined,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      title: title ?? this.title,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      sportType: sportType ?? this.sportType,
      district: district ?? this.district,
      skillLevel: skillLevel ?? this.skillLevel,
      venueName: venueName ?? this.venueName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      requiredPlayers: requiredPlayers ?? this.requiredPlayers,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      shareFee: shareFee ?? this.shareFee,
      note: note ?? this.note,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
```

Add `SeedData.sampleCommunityPosts` in `lib/core/utils/seed_data.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/entities/community_post_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/community_post.dart lib/core/utils/seed_data.dart test/domain/entities/community_post_test.dart
git commit -m "feat: implement CommunityPost entity and seed data"
```

---

### Task 2: Implement Community Hub with Live Feed, Filters, Join Action, and Create Dialog in `MatchmakingScreen`

**Files:**
- Modify: `lib/main.dart` (`MatchmakingScreen`)
- Test: `test/presentation/screens/community_feed_test.dart`

**Interfaces:**
- Consumes:
  - `CommunityPost` and `SeedData.sampleCommunityPosts`
  - `AppColors`
- Produces:
  - Dual mode selector in `MatchmakingScreen` (`[🔥 Kèo tuyển thành viên]` and `[✨ Gợi ý đối thủ AI]`)
  - Filter chips for sports and district
  - Post cards with slot progress indicator and interactive `[Tham gia ngay]` button
  - Floating Action Button `[+ Đăng kèo tuyển người]` with creation modal

- [ ] **Step 1: Write failing widget test**

```dart
// test/presentation/screens/community_feed_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/main.dart';

void main() {
  testWidgets('Community feed displays posts, switches modes, and joins a match', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Tap Tab 2 (Cộng đồng & Ghép kèo)
    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    await tester.pumpAndSettle();

    // Verifies mode tabs exist
    expect(find.text('🔥 Kèo tuyển thành viên'), findsOneWidget);
    expect(find.text('✨ Gợi ý đối thủ AI'), findsOneWidget);

    // Verifies community post card exists
    expect(find.text('Tìm bạn đánh đôi Pickleball giao lưu vui vẻ'), findsOneWidget);
    expect(find.text('Tham gia ngay'), findsWidgets);

    // Tap join post
    await tester.tap(find.text('Tham gia ngay').first);
    await tester.pumpAndSettle();

    // Shows joined status
    expect(find.text('Đã tham gia ✓'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/community_feed_test.dart`
Expected: FAIL because `MatchmakingScreen` does not have community feed mode yet.

- [ ] **Step 3: Update `MatchmakingScreen` in `lib/main.dart`**

1. Add state:
   - `String _hubMode = 'community';` // 'community' or 'ai'
   - `String _sportFilter = 'all';`
   - `List<CommunityPost> _communityPosts = List.from(SeedData.sampleCommunityPosts);`
2. Render segmented switch:
   - `[🔥 Kèo tuyển thành viên]`
   - `[✨ Gợi ý đối thủ AI]`
3. In `_buildCommunityFeed()`:
   - Sport filter chips: Tất cả, Cầu lông, Pickleball, Bóng đá.
   - List of post cards:
     - Header: Avatar circle, Author name, sport chip, district badge.
     - Title, Venue name, Scheduled time.
     - Capacity progress bar with `Đã có X/Y người - Còn thiếu Z slot`.
     - Fee tag (e.g. `35.000 đ/người`).
     - Button: `[Tham gia ngay]` or `[Đã tham gia ✓]` (updates state on tap and shows dialog with contact info).
4. Add `_showCreatePostDialog(BuildContext context)`:
   - Form fields: Title, sport dropdown, venue, time, required players, fee, note.
   - On submit, adds new `CommunityPost` to `_communityPosts` and shows snackbar.
5. In `_buildAiMatchmaker()`:
   - Keep existing AI banner and recommendations list.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/community_feed_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/presentation/screens/community_feed_test.dart
git commit -m "feat: implement dual-mode Community Hub with live recruitment feed and join action"
```

---

### Task 3: Integrate 1-Tap Recruitment from Booked Tickets in `TicketsScreen`

**Files:**
- Modify: `lib/main.dart` (`TicketsScreen`)
- Test: `test/presentation/screens/community_feed_test.dart`

**Interfaces:**
- Consumes:
  - `TicketsScreen` ticket list
- Produces:
  - `[📢 Tuyển thêm người chơi]` button on ticket cards opening the recruitment dialog pre-filled with ticket info

- [ ] **Step 1: Write failing widget test for ticket recruitment**

In `test/presentation/screens/community_feed_test.dart`, add:
```dart
testWidgets('TicketsScreen displays recruit button and opens prefilled dialog', (tester) async {
  await tester.pumpWidget(const SportHubApp());
  await tester.pumpAndSettle();

  // Navigate to Tab 3 (Vé của tôi)
  await tester.tap(find.byIcon(Icons.confirmation_number_rounded));
  await tester.pumpAndSettle();

  // Verify recruit button exists on ticket
  expect(find.text('📢 Tuyển thêm người chơi'), findsWidgets);

  // Tap recruit button
  await tester.tap(find.text('📢 Tuyển thêm người chơi').first);
  await tester.pumpAndSettle();

  // Dialog opens with prefilled venue
  expect(find.text('Đăng bài tuyển người chơi'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/community_feed_test.dart`
Expected: FAIL because button doesn't exist yet on tickets.

- [ ] **Step 3: Update `TicketsScreen` in `lib/main.dart`**

1. On each ticket card in `TicketsScreen`, add an outline/neon button:
   ```dart
   OutlinedButton.icon(
     key: Key('recruit_from_ticket_${ticket.id}'),
     icon: const Icon(Icons.group_add_rounded, size: 16, color: AppColors.primary),
     label: const Text('📢 Tuyển thêm người chơi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
     onPressed: () => _openRecruitDialogForTicket(ticket),
   )
   ```
2. Implement `_openRecruitDialogForTicket(TicketModel ticket)`:
   - Pre-fills venue name, district, time slot from ticket.
   - On submit, adds post to community state and navigates user to Tab 2 (`Cộng đồng & Ghép kèo`).

- [ ] **Step 4: Run all tests to verify they pass**

Run: `flutter test`
Expected: All 70+ tests pass cleanly.

- [ ] **Step 5: Verify static analysis**

Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart test/presentation/screens/community_feed_test.dart
git commit -m "feat: integrate 1-tap community recruitment from booked tickets in TicketsScreen"
```
