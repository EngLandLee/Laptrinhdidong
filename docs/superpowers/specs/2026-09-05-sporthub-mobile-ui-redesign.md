# Specification: SportHub Mobile UI Overhaul (Sporty Dark Luxury)

**Date:** 2026-09-05  
**Topic:** SportHub Mobile UI & UX Modernization  
**Theme:** Sporty Dark Luxury (Obsidian `#0B0F19`, Electric Neon Green `#10B981` / `#00E676`, Cyber Cyan `#06B6D4`, Glassmorphism `#1E293B`)  
**Status:** Approved  

---

## 1. Problem Statement & Root Cause
1. **Desktop Aspect Ratio Stretch**: Running Flutter web on desktop/Chrome stretched 1920px width across all widgets, causing sparse layout, awkward oversized image banners, and loss of the mobile app feel.
2. **Missing Material Icons Font Glyphs**: `uses-material-design: true` was absent in `pubspec.yaml`, rendering Material icons as empty glyph boxes `[x]`.
3. **Outdated Plain Flat Aesthetics**: Raw flat green AppBar with basic white rectangular cards lacked the modern polish expected from top-tier sports booking apps (Playtomic, Hudle, Dribbble trending).

---

## 2. Architecture & Responsive Viewport Wrapper

### 2.1. `ResponsiveMobileWrapper`
To provide an authentic mobile preview on desktop/Chrome without breaking native mobile rendering:
- Check `MediaQuery.sizeOf(context).width`:
  - If `width > 600` (desktop/tablet web preview):
    - Wrap the app in a centered container with `maxWidth: 420` and `maxHeight: 890`.
    - Apply rounded borders (`borderRadius: 36`), a dark phone bezel frame (`border: Border.all(color: Colors.white12, width: 3)`), and soft multi-layer ambient shadow (`BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 5)`).
    - Top status bar area simulating modern phone notch/Dynamic Island.
  - If `width <= 600` (native smartphone or mobile web):
    - Render 100% full screen with native safe area insets.

### 2.2. Font & Icon Configuration
- Enable `uses-material-design: true` under `flutter:` in `pubspec.yaml`.

---

## 3. Design System & Theme Definition

### 3.1. Color Palette (`AppColors`)
- **Background**: `Color(0xFF0B0F19)` (Obsidian Dark)
- **Surface / Card**: `Color(0xFF161F30)` (Midnight Slate)
- **Card Border**: `Color(0xFF223049)` / `Colors.white.withOpacity(0.08)` (Subtle Glass Edge)
- **Primary / Accent**: `Color(0xFF00E676)` / `Color(0xFF10B981)` (Electric Volt / Emerald)
- **Secondary / AI Accent**: `Color(0xFF06B6D4)` (Cyber Cyan)
- **Warning / Selection / Rating**: `Color(0xFFF59E0B)` (Radiant Amber)
- **Error / Booked**: `Color(0xFFEF4444)` (Coral Red)
- **Text Primary**: `Color(0xFFF8FAFC)`
- **Text Secondary**: `Color(0xFF94A3B8)`

### 3.2. Typography & Surfaces
- High-contrast sans-serif typography with distinct hierarchy (Heading 20sp bold, Card Title 16sp bold, Captions 12sp).
- Soft rounded cards (`borderRadius: 20`) with subtle backdrop blur or glass border.

---

## 4. Component & Screen Redesign

### 4.1. Navigation & Shell (`MainNavigationScreen`)
- **Floating Bottom Navigation Bar**:
  - Dark floating capsule with rounded corners (`borderRadius: 24`), margin padding, and background `Color(0xFF161F30)`.
  - 3 items with vibrant active indicators:
    - 🏸 Đặt sân (`Icons.sports_tennis_rounded`)
    - ⚡ Ghép kèo AI (`Icons.auto_awesome_rounded`)
    - 🎟️ Vé của tôi (`Icons.confirmation_number_rounded`)

