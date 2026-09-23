# Design Specification: SportHub Web Admin & Partner Portal (`admin-web`)

**Date:** 2026-09-07  
**Author:** Google DeepMind Assistant & Quoc Anh  
**Status:** Approved  
**Target:** Standalone React 19 + TypeScript + Vite + Tailwind CSS Web Application in `admin-web/`

---

## 1. Overview & Objectives

SportHub previously featured an Android-first mobile client. To empower both **Super Admins** (managing the overall sports platform) and **Venue Owners** (managing individual sports complexes such as CLB Tao Đàn, Kỳ Hòa, Tân Bình Arena), we are building a dedicated, modern standalone Web Management Portal located in `admin-web/`.

### Core Goals:
1. **Dedicated Standalone Web Architecture:** Located at `/home/quocanh/Projects/Mobile/admin-web`, running independently on Vite (e.g. port 5173 / 3000), crafted with React 19, TypeScript, Tailwind CSS, Lucide Icons, and React Router.
2. **Role-Based Access Control (2 Tiers):**
   - **Super Admin:** System-wide oversight, all venue management (create new venue, edit facilities, approve/suspend), owner account assignments, platform revenue analytics.
   - **Venue Owner (Partner):** Court management (add/edit courts, sport partitions, surface types, pricing), master court schedule matrix (16 hours x all courts), rapid POS check-in desk with QR/barcode support, and venue-specific financial reporting.
3. **Seamless Role Switching:** A prominent top-bar role switcher (`Super Admin` <-> `Chủ Sân Tao Đàn`) for live demonstration, testing, and operational convenience.
4. **Reactive LocalStorage Data Store:** Fully populated with realistic seed data matching the mobile app (Tao Đàn, Kỳ Hòa, Tân Bình Arena, Phú Nhuận), persisting all changes, supporting export/import, and architected with clean repository interfaces ready for Firebase Firestore / REST API integration.
5. **Modern Athletic Dashboard UI:** Sports-luxury dark and clean light mode themes, high-contrast badges, responsive desktop layouts (optimized for 1080p and widescreen monitors).

---

## 2. Tech Stack & Directory Structure

### 2.1 Tech Stack
- **Framework:** React 19 (TypeScript)
- **Bundler / Dev Server:** Vite
- **Styling:** Tailwind CSS + Lucide React Icons
- **Navigation:** React Router v6
- **Data Persistence:** Reactive LocalStorage Store with Event Emitter pattern

### 2.2 Directory Structure
```
admin-web/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── postcss.config.js
├── index.html
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── index.css
│   ├── types/
│   │   ├── venue.ts
│   │   ├── court.ts
│   │   ├── slot.ts
│   │   ├── booking.ts
│   │   └── user.ts
│   ├── store/
│   │   ├── authStore.ts
│   │   ├── venueStore.ts
│   │   └── seedData.ts
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Topbar.tsx
│   │   │   └── AdminLayout.tsx
│   │   ├── common/
│   │   │   ├── StatCard.tsx
│   │   │   ├── Badge.tsx
│   │   │   └── Modal.tsx
│   │   └── schedule/
│   │       ├── ScheduleMatrix.tsx
│   │       └── SlotActionModal.tsx
│   └── views/
│       ├── superadmin/
│       │   ├── SuperAdminDashboardView.tsx
│       │   ├── VenuesManagementView.tsx
│       │   └── PartnerAccountsView.tsx
│       └── partner/
│           ├── PartnerDashboardView.tsx
│           ├── CourtsManagementView.tsx
│           ├── ScheduleMatrixView.tsx
│           ├── PosCheckinView.tsx
│           └── RevenueAnalyticsView.tsx
```

---

## 3. Detailed Features & Modules

### 3.1 Super Admin Modules

#### Module A1: Super Admin Dashboard (`SuperAdminDashboardView`)
- **System KPIs:**
  - Tổng số Cụm sân hoạt động: `4 cụm sân`
  - Tổng số Sân thể thao: `28 sân` (Cầu lông: 16, Pickleball: 8, Bóng đá: 4)
  - Tổng lượt đặt hôm nay: `86 lượt` (+14% so với hôm qua)
  - Tổng doanh thu toàn sàn: `14.850.000 đ`
- **Platform Health & Growth Charts:**
  - Booking trend across the week.
  - Revenue distribution by venue (Tao Đàn, Kỳ Hòa, Tân Bình Arena, Phú Nhuận).
