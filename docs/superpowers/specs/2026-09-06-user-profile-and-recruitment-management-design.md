# Design Specification: User Profile Tab, Recruitment Management & Join Approval Workflow

**Date:** 2026-09-06  
**Author:** Google Antigravity & User  
**Status:** Validated Draft  
**Scope:** Mobile App (`lib/main.dart`, `lib/domain/entities/`, `lib/core/utils/seed_data.dart`)

---

## 1. Overview & Goals

SportHub Mobile currently provides venue booking, offline pass tickets, and a community recruitment feed. To complete the social sports experience and give players full ownership of their activities, this feature introduces:
1. **User Profile Tab (Tab 4):** A dedicated screen for viewing and updating personal sports credentials (Full Name, Phone, Favorite Sport, Skill Level, District, Preferred Play Time), along with player reputation stats and quick activity management.
2. **"Kèo của tôi" (My Recruitment Posts Management):** Clear separation and management tools for posts published by the current user in the Community Feed.
3. **Flexible Join & Host Approval Workflow:** A multi-step recruitment approval system where hosts can choose between manual approval (reviewing applicants' skill levels and contact info) or instant join.

---

## 2. Architecture & Data Model

### 2.1. Domain Entities

#### `JoinRequest` (`lib/domain/entities/join_request.dart`)
Represents an applicant's request to join a community recruitment post:
- `id`: String (UUID or timestamp)
- `postId`: String (target post ID)
- `userId`: String (applicant ID)
- `userName`: String (applicant full name)
- `userPhone`: String (applicant phone number)
- `skillLevel`: String ('Beginner', 'Intermediate', 'Advanced')
- `preferredSport`: String ('pickleball', 'badminton', 'football')
- `createdAt`: DateTime
- `status`: String ('pending', 'approved', 'rejected')

#### `CommunityPost` Extensions (`lib/domain/entities/community_post.dart`)
Enhance the existing entity:
- `authorId`: String (defaults to `'user_demo_01'` for user-created posts, `'user_host_xx'` for seeds)
- `requiresApproval`: bool (default `true` for newly created posts)
- `isClosed`: bool (default `false`)
- `pendingRequests`: List<JoinRequest> (default `const []`)
- Helper getters:
  - `isHost(String currentUserId)`: `authorId == currentUserId`
  - `pendingCount`: `pendingRequests.where((r) => r.status == 'pending').length`
  - `hasJoined(String currentUserId)`: whether the user is in approved requests or author
  - `hasPendingRequest(String currentUserId)`: whether user has a pending join request

#### `UserProfile` (`lib/domain/entities/user_profile.dart`)
Represents the current user's profile and sports preferences:
- `userId`: String
- `fullName`: String
- `phone`: String
- `preferredSport`: String ('pickleball', 'badminton', 'football')
- `skillLevel`: String ('Beginner', 'Intermediate', 'Advanced')
- `district`: String ('Bình Thạnh', 'Quận 1', 'Thủ Đức', 'Quận 7', 'Tân Bình')
- `playTimePreference`: String
- `matchesPlayed`: int
- `reputationRating`: double
- `onTimeRate`: int (percentage, e.g. 98)

### 2.2. Reactive State Management

#### `UserProfileStore` Singleton
- Holds `ValueNotifier<UserProfile>` initialized with `SeedData.sampleUserProfile`.
- Method `updateProfile({String? fullName, String? phone, String? preferredSport, String? skillLevel, String? district, String? playTimePreference})`.

#### `CommunityFeedStore` Enhancements
- Method `sendJoinRequest(String postId, UserProfile applicant)`:
  - Adds a new `JoinRequest` with `status: 'pending'` to the post's `pendingRequests`.
- Method `approveJoinRequest(String postId, String requestId)`:
  - Updates the request status to `'approved'`.
  - Increments `currentPlayers` by 1.
  - If `currentPlayers >= maxPlayers`, marks `isClosed: true`.
- Method `rejectJoinRequest(String postId, String requestId)`:
  - Updates request status to `'rejected'`.
- Method `closePost(String postId)`:
  - Sets `isClosed: true`.

---

## 3. User Interface & Interactions

### 3.1. Bottom Navigation Bar Update
The bottom navigation bar expands from 3 to 4 balanced items:
- Tab 0: **Đặt sân** (`Icons.sports_tennis_rounded`)
- Tab 1: **Cộng đồng** (`Icons.groups_rounded`)
- Tab 2: **Vé của tôi** (`Icons.confirmation_number_rounded`)
- Tab 3: **Hồ sơ** (`Icons.person_rounded`)

*Header Quick Link:* Tapping the top-left Avatar (`QA`) in the Explore/Booking screen triggers `MainNavigationController.switchToTab(3)` directly to the Profile tab.

### 3.2. Tab 3: "Hồ sơ cá nhân" (`ProfileScreen`)
Styled with Sporty Dark Luxury aesthetics:
1. **User Header Card:**
   - Circular gradient avatar with user initials.
   - Full Name, Phone number, and `⭐ Thành viên VIP` badge.
2. **Player Reputation Statistics Row:**
   - 3 stat cards:
     - `4.9 ⭐`: Đánh giá uy tín
     - `18`: Trận đã chơi
     - `98%`: Đúng giờ / Nghiêm túc
3. **Sports Preferences & Edit Form:**
   - Editable fields with instant update:
     - Họ và tên (`TextField`)
     - Số điện thoại (`TextField`)
     - Môn thể thao sở trường (`Dropdown` or chip selector: Cầu lông, Pickleball, Bóng đá)
     - Trình độ (`Dropdown`: Cơ bản, Trung bình, Nâng cao)
     - Khu vực ưu tiên (`Dropdown`: Bình Thạnh, Quận 1, Thủ Đức, Quận 7, Tân Bình)
     - Khung giờ ưa thích (`Dropdown`: Sáng, Chiều, Tối)
   - Action: `[💾 Lưu thông tin]` updating `UserProfileStore` with SnackBar confirmation.
4. **Activity Management Section:**
   - **"Kèo tuyển của tôi" card:** Displays number of active posts and badge for pending requests (`X yêu cầu chờ duyệt`). Tapping navigates to Tab 1 filtered to "Kèo của tôi".
   - **"Vé đã đặt" card:** Quick shortcut to Tab 2.

### 3.3. Tab 1: Community Feed - "Kèo của tôi" & Host Tools
1. **Sub-filter Pill:**
   - Below the sport filter chips: `[🔥 Tất cả kèo]` vs `[👑 Kèo của tôi (${myPostsCount})]`.
2. **User Post Identification:**
   - Posts where `post.authorId == currentUserId` render a distinct `👑 Kèo của bạn` neon cyan badge.
3. **Host Actions on Own Posts:**
   - If post has pending requests:
     - **`[👥 Duyệt yêu cầu (${post.pendingCount})]`** button (Neon Amber).
     - Tapping opens `_showApprovalBottomSheet(context, post)`:
       - Lists all pending applicants with their name, phone, skill level, and requested time.
       - Each applicant card has:
         - `[✅ Đồng ý]`: Approves applicant, increments current slot, notifies via SnackBar.
         - `[❌ Từ chối]`: Rejects applicant cleanly.
   - **`[🔒 Đóng kèo]`** button: Closes recruitment when host already found players offline.
4. **Recruitment Creation Modal Update:**
   - Added Switch: `🔘 Cần duyệt người tham gia` (default: On).

### 3.4. Join Workflow for Non-Host Players
1. On other hosts' recruitment cards:
   - If `post.isClosed` or `post.isFull`: Button shows `[Đã đủ người]` (disabled).
   - If user already requested and is pending: Button shows `[⏳ Đang chờ duyệt]` (disabled amber).
   - If user is approved: Button shows `[✓ Đã tham gia]` (green) with hotline modal option.
   - If user hasn't joined:
     - If `requiresApproval`: Button says `[📩 Yêu cầu tham gia]`.
       - Tapping prompts confirmation and sends `JoinRequest` populated with the current user's profile info.
       - Shows SnackBar: *"Đã gửi yêu cầu tham gia đến chủ kèo!"*.
     - If `!requiresApproval`: Button says `[Tham gia ngay]`.
       - Instant join and opens host hotline modal.

---

## 4. Test & Verification Plan

1. **Entity & Store Unit Tests:**
   - `JoinRequest` serialization and equality.
   - `UserProfile` updates in `UserProfileStore`.
   - `CommunityFeedStore` approval lifecycle: `sendJoinRequest`, `approveJoinRequest` (increments count, closes if full), `rejectJoinRequest`, and `closePost`.
2. **Widget & Screen Tests:**
   - Bottom navigation switches between all 4 tabs cleanly.
   - Tapping avatar in header navigates to Profile tab.
   - `ProfileScreen` renders user info, stats, and updates profile on form submit.
   - `MatchmakingScreen` filters to "Kèo của tôi" and shows `👑 Kèo của bạn` badge.
   - Host opens approval bottom sheet and approves an applicant, verifying slot increments.
3. **Integration Verification:**
   - `flutter analyze`: 0 errors/warnings.
   - `flutter test`: all test suites pass.
   - Live testing on internal web server `http://localhost:46477/`.