### 4.2. Tab 1: Khám Phá & Đặt Sân (`ExploreVenuesScreen`)
- **Header**:
  - Greeting: "Chào bạn 👋" + "Tìm sân & Kèo đấu hôm nay"
  - Location Selector: "📍 Q. Bình Thạnh, TP.HCM" with dropdown chevron
  - Notification icon with active green status dot.
- **Search Bar**:
  - Rounded input (`borderRadius: 16`), dark slate fill, search icon, and quick filter icon button.
- **Category Filter Chips**:
  - Pill chips with icons: `Tất cả môn`, `🏓 Pickleball`, `🏸 Cầu lông`, `⚽ Bóng đá`.
  - Active state: Glowing Neon Green gradient with dark text.
  - Inactive state: Dark slate card with white text.
- **Venue Cards**:
  - Rounded container with 16:9 court image.
  - Floating rating badge top right: `⭐ 4.8 (128)`.
  - Floating badge top left: `🔥 Nổi bật` or `⚡ Đặt nhanh`.
  - Information block:
    - Venue name in bold white.
    - Distance and address: `🚗 1.8 km • 123 Chu Văn An, P.12`.
    - Features tag row: `❄️ Máy lạnh`, `🚗 Bãi xe`, `🟢 Còn 4 sân`.
    - Price highlight: `150.000 đ/h` in electric neon.
    - Action button: Gradient pill "Xem lịch sân".

### 4.3. Màn hình Chi tiết Sân & 2D Time-Slot Matrix (`VenueDetailScreen`)
- **Venue Banner**:
  - Full-width hero image with back button and favorite icon.
  - Venue specs (surface, operating hours, amenities).
- **2D Matrix Grid**:
  - Columns: Sân 1, Sân 2, Sân 3...
  - Rows: Time intervals (17:00 - 18:00, 18:00 - 19:00, 19:00 - 20:00...).
  - States:
    - `Available`: Dark card with neon green border & price `150k`.
    - `Booked`: Muted dark red `#2A1619` with red text & padlock icon.
    - `Selected`: Radiant amber `#F59E0B` glow with checkmark.
- **Sticky Floating Summary & Checkout Bar**:
  - Selected count + total price in large bold neon green.
  - "Thanh toán VietQR" action button opening dynamic VietQR dialog with 05:00 holding countdown timer.

### 4.4. Tab 2: Ghép Kèo AI (`MatchmakingScreen`)
- **AI Hero Card**:
  - Deep gradient banner (Cyan to Emerald) with AI sparkles icon.
  - Action trigger: "✨ Phân tích đối thủ phù hợp" with animated loading state.
- **Recommendation Cards**:
  - Match compatibility meter: Circular or pill score `🎯 95% Match` (Cyber Cyan / Emerald).
  - Detailed reason breakdown: Skill alignment, district distance, preferred sport.
  - "Gửi lời mời ghép kèo" action button.

### 4.5. Tab 3: Vé Của Tôi Offline Pass (`MyTicketsScreen`)
- **Offline Pass Visual Card**:
  - Ticket design with cutout notches on both sides and dashed divider line.
  - Header: Venue name, Sport icon, status chip `✅ ĐÃ THANH TOÁN`.
  - Match details: Date, Court number, Time window, Amount paid.
  - Center: High-contrast scannable QR Code with ticket ID.
  - Notice badge: `💾 Lưu trữ cục bộ SQLite - Quét offline không cần mạng`.

---

## 5. Verification & Testing Plan
- Execute `flutter test` to ensure 100% of the 26 existing unit, widget, and BLoC tests continue passing.
- Hot reload / refresh Chrome session to verify:
  - Phone frame is centered cleanly with 420px max width on wide screens.
  - Material icons render perfectly without broken box glyphs.
  - All tabs, slot selection, VietQR dialog, and AI matchmaking work seamlessly.
