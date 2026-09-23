# Design Specification: SportHub Partner Web Portal (Trang Web Quản Trị Cụm Sân)

**Date:** 2026-09-07  
**Author:** Google DeepMind Assistant & Quoc Anh  
**Status:** Approved  
**Target:** SportHub Mobile & Web (Flutter 3.x, Dart 3.x)

---

## 1. Overview & Objectives

SportHub previously featured an Android-first smartphone viewport frame (`maxWidth: 420px`) on Web/Desktop. While ideal for simulating the player's mobile experience, venue owners and front-desk receptionists need a full-screen, widescreen-optimized **Partner Web Portal** on computer monitors to manage court schedules across 8+ courts, handle rapid check-in at the front desk, and inspect financial metrics.

### Core Goals
1. **Integrated Responsive Web Architecture:** On wide desktop screens (`width >= 800px`), when in Venue Owner Mode, the app seamlessly expands into a full-width desktop SaaS portal with a navigation sidebar and rich data views, without being constrained to the 420px phone mockup.
2. **Layout Preview Flexibility:** Provide a prominent toggle button `[💻 Bản Web Desktop / 📱 Bản Mobile Frame]` allowing venue owners to preview both the full desktop management portal and the mobile app view.
3. **Four Core Management Modules:**
   - **Module 1: Dashboard Overview (Tổng quan):** Real-time KPI cards, live booking feed, and instant operational shortcuts.
   - **Module 2: Master Court Schedule Matrix (Lịch sân mở rộng):** Widescreen matrix displaying 16 hours x 8 courts simultaneously with quick reservation and pricing adjustments.
   - **Module 3: Front-Desk POS & Check-in (Quầy Lễ tân Soát vé & Bán nước/thuê vợt):** Rapid QR/ticket ID check-in with keyboard enter shortcut and add-on sales counter.
   - **Module 4: Financial Analytics (Doanh thu & Báo cáo):** Multi-day revenue charts, sport-type revenue breakdowns, and transaction tables.
4. **Reactive State Sharing:** 100% synchronized with existing `VenueOwnerStore`, `NotificationStore`, and `AuthStore`.
5. **Theme Support:** Fully adaptive to both **Fresh Athletic Light Theme** and **Sporty Dark Luxury**.

---

## 2. Architecture & Layout Structure

### 2.1 Responsive Routing & Wrapper
- Location: `lib/presentation/widgets/responsive_mobile_wrapper.dart`
- Adds a reactive `ValueNotifier<bool> isWebDesktopViewNotifier = ValueNotifier<bool>(true);` in `VenueOwnerStore`.
- Decision logic:
  - If `VenueOwnerStore.instance.isOwnerMode` is `true` AND `constraints.maxWidth >= 800` AND `VenueOwnerStore.instance.isWebDesktopView` is `true`:
    - Renders `PartnerWebScaffold` full-screen.
  - Otherwise:
    - Renders existing `ResponsiveMobileWrapper` smartphone frame (or native mobile screen if on phone).

### 2.2 Component Hierarchy
```
PartnerWebScaffold
├── Left Navigation Sidebar (250px width, sticky)
│   ├── Venue Brand Header (Tao Đàn, 8 sân)
│   ├── Navigation Menu Items (Dashboard, Schedule, POS, Revenue)
│   └── Bottom Tools (Theme Switcher, Mobile Preview Toggle, Exit to Player Mode)
└── Main Workspace Area (Expanded)
    ├── Top App Bar (Breadcrumb, Search, Status Pills, Notification Bell, Staff Profile)
    └── Active View (IndexedStack or switch)
        ├── PartnerWebDashboardView
        ├── PartnerWebScheduleView
        ├── PartnerWebPosView
        └── PartnerWebRevenueView
```

---

## 3. Detailed Modules & Visual Design

### 3.1 Sidebar Navigation (`PartnerWebSidebar`)
- Width: 250px with subtle right border `AppColors.cardBorder`.
- Items:
  - `Key('web_nav_dashboard')`: "Tổng quan", icon `Icons.dashboard_rounded`.
  - `Key('web_nav_schedule')`: "Lịch sân Master", icon `Icons.calendar_month_rounded`.
  - `Key('web_nav_pos')`: "Quầy lễ tân & Soát vé", icon `Icons.point_of_sale_rounded`.
  - `Key('web_nav_revenue')`: "Báo cáo Doanh thu", icon `Icons.analytics_rounded`.
- Footer:
  - Theme toggle button (`Key('web_theme_toggle')`).
  - View mode switcher `[📱 Xem dạng Mobile]` (`Key('web_toggle_mobile_view')`).
  - `[🔄 Quay lại Chế độ Người Chơi]` (`Key('web_exit_owner_mode_button')`).

