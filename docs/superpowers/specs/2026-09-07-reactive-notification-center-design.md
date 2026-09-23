# Design Specification: Reactive Notification Center (Trung Tâm Thông Báo)

**Date:** 2026-09-07  
**Author:** Google DeepMind Assistant & Quoc Anh  
**Status:** Approved  
**Target:** SportHub Mobile (Flutter 3.x, Dart 3.x)

---

## 1. Overview & Objectives

SportHub previously featured a static notification bell icon in the top header as a visual placeholder with no interaction. This feature delivers a full-featured, reactive **Notification Center (Trung Tâm Thông Báo)** accessible from both the Consumer (Player) and Partner (Venue Owner) interfaces.

### Core Goals
1. **Interactive Notification Sheet:** Tapping the header bell icon (`🔔`) opens a smooth modal bottom sheet displaying categorized notifications with read/unread statuses.
2. **Context-Aware Roles:** Support both Player notifications (booking confirmations, match reminders, community invites) and Partner Owner notifications (new app bookings, check-in success).
3. **Reactive State & Badge Counter:** Live `NotificationStore` updating the header bell's badge indicator in realtime when notifications are created or read.
4. **Deep-Link Navigation:** Tapping a notification automatically marks it as read and navigates directly to the associated screen/tab (e.g. "Vé của tôi", "Cộng đồng").
5. **Theme Consistency:** Complete support for Fresh Athletic Light Theme and Sporty Dark Luxury without contrast issues.

---

## 2. Architecture & Domain Model

### 2.1 Domain Entity: `AppNotification`
Location: `lib/domain/entities/app_notification.dart`

```dart
enum NotificationType {
  booking,   // Đặt sân, nhắc giờ chơi, vé QR
  community, // Ghép đội, bình luận, lời mời giao lưu
  system,    // Ưu đãi giờ vàng, thông báo hệ thống
  partner,   // Chủ sân: Khách đặt sân mới, check-in thành công
}

enum NotificationRole {
  player,
  owner,
  all,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final NotificationRole role;
  final bool isRead;
  final String? targetId; // e.g. bookingId, postId, courtId

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.role = NotificationRole.player,
    this.isRead = false,
    this.targetId,
  });

  String get timeAgoDisplay {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    NotificationRole? role,
    bool? isRead,
    String? targetId,
  });
}
```

---

## 3. Reactive State: `NotificationStore`
Location: `lib/core/state/notification_store.dart`

Singleton pattern matching `AuthStore`, `VenueOwnerStore`, and `ThemeStore`:

- **State:**
  - `ValueNotifier<List<AppNotification>> notificationsNotifier`
- **Computed Getters:**
  - `int getUnreadCount({NotificationRole? role})`
  - `List<AppNotification> getNotificationsForRole(NotificationRole role)`
- **Actions:**
  - `void markAsRead(String id)`
  - `void markAllAsRead({NotificationRole? role})`
  - `void addNotification(AppNotification notification)`
  - `void deleteNotification(String id)`
  - `void clearAll({NotificationRole? role})`
  - `void resetSeedData()`: Seeds realistic notifications:
    - *Player:*
      - "Nhắc giờ chơi sắp tới: Sân Cầu Lông Bình Thạnh lúc 18:00 hôm nay."
      - "Lời mời giao lưu: Minh Hoàng mời bạn tham gia trận Pickleball tại Thảo Điền."
      - "Ưu đãi giờ vàng: Giảm 20% đặt sân ca sáng (08:00 - 16:00) tại Tao Đàn."
    - *Partner Owner:*
      - "Đơn đặt sân mới: Khách app vừa đặt Sân Cầu Lông 01 (18:00 - 19:00)."
      - "Check-in thành công: Vé SH-8291 đã hoàn tất nhận sân."

---

## 4. UI Components & Visual Design

### 4.1 Header Notification Bell
- **Player Screen (`ExploreVenuesScreen`):**
  - Bell container wrapped in `InkWell(key: Key('notification_bell_button'))`.
  - Subscribes to `NotificationStore.instance.notificationsNotifier`.
  - Badging: If `unreadCount > 0`, renders glowing badge dot / count badge on top-right corner.
- **Partner Screen (`OwnerNavigationScreen`):**
  - Added to AppBar actions with `key: Key('notification_bell_button_owner')`.
  - Displays owner-specific unread badge.

### 4.2 Modal Sheet: `NotificationCenterSheet`
Location: `lib/presentation/widgets/notification_center_sheet.dart`
Invoked via `NotificationCenterSheet.show(context, role: NotificationRole.player)`:

- **Header Section:**
  - Title "Thông báo", unread counter pill (`3 mới`), `[✓ Đã đọc tất cả]` button (`Key('mark_all_read_button')`), and Close button (`Key('close_notification_sheet_button')`).
- **Filter Chips Bar:**
  - `Tất cả` (`Key('filter_notification_all')`)
  - `🏸 Đặt sân` (`Key('filter_notification_booking')`)
  - `👥 Cộng đồng` (`Key('filter_notification_community')`)
  - `🎁 Ưu đãi` (`Key('filter_notification_system')`)
- **Notification List Item (`Key('notification_tile_${item.id}')`):**
  - Icon container with type-specific styling:
    - Booking: Emerald green icon (`confirmation_number_rounded`)
    - Community: Cyan icon (`groups_rounded`)
    - System: Amber icon (`local_offer_rounded`)
    - Partner: Purple/Emerald icon (`storefront_rounded`)
  - Unread indicator dot: Emerald pulsing circle for `!isRead`.
  - Title (`AppColors.textPrimary`), subtitle/body (`AppColors.textSecondary`), relative time (`timeAgoDisplay`).
  - Dismissible / swipe-to-delete support.
- **Tap & Navigation Action:**
  - Marks item as read in `NotificationStore`.
  - Closes bottom sheet.
  - If `type == NotificationType.booking`: switches to "Vé của tôi" (Tab 2) via `MainNavigationController.switchToTab(2)`.
  - If `type == NotificationType.community`: switches to "Cộng đồng" (Tab 1) via `MainNavigationController.switchToTab(1)`.

---

## 5. Booking Flow Integration
In `lib/main.dart`'s booking confirmation dialog (`_showVietQrDialog`), upon successful booking:
- Dispatches `NotificationStore.instance.addNotification(...)` with:
  - Title: "Đặt sân thành công! (#${bookingId})"
  - Message: "Bạn đã đặt thành công tại ${venue.name}. Kiểm tra vé trong mục Vé của tôi."
  - Type: `NotificationType.booking`
  - TargetId: bookingId

---

## 6. Verification & Test Plan

1. **Unit Tests (`test/core/state/notification_store_test.dart`):**
   - Verify initial seed data generation.
   - Verify `markAsRead` updates specific item and decrements `unreadCount`.
   - Verify `markAllAsRead` marks all active role notifications as read.
   - Verify `addNotification` adds item and increments `unreadCount`.
   - Verify filtering by `NotificationType` and `NotificationRole`.

2. **Widget Tests (`test/presentation/screens/notification_center_test.dart`):**
   - Verify tapping bell icon opens `NotificationCenterSheet`.
   - Verify unread count badge renders correctly on bell button.
   - Verify category filter chips filter notifications.
   - Verify "Đã đọc tất cả" marks all items read and clears unread badges.
   - Verify tapping a booking notification navigates to Tickets tab.

3. **Full Suite Regression:**
   - Verify all existing 180 tests pass with 0 regressions.
   - Verify `flutter analyze` reports 0 issues.
