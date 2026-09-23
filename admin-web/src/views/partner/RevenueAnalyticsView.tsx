import React, { useState } from 'react';
import {
  TrendingUp,
  DollarSign,
  ShoppingBag,
  Download,
  Layers,
  CheckCircle2,
  Clock,
  Zap,
} from 'lucide-react';
import { useVenueStore } from '../../store/venueStore';
import { useAuthStore } from '../../store/authStore';

// 7-day seed trend for Tao Đàn / current venue
const WEEKLY_DATA = [
  { day: 'Thứ 2', short: 'T2', revenue: 2450000, bookings: 16 },
  { day: 'Thứ 3', short: 'T3', revenue: 2890000, bookings: 19 },
  { day: 'Thứ 4', short: 'T4', revenue: 3120000, bookings: 21 },
  { day: 'Thứ 5', short: 'T5', revenue: 3450000, bookings: 23 },
  { day: 'Thứ 6', short: 'T6', revenue: 4200000, bookings: 28 },
  { day: 'Thứ 7', short: 'T7', revenue: 5600000, bookings: 36 },
  { day: 'Chủ nhật', short: 'CN', revenue: 5850000, bookings: 38 },
];

export const RevenueAnalyticsView: React.FC = () => {
  const { transactions, bookings, venues } = useVenueStore();
  const { activeVenueId } = useAuthStore();
  const currentVenueId = activeVenueId || 'venue_01';
  const currentVenue = venues.find((v) => v.id === currentVenueId) || venues[0];

  const venueTransactions = transactions.filter((t) => t.venueId === currentVenueId);
  const venueBookings = bookings.filter((b) => b.venueId === currentVenueId);

  const [exportNotice, setExportNotice] = useState<string | null>(null);
  const [selectedDay, setSelectedDay] = useState<string | null>(null);

  // Financial Breakdown Calculations
  const courtRevenue = venueBookings.reduce((sum, b) => sum + b.price, 0);

  const posRevenue = venueTransactions
    .filter((t) => t.type === 'pos_service' && t.status === 'completed')
    .reduce((sum, t) => sum + t.amount, 0);

  const badmintonRevenue = venueBookings
    .filter((b) => b.sport === 'badminton')
    .reduce((sum, b) => sum + b.price, 0);

  const pickleballRevenue = venueBookings
    .filter((b) => b.sport === 'pickleball')
    .reduce((sum, b) => sum + b.price, 0);

  // Peak vs Off-peak
  // Peak is 17:00 - 21:00
  const peakRevenue = venueBookings
    .filter((b) => {
      const startHour = parseInt(b.timeSlot.split(':')[0], 10);
      return startHour >= 17 && startHour < 21;
    })
    .reduce((sum, b) => sum + b.price, 0);

  const offPeakRevenue = courtRevenue - peakRevenue;

  // Max revenue for bar height scale
  const maxDayRevenue = Math.max(...WEEKLY_DATA.map((d) => d.revenue));

  // CSV Export Handler
  const handleExportCSV = () => {
    const headers = ['ID', 'Ngày tạo', 'Khách hàng', 'Mô tả', 'Phương thức', 'Số tiền (VND)', 'Trạng thái'];
    const rows = venueTransactions.map((tx) => [
      tx.id,
      new Date(tx.createdAt).toLocaleString('vi-VN'),
      `"${tx.customerName.replace(/"/g, '""')}"`,
      `"${tx.description.replace(/"/g, '""')}"`,
      tx.paymentMethod.toUpperCase(),
      tx.amount,
      tx.status === 'completed' ? 'Hoàn tất' : 'Hoàn tiền',
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `bao_cao_doanh_thu_${currentVenueId}_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    setExportNotice(`Đã xuất file CSV thành công (${venueTransactions.length} giao dịch)!`);
    setTimeout(() => setExportNotice(null), 5000);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* 1. Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              {currentVenue ? currentVenue.name : 'CLB Tao Đàn'}
            </span>
            <span className="text-xs text-slate-400">• Báo cáo tài chính</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Báo cáo Doanh thu
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Báo cáo dòng tiền, phân chia nguồn thu tiền mặt / chuyển khoản và biểu đồ xu hướng.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="button"
            data-testid="btn-export-csv"
            onClick={handleExportCSV}
            className="glass-pill px-4 py-2.5 rounded-full text-xs font-bold text-slate-700 dark:text-slate-200 hover:text-emerald-600 dark:hover:text-emerald-400 shadow-xs hover:shadow-md transition-all flex items-center gap-2 cursor-pointer"
          >
            <Download className="w-4 h-4 text-emerald-500" />
            <span>Xuất file CSV / Excel</span>
          </button>
        </div>
      </div>

      {/* Export Notice */}
      {exportNotice && (
        <div
          role="status"
          className="p-4 rounded-[22px] glass-card bg-emerald-50/80 dark:bg-emerald-950/50 border border-emerald-500/30 text-emerald-800 dark:text-emerald-200 flex items-center gap-3 shadow-md"
        >
          <CheckCircle2 className="w-5 h-5 text-emerald-600 dark:text-emerald-400 shrink-0" />
          <span className="text-xs font-bold">{exportNotice}</span>
        </div>
      )}

      {/* 2. 7-Day Revenue Bar Chart Card with Glassmorphism */}
      <div className="rounded-[28px] glass-card p-6 shadow-xs space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <div>
            <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-emerald-500" />
              Doanh thu 7 ngày gần nhất
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Tổng quan biến động doanh thu theo tuần từ Thứ 2 đến Chủ nhật
            </p>
          </div>
          <div className="glass-pill px-3 py-1 rounded-full flex items-center gap-2 text-xs text-slate-500 dark:text-slate-400 font-semibold">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
            <span>Doanh thu thực nhận</span>
          </div>
        </div>

        {/* Bar Chart Representation */}
        <div className="pt-4 pb-2">
          <div className="grid grid-cols-7 gap-2 sm:gap-4 items-end h-64 border-b border-slate-100 dark:border-slate-800 pb-2">
            {WEEKLY_DATA.map((item) => {
              const heightPercent = Math.round((item.revenue / maxDayRevenue) * 100);
              const isSelected = selectedDay === item.day;
              return (
                <div
                  key={item.day}
                  onClick={() => setSelectedDay(item.day === selectedDay ? null : item.day)}
                  className="flex flex-col items-center gap-2 h-full justify-end group cursor-pointer"
                >
                  {/* Tooltip on hover or click */}
                  <div
                    className={`transition-all duration-200 ${
                      isSelected
                        ? 'opacity-100 scale-100'
                        : 'opacity-0 group-hover:opacity-100 scale-95 group-hover:scale-100'
                    }`}
                  >
                    <div className="bg-slate-900 dark:bg-slate-800 text-white text-[11px] font-bold px-2.5 py-1 rounded-xl shadow-lg whitespace-nowrap mb-1">
                      {item.revenue.toLocaleString('vi-VN')} đ
                    </div>
                  </div>

                  {/* Daily Bar */}
                  <div className="w-full max-w-[48px] bg-slate-100/80 dark:bg-slate-800/80 rounded-2xl p-1 flex items-end justify-center h-full shadow-inner">
                    <div
                      style={{ height: `${heightPercent}%` }}
                      className={`w-full rounded-xl transition-all duration-300 ${
                        isSelected
                          ? 'bg-gradient-to-t from-emerald-600 to-lime-400 shadow-md shadow-emerald-500/20 scale-105'
                          : 'bg-gradient-to-t from-emerald-500 to-teal-400 group-hover:from-emerald-400 group-hover:to-teal-300'
                      }`}
                    />
                  </div>

                  {/* Day Label */}
                  <div className="text-center">
                    <div className="text-xs font-bold text-slate-700 dark:text-slate-300">
                      {item.day}
                    </div>
                    <div className="text-[10px] text-slate-400 hidden sm:block">
                      {item.bookings} ca
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Selected Day Info */}
        <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400 glass-pill p-3.5 rounded-2xl">
          <span>Tổng doanh thu tuần qua: <strong className="text-slate-900 dark:text-white font-black">{WEEKLY_DATA.reduce((s, i) => s + i.revenue, 0).toLocaleString('vi-VN')} đ</strong></span>
          <span>Trung bình mỗi ngày: <strong className="text-slate-900 dark:text-white font-black">{Math.round(WEEKLY_DATA.reduce((s, i) => s + i.revenue, 0) / 7).toLocaleString('vi-VN')} đ</strong></span>
        </div>
      </div>

      {/* 3. Financial Breakdown Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* Card 1: Doanh thu tiền sân */}
        <div className="p-5 rounded-[26px] glass-card space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Doanh thu tiền sân
            </span>
            <div className="w-8 h-8 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-slate-900 dark:text-white tracking-tight">
            {courtRevenue.toLocaleString('vi-VN')} đ
          </div>
          <div className="text-xs text-emerald-600 dark:text-emerald-400 font-bold">
            {venueBookings.length} lượt đặt hôm nay
          </div>
        </div>

        {/* Card 2: Dịch vụ phụ trợ */}
        <div className="p-5 rounded-[26px] glass-card space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Dịch vụ phụ trợ
            </span>
            <div className="w-8 h-8 rounded-xl bg-cyan-500/10 text-cyan-600 dark:text-cyan-400 flex items-center justify-center">
              <ShoppingBag className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-slate-900 dark:text-white tracking-tight">
            {posRevenue.toLocaleString('vi-VN')} đ
          </div>
          <div className="text-xs text-cyan-600 dark:text-cyan-400 font-bold">
            Quầy nước & thuê vợt
          </div>
        </div>

        {/* Card 3: Cầu lông */}
        <div className="p-5 rounded-[26px] glass-card space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Cầu lông
            </span>
            <div className="w-8 h-8 rounded-xl bg-blue-500/10 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <Layers className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-slate-900 dark:text-white tracking-tight">
            {badmintonRevenue.toLocaleString('vi-VN')} đ
          </div>
          <div className="text-xs text-blue-600 dark:text-blue-400 font-bold">
            4 sân cầu lông chuẩn
          </div>
        </div>

        {/* Card 4: Pickleball */}
        <div className="p-5 rounded-[26px] glass-card space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
              Pickleball
            </span>
            <div className="w-8 h-8 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center">
              <Zap className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xl font-black text-slate-900 dark:text-white tracking-tight">
            {pickleballRevenue.toLocaleString('vi-VN')} đ
          </div>
          <div className="text-xs text-amber-600 dark:text-amber-400 font-bold">
            4 sân Pickleball
          </div>
        </div>

        {/* Card 5: Giờ vàng vs Giờ ưu đãi */}
        <div className="p-5 rounded-[26px] glass-card space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider truncate">
              Giờ vàng vs Giờ ưu đãi
            </span>
            <div className="w-8 h-8 rounded-xl bg-purple-500/10 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <Clock className="w-4 h-4" />
            </div>
          </div>
          <div className="text-xs font-bold text-slate-900 dark:text-white">
            <span className="text-purple-600 dark:text-purple-400 font-black">Vàng:</span> {peakRevenue.toLocaleString('vi-VN')} đ
          </div>
          <div className="text-xs text-slate-500 dark:text-slate-400 font-medium">
            Ưu đãi: {offPeakRevenue.toLocaleString('vi-VN')} đ
          </div>
        </div>
      </div>

      {/* 4. Transaction Log Table */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
              <Layers className="w-5 h-5 text-emerald-500" />
              Lịch sử giao dịch gần nhất
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Nhật ký chi tiết các giao dịch đặt sân và hóa đơn POS tại cụm sân
            </p>
          </div>
          <span className="glass-pill text-xs font-bold px-3 py-1 rounded-full text-slate-700 dark:text-slate-300">
            {venueTransactions.length} giao dịch
          </span>
        </div>

        <div className="rounded-[28px] glass-card p-2 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="border-b border-slate-200/60 dark:border-slate-800 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                <tr>
                  <th className="py-3.5 px-4">Mã GD</th>
                  <th className="py-3.5 px-4">Thời Gian</th>
                  <th className="py-3.5 px-4">Khách Hàng</th>
                  <th className="py-3.5 px-4">Khoản Mục</th>
                  <th className="py-3.5 px-4">Phương Thức</th>
                  <th className="py-3.5 px-4 text-right">Số Tiền</th>
                  <th className="py-3.5 px-4 text-center">Trạng Thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                {venueTransactions.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-slate-400 text-xs">
                      Chưa có giao dịch nào được ghi nhận
                    </td>
                  </tr>
                ) : (
                  venueTransactions.map((tx) => (
                    <tr
                      key={tx.id}
                      className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors"
                    >
                      <td className="py-3.5 px-4">
                        <span className="font-mono text-xs font-bold text-slate-600 dark:text-slate-400">
                          {tx.id}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-xs text-slate-500 dark:text-slate-400">
                        {new Date(tx.createdAt).toLocaleTimeString('vi-VN', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })} - {new Date(tx.createdAt).toLocaleDateString('vi-VN')}
                      </td>
                      <td className="py-3.5 px-4 font-bold text-slate-900 dark:text-white">
                        {tx.customerName}
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 dark:text-slate-300 max-w-xs truncate">
                        {tx.description}
                      </td>
                      <td className="py-3.5 px-4">
                        <span className="text-[11px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full glass-pill text-slate-700 dark:text-slate-300">
                          {tx.paymentMethod}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-right font-black text-slate-900 dark:text-white">
                        {tx.amount.toLocaleString('vi-VN')} đ
                      </td>
                      <td className="py-3.5 px-4 text-center">
                        <span
                          className={`inline-flex items-center gap-1 text-[10px] font-bold px-2.5 py-0.5 rounded-full border ${
                            tx.status === 'completed'
                              ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                              : 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20'
                          }`}
                        >
                          {tx.status === 'completed' ? 'Hoàn tất' : 'Đã hoàn tiền'}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RevenueAnalyticsView;
