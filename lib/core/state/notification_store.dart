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
      if (role == null ||
          role == NotificationRole.all ||
          n.role == role ||
          n.role == NotificationRole.all) {
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
    final updated =
        notificationsNotifier.value.where((n) => n.id != id).toList();
    notificationsNotifier.value = List.unmodifiable(updated);
  }

  void clearAll({NotificationRole? role}) {
    if (role == null || role == NotificationRole.all) {
      notificationsNotifier.value = const [];
    } else {
      final updated = notificationsNotifier.value
          .where((n) => n.role != role && n.role != NotificationRole.all)
          .toList();
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
        message:
            'Bạn có trận đấu tại Sân Cầu Lông Bình Thạnh vào 18:00 hôm nay. Sẵn sàng ra sân nhé!',
        timestamp: now.subtract(const Duration(minutes: 25)),
        type: NotificationType.booking,
        role: NotificationRole.player,
        isRead: false,
        targetId: 'BK-20260906-889',
      ),
      AppNotification(
        id: 'notif_p_02',
        title: 'Lời mời ghép trận mới 👥',
        message:
            'Minh Hoàng đã mời bạn tham gia trận Pickleball giao lưu tại Thảo Điền Hub.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: NotificationType.community,
        role: NotificationRole.player,
        isRead: false,
        targetId: 'post_01',
      ),
      AppNotification(
        id: 'notif_p_03',
        title: 'Ưu đãi Giờ Vàng 20% 🎁',
        message:
            'Đặt sân ca sáng (08:00 - 16:00) tại CLB Tao Đàn để nhận mức giá ưu đãi đặc biệt hôm nay.',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.system,
        role: NotificationRole.player,
        isRead: true,
      ),

      // Partner Owner Notifications
      AppNotification(
        id: 'notif_o_01',
        title: 'Đơn đặt sân mới qua App ⚡',
        message:
            'Khách hàng Nguyễn Văn A vừa đặt Sân Cầu Lông 01 (18:00 - 19:00). Mã vé: SH-8291.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: false,
        targetId: 'SH-8291',
      ),
      AppNotification(
        id: 'notif_o_02',
        title: 'Soát vé Check-in thành công ✅',
        message:
            'Vé SH-9120 đã được quét mã QR và hoàn tất nhận sân tại Sân Pickleball 05.',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: false,
        targetId: 'SH-9120',
      ),
      AppNotification(
        id: 'notif_o_03',
        title: 'Báo cáo doanh thu ngày 📊',
        message:
            'Doanh thu hôm nay đã đạt 2.850.000 đ với tỷ lệ lấp đầy 81.2%.',
        timestamp: now.subtract(const Duration(hours: 8)),
        type: NotificationType.system,
        role: NotificationRole.owner,
        isRead: true,
      ),
    ]);
  }
}
