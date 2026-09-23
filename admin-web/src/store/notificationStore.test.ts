import { describe, it, expect, beforeEach } from 'vitest';
import { notificationStore } from './notificationStore';

describe('notificationStore', () => {
  beforeEach(() => {
    notificationStore.reset();
  });

  it('initializes with sample notifications and calculates unread count', () => {
    const list = notificationStore.getNotifications();
    expect(list.length).toBeGreaterThanOrEqual(4);
    expect(notificationStore.getUnreadCount()).toBe(3);
  });

  it('marks a single notification as read', () => {
    const list = notificationStore.getNotifications();
    const firstUnread = list.find((n) => !n.isRead);
    expect(firstUnread).toBeDefined();

    notificationStore.markAsRead(firstUnread!.id);
    expect(notificationStore.getUnreadCount()).toBe(2);
    const updated = notificationStore.getNotifications().find((n) => n.id === firstUnread!.id);
    expect(updated?.isRead).toBe(true);
  });

  it('marks all notifications as read', () => {
    expect(notificationStore.getUnreadCount()).toBe(3);
    notificationStore.markAllAsRead();
    expect(notificationStore.getUnreadCount()).toBe(0);
    const allRead = notificationStore.getNotifications().every((n) => n.isRead);
    expect(allRead).toBe(true);
  });

  it('adds a new notification dynamically', () => {
    const initialCount = notificationStore.getNotifications().length;
    notificationStore.addNotification({
      title: 'Khách yêu cầu hủy sân',
      message: 'Vé #BK-9912 xin dời lịch thi đấu',
      timestamp: 'Vừa xong',
      type: 'booking',
    });

    expect(notificationStore.getNotifications().length).toBe(initialCount + 1);
    expect(notificationStore.getNotifications()[0].title).toBe('Khách yêu cầu hủy sân');
  });
});
