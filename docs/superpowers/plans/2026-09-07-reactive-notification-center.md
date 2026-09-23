# Reactive Notification Center Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a full-featured, theme-aware Reactive Notification Center for SportHub with `NotificationStore`, interactive modal bottom sheet, category filtering, live unread badges in both Player and Partner headers, and deep-link routing.

**Architecture:** Clean Architecture + Singleton Reactive Pattern using `ValueNotifier`. Domain entity `AppNotification`, reactive `NotificationStore`, reusable `NotificationCenterSheet` widget, and hooks into `ExploreVenuesScreen`, `OwnerNavigationScreen`, and the booking completion flow.

**Tech Stack:** Flutter SDK 3.x, Dart 3.x, `ValueNotifier` reactive pattern, Material 3 with Fresh Athletic Light Theme & Sporty Dark Luxury.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Architecture Pattern: Clean Architecture + ValueNotifier reactive pattern.
- Design Theme: Fresh Athletic Light Theme default (background #F8FAFC, surface #FFFFFF, cardBorder #E2E8F0, textPrimary #0F172A, textSecondary #64748B, primary #059669), retaining Sporty Dark Luxury theme (#0B0F19, #161F30, #223049, #F8FAFC, #94A3B8, #10B981) on toggle.
- Backward Compatibility: Keep existing 180 unit, widget, and integration tests passing 100%.

---

### Task 1: Domain Entity `AppNotification` & `NotificationStore` Reactive State

**Files:**
- Create: `lib/domain/entities/app_notification.dart`
- Create: `lib/core/state/notification_store.dart`
- Test: `test/core/state/notification_store_test.dart`

**Interfaces:**
- Produces:
  - `enum NotificationType { booking, community, system, partner }`
  - `enum NotificationRole { player, owner, all }`
  - `class AppNotification { id, title, message, timestamp, type, role, isRead, targetId, timeAgoDisplay, copyWith }`
  - `class NotificationStore { static NotificationStore get instance; ValueNotifier<List<AppNotification>> notificationsNotifier; int getUnreadCount({NotificationRole? role}); List<AppNotification> getNotificationsForRole(NotificationRole role); void markAsRead(String id); void markAllAsRead({NotificationRole? role}); void addNotification(AppNotification notification); void deleteNotification(String id); void clearAll({NotificationRole? role}); void resetSeedData(); }`

- [ ] **Step 1: Write the failing unit tests for `AppNotification` and `NotificationStore`**

Create `test/core/state/notification_store_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/app_notification.dart';
import 'package:sporthub/core/state/notification_store.dart';

void main() {
  late NotificationStore store;

  setUp(() {
    store = NotificationStore.instance;
    store.resetSeedData();
  });

  test('NotificationStore initializes with realistic seed data for player and owner', () {
    final playerNotifs = store.getNotificationsForRole(NotificationRole.player);
    final ownerNotifs = store.getNotificationsForRole(NotificationRole.owner);

    expect(playerNotifs, isNotEmpty);
    expect(ownerNotifs, isNotEmpty);
    expect(store.getUnreadCount(role: NotificationRole.player), greaterThan(0));
    expect(store.getUnreadCount(role: NotificationRole.owner), greaterThan(0));
  });

  test('markAsRead marks specific notification as read and decrements unread count', () {
    final playerNotifs = store.getNotificationsForRole(NotificationRole.player);
    final unreadItem = playerNotifs.firstWhere((n) => !n.isRead);
    final initialUnread = store.getUnreadCount(role: NotificationRole.player);

    store.markAsRead(unreadItem.id);

    final updatedItem = store.notificationsNotifier.value.firstWhere((n) => n.id == unreadItem.id);
    expect(updatedItem.isRead, isTrue);
    expect(store.getUnreadCount(role: NotificationRole.player), equals(initialUnread - 1));
  });

  test('markAllAsRead marks all notifications as read for specified role', () {
    expect(store.getUnreadCount(role: NotificationRole.player), greaterThan(0));

    store.markAllAsRead(role: NotificationRole.player);

    expect(store.getUnreadCount(role: NotificationRole.player), equals(0));
    // Owner unread count is preserved
    expect(store.getUnreadCount(role: NotificationRole.owner), greaterThan(0));
  });

  test('addNotification prepends new notification and increments unread count', () {
    final initialCount = store.getNotificationsForRole(NotificationRole.player).length;
    final initialUnread = store.getUnreadCount(role: NotificationRole.player);

    final newNotif = AppNotification(
      id: 'notif_test_1',
      title: 'Đặt sân thành công!',
      message: 'Mã vé BK-999 đã được tạo.',
      timestamp: DateTime.now(),
      type: NotificationType.booking,
      role: NotificationRole.player,
      isRead: false,
      targetId: 'BK-999',
    );

    store.addNotification(newNotif);

    final updatedNotifs = store.getNotificationsForRole(NotificationRole.player);
    expect(updatedNotifs.length, equals(initialCount + 1));
    expect(updatedNotifs.first.id, equals('notif_test_1'));
    expect(store.getUnreadCount(role: NotificationRole.player), equals(initialUnread + 1));
  });

  test('deleteNotification removes notification from store', () {
    final playerNotifs = store.getNotificationsForRole(NotificationRole.player);
    final itemToDelete = playerNotifs.first;
    final initialCount = store.notificationsNotifier.value.length;

    store.deleteNotification(itemToDelete.id);

    expect(store.notificationsNotifier.value.any((n) => n.id == itemToDelete.id), isFalse);
    expect(store.notificationsNotifier.value.length, equals(initialCount - 1));
  });

  test('AppNotification.timeAgoDisplay formats correctly for Vietnamese UI', () {
    final justNow = AppNotification(
      id: '1',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now(),
      type: NotificationType.system,
    );
    expect(justNow.timeAgoDisplay, equals('Vừa xong'));

    final minutesAgo = AppNotification(
      id: '2',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: NotificationType.system,
    );
    expect(minutesAgo.timeAgoDisplay, equals('15 phút trước'));

    final hoursAgo = AppNotification(
      id: '3',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.system,
    );
    expect(hoursAgo.timeAgoDisplay, equals('3 giờ trước'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `flutter test test/core/state/notification_store_test.dart`
Expected: Compilation failure because `AppNotification` and `NotificationStore` do not exist.

- [ ] **Step 3: Implement `lib/domain/entities/app_notification.dart`**

```dart
enum NotificationType {
  booking,
  community,
  system,
  partner,
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
  final String? targetId;

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
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
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
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      role: role ?? this.role,
      isRead: isRead ?? this.isRead,
      targetId: targetId ?? this.targetId,
    );
  }
}
```

- [ ] **Step 4: Implement `lib/core/state/notification_store.dart`**

```dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/app_notification.dart';