### 3.2 Top Bar (`PartnerWebTopBar`)
- Breadcrumbs indicating active module.
- Quick status indicators: "Tỷ lệ lấp đầy: 81.2%", "8/8 Sân đang mở".
- Interactive Notification Bell (`Key('web_topbar_notification_bell')`) connected to `NotificationStore`.
- Staff avatar with receptionist name "Trần Văn (Quản lý ca)".

### 3.3 Module 1: Dashboard Overview (`PartnerWebDashboardView`)
- 4 Large KPI Cards:
  1. **Tổng doanh thu hôm nay:** `3.450.000 đ` (+18% so với hôm qua).
  2. **Số ca đã đặt:** `24 / 32 ca`.
  3. **Tỷ lệ lấp đầy:** `75.0%`.
  4. **Khách đã check-in:** `19 / 24 khách`.
- 2-Column Desktop Grid:
  - Left (60%): Live Court Availability Overview (quick grid of 8 courts for the current hour with status badges).
  - Right (40%): Live Booking & Activity Feed (realtime log of new bookings, phone reservations, and check-ins).
- Quick Action Shortcuts:
  - `[📞 Giữ chỗ nhanh]`
  - `[🔒 Khóa sân bảo trì]`
  - `[📷 Soát vé QR]`

### 3.4 Module 2: Master Court Schedule Matrix (`PartnerWebScheduleView`)
- High-density matrix displaying all 8 courts across columns and 16 hours (06:00 - 22:00) down rows.
- Filter toolbar:
  - Sport filter tabs (`Tất cả`, `🏸 Sân Cầu Lông 1-4`, `🎾 Sân Pickleball 5-8`).
  - Shift filter chips (`Tất cả`, `Ca Sáng 06-12h`, `Ca Chiều 12-17h`, `Ca Tối 17-22h`).
- Interactive slot cells:
  - Color-coded: Emerald (`bookedApp`), Amber (`reservedManual`), Red (`maintenance`), Theme Surface (`available`).
  - Displays time, price, customer name/phone, peak/off-peak tag.
  - Clicking opens modal dialog for:
    - Reserving slot for walk-in/call customer.
    - Custom price adjustment with preset chips (80k, 120k, 150k, 180k, 240k).
    - Locking/unlocking court maintenance.

### 3.5 Module 3: Front-Desk POS & Check-in (`PartnerWebPosView`)
- Rapid Check-in Bar:
  - Large search/input field (`Key('web_pos_ticket_input')`) accepting barcode scanner input or keyboard typing.
  - Pressing `Enter` or clicking `[Check-in ngay]` immediately validates ticket and updates store.
- Today's Arrivals Table:
  - Columns: Khách hàng, Số điện thoại, Sân, Khung giờ, Mã vé, Dịch vụ kèm theo, Trạng thái, Thao tác.
  - One-click `[Xác nhận]` action button (`Key('web_confirm_checkin_${ticketId}')`).
- Add-on Quick POS Counter:
  - Cards for quick sales: Pocari Sweat (20k), Nước suối (10k), Revive (18k), Thuê vợt (50k), Hộp bóng (60k).
  - Increment/decrement counters with realtime total calculation.

### 3.6 Module 4: Financial Analytics (`PartnerWebRevenueView`)
- 7-Day Revenue Bar Chart with daily totals and breakdown.
- Metric summaries:
  - Doanh thu từ tiền sân vs Doanh thu dịch vụ phụ trợ.
  - Doanh thu theo môn thể thao (Cầu lông vs Pickleball).
  - Tỷ lệ ca giờ vàng (Peak) vs Ca ưu đãi (Off-peak).
- Detailed transaction log table with date/time, customer name, amount, payment method (App VietQR vs Tiền mặt tại quầy).

---

## 4. State Integration & Consistency

- Directly connects to `VenueOwnerStore.instance`:
  - `slotsNotifier` for schedule matrix and occupancy rates.
  - `checkInTicket(ticketId)` for POS desk operations.
  - `reserveSlot(...)` and `updateSlotPrice(...)` for court adjustments.
- Directly connects to `NotificationStore.instance` for live alerts and badges.
- Directly connects to `ThemeStore.instance` for dynamic colors (`AppColors.surface`, `AppColors.background`, etc.).

---

## 5. Verification & Test Plan

1. **Unit & Widget Tests:**
   - `test/presentation/screens/partner_web_portal_test.dart`:
     - Test `PartnerWebScaffold` renders sidebar with all 4 navigation items.
     - Test clicking sidebar items switches active views (Dashboard, Schedule, POS, Revenue).
     - Test view mode switcher toggles between Web Desktop mode and Mobile Frame preview.
     - Test rapid POS check-in verifies ticket and updates check-in status.
     - Test schedule matrix interactions (reserve slot, lock maintenance, update price).
2. **Analyzer & Regressions:**
   - Zero analyzer issues (`flutter analyze`).
   - All existing 200 tests pass without regression.
