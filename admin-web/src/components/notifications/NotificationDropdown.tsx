import React from 'react';
import {
  Bell,
  CheckCircle2,
  Calendar,
  AlertCircle,
  TrendingUp,
  CheckCheck,
} from 'lucide-react';
import { useNotificationStore, NotificationType } from '../../store/notificationStore';

interface NotificationDropdownProps {
  isOpen: boolean;
  onClose: () => void;
}

export const NotificationDropdown: React.FC<NotificationDropdownProps> = ({
  isOpen,
  onClose: _onClose,
}) => {
  const { notifications, unreadCount, markAsRead, markAllAsRead } =
    useNotificationStore();

  if (!isOpen) return null;

  const getTypeIcon = (type: NotificationType) => {
    switch (type) {
      case 'booking':
        return <Calendar className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />;
      case 'checkin':
        return <CheckCircle2 className="w-4 h-4 text-teal-600 dark:text-teal-400" />;
      case 'maintenance':
        return <AlertCircle className="w-4 h-4 text-amber-600 dark:text-amber-400" />;
      case 'revenue':
        return <TrendingUp className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />;
      default:
        return <Bell className="w-4 h-4 text-slate-500" />;
    }
  };

  const getTypeBg = (type: NotificationType) => {
    switch (type) {
      case 'booking':
        return 'bg-emerald-50 dark:bg-emerald-950/50 border-emerald-200 dark:border-emerald-800/60';
      case 'checkin':
        return 'bg-teal-50 dark:bg-teal-950/50 border-teal-200 dark:border-teal-800/60';
      case 'maintenance':
        return 'bg-amber-50 dark:bg-amber-950/50 border-amber-200 dark:border-amber-800/60';
      case 'revenue':
        return 'bg-indigo-50 dark:bg-indigo-950/50 border-indigo-200 dark:border-indigo-800/60';
      default:
        return 'bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700';
    }
  };

  return (
    <div
      role="region"
      aria-label="Trung tâm thông báo"
      className="absolute right-0 mt-2 w-80 sm:w-96 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-xl z-50 overflow-hidden animate-in fade-in zoom-in-95 duration-150"
    >
      {/* Header */}
      <div className="p-3.5 border-b border-slate-100 dark:border-slate-800/80 flex items-center justify-between bg-slate-50/50 dark:bg-slate-900/40">
        <div className="flex items-center gap-2">
          <span className="font-bold text-xs text-slate-900 dark:text-white">
            Thông báo
          </span>
          {unreadCount > 0 && (
            <span
              data-testid="unread-badge-count"
              className="px-1.5 py-0.2 rounded-full text-[10px] font-bold bg-emerald-500 text-white"
            >
              {unreadCount} mới
            </span>
          )}
        </div>

        {unreadCount > 0 && (
          <button
            type="button"
            data-testid="btn-mark-all-read"
            onClick={markAllAsRead}
            className="flex items-center gap-1 text-[11px] font-semibold text-emerald-600 dark:text-emerald-400 hover:underline cursor-pointer"
          >
            <CheckCheck className="w-3.5 h-3.5" />
            <span>Đã đọc tất cả</span>
          </button>
        )}
      </div>

      {/* Notifications List */}
      <div className="max-h-80 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-800/60">
        {notifications.length === 0 ? (
          <div className="p-6 text-center text-xs text-slate-400">
            Không có thông báo mới nào
          </div>
        ) : (
          notifications.map((item) => (
            <div
              key={item.id}
              data-testid={`notif-item-${item.id}`}
              onClick={() => markAsRead(item.id)}
              className={`p-3.5 transition-colors cursor-pointer flex items-start gap-3 ${
                item.isRead
                  ? 'bg-white hover:bg-slate-50/80 dark:bg-[#141B2D] dark:hover:bg-slate-800/40'
                  : 'bg-emerald-50/30 hover:bg-emerald-50/60 dark:bg-emerald-950/20 dark:hover:bg-emerald-950/30'
              }`}
            >
              <div
                className={`p-2 rounded-xl border shrink-0 ${getTypeBg(item.type)}`}
              >
                {getTypeIcon(item.type)}
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-1 mb-0.5">
                  <p
                    className={`text-xs font-semibold truncate ${
                      item.isRead
                        ? 'text-slate-700 dark:text-slate-300'
                        : 'text-slate-900 dark:text-white'
                    }`}
                  >
                    {item.title}
                  </p>
                  <span className="text-[10px] text-slate-400 shrink-0 font-medium">
                    {item.timestamp}
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 line-clamp-2 leading-relaxed">
                  {item.message}
                </p>
              </div>

              {!item.isRead && (
                <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0 mt-1.5" />
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default NotificationDropdown;
