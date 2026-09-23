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
      constraints: const BoxConstraints(maxWidth: 420),
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
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
                      Expanded(
                        child: Row(
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
                            Flexible(
                              child: Text(
                                'Thông báo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                          ],
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          key: const Key('mark_all_read_button'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
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
                      ],
                      IconButton(
                        key: const Key('close_notification_sheet_button'),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
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