- **Recent Platform Activities Feed:**
  - New bookings placed via app across all venues.
  - New partner registrations and status updates.

#### Module A2: Venues Management (`VenuesManagementView`)
- Table and Grid of all sports complexes displayed on the mobile app.
- Search by venue name, filter by district/city and sport type.
- **Add New Venue Modal:**
  - Tên cụm sân, địa chỉ đầy đủ, quận, hotline liên hệ.
  - Môn thể thao hỗ trợ: Cầu lông, Pickleball, Bóng đá mini.
  - Giờ mở cửa / đóng cửa (mặc định 06:00 - 22:00).
  - Tải lên ảnh đại diện / banner URL.
  - Giá thuê cơ bản (VNĐ/giờ).
- **Actions:** Chỉnh sửa thông tin, Bật/Tắt hiển thị trên App, Xóa/Lưu trữ cụm sân.

#### Module A3: Partner Accounts & Assignments (`PartnerAccountsView`)
- Danh sách tài khoản chủ sân / nhân viên vận hành.
- Phân quyền cụm sân phụ trách: gán tài khoản vào cụm sân (ví dụ: `owner_taodan` quản lý CLB Tao Đàn).
- Thêm tài khoản quản lý mới, đặt lại mật khẩu, khóa quyền truy cập.

---

### 3.2 Venue Owner / Partner Modules
*(Default active venue: CLB Cầu Lông & Pickleball Tao Đàn)*

#### Module P1: Partner Dashboard (`PartnerDashboardView`)
- **Venue KPIs:**
  - Doanh thu hôm nay: `3.450.000 đ`
  - Số ca đã đặt: `24 / 32 ca`
  - Tỷ lệ lấp đầy: `75.0%`
  - Khách đã check-in: `19 / 24 khách`
- **Live Court Status Grid:**
  - Trạng thái 8 sân trong giờ hiện tại (Sân 1-4 Cầu lông, Sân 5-8 Pickleball) với huy hiệu: Đang trống, Có khách chơi, Đặt trước, Bảo trì.
- **Live Booking & Check-in Stream:**
  - Dòng sự kiện thời gian thực khi khách đặt từ mobile app hoặc check-in tại quầy.
- **Quick Action Buttons:**
  - `[📞 Giữ chỗ nhanh]`, `[📷 Quầy soát vé]`, `[🔒 Khóa sân bảo trì]`, `[➕ Thêm sân mới]`.

#### Module P2: Courts Management (`CourtsManagementView`)
- Danh sách các sân con thuộc cụm:
  - Sân 01 - 04: Cầu lông (Thảm PVC Yonex thi đấu tiêu chuẩn, trong nhà có mái che).
  - Sân 05 - 08: Pickleball (Sân chuẩn USAPA, thảm Silicon chuyên dụng, đèn LED chống chói).
- **Add/Edit Court Modal:**
  - Mã sân, Tên sân hiển thị ("Sân Cầu Lông 05", "Sân Pickleball VIP").
  - Môn thể thao (Cầu lông, Pickleball, Bóng đá, Quần vợt).
  - Loại mặt sân và cơ sở vật chất (Trong nhà, Ngoài trời, Có mái che, Máy lạnh).
  - Bảng giá: Giá giờ thường (Off-peak) và Giá giờ vàng (Peak: 17:00 - 21:00).
  - Trạng thái hoạt động (Hoạt động / Tạm ngừng bảo trì).

#### Module P3: Master Court Schedule Matrix (`ScheduleMatrixView`)
- Ma trận toàn màn hình độ nét cao:
  - Các cột: Danh sách 8 sân (hoặc lọc theo môn).
  - Các hàng: 16 khung giờ từ 06:00 đến 22:00.
