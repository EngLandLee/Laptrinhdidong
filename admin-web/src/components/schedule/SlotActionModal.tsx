import React, { useState, useEffect } from 'react';
import {
  X,
  Clock,
  Phone,
  User,
  DollarSign,
  AlertTriangle,
  CheckCircle2,
  Lock,
  Unlock,
} from 'lucide-react';
import { CourtSlot } from '../../types';
import { venueStore } from '../../store/venueStore';

interface SlotActionModalProps {
  slot: CourtSlot | null;
  isOpen: boolean;
  onClose: () => void;
  onSlotUpdated?: (slot: CourtSlot) => void;
}

type ModalTab = 'reserve' | 'price' | 'maintenance';

const QUICK_PRICES = [80000, 100000, 120000, 150000, 180000, 240000];

export const SlotActionModal: React.FC<SlotActionModalProps> = ({
  slot,
  isOpen,
  onClose,
  onSlotUpdated,
}) => {
  const [activeTab, setActiveTab] = useState<ModalTab>('reserve');
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [reserveNote, setReserveNote] = useState('');
  const [customPrice, setCustomPrice] = useState<number>(120000);
  const [maintenanceReason, setMaintenanceReason] = useState('');
  const [actionSuccess, setActionSuccess] = useState('');
  const [actionError, setActionError] = useState('');

  useEffect(() => {
    if (slot) {
      setCustomerName(slot.customerName || '');
      setCustomerPhone(slot.customerPhone || '');
      setReserveNote(slot.note || '');
      setCustomPrice(slot.price || 120000);
      setMaintenanceReason(slot.status === 'maintenance' ? slot.note || '' : '');
      setActionSuccess('');
      setActionError('');
      // Default to maintenance tab if it's already in maintenance, else reserve
      if (slot.status === 'maintenance') {
        setActiveTab('maintenance');
      } else {
        setActiveTab('reserve');
      }
    }
  }, [slot]);

  if (!isOpen || !slot) return null;

  const handleManualReserve = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerName.trim()) {
      setActionError('Vui lòng nhập tên khách hàng');
      return;
    }
    if (!customerPhone.trim()) {
      setActionError('Vui lòng nhập số điện thoại');
      return;
    }

    const updated = venueStore.reserveSlot(slot.id, {
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      note: reserveNote.trim() || 'Đặt chỗ thủ công tại quầy',
    });

    if (updated) {
      if (onSlotUpdated) onSlotUpdated(updated);
      onClose();
    }
  };

  const handleUpdatePrice = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customPrice || customPrice <= 0) {
      setActionError('Giá ca phải lớn hơn 0đ');
      return;
    }

    const updated = venueStore.updateSlotPrice(slot.id, customPrice);
    if (updated) {
      if (onSlotUpdated) onSlotUpdated(updated);
      setActionSuccess('Đã cập nhật giá ca thành công');
      onClose();
    }
  };

  const handleLockMaintenance = () => {
    const reason = maintenanceReason.trim() || 'Bảo dưỡng sân định kỳ';
    const updated = venueStore.lockMaintenance(slot.id, reason);
    if (updated) {
      if (onSlotUpdated) onSlotUpdated(updated);
      onClose();
    }
  };

  const handleUnlockSlot = () => {
    const updated = venueStore.unlockSlot(slot.id);
    if (updated) {
      if (onSlotUpdated) onSlotUpdated(updated);
      onClose();
    }
  };

  const getStatusBadge = () => {
    switch (slot.status) {
      case 'available':
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
            Trống • Sẵn sàng
          </span>
        );
      case 'bookedApp':
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20">
            Đặt qua App • {slot.ticketId}
          </span>
        );
      case 'reservedManual':
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20">
            Giữ chỗ thủ công
          </span>
        );
      case 'maintenance':
        return (
          <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20">
            Khóa bảo trì
          </span>
        );
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-200"
      role="dialog"
      aria-modal="true"
    >
      <div className="relative w-full max-w-lg bg-white dark:bg-[#141B2D] rounded-3xl border border-slate-200 dark:border-slate-800 shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-start justify-between px-6 py-5 border-b border-slate-100 dark:border-slate-800 shrink-0">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                Quản lý Ca Sân
              </h2>
              {getStatusBadge()}
            </div>
            <div className="flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400">
              <span className="font-semibold text-slate-800 dark:text-slate-200">
                {slot.courtName}
              </span>
              <span>•</span>
              <span className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5 text-emerald-500" />
                {slot.startTime} - {slot.endTime}
              </span>
              <span>•</span>
              <span className="font-bold text-emerald-600 dark:text-emerald-400">
                {slot.price.toLocaleString('vi-VN')} đ
              </span>
              {slot.isPeak && (
                <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20">
                  Giờ vàng
                </span>
              )}
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            aria-label="Đóng"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Existing Slot Info (if booked or maintenance) */}
        {(slot.customerName || slot.ticketId || slot.note) && (
          <div className="mx-6 mt-4 p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 text-xs space-y-1 shrink-0">
            <div className="font-bold text-slate-700 dark:text-slate-300">
              Thông tin hiện tại:
            </div>
            {slot.ticketId && (
              <div className="text-slate-600 dark:text-slate-400">
                Mã vé App: <span className="font-mono font-bold text-emerald-600 dark:text-emerald-400">{slot.ticketId}</span>
              </div>
            )}
            {slot.customerName && (
              <div className="text-slate-600 dark:text-slate-400">
                Khách hàng: <span className="font-semibold text-slate-900 dark:text-white">{slot.customerName}</span> {slot.customerPhone ? `(${slot.customerPhone})` : ''}
              </div>
            )}
            {slot.note && (
              <div className="text-slate-500 dark:text-slate-400 italic">
                Ghi chú: {slot.note}
              </div>
            )}
          </div>
        )}

        {/* Tabs Bar */}
        <div className="px-6 pt-4 shrink-0">
          <div className="flex p-1 bg-slate-100 dark:bg-slate-900 rounded-2xl gap-1">
            <button
              type="button"
              data-testid="tab-reserve"
              onClick={() => {
                setActiveTab('reserve');
                setActionError('');
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                activeTab === 'reserve'
                  ? 'bg-white dark:bg-[#141B2D] text-slate-900 dark:text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Đặt Chỗ Thủ Công
            </button>
            <button
              type="button"
              data-testid="tab-price"
              onClick={() => {
                setActiveTab('price');
                setActionError('');
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                activeTab === 'price'
                  ? 'bg-white dark:bg-[#141B2D] text-slate-900 dark:text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Điều Chỉnh Giá Ca
            </button>
            <button
              type="button"
              data-testid="tab-maintenance"
              onClick={() => {
                setActiveTab('maintenance');
                setActionError('');
              }}
              className={`flex-1 py-2 text-xs font-bold rounded-xl transition-all ${
                activeTab === 'maintenance'
                  ? 'bg-white dark:bg-[#141B2D] text-slate-900 dark:text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Khóa / Mở Sân
            </button>
          </div>
        </div>

        {/* Feedback messages */}
        {actionError && (
          <div className="mx-6 mt-3 p-3 text-xs text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-950/40 rounded-xl border border-rose-200 dark:border-rose-900 shrink-0">
            {actionError}
          </div>
        )}
        {actionSuccess && (
          <div className="mx-6 mt-3 p-3 text-xs text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 rounded-xl border border-emerald-200 dark:border-emerald-900 shrink-0">
            {actionSuccess}
          </div>
        )}

        {/* Tab Content */}
        <div className="p-6 overflow-y-auto flex-1">
          {/* TAB 1: Reserve */}
          {activeTab === 'reserve' && (
            <form onSubmit={handleManualReserve} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                  Tên Khách Hàng *
                </label>
                <div className="relative">
                  <input
                    type="text"
                    data-testid="input-customer-name"
                    value={customerName}
                    onChange={(e) => {
                      setCustomerName(e.target.value);
                      if (actionError) setActionError('');
                    }}
                    placeholder="VD: Trịnh Thăng Bình"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                  />
                  <User className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                  Số Điện Thoại Liên Hệ *
                </label>
                <div className="relative">
                  <input
                    type="text"
                    data-testid="input-customer-phone"
                    value={customerPhone}
                    onChange={(e) => {
                      setCustomerPhone(e.target.value);
                      if (actionError) setActionError('');
                    }}
                    placeholder="VD: 0988 999 888"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                  />
                  <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                  Ghi Chú Đặt Chỗ
                </label>
                <textarea
                  value={reserveNote}
                  onChange={(e) => setReserveNote(e.target.value)}
                  placeholder="VD: Khách quen câu lạc bộ, đã cọc 50%"
                  rows={2}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                />
              </div>

              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-500 hover:text-slate-700 dark:text-slate-400"
                >
                  Đóng
                </button>
                <button
                  type="submit"
                  data-testid="btn-confirm-reserve"
                  className="px-5 py-2.5 rounded-xl text-xs font-bold bg-amber-500 hover:bg-amber-600 text-white shadow-xs shadow-amber-500/20 transition-all flex items-center gap-1.5"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Xác Nhận Giữ Chỗ</span>
                </button>
              </div>
            </form>
          )}

          {/* TAB 2: Update Price */}
          {activeTab === 'price' && (
            <form onSubmit={handleUpdatePrice} className="space-y-4">
              <div>
                <h3 className="text-sm font-bold text-slate-900 dark:text-white mb-1">
                  Điều chỉnh giá ca
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  Chọn mức giá nhanh hoặc nhập số tiền áp dụng cho ca thi đấu này
                </p>
              </div>

              {/* Quick chips */}
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                  Mức Giá Nhanh
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {QUICK_PRICES.map((price) => (
                    <button
                      key={price}
                      type="button"
                      data-testid={`price-chip-${price}`}
                      onClick={() => setCustomPrice(price)}
                      className={`py-2 px-3 rounded-xl text-xs font-bold border transition-all ${
                        customPrice === price
                          ? 'bg-emerald-500 text-white border-emerald-500 shadow-xs'
                          : 'bg-slate-50 dark:bg-slate-900 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-800 hover:border-emerald-500/50'
                      }`}
                    >
                      {(price / 1000).toLocaleString('vi-VN')}k đ
                    </button>
                  ))}
                </div>
              </div>

              {/* Custom Price Input */}
              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                  Giá Tùy Chỉnh (đ/h)
                </label>
                <div className="relative">
                  <input
                    type="number"
                    data-testid="input-custom-price"
                    value={customPrice}
                    onChange={(e) => setCustomPrice(parseInt(e.target.value, 10) || 0)}
                    step="10000"
                    min="0"
                    className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-500 transition-all"
                  />
                  <DollarSign className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-500 hover:text-slate-700 dark:text-slate-400"
                >
                  Đóng
                </button>
                <button
                  type="submit"
                  data-testid="btn-save-price"
                  className="px-5 py-2.5 rounded-xl text-xs font-bold bg-emerald-500 hover:bg-emerald-600 text-white shadow-xs shadow-emerald-500/20 transition-all flex items-center gap-1.5"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Lưu Giá Mới</span>
                </button>
              </div>
            </form>
          )}

          {/* TAB 3: Maintenance */}
          {activeTab === 'maintenance' && (
            <div className="space-y-4">
              {slot.status === 'maintenance' ? (
                <div className="space-y-4">
                  <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 flex items-start gap-3">
                    <AlertTriangle className="w-5 h-5 text-rose-600 dark:text-rose-400 shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-sm font-bold text-rose-700 dark:text-rose-300">
                        Ca sân này đang bị khóa bảo trì
                      </h4>
                      <p className="text-xs text-rose-600/90 dark:text-rose-400/90 mt-1">
                        Lý do: {slot.note || 'Bảo trì định kỳ mặt sân'}
                      </p>
                    </div>
                  </div>

                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    Mở lại sân sẽ chuyển trạng thái ca về &quot;Trống&quot; để khách hàng có thể đặt trên Mobile App hoặc quầy lễ tân.
                  </p>

                  <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-3">
                    <button
                      type="button"
                      onClick={onClose}
                      className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-500 hover:text-slate-700 dark:text-slate-400"
                    >
                      Đóng
                    </button>
                    <button
                      type="button"
                      data-testid="btn-unlock-slot"
                      onClick={handleUnlockSlot}
                      className="px-5 py-2.5 rounded-xl text-xs font-bold bg-emerald-500 hover:bg-emerald-600 text-white shadow-xs shadow-emerald-500/20 transition-all flex items-center gap-1.5"
                    >
                      <Unlock className="w-4 h-4" />
                      <span>Mở Lại Ca Trống</span>
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-start gap-3">
                    <Lock className="w-5 h-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                    <div>
                      <h4 className="text-sm font-bold text-amber-700 dark:text-amber-300">
                        Khóa sân bảo dưỡng kỹ thuật
                      </h4>
                      <p className="text-xs text-amber-600/90 dark:text-amber-400/90 mt-1">
                        Khóa khung giờ này sẽ ngăn không cho khách hàng đặt sân từ Mobile App.
                      </p>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                      Lý Do Khóa Bảo Trì
                    </label>
                    <input
                      type="text"
                      data-testid="input-maintenance-reason"
                      value={maintenanceReason}
                      onChange={(e) => setMaintenanceReason(e.target.value)}
                      placeholder="VD: Thay lưới, lau sàn, kiểm tra đèn chiếu sáng..."
                      className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900 text-sm text-slate-900 dark:text-white placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-rose-500/30 focus:border-rose-500 transition-all"
                    />
                  </div>

                  <div className="pt-3 border-t border-slate-100 dark:border-slate-800 flex items-center justify-end gap-3">
                    <button
                      type="button"
                      onClick={onClose}
                      className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-500 hover:text-slate-700 dark:text-slate-400"
                    >
                      Đóng
                    </button>
                    <button
                      type="button"
                      data-testid="btn-lock-maintenance"
                      onClick={handleLockMaintenance}
                      className="px-5 py-2.5 rounded-xl text-xs font-bold bg-rose-500 hover:bg-rose-600 text-white shadow-xs shadow-rose-500/20 transition-all flex items-center gap-1.5"
                    >
                      <Lock className="w-4 h-4" />
                      <span>Khóa Sân Bảo Trì</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default SlotActionModal;