class NotificationStore {
  NotificationStore._internal() {
    resetSeedData();
  }

  static final NotificationStore instance = NotificationStore._internal();

  final ValueNotifier<List<AppNotification>> notificationsNotifier =
      ValueNotifier<List<AppNotification>>([]);

  List<AppNotification> get notifications => notificationsNotifier.value;

  int getUnreadCount({NotificationRole? role}) {
    return notificationsNotifier.value.where((n) {
      if (n.isRead) return false;
      if (role == null || role == NotificationRole.all) return true;
      return n.role == role || n.role == NotificationRole.all;
    }).length;
  }

  List<AppNotification> getNotificationsForRole(NotificationRole role) {
    if (role == NotificationRole.all) return notificationsNotifier.value;
    return notificationsNotifier.value
        .where((n) => n.role == role || n.role == NotificationRole.all)
        .toList();
  }

  void markAsRead(String id) {
    final list = notificationsNotifier.value;
    final index = list.indexWhere((n) => n.id == id);
    if (index != -1 && !list[index].isRead) {
      final updated = List<AppNotification>.from(list);
      updated[index] = updated[index].copyWith(isRead: true);
      notificationsNotifier.value = List.unmodifiable(updated);
    }
  }

  void markAllAsRead({NotificationRole? role}) {
    final list = notificationsNotifier.value;
    final updated = list.map((n) {
      if (role == null || role == NotificationRole.all || n.role == role || n.role == NotificationRole.all) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    notificationsNotifier.value = List.unmodifiable(updated);
  }

  void addNotification(AppNotification notification) {
    final updated = [notification, ...notificationsNotifier.value];
    notificationsNotifier.value = List.unmodifiable(updated);
  }

  void deleteNotification(String id) {
    final updated = notificationsNotifier.value.where((n) => n.id != id).toList();
    notificationsNotifier.value = List.unmodifiable(updated);
  }

  void clearAll({NotificationRole? role}) {
    if (role == null || role == NotificationRole.all) {
      notificationsNotifier.value = const [];
    } else {
      final updated = notificationsNotifier.value.where((n) => n.role != role && n.role != NotificationRole.all).toList();
      notificationsNotifier.value = List.unmodifiable(updated);
    }
  }

  void resetSeedData() {
    final now = DateTime.now();
    notificationsNotifier.value = List.unmodifiable([
      // Player Notifications
      AppNotification(
        id: 'notif_p_01',
        title: 'Nhắc lịch thi đấu sắp tới 🏸',
        message: 'Bạn có trận đấu tại Sân Cầu Lông Bình Thạnh vào 18:00 hôm nay. Sẵn sàng ra sân nhé!',
        timestamp: now.subtract(const Duration(minutes: 25)),
        type: NotificationType.booking,
        role: NotificationRole.player,
        isRead: false,
        targetId: 'BK-20260906-889',
      ),
      AppNotification(
        id: 'notif_p_02',
        title: 'Lời mời ghép trận mới 👥',
        message: 'Minh Hoàng đã mời bạn tham gia trận Pickleball giao lưu tại Thảo Điền Hub.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: NotificationType.community,
        role: NotificationRole.player,
        isRead: false,
        targetId: 'post_01',
      ),
      AppNotification(
        id: 'notif_p_03',
        title: 'Ưu đãi Giờ Vàng 20% 🎁',
        message: 'Đặt sân ca sáng (08:00 - 16:00) tại CLB Tao Đàn để nhận mức giá ưu đãi đặc biệt hôm nay.',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.system,
        role: NotificationRole.player,
        isRead: true,
      ),

      // Partner Owner Notifications
      AppNotification(
        id: 'notif_o_01',
        title: 'Đơn đặt sân mới qua App ⚡',
        message: 'Khách hàng Nguyễn Văn A vừa đặt Sân Cầu Lông 01 (18:00 - 19:00). Mã vé: SH-8291.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: false,
        targetId: 'SH-8291',
      ),
      AppNotification(
        id: 'notif_o_02',
        title: 'Soát vé Check-in thành công ✅',
        message: 'Vé SH-9120 đã được quét mã QR và hoàn tất nhận sân tại Sân Pickleball 05.',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: false,
        targetId: 'SH-9120',
      ),
      AppNotification(
        id: 'notif_o_03',
        title: 'Báo cáo doanh thu ngày 📊',
        message: 'Doanh thu hôm nay đã đạt 2.850.000 đ với tỷ lệ lấp đầy 81.2%.',
        timestamp: now.subtract(const Duration(hours: 8)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: true,
      ),
    ]);
  }
}
```

- [ ] **Step 5: Run tests to verify they pass (GREEN)**

Run: `flutter test test/core/state/notification_store_test.dart`
Expected: 6 tests pass.

- [ ] **Step 6: Commit Task 1**

```bash
git add lib/domain/entities/app_notification.dart lib/core/state/notification_store.dart test/core/state/notification_store_test.dart
git commit -m "feat: implement AppNotification entity and NotificationStore reactive singleton"
```

---

### Task 2: UI Component `NotificationCenterSheet`

**Files:**
- Create: `lib/presentation/widgets/notification_center_sheet.dart`
- Test: `test/presentation/screens/notification_sheet_test.dart`

**Interfaces:**
- Consumes:
  - `NotificationStore.instance`
  - `AppColors.surface`, `AppColors.background`, `AppColors.primary`, `AppColors.cardBorder`, `AppColors.textPrimary`, `AppColors.textSecondary`
  - `AppNotification`, `NotificationType`, `NotificationRole`
- Produces:
  - `NotificationCenterSheet.show(BuildContext context, {NotificationRole role = NotificationRole.player, void Function(AppNotification)? onNotificationTap})`

- [ ] **Step 1: Write failing widget tests for `NotificationCenterSheet`**

Create `test/presentation/screens/notification_sheet_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/core/state/notification_store.dart';
import 'package:sporthub/domain/entities/app_notification.dart';
import 'package:sporthub/presentation/widgets/notification_center_sheet.dart';

void main() {
  setUp(() {
    ThemeStore.instance.setThemeMode(ThemeMode.light);
    NotificationStore.instance.resetSeedData();
  });

  testWidgets('NotificationCenterSheet renders title, unread badge, and notification list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => NotificationCenterSheet.show(context, role: NotificationRole.player),
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_all')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_booking')), findsOneWidget);

    // Initial player seed notifications render
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
    expect(find.text('Lời mời ghép trận mới 👥'), findsOneWidget);
  });

  testWidgets('Filter chips filter notifications by type', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => NotificationCenterSheet.show(context, role: NotificationRole.player),
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap Booking filter
    await tester.tap(find.byKey(const Key('filter_notification_booking')));
    await tester.pumpAndSettle();

    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
    expect(find.text('Lời mời ghép trận mới 👥'), findsNothing);

    // Tap Community filter
    await tester.tap(find.byKey(const Key('filter_notification_community')));
    await tester.pumpAndSettle();

    expect(find.text('Lời mời ghép trận mới 👥'), findsOneWidget);
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsNothing);
  });

  testWidgets('Mark all read button marks notifications read and updates unread badge', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => NotificationCenterSheet.show(context, role: NotificationRole.player),
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(NotificationStore.instance.getUnreadCount(role: NotificationRole.player), greaterThan(0));

    await tester.tap(find.byKey(const Key('mark_all_read_button')));
    await tester.pumpAndSettle();

    expect(NotificationStore.instance.getUnreadCount(role: NotificationRole.player), equals(0));
  });

  testWidgets('Tapping notification tile triggers onNotificationTap and marks it as read', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    AppNotification? tappedNotif;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => NotificationCenterSheet.show(
              context,
              role: NotificationRole.player,
              onNotificationTap: (notif) => tappedNotif = notif,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nhắc lịch thi đấu sắp tới 🏸'));
    await tester.pumpAndSettle();

    expect(tappedNotif, isNotNull);
    expect(tappedNotif!.id, equals('notif_p_01'));
    expect(NotificationStore.instance.notificationsNotifier.value.firstWhere((n) => n.id == 'notif_p_01').isRead, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `flutter test test/presentation/screens/notification_sheet_test.dart`
Expected: Compilation failure because `NotificationCenterSheet` does not exist.

- [ ] **Step 3: Implement `lib/presentation/widgets/notification_center_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/notification_store.dart';
import '../../domain/entities/app_notification.dart';

class NotificationCenterSheet extends StatefulWidget {
  final NotificationRole role;
  final void Function(AppNotification)? onNotificationTap;

  const NotificationCenterSheet({
    super.key,
    this.role = NotificationRole.player,
    this.onNotificationTap,
  });

  static Future<void> show(
    BuildContext context, {
    NotificationRole role = NotificationRole.player,
    void Function(AppNotification)? onNotificationTap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationCenterSheet(
        role: role,
        onNotificationTap: onNotificationTap,
      ),
    );
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
          left: BorderSide(color: AppColors.cardBorder, width: 1.5),
          right: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: ValueListenableBuilder<List<AppNotification>>(
              valueListenable: NotificationStore.instance.notificationsNotifier,
              builder: (context, notifs, _) {
                final unreadCount = NotificationStore.instance.getUnreadCount(role: widget.role);
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thông báo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount mới',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (unreadCount > 0)
                      TextButton(
                        key: const Key('mark_all_read_button'),
                        onPressed: () => NotificationStore.instance.markAllAsRead(role: widget.role),
                        child: Text(
                          'Đã đọc tất cả',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    IconButton(
                      key: const Key('close_notification_sheet_button'),
                      icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả', 'filter_notification_all'),
                const SizedBox(width: 8),
                if (widget.role == NotificationRole.player || widget.role == NotificationRole.all) ...[
                  _buildFilterChip('booking', '🏸 Đặt sân', 'filter_notification_booking'),
                  const SizedBox(width: 8),
                  _buildFilterChip('community', '👥 Cộng đồng', 'filter_notification_community'),
                  const SizedBox(width: 8),
                  _buildFilterChip('system', '🎁 Ưu đãi', 'filter_notification_system'),
                ] else ...[
                  _buildFilterChip('partner', '⚡ Khách đặt sân', 'filter_notification_partner'),
                  const SizedBox(width: 8),
                  _buildFilterChip('system', '📊 Báo cáo', 'filter_notification_system'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.cardBorder),

          // Notification List
          Expanded(
            child: ValueListenableBuilder<List<AppNotification>>(
              valueListenable: NotificationStore.instance.notificationsNotifier,
              builder: (context, _, __) {
                final roleNotifs = NotificationStore.instance.getNotificationsForRole(widget.role);
                final filtered = roleNotifs.where((n) {
                  if (_selectedFilter == 'all') return true;
                  if (_selectedFilter == 'booking') return n.type == NotificationType.booking;
                  if (_selectedFilter == 'community') return n.type == NotificationType.community;
                  if (_selectedFilter == 'system') return n.type == NotificationType.system;
                  if (_selectedFilter == 'partner') return n.type == NotificationType.partner;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 68,
                    endIndent: 20,
                    color: AppColors.cardBorder.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildNotificationTile(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, String testKey) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      key: Key(testKey),
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification item) {
    final (icon, iconBg, iconColor) = _getTypeVisuals(item.type);

    return InkWell(
      key: Key('notification_tile_${item.id}'),
      onTap: () {
        NotificationStore.instance.markAsRead(item.id);
        Navigator.of(context).pop();
        widget.onNotificationTap?.call(item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: item.isRead
            ? Colors.transparent
            : AppColors.primary.withValues(alpha: AppColors.isDark ? 0.08 : 0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.timeAgoDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _getTypeVisuals(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return (
          Icons.confirmation_number_rounded,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
        );
      case NotificationType.community:
        return (
          Icons.groups_rounded,
          AppColors.secondary.withValues(alpha: 0.15),
          AppColors.secondary,
        );
      case NotificationType.system:
        return (
          Icons.local_offer_rounded,
          AppColors.warning.withValues(alpha: 0.15),
          AppColors.warning,
        );
      case NotificationType.partner:
        return (
          Icons.storefront_rounded,
          Colors.purple.withValues(alpha: 0.15),
          Colors.purple,
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có thông báo nào',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Các cập nhật về lịch sân và cộng đồng sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass (GREEN)**

Run: `flutter test test/presentation/screens/notification_sheet_test.dart`
Expected: 4 tests pass.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/presentation/widgets/notification_center_sheet.dart test/presentation/screens/notification_sheet_test.dart
git commit -m "feat: implement NotificationCenterSheet modal with filters and unread counter"
```

---

### Task 3: Integration into Consumer & Partner App Shells and Booking Flow

**Files:**
- Modify: `lib/main.dart:772-811` (Consumer Explore header bell icon & booking confirmation hook)
- Modify: `lib/presentation/screens/owner_navigation_screen.dart:90-105` (Partner AppBar actions bell icon)
- Test: `test/presentation/screens/notification_integration_test.dart`

**Interfaces:**
- Consumes:
  - `NotificationStore.instance`
  - `NotificationCenterSheet.show`
  - `MainNavigationController.switchToTab`
- Produces:
  - Header bell buttons with live unread badge counters and deep-link routing.

- [ ] **Step 1: Write failing integration widget test**

Create `test/presentation/screens/notification_integration_test.dart`:
```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/state/notification_store.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/domain/entities/app_notification.dart';
import 'package:sporthub/main.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    ThemeStore.instance.setThemeMode(ThemeMode.light);
    AuthStore.instance.continueAsGuest();
    NotificationStore.instance.resetSeedData();
    VenueOwnerStore.instance.toggleOwnerMode(false);
  });

  testWidgets('Consumer Explore header displays notification bell with badge and opens sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final bellFinder = find.byKey(const Key('notification_bell_button'));
    expect(bellFinder, findsOneWidget);

    await tester.tap(bellFinder);
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
  });

  testWidgets('Tapping booking notification deep-links to Tickets tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification_bell_button')));
    await tester.pumpAndSettle();

    // Tap the booking notification
    await tester.tap(find.text('Nhắc lịch thi đấu sắp tới 🏸'));
    await tester.pumpAndSettle();

    // Sheet dismissed and navigated to Tickets tab
    expect(find.text('SPORTHUB PASS'), findsWidgets);
  });

  testWidgets('Partner Owner header displays notification bell and opens owner sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    VenueOwnerStore.instance.toggleOwnerMode(true);

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final ownerBellFinder = find.byKey(const Key('notification_bell_button_owner'));
    expect(ownerBellFinder, findsOneWidget);

    await tester.tap(ownerBellFinder);
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Đơn đặt sân mới qua App ⚡'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails (RED)**

Run: `flutter test test/presentation/screens/notification_integration_test.dart`
Expected: FAIL because `notification_bell_button` and `notification_bell_button_owner` are not wired yet.

- [ ] **Step 3: Update `lib/main.dart` header notification bell & booking hook**

In `lib/main.dart`:
1. Import `'presentation/widgets/notification_center_sheet.dart'`.
2. Replace static notification stack in `ExploreVenuesScreen` with:
```dart
                        // Notification Icon with Live Badge
                        ValueListenableBuilder<List<AppNotification>>(
                          valueListenable: NotificationStore.instance.notificationsNotifier,
                          builder: (context, notifs, _) {
                            final unreadCount = NotificationStore.instance.getUnreadCount(role: NotificationRole.player);
                            return InkWell(
                              key: const Key('notification_bell_button'),
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                NotificationCenterSheet.show(
                                  context,
                                  role: NotificationRole.player,
                                  onNotificationTap: (notif) {
                                    if (notif.type == NotificationType.booking) {
                                      MainNavigationController.switchToTab?.call(2);
                                    } else if (notif.type == NotificationType.community) {
                                      MainNavigationController.switchToTab?.call(1);
                                    }
                                  },
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      size: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.surface, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
```
3. In `_showVietQrDialog`, upon payment confirmation:
```dart
          NotificationStore.instance.addNotification(
            AppNotification(
              id: 'notif_booking_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Đặt sân thành công! 🎉',
              message: 'Bạn đã đặt thành công ${selectedSlots.length} ca tại ${widget.venue.name}. Mã vé: $newBookingId.',
              timestamp: DateTime.now(),
              type: NotificationType.booking,
              role: NotificationRole.player,
              targetId: newBookingId,
            ),
          );
```

- [ ] **Step 4: Update `lib/presentation/screens/owner_navigation_screen.dart` AppBar actions**

In `lib/presentation/screens/owner_navigation_screen.dart`:
1. Import `../widgets/notification_center_sheet.dart`.
2. In AppBar actions (between theme switcher and exit button):
```dart
              // Notification Bell with Badge
              ValueListenableBuilder<List<AppNotification>>(
                valueListenable: NotificationStore.instance.notificationsNotifier,
                builder: (context, notifs, _) {
                  final unreadCount = NotificationStore.instance.getUnreadCount(role: NotificationRole.owner);
                  return IconButton(
                    key: const Key('notification_bell_button_owner'),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      NotificationCenterSheet.show(
                        context,
                        role: NotificationRole.owner,
                      );
                    },
                  );
                },
              ),
```

- [ ] **Step 5: Run integration tests to verify they pass (GREEN)**

Run: `flutter test test/presentation/screens/notification_integration_test.dart`
Expected: 3 tests pass.

- [ ] **Step 6: Run full test suite and analyzer**

Run: `flutter analyze && flutter test`
Expected: 0 issues, 187/187 tests pass.

- [ ] **Step 7: Commit Task 3**

```bash
git add lib/main.dart lib/presentation/screens/owner_navigation_screen.dart test/presentation/screens/notification_integration_test.dart
git commit -m "feat: integrate notification bell buttons and auto-dispatch booking alerts"
```