- Bộ lọc môn (`Tất cả`, `Cầu Lông 1-4`, `Pickleball 5-8`) và ca (`Sáng 06-12h`, `Chiều 12-17h`, `Tối 17-22h`).
- **Tương tác trực tiếp trên ô ca:**
  - Ô Trống: Hiển thị giá tiền và tag giờ vàng/ưu đãi. Click mở Modal:
    - Giữ chỗ nhanh cho khách gọi điện thoại (Tên khách + SĐT).
    - Tùy chỉnh giá ca này (các mốc nhanh 80k, 120k, 150k, 180k, 240k).
    - Khóa sân bảo trì ca này.
  - Ô Đã Đặt qua App: Màu xanh ngọc (Emerald), hiển thị mã vé `SH-xxxx`, tên khách, SĐT. Click để xem chi tiết thanh toán hoặc hủy/mở lại ca.
  - Ô Khách Đặt Thủ Công: Màu hổ phách (Amber), hiển thị thông tin khách đặt qua điện thoại.
  - Ô Bảo Trì: Màu đỏ xọc chéo, hiển thị lý do bảo trì. Click để mở lại ca.

#### Module P4: Front-Desk POS & Check-in Desk (`PosCheckinView`)
- **Thanh tra cứu & soát vé nhanh:**
  - Ô nhập lớn `[Nhập mã vé hoặc quét QR (ví dụ: SH-8291)...]` tự động focus, nhấn `Enter` hoặc click `Check-in ngay` để kiểm tra và cập nhật trạng thái ngay lập tức.
- **Bảng Khách Đến Hôm Nay (Today's Arrivals Table):**
  - Cột: Mã vé, Khách hàng, SĐT, Sân, Khung giờ, Trạng thái (Chờ check-in / Đã vào sân), Thao tác (Nút `Check-in 1 chạm`).
- **Quầy Bán Lẻ Phụ Kiện & Nước Uống (Add-on POS Counter):**
  - Các mặt hàng thông dụng: Nước suối (10k), Pocari Sweat (20k), Revive chanh muối (18k), Thuê vợt thi đấu (50k), Hộp bóng (60k).
  - Bộ đếm số lượng `+` / `-` kèm tính tổng bill tức thì.
  - Nút `Thanh toán tại quầy (Tiền mặt / Chuyển khoản QR)` in hóa đơn hoặc xác nhận thanh toán.

#### Module P5: Revenue Analytics & Financial Logs (`RevenueAnalyticsView`)
- Biểu đồ cột Doanh thu 7 ngày gần nhất (từ Thứ 2 đến Chủ nhật).
- Phân tích cơ cấu tài chính:
  - Doanh thu tiền sân (82%) vs Dịch vụ phụ trợ (18%).
  - Doanh thu theo môn: Cầu lông (58%) vs Pickleball (42%).
  - Tỷ lệ ca: Giờ vàng (Peak 64%) vs Giờ ưu đãi (Off-peak 36%).
- Bảng lịch sử giao dịch chi tiết: Thời gian, Khách hàng, Sân / Dịch vụ, Phương thức (VietQR / Tiền mặt), Số tiền, Trạng thái.
- Nút `Xuất file CSV / Excel`.

---

## 4. UI/UX Design & Theming

- **Tone & Voice:** Sang trọng thể thao, chuyên nghiệp, hiện đại.
- **Bảng màu:**
  - Dark Theme: Nền `#0B0F19`, Thẻ & Bảng `#161F30`, Viền `#223049`, Chữ `#F8FAFC`.
  - Light Theme: Nền `#F8FAFC`, Thẻ & Bảng `#FFFFFF`, Viền `#E2E8F0`, Chữ `#0F172A`.
  - Màu chủ đạo: Emerald `#10B981` (Thành công / Hoạt động), Amber `#F59E0B` (Giữ chỗ / Cảnh báo), Rose `#EF4444` (Bảo trì / Đóng ca).
- **Hỗ trợ Đa Thiết Bị:** Tối ưu chuẩn máy tính bàn (Desktop) & laptop (1366x768 trở lên).

---

## 5. Verification Plan

1. Khởi tạo dự án `admin-web` với Vite + React + TypeScript + Tailwind CSS thành công.
2. Kiểm tra build TypeScript (`npm run build`) không có lỗi type.
3. Chạy máy chủ phát triển Vite và kiểm tra toàn bộ các trang:
   - Super Admin: Dashboard, Quản lý Cụm sân, Phân quyền chủ sân.
   - Chủ sân: Dashboard Tao Đàn, Quản lý 8 Sân con, Lịch sân 16h x 8 sân, Soát vé POS, Báo cáo doanh thu.
4. Kiểm tra tương tác: Thêm cụm sân mới, đổi giá ca, giữ chỗ qua điện thoại, check-in mã vé `SH-8291`, đổi vai trò và chuyển đổi Dark/Light mode.
