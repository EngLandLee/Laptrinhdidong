import React from 'react';
import {
  Building2,
  Layers,
  CalendarCheck,
  TrendingUp,
  DollarSign,
  Activity,
  ArrowUpRight,
  ShieldCheck,
  Clock,
  Sparkles,
  CheckCircle2,
  SunMedium,
} from 'lucide-react';
import { useVenueStore } from '../../store/venueStore';

export const SuperAdminDashboardView: React.FC = () => {
  const { venues, courts, bookings, transactions } = useVenueStore();

  // Metrics
  const activeVenuesCount = venues.filter((v) => v.isActive).length;
  const totalCourtsCount = courts.length > 0 ? courts.length : venues.reduce((acc, v) => acc + (v.totalCourts || 0), 0);
  const totalBookingsToday = bookings.length;

  // Calculate platform revenue: sum of transactions or bookings
  const bookingRevenue = bookings.reduce((sum, b) => sum + b.price, 0);
  const txRevenue = transactions.reduce((sum, tx) => sum + (tx.status === 'completed' ? tx.amount : 0), 0);
  const totalRevenue = Math.max(bookingRevenue, txRevenue);

  // Venue statistics for distribution
  const venueStats = venues.map((venue) => {
    const venueCourts = courts.filter((c) => c.venueId === venue.id);
    const count = venueCourts.length > 0 ? venueCourts.length : venue.totalCourts || 0;
    const venueBookings = bookings.filter((b) => b.venueId === venue.id);
    const revenue = venueBookings.reduce((sum, b) => sum + b.price, 0);
    const percentage = totalCourtsCount > 0 ? Math.round((count / totalCourtsCount) * 100) : 25;

    return {
      ...venue,
      courtCount: count,
      bookingCount: venueBookings.length,
      revenue,
      percentage,
    };
  });

  return (
    <div className="space-y-6 pb-12">
      {/* 1. Header & Pill Controls Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-indigo-500 animate-pulse" />
              Toàn Sàn SportHub 🏄‍♂️
            </span>
            <span className="text-xs text-slate-400">• Trung tâm Điều hành</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Tổng quan Sàn
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Báo cáo tổng quan toàn bộ nền tảng SportHub và tình trạng hoạt động cụm sân.
          </p>
        </div>

        {/* Floating Pill Info Bar */}
        <div className="flex items-center flex-wrap gap-2.5">
          <div className="glass-pill px-3.5 py-1.5 rounded-full text-xs font-semibold text-slate-600 dark:text-slate-300 flex items-center gap-2">
            <SunMedium className="w-4 h-4 text-amber-500" />
            <span>Hôm nay</span>
            <span className="text-slate-300 dark:text-slate-600">•</span>
            <span className="text-[11px] text-slate-500 dark:text-slate-400">
              {new Date().toLocaleDateString('vi-VN', {
                weekday: 'long',
                day: 'numeric',
                month: 'long',
              })}
            </span>
          </div>

          <div className="glass-pill px-3 py-1.5 rounded-full text-xs font-bold text-emerald-600 dark:text-emerald-400 flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
            <span>5/5 Cụm sân online</span>
          </div>
        </div>
      </div>

      {/* 2. 4 Hero KPI Cards with Dashboards V2 Wave Gradients */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        {/* Card 1: Active Venues (Lime Green Wave) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-[#d9f99d]/90 via-[#bef264]/80 to-[#a3e635]/60 dark:from-[#14532d]/80 dark:via-[#166534]/70 dark:to-[#052e16]/90 border border-lime-300/60 dark:border-lime-700/40 shadow-lg shadow-lime-500/10 hover:-translate-y-1 transition-all group">
          <div className="absolute -right-6 -bottom-6 w-36 h-36 opacity-30 pointer-events-none group-hover:scale-110 transition-transform">
            <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
              <path
                fill="#4d7c0f"
                d="M44.7,-76.4C58.8,-69.2,71.8,-59.1,79.6,-45.8C87.4,-32.6,90,-16.3,88.5,-0.9C86.9,14.6,81.2,29.1,72.7,41.9C64.2,54.7,52.8,65.8,39.3,72.9C25.8,80.1,10.2,83.3,-4.8,81.6C-19.8,79.9,-34.2,73.3,-47.4,64.7C-60.6,56.1,-72.6,45.5,-79.8,32.1C-87,18.7,-89.4,2.5,-86.6,-12.7C-83.8,-27.9,-75.8,-42.1,-64.3,-50.1C-52.8,-58.1,-37.8,-59.9,-23.8,-67.2C-9.8,-74.5,3.2,-87.3,17.4,-88.2C31.6,-89.1,47,-78.1,44.7,-76.4Z"
                transform="translate(100 100)"
              />
            </svg>
          </div>

          <div className="flex items-center justify-between relative z-10">
            <div className="w-10 h-10 rounded-2xl bg-black/10 dark:bg-black/30 backdrop-blur-md flex items-center justify-center text-slate-900 dark:text-white font-bold">
              <Building2 className="w-5 h-5" />
            </div>
            <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-black/10 dark:bg-black/30 text-slate-900 dark:text-lime-200 backdrop-blur-xs">
              100% Hoạt động
            </span>
          </div>

          <div className="mt-5 relative z-10">
            <div className="text-xs font-bold uppercase tracking-wider text-slate-800/80 dark:text-lime-300">
              Tổng Cụm Sân Hoạt Động
            </div>
            <div className="mt-1 flex items-baseline gap-2">
              <span className="text-3xl sm:text-4xl font-black tracking-tight text-slate-950 dark:text-white">
                {activeVenuesCount}
              </span>
              <span className="text-xs font-bold text-slate-700/80 dark:text-lime-200">
                / {venues.length} cụm sân
              </span>
            </div>
            <div className="mt-2 text-xs font-medium text-slate-800/80 dark:text-slate-300 flex items-center gap-1">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>Đầy đủ tại Q1, BT, Q2, Q7, TB</span>
            </div>
          </div>
        </div>

        {/* Card 2: Total Sports Courts (Peach / Coral Wave) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-[#ffedd5]/90 via-[#fed7aa]/80 to-[#fdba74]/60 dark:from-[#7c2d12]/80 dark:via-[#9a3412]/70 dark:to-[#431407]/90 border border-orange-300/60 dark:border-orange-700/40 shadow-lg shadow-orange-500/10 hover:-translate-y-1 transition-all group">
          <div className="absolute -right-6 -bottom-6 w-36 h-36 opacity-30 pointer-events-none group-hover:scale-110 transition-transform">
            <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
              <path
                fill="#ea580c"
                d="M48.7,-81.4C63.4,-75.3,75.9,-63.3,84.1,-48.7C92.3,-34.1,96.2,-17,94.4,-0.9C92.7,15.1,85.2,30.2,75.7,43.2C66.1,56.2,54.4,67.1,40.7,74.7C27,82.3,11.3,86.6,-4.2,85.1C-19.7,83.6,-34.9,76.3,-48.1,67.3C-61.2,58.2,-72.3,47.4,-78.9,34.2C-85.5,21,-87.7,5.5,-85.2,-9.2C-82.8,-23.9,-75.7,-37.8,-65.4,-48.3C-55.2,-58.8,-41.8,-65.9,-28.3,-72.8C-14.7,-79.8,0.9,-86.6,17.2,-87.8C33.6,-89,51.8,-84.6,48.7,-81.4Z"
                transform="translate(100 100)"
              />
            </svg>
          </div>

          <div className="flex items-center justify-between relative z-10">
            <div className="w-10 h-10 rounded-2xl bg-black/10 dark:bg-black/30 backdrop-blur-md flex items-center justify-center text-slate-900 dark:text-white font-bold">
              <Layers className="w-5 h-5" />
            </div>
            <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-black/10 dark:bg-black/30 text-slate-900 dark:text-orange-200 backdrop-blur-xs">
              Tiêu chuẩn
            </span>
          </div>

          <div className="mt-5 relative z-10">
            <div className="text-xs font-bold uppercase tracking-wider text-slate-800/80 dark:text-orange-300">
              Tổng Sân Thể Thao
            </div>
            <div className="mt-1 flex items-baseline gap-2">
              <span className="text-3xl sm:text-4xl font-black tracking-tight text-slate-950 dark:text-white">
                {totalCourtsCount}
              </span>
              <span className="text-xs font-bold text-slate-700/80 dark:text-orange-200">
                sân tiêu chuẩn
              </span>
            </div>
            <div className="mt-2 text-xs font-medium text-slate-800/80 dark:text-slate-300 flex items-center gap-1">
              <Sparkles className="w-3.5 h-3.5" />
              <span>Cầu lông & Pickleball chuẩn thi đấu</span>
            </div>
          </div>
        </div>

        {/* Card 3: Today's Bookings (Cyan / Blue Theme) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-cyan-100/90 via-sky-100/80 to-blue-200/60 dark:from-cyan-950/80 dark:via-sky-950/70 dark:to-blue-950/90 border border-cyan-300/60 dark:border-cyan-700/40 shadow-lg shadow-cyan-500/10 hover:-translate-y-1 transition-all group">
          <div className="flex items-center justify-between relative z-10">
            <div className="w-10 h-10 rounded-2xl bg-black/10 dark:bg-black/30 backdrop-blur-md flex items-center justify-center text-slate-900 dark:text-white font-bold">
              <CalendarCheck className="w-5 h-5" />
            </div>
            <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-black/10 dark:bg-black/30 text-slate-900 dark:text-cyan-200 backdrop-blur-xs">
              Hôm nay
            </span>
          </div>

          <div className="mt-5 relative z-10">
            <div className="text-xs font-bold uppercase tracking-wider text-slate-800/80 dark:text-cyan-300">
              Lượt Đặt Sân Hôm Nay
            </div>
            <div className="mt-1 flex items-baseline gap-2">
              <span className="text-3xl sm:text-4xl font-black tracking-tight text-slate-950 dark:text-white">
                {totalBookingsToday}
              </span>
              <span className="text-xs font-bold text-slate-700/80 dark:text-cyan-200">
                lượt đặt app
              </span>
            </div>
            <div className="mt-2 text-xs font-medium text-slate-800/80 dark:text-slate-300 flex items-center gap-1">
              <ArrowUpRight className="w-3.5 h-3.5" />
              <span>+24% so với trung bình tuần</span>
            </div>
          </div>
        </div>

        {/* Card 4: Platform Revenue (Vibrant Orange / Amber Wave) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-[#fb923c] to-[#ea580c] text-white shadow-lg shadow-orange-500/20 hover:-translate-y-1 transition-all group flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <div className="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white font-bold">
              <DollarSign className="w-5 h-5" />
            </div>
            <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-white/20 text-white backdrop-blur-xs">
              Toàn sàn
            </span>
          </div>

          <div className="mt-5">
            <div className="text-xs font-semibold text-orange-100 uppercase tracking-wider">
              Doanh Thu Toàn Sàn
            </div>
            <div className="mt-1 flex items-baseline gap-1">
              <span className="text-2xl sm:text-3xl font-black tracking-tight text-white">
                {totalRevenue.toLocaleString('vi-VN')}
              </span>
              <span className="text-sm font-bold text-orange-100">đ</span>
            </div>
            <div className="mt-2 text-xs text-orange-100 flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>Thanh toán ví điện tử & tiền mặt</span>
            </div>
          </div>
        </div>
      </div>

      {/* 3. Mid Section: Venue Distribution & Platform Activity Stream */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Venue Distribution Cards */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
                <Building2 className="w-5 h-5 text-emerald-500" />
                Phân Bố & Công Suất Cụm Sân
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Thống kê quy mô sân và doanh thu phân bổ trên các cụm sân trọng điểm
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {venueStats.map((venue) => (
              <div
                key={venue.id}
                className="p-5 rounded-[24px] glass-card flex flex-col justify-between space-y-4"
              >
                <div>
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <div>
                      <span className="glass-pill px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300">
                        {venue.district}
                      </span>
                      <h3 className="text-sm font-black text-slate-900 dark:text-white mt-1.5 line-clamp-1">
                        {venue.name}
                      </h3>
                    </div>
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-bold shrink-0 border ${
                        venue.isActive
                          ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                          : 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20'
                      }`}
                    >
                      {venue.isActive ? 'Hoạt động' : 'Tạm dừng'}
                    </span>
                  </div>

                  {/* Sports tags */}
                  <div className="flex items-center gap-1.5 flex-wrap mt-2 mb-2">
                    {venue.sports.map((sp) => (
                      <span
                        key={sp}
                        className="text-[11px] px-2.5 py-0.5 rounded-full glass-pill text-slate-600 dark:text-slate-300 font-semibold"
                      >
                        {sp === 'badminton' ? 'Cầu lông' : sp === 'pickleball' ? 'Pickleball' : sp}
                      </span>
                    ))}
                  </div>
                </div>

                <div>
                  {/* Stats line */}
                  <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400 mb-1.5 font-medium">
                    <span>Quy mô: <b className="text-slate-900 dark:text-white font-bold">{venue.courtCount} sân</b></span>
                    <span>Tỷ trọng: <b className="text-emerald-600 dark:text-emerald-400 font-bold">{venue.percentage}%</b></span>
                  </div>

                  {/* Pill progress bar */}
                  <div className="w-full h-2.5 rounded-full bg-slate-100 dark:bg-slate-800 p-0.5 shadow-inner">
                    <div
                      className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-lime-500 transition-all duration-500"
                      style={{ width: `${Math.min(venue.percentage * 2.5, 100)}%` }}
                    />
                  </div>

                  {/* Price & hotline */}
                  <div className="flex items-center justify-between text-xs pt-3 mt-3 border-t border-slate-100 dark:border-slate-800/80 text-slate-400">
                    <span>Hotline: {venue.hotline}</span>
                    <span className="font-bold text-slate-800 dark:text-slate-200">
                      {venue.baseHourlyRate.toLocaleString('vi-VN')} đ/h
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right Col: Platform Activity Stream */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
                <Activity className="w-5 h-5 text-cyan-500" />
                Dòng Hoạt Động Trực Tiếp
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Lượt đặt vé theo thời gian thực từ Mobile App
              </p>
            </div>
          </div>

          <div className="rounded-[28px] glass-card p-5 space-y-3.5">
            {bookings.length === 0 ? (
              <div className="py-12 text-center text-slate-400 text-xs">
                Chưa có lượt đặt sân nào hôm nay
              </div>
            ) : (
              bookings.map((ticket) => (
                <div
                  key={ticket.id}
                  className="p-3.5 rounded-2xl bg-white/70 dark:bg-slate-900/50 border border-slate-100 dark:border-slate-800/80 space-y-2 hover:border-slate-300 dark:hover:border-slate-700 transition-all shadow-xs"
                >
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-mono font-bold text-emerald-600 dark:text-emerald-400">
                      {ticket.id}
                    </span>
                    <span className="inline-flex items-center gap-1 text-[10px] font-bold uppercase px-2.5 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-300 border border-emerald-500/20">
                      <CheckCircle2 className="w-3 h-3" />
                      {ticket.paymentMethod ? ticket.paymentMethod.toUpperCase() : 'ĐÃ THANH TOÁN'}
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-sm font-bold text-slate-900 dark:text-white">
                        {ticket.customerName}
                      </div>
                      <div className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                        <span>{ticket.courtName}</span>
                        <span>•</span>
                        <span>{ticket.venueName.replace('CLB Cầu Lông & Pickleball ', '')}</span>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-black text-slate-800 dark:text-slate-100">
                        {ticket.price.toLocaleString('vi-VN')} đ
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center justify-between pt-1.5 border-t border-slate-100 dark:border-slate-800/60 text-[11px] text-slate-400">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3 text-slate-400" />
                      {ticket.timeSlot}
                    </span>
                    <span className="capitalize text-slate-500 dark:text-slate-400 font-semibold">
                      {ticket.sport === 'badminton' ? 'Cầu lông' : ticket.sport}
                    </span>
                  </div>
                </div>
              ))
            )}

            <div className="pt-2 text-center">
              <span className="text-xs text-slate-400 flex items-center justify-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
                Đồng bộ tự động với hệ thống Mobile SportHub
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SuperAdminDashboardView;
