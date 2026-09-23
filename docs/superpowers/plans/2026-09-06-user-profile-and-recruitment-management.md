# User Profile Tab, Recruitment Management & Join Approval Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a dedicated User Profile tab (Tab 4), personal sports credential settings, "Kèo của tôi" recruitment post filtering and management, and a flexible join/approval workflow with host reviewing.

**Architecture:** Domain entities (`JoinRequest`, `UserProfile`, `CommunityPost` extensions) provide clean data modeling. `UserProfileStore` and `CommunityFeedStore` reactive singletons manage shared state across tabs without heavy boilerplate. Clean Architecture presentation widgets (`ProfileScreen`, approval modal bottom sheet, updated `MatchmakingScreen` and `_SportHubShell`) deliver Sporty Dark Luxury UI.

**Tech Stack:** Flutter 3.x, Dart 3.x, Clean Architecture, ValueNotifier reactive stores, Flutter Material 3, Sporty Dark Luxury styling.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + BLoC / ValueNotifier reactive pattern.
- Design Theme: Sporty Dark Luxury (`AppColors.background` #0B0F19, `surface` #161F30, `primary` #10B981, `secondary` #06B6D4, `accent` #F59E0B).
- Backward Compatibility: Keep existing 76 unit, widget, and integration tests passing.

---

### Task 1: Domain Entities (`JoinRequest`, `UserProfile`, `CommunityPost` Extensions) & `UserProfileStore`

**Files:**
- Create: `lib/domain/entities/join_request.dart`
- Create: `lib/domain/entities/user_profile.dart`
- Modify: `lib/domain/entities/community_post.dart`
- Modify: `lib/core/utils/seed_data.dart`
- Modify: `lib/main.dart:2840-2960`
- Test: `test/domain/entities/user_profile_and_recruitment_test.dart`

**Interfaces:**
- Consumes: `SeedData.sampleUserProfile`, `CommunityPost`
- Produces:
  - `JoinRequest`: `id`, `postId`, `userId`, `userName`, `userPhone`, `skillLevel`, `preferredSport`, `createdAt`, `status` ('pending'|'approved'|'rejected')
  - `UserProfile`: `userId`, `fullName`, `phone`, `preferredSport`, `skillLevel`, `district`, `playTimePreference`, `matchesPlayed`, `reputationRating`, `onTimeRate`
  - `UserProfileStore`: singleton holding `ValueNotifier<UserProfile>` with `updateProfile(...)`
  - `CommunityFeedStore`: enhanced with `sendJoinRequest(...)`, `approveJoinRequest(...)`, `rejectJoinRequest(...)`, `closePost(...)`

- [ ] **Step 1: Write the failing unit tests for `JoinRequest`, `UserProfile`, and Store approval methods**

Create `test/domain/entities/user_profile_and_recruitment_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:Mobile/domain/entities/join_request.dart';
import 'package:Mobile/domain/entities/user_profile.dart';
import 'package:Mobile/domain/entities/community_post.dart';
import 'package:Mobile/main.dart';

void main() {
  group('JoinRequest & UserProfile Entities', () {
    test('JoinRequest instantiates correctly and supports copyWith', () {
      final req = JoinRequest(
        id: 'req_01',
        postId: 'post_01',
        userId: 'user_02',
        userName: 'Lê Minh',
        userPhone: '0901234567',
        skillLevel: 'Intermediate',
        preferredSport: 'pickleball',
        createdAt: DateTime.parse('2026-09-06 10:00:00'),
        status: 'pending',
      );

      expect(req.userName, 'Lê Minh');
      expect(req.status, 'pending');

      final approved = req.copyWith(status: 'approved');
      expect(approved.status, 'approved');
      expect(approved.id, 'req_01');
    });

    test('UserProfile instantiates and updates fields via copyWith', () {
      final profile = UserProfile(
        userId: 'user_demo_01',
        fullName: 'Nguyễn Văn An',
        phone: '0909 123 456',
        preferredSport: 'pickleball',
        skillLevel: 'Intermediate',
        district: 'Bình Thạnh',
        playTimePreference: 'Buổi tối (18:00 - 21:00)',
        matchesPlayed: 18,
        reputationRating: 4.9,
        onTimeRate: 98,
      );

      expect(profile.fullName, 'Nguyễn Văn An');
      expect(profile.matchesPlayed, 18);

      final updated = profile.copyWith(fullName: 'Trần Bình', district: 'Quận 1');
      expect(updated.fullName, 'Trần Bình');
      expect(updated.district, 'Quận 1');
      expect(updated.phone, '0909 123 456');
    });
  });

  group('CommunityFeedStore Approval & Request Workflow', () {
    setUp(() {
      CommunityFeedStore.instance.reset();
    });

    test('sendJoinRequest adds pending request to post', () {
      final post = CommunityFeedStore.instance.posts.first;
      final applicant = UserProfile(
        userId: 'user_applicant_99',
        fullName: 'Phạm Hùng',
        phone: '0988776655',
        preferredSport: 'badminton',
        skillLevel: 'Advanced',
        district: 'Quận 7',
        playTimePreference: 'Sáng',
        matchesPlayed: 5,
        reputationRating: 4.8,
        onTimeRate: 100,
      );

      CommunityFeedStore.instance.sendJoinRequest(post.id, applicant);
      final updatedPost = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);

      expect(updatedPost.pendingRequests.length, 1);
      expect(updatedPost.pendingRequests.first.userName, 'Phạm Hùng');
      expect(updatedPost.pendingRequests.first.status, 'pending');
      expect(updatedPost.pendingCount, 1);
    });

    test('approveJoinRequest approves request and increments currentPlayers', () {
      final post = CommunityFeedStore.instance.posts.first;
      final initialPlayers = post.currentPlayers;
      final applicant = UserProfile(
        userId: 'user_applicant_99',
        fullName: 'Phạm Hùng',
        phone: '0988776655',
        preferredSport: 'badminton',
        skillLevel: 'Advanced',
        district: 'Quận 7',
        playTimePreference: 'Sáng',
        matchesPlayed: 5,
        reputationRating: 4.8,
        onTimeRate: 100,
      );

      CommunityFeedStore.instance.sendJoinRequest(post.id, applicant);
      final reqId = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id).pendingRequests.first.id;

      CommunityFeedStore.instance.approveJoinRequest(post.id, reqId);
      final afterApproval = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);

      expect(afterApproval.currentPlayers, initialPlayers + 1);
      expect(afterApproval.pendingRequests.first.status, 'approved');
      expect(afterApproval.pendingCount, 0);
    });

    test('closePost sets isClosed to true', () {
      final post = CommunityFeedStore.instance.posts.first;
      CommunityFeedStore.instance.closePost(post.id);
      final closedPost = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);
      expect(closedPost.isClosed, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/entities/user_profile_and_recruitment_test.dart`
Expected: Compilation failure because `join_request.dart`, `user_profile.dart`, and new methods in `CommunityFeedStore` do not exist yet.

- [ ] **Step 3: Implement `JoinRequest`, `UserProfile`, update `CommunityPost`, and enhance `CommunityFeedStore`**

Create `lib/domain/entities/join_request.dart`:
```dart
class JoinRequest {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userPhone;
  final String skillLevel;
  final String preferredSport;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  const JoinRequest({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.skillLevel,
    required this.preferredSport,
    required this.createdAt,
    this.status = 'pending',
  });

  JoinRequest copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userPhone,
    String? skillLevel,
    String? preferredSport,
    DateTime? createdAt,
    String? status,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredSport: preferredSport ?? this.preferredSport,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
```

Create `lib/domain/entities/user_profile.dart`:
```dart
class UserProfile {
  final String userId;
  final String fullName;
  final String phone;
  final String preferredSport;
  final String skillLevel;
  final String district;
  final String playTimePreference;
  final int matchesPlayed;
  final double reputationRating;
  final int onTimeRate;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.preferredSport,
    required this.skillLevel,
    required this.district,
    required this.playTimePreference,
    this.matchesPlayed = 18,
    this.reputationRating = 4.9,
    this.onTimeRate = 98,
  });

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? preferredSport,
    String? skillLevel,
    String? district,
    String? playTimePreference,
    int? matchesPlayed,
    double? reputationRating,
    int? onTimeRate,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      preferredSport: preferredSport ?? this.preferredSport,
      skillLevel: skillLevel ?? this.skillLevel,
      district: district ?? this.district,
      playTimePreference: playTimePreference ?? this.playTimePreference,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      reputationRating: reputationRating ?? this.reputationRating,
      onTimeRate: onTimeRate ?? this.onTimeRate,
    );
  }
}
```

Update `lib/domain/entities/community_post.dart`:
Add `authorId`, `requiresApproval`, `isClosed`, `pendingRequests`, `pendingCount`, `hasPendingRequest(String userId)`, `hasJoined(String userId)`.

In `lib/main.dart`:
Add `UserProfileStore` singleton:
```dart
class UserProfileStore {
  UserProfileStore._();
  static final UserProfileStore instance = UserProfileStore._();

  final ValueNotifier<UserProfile> profileNotifier = ValueNotifier<UserProfile>(
    const UserProfile(
      userId: 'user_demo_01',
      fullName: 'Nguyễn Văn An',
      phone: '0909 123 456',
      preferredSport: 'pickleball',
      skillLevel: 'Intermediate',
      district: 'Bình Thạnh',
      playTimePreference: 'Buổi tối (18:00 - 21:00)',
      matchesPlayed: 18,
      reputationRating: 4.9,
      onTimeRate: 98,
    ),
  );

  UserProfile get profile => profileNotifier.value;

  void updateProfile({
    String? fullName,
    String? phone,
    String? preferredSport,
    String? skillLevel,
    String? district,
    String? playTimePreference,
  }) {
    profileNotifier.value = profile.copyWith(
      fullName: fullName,
      phone: phone,
      preferredSport: preferredSport,
      skillLevel: skillLevel,
      district: district,
      playTimePreference: playTimePreference,
    );
  }
}
```

Enhance `CommunityFeedStore` in `lib/main.dart`:
Add `sendJoinRequest`, `approveJoinRequest`, `rejectJoinRequest`, `closePost`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/entities/user_profile_and_recruitment_test.dart`
Expected: PASS (All tests passing)

- [ ] **Step 5: Run full test suite and commit**

Run: `flutter test && flutter analyze`
Run: `git add lib/domain/entities/ lib/core/utils/seed_data.dart lib/main.dart test/domain/entities/`
Run: `git commit -m "feat: add JoinRequest and UserProfile entities with reactive store management"`

---

### Task 2: Tab 4 "Hồ sơ" (`ProfileScreen`) & Bottom Navigation / Header Avatar Deep Link

**Files:**
- Modify: `lib/main.dart:130-220` (Bottom nav 4 tabs & `_screens`)
- Modify: `lib/main.dart:455-485` (ExploreVenuesScreen avatar tap)
- Modify: `lib/main.dart` (Implement `ProfileScreen` widget with header, reputation stats, editable sports profile form, and quick links)
- Test: `test/presentation/screens/profile_screen_test.dart`

**Interfaces:**
- Consumes: `UserProfileStore.instance`, `CommunityFeedStore.instance`, `MainNavigationController`
- Produces:
  - 4-tab bottom navigation (`0: Đặt sân`, `1: Cộng đồng`, `2: Vé của tôi`, `3: Hồ sơ`)
  - `ProfileScreen` widget with real-time profile editing and activity summary
  - Header avatar tap routing to Tab 3

- [ ] **Step 1: Write widget tests for `ProfileScreen` and 4-tab navigation**

Create `test/presentation/screens/profile_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Mobile/main.dart';

void main() {
  testWidgets('Bottom navigation includes 4 tabs and switches to ProfileScreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Verify 4 tabs exist
    expect(find.text('Đặt sân'), findsOneWidget);
    expect(find.text('Cộng đồng'), findsOneWidget);
    expect(find.text('Vé của tôi'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Profile screen header and stats
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('⭐ Thành viên VIP'), findsOneWidget);
    expect(find.text('4.9 ⭐'), findsOneWidget);
    expect(find.text('18 Trận'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);
  });

  testWidgets('Tapping header avatar in Explore screen navigates to Profile tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Find avatar container with QA
    final avatarFinder = find.byKey(const Key('header_user_avatar'));
    expect(avatarFinder, findsOneWidget);
    await tester.tap(avatarFinder);
    await tester.pumpAndSettle();

    // Should now be on Profile screen
    expect(find.text('⭐ Thành viên VIP'), findsOneWidget);
    expect(find.text('Thông tin cá nhân & Thể thao'), findsOneWidget);
  });

  testWidgets('Updating user profile form saves and reflects changes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    // Change full name
    final nameField = find.byKey(const Key('profile_input_fullname'));
    await tester.enterText(nameField, 'Nguyễn Quốc Anh');
    
    // Tap Save button
    final saveButton = find.byKey(const Key('profile_save_button'));
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify updated name in header
    expect(find.text('Nguyễn Quốc Anh'), findsOneWidget);
    expect(find.text('Đã cập nhật hồ sơ thành công!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/profile_screen_test.dart`
Expected: FAIL because 4th tab 'Hồ sơ' and `ProfileScreen` do not exist yet.

- [ ] **Step 3: Implement 4-tab navigation, header avatar tap, and `ProfileScreen`**

In `lib/main.dart`:
1. In `_SportHubShellState`:
   - Update `_screens` to include `const ProfileScreen()`.
   - Update bottom navigation bar with `_buildNavItem(3, Icons.person_rounded, 'Hồ sơ')`.
2. In `ExploreVenuesScreen`:
   - Wrap the Avatar container in `GestureDetector(key: const Key('header_user_avatar'), onTap: () => MainNavigationController.switchToTab(3), child: ...)`.
3. Implement `ProfileScreen`:
   - Use `ValueListenableBuilder<UserProfile>` listening to `UserProfileStore.instance.profileNotifier`.
   - Header with avatar gradient and user initials, full name, phone number, and VIP badge.
   - Reputation stats row: 3 styled cards (`4.9 ⭐` Đánh giá uy tín, `18 Trận` Đã chơi, `98%` Đúng hẹn).
   - "Thông tin cá nhân & Thể thao" section:
     - `TextField` for Full Name (`key: const Key('profile_input_fullname')`)
     - `TextField` for Phone (`key: const Key('profile_input_phone')`)
     - Sport selector chip list (`Pickleball`, `Cầu lông`, `Bóng đá`)
     - Skill level dropdown / chips (`Cơ bản`, `Trung bình`, `Nâng cao`)
     - District dropdown (`Bình Thạnh`, `Quận 1`, `Thủ Đức`, `Quận 7`, `Tân Bình`)
     - Preferred time dropdown (`Buổi tối (18:00 - 21:00)`, `Buổi sáng (06:00 - 09:00)`, `Buổi chiều (15:00 - 18:00)`)
     - Save button `[💾 Lưu thông tin]` (`key: const Key('profile_save_button')`) calling `UserProfileStore.instance.updateProfile(...)` and showing SnackBar.
   - "Quản lý hoạt động" section:
     - Card **"Kèo tuyển của tôi"** showing count of posts created by current user and count of pending requests. Tapping switches to Tab 1 (`Cộng đồng`) with filter `my_posts`.
     - Card **"Vé đã đặt"** showing offline pass status. Tapping switches to Tab 2 (`Vé của tôi`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/profile_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite and commit**

Run: `flutter test && flutter analyze`
Run: `git add lib/main.dart test/presentation/screens/profile_screen_test.dart`
Run: `git commit -m "feat: implement ProfileScreen tab, 4-tab navigation, and header avatar deep-link"`

---

### Task 3: Community Feed "Kèo của tôi" Filter, Host Approval Sheet & Join Workflow

**Files:**
- Modify: `lib/main.dart:2900-3400` (`MatchmakingScreen`, recruitment cards, approval modal sheet, join button states)
- Test: `test/presentation/screens/recruitment_approval_test.dart`

**Interfaces:**
- Consumes: `UserProfileStore.instance`, `CommunityFeedStore.instance`, `JoinRequest`, `CommunityPost`
- Produces:
  - Sub-filter `[🔥 Tất cả kèo]` vs `[👑 Kèo của tôi (${count})]`
  - Host card badge `[👑 Kèo của bạn]`
  - Host action `[👥 Duyệt yêu cầu (${post.pendingCount})]` opening `_showApprovalBottomSheet`
  - Host action `[🔒 Đóng kèo]`
  - Applicant action: `[📩 Gửi yêu cầu]` creating `JoinRequest`, changing state to `[⏳ Đang chờ duyệt]`

- [ ] **Step 1: Write widget tests for recruitment approval sheet and join workflow**

Create `test/presentation/screens/recruitment_approval_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Mobile/main.dart';
import 'package:Mobile/domain/entities/community_post.dart';
import 'package:Mobile/domain/entities/join_request.dart';

void main() {
  setUp(() {
    CommunityFeedStore.instance.reset();
  });

  testWidgets('Sub-filter switches between Tất cả kèo and Kèo của tôi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();

    expect(find.text('🔥 Tất cả kèo'), findsOneWidget);
    expect(find.byKey(const Key('filter_my_posts')), findsOneWidget);

    // Filter to Kèo của tôi
    await tester.tap(find.byKey(const Key('filter_my_posts')));
    await tester.pumpAndSettle();

    // Verify only host posts are shown
    expect(find.text('👑 Kèo của bạn'), findsWidgets);
  });

  testWidgets('Host can view pending requests and approve an applicant', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    
    // Seed a post owned by user_demo_01 with a pending join request
    final testPost = CommunityPost(
      id: 'post_host_test_01',
      title: 'Kèo test duyệt thành viên',
      authorId: 'user_demo_01',
      authorName: 'Nguyễn Văn An',
      authorAvatarUrl: '',
      sportType: 'pickleball',
      district: 'Bình Thạnh',
      venueName: 'CLB Pickleball Bình Thạnh',
      scheduledTime: '19:00 - 21:00 Hôm nay',
      requiredPlayers: 4,
      currentPlayers: 2,
      shareFee: '45.000 đ',
      note: 'Duyệt thành viên',
      requiresApproval: true,
      pendingRequests: [
        JoinRequest(
          id: 'req_test_01',
          postId: 'post_host_test_01',
          userId: 'user_other_02',
          userName: 'Trần Hoàng',
          userPhone: '0908889999',
          skillLevel: 'Intermediate',
          preferredSport: 'pickleball',
          createdAt: DateTime.now(),
          status: 'pending',
        ),
      ],
    );
    CommunityFeedStore.instance.addPost(testPost);

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cộng đồng'));
    await tester.pumpAndSettle();

    // Switch to Kèo của tôi
    await tester.tap(find.byKey(const Key('filter_my_posts')));
    await tester.pumpAndSettle();

    // Find review button
    final reviewBtn = find.byKey(const Key('review_requests_post_host_test_01'));
    expect(reviewBtn, findsOneWidget);
    await tester.tap(reviewBtn);
    await tester.pumpAndSettle();

    // Check bottom sheet contents
    expect(find.text('Duyệt người tham gia (1)'), findsOneWidget);
    expect(find.text('Trần Hoàng'), findsOneWidget);
    expect(find.text('0908889999'), findsOneWidget);

    // Tap Approve button
    final approveBtn = find.byKey(const Key('approve_req_test_01'));
    expect(approveBtn, findsOneWidget);
    await tester.tap(approveBtn);
    await tester.pumpAndSettle();

    // Check slot incremented
    expect(find.text('Đã chấp nhận Trần Hoàng vào kèo!'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/recruitment_approval_test.dart`
Expected: FAIL because `filter_my_posts` and host approval buttons do not exist yet.

- [ ] **Step 3: Implement "Kèo của tôi" filtering, Host approval sheet, and Join request workflow**

In `lib/main.dart`:
1. In `_MatchmakingScreenState`:
   - Add `String _postScope = 'all'` ('all' vs 'my_posts').
   - Render scope selector below sport chips:
     - `_buildScopePill('all', '🔥 Tất cả kèo')`
     - `_buildScopePill('my_posts', '👑 Kèo của tôi (${myPostsCount})', key: const Key('filter_my_posts'))`
   - Filter `_communityPosts` based on `_selectedSport` AND (`_postScope == 'all'` or `post.authorId == currentUserId`).
2. On Post Card:
   - If `post.authorId == currentUserId`:
     - Render `👑 Kèo của bạn` badge in cyan.
     - If `post.pendingCount > 0`:
       - Show `[👥 Duyệt yêu cầu (${post.pendingCount})]` button (`key: Key('review_requests_${post.id}')`).
       - Tapping opens `_showApprovalBottomSheet(context, post)`.
     - Show `[🔒 Đóng kèo]` button (`key: Key('close_post_${post.id}')`) if `!post.isClosed`.
   - If `post.authorId != currentUserId`:
     - If `post.isClosed`: Show disabled `[🔒 Đã chốt kèo]`.
     - If `post.hasPendingRequest(currentUserId)`: Show disabled `[⏳ Đang chờ duyệt]`.
     - If `post.hasJoined(currentUserId)`: Show `[✓ Đã tham gia]` with hotline modal option.
     - Else:
       - If `post.requiresApproval`: Button says `[📩 Gửi yêu cầu]` (`key: Key('request_join_${post.id}')`).
         - On tap: calls `CommunityFeedStore.instance.sendJoinRequest(post.id, UserProfileStore.instance.profile)`.
         - Shows SnackBar: *"Đã gửi yêu cầu tham gia đến chủ kèo!"*.
       - Else: Button says `[Tham gia ngay]`.
3. Implement `_showApprovalBottomSheet(BuildContext context, CommunityPost post)`:
   - Header: "Duyệt người tham gia (${post.pendingRequests.where((r) => r.status == 'pending').length})".
   - Applicant list:
     - Name, Phone, Sport skill level badge.
     - Action buttons:
       - `[✅ Đồng ý]` (`key: Key('approve_${req.id}')`) calling `approveJoinRequest`.
       - `[❌ Từ chối]` (`key: Key('reject_${req.id}')`) calling `rejectJoinRequest`.
4. In `_showCreatePostDialog` & `_openRecruitDialogForTicket`:
   - Add Switch: `🔘 Cần duyệt người tham gia` (default `true`), setting `requiresApproval: true` on created `CommunityPost`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/recruitment_approval_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: 0 analyzer warnings, 100% test suites pass.

- [ ] **Step 6: Commit**

Run: `git add lib/main.dart test/presentation/screens/recruitment_approval_test.dart`
Run: `git commit -m "feat: implement 'Kèo của tôi' filter, host approval bottom sheet, and join request workflow"`

---

### Task 4: Verification, Hot Restart & Demo Handoff

**Files:**
- Entire project verification

- [ ] **Step 1: Run full test suite**
Run: `flutter test`
Verify all tests pass cleanly.

- [ ] **Step 2: Run static analysis**
Run: `flutter analyze`
Confirm 0 issues found.

- [ ] **Step 3: Hot restart local running web server**
Send `R` to running background task `task-673`.

- [ ] **Step 4: Present final work to user with live test instructions**
Present completed features in Vietnamese and provide link `http://localhost:46477/`.
