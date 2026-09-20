# Design Spec: Partner Dashboard V2 Redesign (Glassmorphism & Micro-interactions)

- **Date:** 2026-09-20
- **Author:** Antigravity AI
- **Target Component:** `admin-web/src/views/partner/PartnerDashboardView.tsx`
- **Design Reference:** Code XR "Dashboards V2" (Glassy Buttons, React, CSS, smooth micro-interactions, wave/blob gradient cards, spline bezier curve chart, progress bars, and glassy pills)

---

## 1. Overview & Goals
Redesign the Partner Venue Owner Dashboard on the Web Admin (`admin-web/src/views/partner/PartnerDashboardView.tsx`) to match the visual language of "Dashboards V2":
- Aesthetic: Modern Glassmorphism (`backdrop-blur-md`, subtle border glows, rounded pill buttons, smooth hover transitions).
- Palette: Fresh lime green wave gradients (`#d9f99d` / `#bef264`), soft peach/coral wave gradients (`#ffedd5` / `#fed7aa`), vibrant coral/orange accent, and sleek dark mode glass accents.
- Responsive & Interactive: Retains 100% store state integration (`useVenueStore`, `useAuthStore`) and satisfies all test expectations in `PartnerScheduleViews.test.tsx` (81/81 tests passing).

---

## 2. Component Architecture & Sections

### Section 1: Header & Quick Actions Bar
- **Left:** Greeting "Hi Quản lý Tao Đàn 👋" (or current venue name), subtext "Chào mừng bạn trở lại hệ thống vận hành!".
- **Right Pill Group:**
  - `+ Giữ chỗ`: Link to `/partner/schedule`.
  - `+ Thêm sân`: Quick action button to trigger `AddCourtModal`.
  - Search input pill with search icon.
  - Live Weather & Time Widget pill: `10:37 AM • Nắng ráo 29°C`.

### Section 2: 4 Hero KPI Cards
- **Card 1 (Lime Green Wave Gradient):**
  - Icon badge: Dollar / Spark.
  - Value: `totalRevenueToday.toLocaleString('vi-VN')} đ` (Label: `Doanh thu hôm nay`).
  - Badge / Subtext: `+18.5% so với hôm qua` with spark indicator.
  - Background: Soft lime gradient with organic SVG wave blob overlay.
- **Card 2 (Peach / Coral Wave Gradient):**
  - Icon badge: Calendar / Bookmark.
  - Value: `{bookedSlotsCount} ca` (Label: `Số ca đã đặt`).
  - Subtext: `{appBookings} qua App • {posBookings} tại quầy`.
  - Background: Peach gradient with organic wave blob overlay.
- **Card 3 (Dashed Glassy Widget):**
  - Border: Dashed translucent (`border-dashed border-2 border-slate-300 dark:border-slate-700`).
  - Title: "Tạo thêm sân / tiện ích nhanh".
  - Action button: `+ Thêm tiện ích / sân mới` (opens `AddCourtModal`).
- **Card 4 (Vibrant Coral / Orange Card):**
  - Title: "SportHub Partner Pro".
  - Subtext: "Vận hành tự động & Đồng bộ tức thời".
  - Status pill: `Đang kích hoạt • Hỗ trợ 24/7`.

### Section 3: Middle Section - Spline Curve Chart & Side Widgets
- **Left (2 cols): Interactive Multi-Node Spline Bezier Chart ("Track time" style):**
  - Day columns: `Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun`.
  - Dual bezier spline paths (Coral curve & Lime curve) with gradient area fill.
  - Floating pill node badges (`8h`, `12 ca`, `6 ca`, `14 ca`, `2h`, `1h`) positioned along key data vertices.
  - Central floating glassy filter switcher pill: `Ca đặt` (Slots) | `Doanh thu` (Revenue).
  - Vertical dashed indicator guidelines.
- **Right (1 col): Side Widgets:**
  - **Widget A: "Tỷ lệ lấp đầy theo môn" (Lime Theme):**
    - Label: `Tỷ lệ lấp đầy`.
    - Progress bars: Cầu lông (85%), Pickleball (92%), Giờ vàng (78%).
    - Styled as smooth pill-shaped progress bars with lime green fill.
  - **Widget B: "Quầy soát vé & Check-in" (Peach Theme):**
    - Label: `Khách đã check-in`.
    - Counter: `{checkedInCount} / {venueBookings.length} khách`.
    - Action: Link to `/partner/pos` (Quầy soát vé QR).
    - Status badge: `Soát vé mã QR tại quầy`.

### Section 4: Bottom Table - "Last notes" / Court Status & Schedule
- **Glassy Table Card:**
  - Title: "Lịch đặt sân & Trạng thái 8 cụm sân".
  - Table headers: `Cụm sân`, `Môn thể thao`, `Công suất / Tiến độ`, `Giá thuê`, `Trạng thái trực tiếp`.
  - Rows:
    - `Sân Cầu Lông 01`, `Sân Cầu Lông 02`... with blue sport badges, progress percentage pills (`43%`, `86%`, etc.).
    - `Sân Pickleball 05`, `Sân Pickleball 06`... with amber sport badges, progress percentage pills.
    - Status badges: `Trống`, `Có khách`, `Giữ chỗ`, `Bảo trì`.

### Section 5: Bottom Floating View Switcher Pill
- Centered floating glass pill bar at the bottom:
  - `Tổng quan` (Active glass pill).
  - `Sơ đồ 8 sân` (Link to `/partner/schedule`).
  - `Doanh thu & POS` (Link to `/partner/revenue`).

---

## 3. Testing & Verification Criteria
1. Required text labels for `PartnerScheduleViews.test.tsx`:
   - `Doanh thu hôm nay`
   - `Số ca đã đặt`
   - `Tỷ lệ lấp đầy`
   - `Khách đã check-in`
   - `Sân Cầu Lông 01`
   - `Sân Pickleball 05`
2. Vitest test suite (`npm --prefix admin-web test -- --run`) must pass 100% (81/81).
3. TypeScript build (`npm --prefix admin-web run build`) must pass with 0 errors.
