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
    expect(find.text('2 mới'), findsOneWidget);
    expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_all')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_booking')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_community')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_system')), findsOneWidget);

    // Initial player seed notifications render
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
    expect(find.text('Lời mời ghép trận mới 👥'), findsOneWidget);
    expect(find.text('Ưu đãi Giờ Vàng 20% 🎁'), findsOneWidget);
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
    await tester.ensureVisible(find.byKey(const Key('filter_notification_booking')));
    await tester.tap(find.byKey(const Key('filter_notification_booking')));
    await tester.pumpAndSettle();

    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
    expect(find.text('Lời mời ghép trận mới 👥'), findsNothing);
    expect(find.text('Ưu đãi Giờ Vàng 20% 🎁'), findsNothing);

    // Tap Community filter
    await tester.ensureVisible(find.byKey(const Key('filter_notification_community')));
    await tester.tap(find.byKey(const Key('filter_notification_community')));
    await tester.pumpAndSettle();

    expect(find.text('Lời mời ghép trận mới 👥'), findsOneWidget);
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsNothing);
    expect(find.text('Ưu đãi Giờ Vàng 20% 🎁'), findsNothing);

    // Tap System / Offer filter
    await tester.ensureVisible(find.byKey(const Key('filter_notification_system')));
    await tester.tap(find.byKey(const Key('filter_notification_system')));
    await tester.pumpAndSettle();

    expect(find.text('Ưu đãi Giờ Vàng 20% 🎁'), findsOneWidget);
    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsNothing);
    expect(find.text('Lời mời ghép trận mới 👥'), findsNothing);

    // Tap All filter
    await tester.ensureVisible(find.byKey(const Key('filter_notification_all')));
    await tester.tap(find.byKey(const Key('filter_notification_all')));
    await tester.pumpAndSettle();

    expect(find.text('Nhắc lịch thi đấu sắp tới 🏸'), findsOneWidget);
    expect(find.text('Lời mời ghép trận mới 👥'), findsOneWidget);
    expect(find.text('Ưu đãi Giờ Vàng 20% 🎁'), findsOneWidget);
  });

  testWidgets('Owner role renders owner chips and notifications', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => NotificationCenterSheet.show(context, role: NotificationRole.owner),
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('filter_notification_all')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_partner')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_system')), findsOneWidget);
    expect(find.byKey(const Key('filter_notification_booking')), findsNothing);

    expect(find.text('Đơn đặt sân mới qua App ⚡'), findsOneWidget);
    expect(find.text('Soát vé Check-in thành công ✅'), findsOneWidget);
    expect(find.text('Báo cáo doanh thu ngày 📊'), findsOneWidget);
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
    expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark_all_read_button')));
    await tester.pumpAndSettle();

    expect(NotificationStore.instance.getUnreadCount(role: NotificationRole.player), equals(0));
    expect(find.byKey(const Key('mark_all_read_button')), findsNothing);
    expect(find.text('2 mới'), findsNothing);
  });

  testWidgets('Tapping notification tile triggers onNotificationTap, marks read, and pops sheet', (tester) async {
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

    expect(find.byType(NotificationCenterSheet), findsOneWidget);

    await tester.tap(find.text('Nhắc lịch thi đấu sắp tới 🏸'));
    await tester.pumpAndSettle();

    expect(tappedNotif, isNotNull);
    expect(tappedNotif!.id, equals('notif_p_01'));
    expect(NotificationStore.instance.notificationsNotifier.value.firstWhere((n) => n.id == 'notif_p_01').isRead, isTrue);
    expect(find.byType(NotificationCenterSheet), findsNothing);
  });

  testWidgets('Empty state renders when no notifications exist', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    NotificationStore.instance.clearAll(role: NotificationRole.player);

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

    expect(find.text('Chưa có thông báo nào'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets('Close button dismisses sheet', (tester) async {
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

    expect(find.byType(NotificationCenterSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('close_notification_sheet_button')));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationCenterSheet), findsNothing);
  });
}
