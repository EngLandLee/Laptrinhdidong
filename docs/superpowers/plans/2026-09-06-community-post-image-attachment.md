# Community Post Image Attachment & Social Sports Feed Card Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to attach photos when recruiting players in Community Hub, choosing from realistic sport-specific presets or custom URLs, and render prominent Facebook-style community post cards with authentic court/group photos.

**Architecture:** Extend `CommunityPost` domain entity with `imageUrl`, `likesCount`, `isLiked`. Provide a `SportImageCatalog` with curated high-resolution sports photos. Create a reusable `CommunityImageAttachmentPicker` component integrated into both post dialogs. Upgrade `_buildCommunityPostCard` in `lib/main.dart` with prominent hero photo rendering and social interaction.

**Tech Stack:** Flutter 3.x, Dart 3.x, `Image.network` with graceful error/loading builders, ValueNotifier reactive state in `CommunityFeedStore`.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + BLoC / ValueNotifier reactive pattern.
- Design Theme: Sporty Dark Luxury (`AppColors.background` #0B0F19, `surface` #161F30, `primary` #10B981, `secondary` #06B6D4, `accent` #F59E0B).
- Backward Compatibility: Keep existing 96 unit, widget, and integration tests passing.

---

### Task 1: Domain Entity Extension & SportImageCatalog

**Files:**
- Create: `lib/core/utils/sport_image_catalog.dart`
- Modify: `lib/domain/entities/community_post.dart`
- Modify: `lib/core/utils/seed_data.dart`
- Create: `test/core/utils/sport_image_catalog_test.dart`
- Modify: `test/domain/entities/community_post_test.dart`

**Interfaces:**
- Consumes: None
- Produces:
  - `SportImageCatalog.getPresetsForSport(String sport) -> List<String>`
  - `SportImageCatalog.getDefaultImageForSport(String sport) -> String`
  - `CommunityPost.imageUrl: String?`
  - `CommunityPost.likesCount: int`
  - `CommunityPost.isLiked: bool`
  - `CommunityPost.copyWith({String? imageUrl, int? likesCount, bool? isLiked, ...})`

- [ ] **Step 1: Write failing tests for SportImageCatalog and CommunityPost extensions**

In `test/core/utils/sport_image_catalog_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/sport_image_catalog.dart';

void main() {
  group('SportImageCatalog', () {
    test('returns preset images for badminton, pickleball, and football', () {
      final badmintonImages = SportImageCatalog.getPresetsForSport('badminton');
      expect(badmintonImages.length, greaterThanOrEqualTo(3));
      expect(badmintonImages.first, startsWith('http'));

      final pickleballImages = SportImageCatalog.getPresetsForSport('pickleball');
      expect(pickleballImages.length, greaterThanOrEqualTo(3));
      expect(pickleballImages.first, startsWith('http'));

      final footballImages = SportImageCatalog.getPresetsForSport('football');
      expect(footballImages.length, greaterThanOrEqualTo(3));
      expect(footballImages.first, startsWith('http'));
    });

    test('returns default fallback image for unknown sport', () {
      final defaultImages = SportImageCatalog.getPresetsForSport('unknown');
      expect(defaultImages.isNotEmpty, isTrue);
      expect(SportImageCatalog.getDefaultImageForSport('pickleball'), startsWith('http'));
    });
  });
}
```

In `test/domain/entities/community_post_test.dart`, append:
```dart
    test('supports imageUrl, likesCount, and isLiked in constructor and copyWith', () {
      final post = CommunityPost(
        id: 'post_img_1',
        title: 'Kèo chiều nay',
        authorName: 'Tuấn',
        sportType: 'badminton',
        district: 'Thủ Đức',
        skillLevel: 'Khá',
        venueName: 'Sân Thủ Đức',
        scheduledTime: '18:00 - 20:00',
        requiredPlayers: 4,
        currentPlayers: 2,
        shareFee: 40000,
        note: 'Giao lưu',
        imageUrl: 'https://images.unsplash.com/photo-court',
        likesCount: 5,
        isLiked: true,
      );

      expect(post.imageUrl, 'https://images.unsplash.com/photo-court');
      expect(post.likesCount, 5);
      expect(post.isLiked, isTrue);

      final updated = post.copyWith(
        imageUrl: 'https://images.unsplash.com/photo-new',
        likesCount: 6,
        isLiked: false,
      );

      expect(updated.imageUrl, 'https://images.unsplash.com/photo-new');
      expect(updated.likesCount, 6);
      expect(updated.isLiked, isFalse);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/utils/sport_image_catalog_test.dart test/domain/entities/community_post_test.dart`
Expected: Compilation failure because `SportImageCatalog` does not exist yet.

- [ ] **Step 3: Implement SportImageCatalog and update CommunityPost**

Create `lib/core/utils/sport_image_catalog.dart`:
```dart
class SportImageCatalog {
  static const List<String> badmintonPresets = [
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', // Court with racquets
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800', // Court floor
    'https://images.unsplash.com/photo-1521537634581-0dced2fed2a8?w=800', // Badminton match
  ];

  static const List<String> pickleballPresets = [
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800', // Court surface
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', // Outdoor court
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', // Net and racquets
  ];

  static const List<String> footballPresets = [
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', // Turf pitch
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800', // Soccer ball on turf
    'https://images.unsplash.com/photo-1518604667004-7472797e1272?w=800', // Match action
  ];

  static List<String> getPresetsForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'badminton':
        return badmintonPresets;
      case 'pickleball':
        return pickleballPresets;
      case 'football':
        return footballPresets;
      default:
        return badmintonPresets;
    }
  }

  static String getDefaultImageForSport(String sport) {
    final presets = getPresetsForSport(sport);
    return presets.first;
  }
}
```

Update `lib/domain/entities/community_post.dart`:
Add fields `imageUrl`, `likesCount`, `isLiked` with default values and update `copyWith`.

Update `SeedData.sampleCommunityPosts` in `lib/core/utils/seed_data.dart`:
Assign high-resolution image URLs and initial like counts to the sample community posts.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/utils/sport_image_catalog_test.dart test/domain/entities/community_post_test.dart`
Expected: PASS (all tests passing)

- [ ] **Step 5: Commit changes**

```bash
git add lib/core/utils/sport_image_catalog.dart lib/domain/entities/community_post.dart lib/core/utils/seed_data.dart test/core/utils/sport_image_catalog_test.dart test/domain/entities/community_post_test.dart
git commit -m "feat: add SportImageCatalog and extend CommunityPost with imageUrl and social likes"
```

---

### Task 2: Reusable Image Attachment Picker & Dialog Integration

**Files:**
- Create: `lib/presentation/widgets/community_image_attachment_picker.dart`
- Modify: `lib/main.dart:3440-3580` (`_showCreatePostDialog`)
- Modify: `lib/main.dart:4770-4840` (`_openRecruitDialogForTicket`)
- Create: `test/presentation/screens/community_image_picker_test.dart`

**Interfaces:**
- Consumes:
  - `SportImageCatalog.getPresetsForSport(String sport)`
- Produces:
  - `CommunityImageAttachmentPicker(sportType: String, initialImageUrl: String?, onImageChanged: ValueChanged<String?>)`

- [ ] **Step 1: Write failing widget test for CommunityImageAttachmentPicker**

Create `test/presentation/screens/community_image_picker_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/community_image_attachment_picker.dart';

void main() {
  testWidgets('CommunityImageAttachmentPicker renders preset options and allows selection and removal', (tester) async {
    String? currentImage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CommunityImageAttachmentPicker(
                sportType: 'badminton',
                selectedImageUrl: currentImage,
                onImageChanged: (url) {
                  setState(() => currentImage = url);
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial state: presets carousel should exist
    expect(find.byKey(const Key('image_preset_carousel')), findsOneWidget);
    expect(find.byKey(const Key('image_preset_0')), findsOneWidget);

    // Tap preset 0
    await tester.tap(find.byKey(const Key('image_preset_0')));
    await tester.pumpAndSettle();

    // Now preview with remove button should appear
    expect(find.byKey(const Key('selected_image_preview')), findsOneWidget);
    expect(find.byKey(const Key('remove_attached_image')), findsOneWidget);

    // Tap remove
    await tester.tap(find.byKey(const Key('remove_attached_image')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('selected_image_preview')), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/community_image_picker_test.dart`
Expected: FAIL (file does not exist).

- [ ] **Step 3: Implement CommunityImageAttachmentPicker and wire into post dialogs**

Create `lib/presentation/widgets/community_image_attachment_picker.dart`:
A widget displaying:
- Label "Ảnh đính kèm / Ảnh check-in sân"
- Active image preview (if selected) with a compact thumbnail and `[✕ Gỡ ảnh]` button.
- Horizontal preset image carousel with `Key('image_preset_$index')`, showing curated photos for the current sport.
- A button `[🔗 Nhập URL ảnh]` showing a dialog to paste an external image URL.

Integrate into `lib/main.dart`:
- In `_showCreatePostDialog`: Add `String? attachedImageUrl;` to state, render `CommunityImageAttachmentPicker` below sport selector, and pass `imageUrl: attachedImageUrl` when constructing `CommunityPost`.
- In `_openRecruitDialogForTicket`: Pre-fill `attachedImageUrl = ticket.venueImage;`, render `CommunityImageAttachmentPicker`, and pass `imageUrl: attachedImageUrl` when creating `CommunityPost`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/community_image_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/widgets/community_image_attachment_picker.dart lib/main.dart test/presentation/screens/community_image_picker_test.dart
git commit -m "feat: implement CommunityImageAttachmentPicker and wire into recruitment dialogs"
```

---

### Task 3: Social Sports Feed Card Hero Photo & Like Interactions

**Files:**
- Modify: `lib/main.dart` (`_buildCommunityPostCard`, `CommunityFeedStore.toggleLike`)
- Create: `test/presentation/screens/community_post_card_image_test.dart`

**Interfaces:**
- Consumes:
  - `CommunityPost.imageUrl`, `CommunityPost.likesCount`, `CommunityPost.isLiked`
- Produces:
  - `CommunityFeedStore.toggleLike(String postId)`
  - Post Card renders hero photo when `post.imageUrl != null`

- [ ] **Step 1: Write failing widget test for hero image and like button on post card**

Create `test/presentation/screens/community_post_card_image_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/community_post.dart';
import 'package:sporthub/main.dart';

void main() {
  testWidgets('renders hero image and handles like tap on post card', (tester) async {
    final testPost = CommunityPost(
      id: 'post_hero_test',
      title: 'LÊN SÂN CHỦ NHẬT HĂNG HÁI',
      authorName: 'Đỗ Nguyễn Thanh Tú',
      sportType: 'badminton',
      district: 'Thủ Đức',
      skillLevel: 'Mọi trình độ',
      venueName: 'CLB Cầu Lông Vãng Lai Thủ Đức',
      scheduledTime: '20:00 - 22:00 Tối CN',
      requiredPlayers: 6,
      currentPlayers: 3,
      shareFee: 45000,
      note: 'Nhậu nhẹt giao lưu vui vẻ',
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      likesCount: 12,
      isLiked: false,
    );

    CommunityFeedStore.instance.reset();
    CommunityFeedStore.instance.addPost(testPost);

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: MatchmakingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify hero image key exists
    expect(find.byKey(const Key('post_hero_image_post_hero_test')), findsOneWidget);

    // Verify like button
    final likeButton = find.byKey(const Key('post_like_button_post_hero_test'));
    expect(likeButton, findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    // Tap like button
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(find.text('13'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/community_post_card_image_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement hero image rendering and toggleLike in lib/main.dart**

1. In `CommunityFeedStore`:
```dart
  void toggleLike(String postId) {
    final list = List<CommunityPost>.from(postsNotifier.value);
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = list[idx];
      final newLiked = !post.isLiked;
      final newCount = newLiked ? post.likesCount + 1 : (post.likesCount - 1).clamp(0, 9999);
      list[idx] = post.copyWith(isLiked: newLiked, likesCount: newCount);
      postsNotifier.value = list;
    }
  }
```

2. In `_buildCommunityPostCard`:
- Render prominent hero photo container when `post.imageUrl != null`:
  - `Key('post_hero_image_${post.id}')`
  - `ClipRRect(borderRadius: BorderRadius.circular(12))`
  - Height ~180px with `BoxFit.cover`
  - Graceful `loadingBuilder` and `errorBuilder`
- Add like button row with heart icon, like counter, and `Key('post_like_button_${post.id}')` calling `CommunityFeedStore.instance.toggleLike(post.id)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/community_post_card_image_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/main.dart test/presentation/screens/community_post_card_image_test.dart
git commit -m "feat: render prominent hero image and social like interaction on community post cards"
```

---

### Task 4: Full Suite Verification, Web Hot Restart & Demo Handoff

**Files:**
- None (verification and execution check)

- [ ] **Step 1: Run static analyzer**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run entire test suite**
Run: `flutter test`
Expected: All tests pass (96 + new tests = 100+ tests).

- [ ] **Step 3: Hot restart web server**
Send hot restart `R\n` to background task `task-673`.

- [ ] **Step 4: Demo handoff**
Present complete feature walkthrough in Vietnamese with link `http://localhost:46477/`.
