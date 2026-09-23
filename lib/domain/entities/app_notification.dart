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
    if (diff.isNegative || diff.inSeconds < 60) return 'Vừa xong';
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
