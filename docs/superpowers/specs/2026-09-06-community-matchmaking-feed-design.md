# Community Recruitment Feed & Smart Matchmaking Design Specification

## Overview
This document specifies the design and implementation of the Community Recruitment Feed & Smart Matchmaking Hub in SportHub Mobile (`MatchmakingScreen`), along with the 1-tap recruitment integration from booked tickets (`TicketsScreen`).

## Context & Problem Statement
Users frequently book courts (e.g. 4-player badminton doubles or 10-player football matches) but lack enough teammates or friends to fill the match, incurring higher per-person costs or having to cancel. Conversely, solo players seek friendly, accessible matches to join without the hassle of securing peak-hour court reservations.

## Key Requirements & User Experience

### 1. Dual-Mode Community & Matchmaking Hub (`MatchmakingScreen`)
- Located on Tab 2 of the bottom navigation bar (renamed to "Cộng đồng & Ghép kèo").
- Top segmented mode switch:
  - **`[🔥 Kèo tuyển thành viên]`** (Live Community Posts Feed)
  - **`[✨ Gợi ý đối thủ AI]`** (AI Compatibility Matchmaker with Gemini)

### 2. Live Community Posts Feed (`[🔥 Kèo tuyển thành viên]`)
- **Filters**: Sport Category pills (Tất cả, Cầu lông, Pickleball, Bóng đá) & District filter chips.
- **Post Card Structure**:
  - Author header: Avatar, author name, timestamp, sport badge.
  - Match details: Venue name, district, scheduled date & time.
  - Skill level indicator: `Giao lưu vui vẻ` (Beginner), `Trung bình` (Intermediate), `Khá cứng` (Advanced).
  - Slot capacity progress bar: e.g. `Đã có 2/4 người` + badge `🔥 Còn thiếu 2 slot`.
  - Share fee: e.g. `35.000 đ/người` (or `Miễn phí`).
  - Note/message from host.
  - Action button: `[Tham gia ngay]` with key `join_post_<id>`.
    - When tapped, increments player count (e.g. 2/4 -> 3/4).
    - Status changes to `Đã tham gia ✓` with amber/emerald styling.
    - Shows bottom notification / dialog with host's contact info (Zalo / Hotline: `0909 123 456`).

### 3. Create Community Post Dialog (`[+ Đăng kèo tuyển người]`)
- Floating Action Button or top banner button: `[+ Đăng kèo tuyển người]`.
- Opens a Dark Luxury dialog / bottom sheet:
  - Input: Title / note.
  - Sport selection (Cầu lông, Pickleball, Bóng đá).
  - Venue name & District.
  - Scheduled time.
  - Total players needed & share fee per person.
  - On submit: appends new post to community state, shows confirmation snackbar, and switches to the feed.

### 4. 1-Tap Recruitment from Booked Tickets (`TicketsScreen`)
- On each ticket card in `TicketsScreen`:
  - Add button `[📢 Tuyển thêm người chơi]` (key `recruit_from_ticket_<id>`).
  - Tapping this button opens the recruitment dialog pre-filled with the ticket's venue name, district, and time slot.
  - Submitting automatically publishes the recruitment post and navigates to the Community feed.

### 5. Smart AI Matchmaker Mode (`[✨ Gợi ý đối thủ AI]`)
- Preserves the existing AI Assistant banner and Gemini scoring algorithm, evaluating user profile compatibility against the active community posts.

## Architecture & Data Flow
- `lib/domain/entities/community_post.dart` (or model inside presentation/data):
  - `CommunityPost` entity with fields: `id`, `title`, `authorName`, `authorAvatar`, `sportType`, `district`, `skillLevel`, `venueName`, `scheduledTime`, `requiredPlayers`, `currentPlayers`, `shareFee`, `note`, `isJoined`.
- `lib/core/utils/seed_data.dart`:
  - Rich initial list of `CommunityPost` items.
- `lib/main.dart`:
  - Update `MatchmakingScreen` with state for active posts, joined posts, filter selection, and create dialog.
  - Update `TicketsScreen` with `[📢 Tuyển thêm người chơi]` action button.
- `test/presentation/screens/community_test.dart`:
  - Unit and widget tests for community feed, joining a post, creating a post, and recruiting from a ticket.

## Verification & Testing
1. Verify community feed renders posts with proper sport, slot progress, and share fee.
2. Verify tapping `[Tham gia ngay]` increments player count and marks post as joined.
3. Verify creating a post appends it to the feed.
4. Verify recruiting from ticket pre-fills details.
5. Verify all tests pass cleanly and `flutter analyze` reports 0 issues.
