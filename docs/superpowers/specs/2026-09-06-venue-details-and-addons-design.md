# Specification: Comprehensive Venue Details Screen & Add-on Services

**Date:** 2026-09-06  
**Topic:** Real-world Venue Detail Screen with Equipment Rentals, Retail Refreshments, and Global Mobile Viewport  
**Status:** Approved  

---

## 1. Problem Statement
1. **Unconstrained Route Pushing on Web**: When navigating to `VenueDetailScreen`, the route bypassed `ResponsiveMobileWrapper` because the wrapper was only wrapped around `home`, causing the detail screen to stretch across 1920px desktop width.
2. **Oversimplified Venue Details**: Real players need comprehensive venue details (photos gallery, operating hours, direct phone call hotline, amenities, policies, reviews, and interactive date picking).
3. **Missing Equipment Rental & Retail Services**: Real badminton/pickleball venues offer equipment rental (rackets, automatic shuttlecock launcher) and retail shop items (water, energy drinks, shuttlecock tubes, grips). These should be selectable as add-ons with automatic price recalculation in VietQR.

---

## 2. Architecture & Viewport Architecture

### 2.1. Global `ResponsiveMobileWrapper` via `MaterialApp.builder`
Configure `MaterialApp` in `lib/main.dart`:
```dart
MaterialApp(
  title: 'SportHub',
  builder: (context, child) => ResponsiveMobileWrapper(child: child!),
  ...
)
```
This guarantees that **every screen, modal bottom sheet, dialog, and Navigator route** is constrained inside the centered smartphone container (max width 420px, 3D ambient shadow) on desktop web while remaining 100% native fullscreen on mobile devices.

---

## 3. Data Models & Entities

### 3.1. `VenueAddonItem` Model
Create `lib/domain/entities/venue_addon.dart`:
```dart
enum AddonCategory { rental, beverage, gear }

class VenueAddonItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit; // 'cây', 'giờ', 'chai', 'lon', 'ống'
  final AddonCategory category;
  final String icon; // emoji or icon name

  const VenueAddonItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.icon,
  });
}
```

Predefined mock add-on catalog in `lib/core/utils/seed_data.dart`:
1. **Rentals**:
   - Vợt Cầu Lông Cao Cấp (Yonex Astrox 88D): `30.000 đ/cây`
   - Vợt Pickleball Carbon (Joola Ben Johns): `40.000 đ/cây`
   - Máy Bắn Cầu Lông Tự Động (Auto Shuttlecock Machine): `80.000 đ/giờ`
2. **Beverages / Căng Tin**:
   - Nước Pocari Sweat / Revive bù điện giải: `15.000 đ/chai`
   - Nước khoáng Aquafina 500ml: `10.000 đ/chai`
   - Bò húc Redbull: `20.000 đ/lon`
3. **Gear & Retail Accessories**:
   - Ống Cầu Lông Hải Yến (12 quả): `240.000 đ/ống`
   - Quả cầu lông lẻ: `22.000 đ/quả`
   - Bóng Pickleball Franklin X-40: `45.000 đ/quả`
   - Quấn cán vợt thấm hút mồ hôi: `25.000 đ/cái`

---

## 4. UI Components & Screen Sections in `VenueDetailScreen`

### 4.1. Photo Gallery Carousel & Header
- Horizontal image carousel with indicators (`1/4`) showing court surface, night lighting, and amenities.
- Top bar with Back button and Bookmark / Share buttons.

### 4.2. Operating Hours & Quick Actions
- Operating Status: `🟢 Đang mở cửa • 06:00 - 23:00`.
- Quick Action Buttons:
  - `📞 Gọi chủ sân` (Hotline: `0909 123 456`)
  - `📍 Chỉ đường` (Opens Google Maps link/toast)
  - `💬 Chat tư vấn`

### 4.3. Amenities & Facilities Grid
- Chips showing facilities:
  - `❄️ Máy lạnh / Quạt công nghiệp`
  - `🚗 Bãi xe ô tô & xe máy (Free)`
  - `🚿 Phòng tắm nóng lạnh riêng`
  - `🥤 Căng tin nước uống & đồ ăn nhẹ`
  - `🏸 Cho thuê vợt & phụ kiện`
  - `💡 Đèn LED chống chói tiêu chuẩn`
  - `🪵 Thảm thi đấu chuẩn BWF`

### 4.4. Horizontal Date Picker
- Horizontal scrollable date chips:
  - `Hôm nay (06/09)`, `Ngày mai (07/09)`, `Thứ 2 (08/09)`, `Thứ 3 (09/09)`, `Thứ 4 (10/09)`.
  - Allows selecting active booking date.

### 4.5. Pricing Tiers
- Card showing:
  - *Giờ thường (06:00 - 16:00)*: `120.000 đ/h`
  - *Giờ cao điểm (16:00 - 22:00)*: `150.000 đ/h`

### 4.6. 2D Time-Slot Matrix
- Existing interactive 2D table grid with columns (Sân 1, Sân 2, Sân 3) and rows (Time intervals).
- Reactive multi-slot selection wired to `BookingBloc`.

### 4.7. Add-on Services & Rental Selector
- Section: "Dịch vụ kèm theo & Thuê dụng cụ tại sân".
- Categorized tabs or list:
  - Cho thuê dụng cụ (Vợt, Máy bắn cầu)
  - Căng tin & Nước uống
  - Phụ kiện & Quả cầu
- Counter widget `[-] count [+]` for each item.
- Reactive subtotal calculation.

### 4.8. House Rules & Cancellation Policy
- Policies card:
  - `👟 Trang phục`: Bắt buộc mang giày đế bám không để lại vết đen (Non-marking shoes).
  - `🔄 Hoàn/hủy`: Miễn phí hủy trước giờ thi đấu 4 tiếng.
  - `🎟️ Check-in`: Xuất trình mã vé QR tại quầy tiếp tân.

### 4.9. Player Ratings & Reviews
- Rating summary: `⭐ 4.8 / 5.0 (142 đánh giá)`.
- Player review cards with avatar, rating stars, player skill level badge, and real feedback.

### 4.10. Sticky Bottom Bar & VietQR Checkout Modal
- Bottom bar dynamically displays:
  - Selected slot count & slot total
  - Selected add-ons count & add-on total
  - **Grand Total**
  - "Thanh toán VietQR" action button
- VietQR Dialog displays breakdown of slots + add-ons, dynamic QR code with exact grand total, and 05:00 countdown timer.

---

## 5. Verification Plan
- Unit test for `VenueAddonItem` entity and calculation logic.
- Widget tests verifying:
  - `MaterialApp.builder` keeps `VenueDetailScreen` inside `ResponsiveMobileWrapper`.
  - Add-on counter increment/decrement updates grand total correctly.
  - Date picker selection updates displayed date.
- Complete regression suite (`flutter test`).
