# Design Spec: Community Post Image Attachment & Social Sports Feed Card

**Date:** 2026-09-06  
**Status:** Approved by user  
**Topic:** Allow users to attach photos when recruiting players in Community Hub, displaying prominent Facebook-style community post cards with authentic court/group photos.

---

## 1. Problem Statement & Motivation
Users recruiting players for sporting matches on SportHub want to post authentic photos (such as photos of friends playing on court, check-in photos, or court conditions) similar to popular Facebook/Zalo sports groups (e.g. "Nhóm cầu lông vãng lai Tp Thủ Đức - Q9").
Currently, `CommunityPost` only supports plain text details (title, venue, time, slots, fee, note) without any image attachment capability. Adding image attachments makes recruitment posts much more engaging, trustworthy, and socially vibrant.

---

## 2. Core Requirements & User Experience

### 2.1. Posting Match with Image (`_showCreatePostDialog` & `_openRecruitDialogForTicket`)
- In both the standalone "+ Đăng kèo" dialog and the 1-tap recruitment from booked tickets:
  1. **Image Attachment Section**: Users see a dedicated "Ảnh đính kèm / Ảnh check-in sân" section.
  2. **1-Tap Realistic Preset Selector**:
     - Users can choose from curated realistic group & court photos matching the selected sport (badminton friends laughing on court, pickleball doubles rally, soccer turf match).
     - Responsive horizontal thumbnail carousel with active indicator (neon border & checkmark).
  3. **Custom Photo URL / Upload Option**:
     - Quick input field or modal to enter custom image URL or paste an image link.
  4. **Live Image Preview & Removal**:
     - Shows the currently selected image preview with a `[✕ Gỡ ảnh]` button to remove or swap.
  5. **Auto-Preset on Ticket Recruitment**:
     - When opening recruitment from a booked ticket, the system automatically uses the booked venue's primary image as default, but allows changing or removing it.

### 2.2. Social Sports Feed Card (`_buildCommunityPostCard`)
- Post cards in the Community feed reflect an authentic social feed post (Facebook/Instagram sports group style):
  1. **Header**: Author avatar + Author name + Post time/district + Sport badge (`🏸 Cầu lông`, `🏓 Pickleball`, `⚽ Bóng đá`).
  2. **Caption / Title**: Prominent bold recruitment title and friendly host caption.
  3. **Hero Photo (Prominent Display)**:
     - Prominent large image (aspect ratio ~4:3 or 16:9, height ~200-240px, rounded corners 12px, border `AppColors.cardBorder`).
     - Graceful `loadingBuilder` with animated shimmer/placeholder and `errorBuilder` fallback so broken links never crash or leave blank holes.
  4. **Court & Match Details Info Box**:
     - Venue name with icon (`Icons.stadium_rounded`).
     - Scheduled time with icon (`Icons.schedule_rounded`).
  5. **Slot Progress & Share Fee**:
     - Progress bar (`Đã có X/Y người - Còn thiếu Z slot`).
     - Share fee pill (`40.000 đ/người`).
  6. **Social Actions & Controls**:
     - Like / heart button with interactive counter.
     - Host controls (`👑 Kèo của bạn`, `[Duyệt yêu cầu]`, `[Đóng kèo]`) or Participant actions (`[Tham gia ngay]`, `[Gửi yêu cầu]`).

---

## 3. Data Architecture & Components

### 3.1. Entity Changes (`lib/domain/entities/community_post.dart`)
```dart
class CommunityPost {
  final String id;
  final String title;
  final String authorId;
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
  final String? imageUrl; // NEW: optional attached image URL
  final int likesCount;   // NEW: social like counter (defaults to 0 or seed value)
  final bool isLiked;     // NEW: current user liked state
  final bool isJoined;
  final bool requiresApproval;
  final bool isClosed;
  final List<JoinRequest> pendingRequests;

  const CommunityPost({
    required this.id,
    required this.title,
    this.authorId = 'user_demo_01',
    required this.authorName,
    String? authorAvatar,
    String? authorAvatarUrl,
    required this.sportType,
    required this.district,
    required this.skillLevel,
    required this.venueName,
    required this.scheduledTime,
    required this.requiredPlayers,
    required this.currentPlayers,
    required this.shareFee,
    required this.note,
    this.imageUrl,
    this.likesCount = 0,
    this.isLiked = false,
    this.isJoined = false,
    this.requiresApproval = true,
    this.isClosed = false,
    this.pendingRequests = const [],
  });
  
  CommunityPost copyWith({
    // ... all existing fields
    String? imageUrl,
    int? likesCount,
    bool? isLiked,
  });
}
```

### 3.2. Curated Preset Gallery (`lib/core/utils/sport_image_catalog.dart`)
- Helper class `SportImageCatalog` providing high-quality, authentic Unsplash photos for sports groups:
  - `badminton`: Group of badminton players on court, doubles players smiling with racquets, indoor BWF court scene.
  - `pickleball`: Pickleball players at the kitchen line, vibrant pickleball court and paddles, friendly team check-in.
  - `football`: 5-a-side soccer team on artificial turf, evening match under floodlights, mini pitch action.
- Methods:
  - `static List<String> getPresetsForSport(String sport)`: Returns 3-4 realistic photo URLs for the specified sport.
  - `static String getDefaultImageForSport(String sport)`: Returns a sensible default hero photo.

### 3.3. State Management & Actions
- `CommunityFeedStore` in `lib/main.dart`:
  - Method `toggleLike(String postId)`: Toggles like state and increments/decrements like counter reactively.
  - `addPost` preserves `imageUrl`.

---

## 4. Testing Strategy

1. **Domain Unit Tests (`test/domain/entities/community_post_test.dart`)**:
   - Verify `CommunityPost` instantiation with `imageUrl`, `likesCount`, `isLiked`.
   - Verify `copyWith` properly preserves or updates `imageUrl` and like state.
2. **Catalog Tests (`test/core/utils/sport_image_catalog_test.dart`)**:
   - Verify presets are returned for badminton, pickleball, football.
   - Verify default images exist and are non-empty URLs.
3. **Widget Tests (`test/presentation/screens/community_image_attachment_test.dart`)**:
   - Verify post dialog displays image attachment selector and preset carousel.
   - Verify selecting a preset photo sets the preview image.
   - Verify removing the image clears the preview.
   - Verify post card in Community feed renders the hero image when `imageUrl` is present.
   - Verify tapping like button updates like state and count.

---

## 5. Non-Functional Constraints
- Flutter 3.x, Dart 3.x.
- Dark Luxury Sport theme consistent with existing screens.
- Zero network crashes: `Image.network` with `errorBuilder` fallback.
- 100% test suite passing with 0 analyzer issues.
