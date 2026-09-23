# Specification: Visual Court Graphics & Flexible Shifts (:00 vs :30)

**Date:** 2026-09-06  
**Topic:** Realistic Visual Sports Court Graphics and Time-Slot Shift Selector (.00 vs .30)  
**Status:** Approved  

---

## 1. Problem Statement
1. **Limited Evening-Only Slots**: Previously only 3 static evening slots (17:00 - 20:00) were shown, omitting Morning (06:00 - 12:00), Afternoon (12:00 - 17:00), and late Evening (20:00 - 23:00).
2. **Missing Half-Hour Odd Shifts (18:30, 19:30)**: In real sports booking in Vietnam, many players need half-hour blocks (e.g., 17:30 - 18:30, 18:30 - 19:30, 19:30 - 20:30, or 90-minute matches 18:30 - 20:00).
3. **Plain Table Grid**: The time slot matrix looked like a generic software spreadsheet rather than an immersive sports venue with badminton court mats or football turf layouts.

---

## 2. Architecture & Component Design

### 2.1. Shift & Odd-Hour System
- **Shift Filter (Ca Trong Ngày)**:
  - `🌅 Sáng (06:00 - 12:00)`: 120.000 đ/h
  - `☀️ Chiều (12:00 - 17:00)`: 120.000 đ/h
  - `🌙 Tối cao điểm (17:00 - 23:00)`: 150.000 đ/h
- **Minute Offset Toggle (Chế độ mốc giờ)**:
  - `🕒 Giờ chẵn (:00)`:
    - Sáng: 06:00-07:00, 07:00-08:00, 08:00-09:00, 09:00-10:00, 10:00-11:00, 11:00-12:00
    - Chiều: 12:00-13:00, 13:00-14:00, 14:00-15:00, 15:00-16:00, 16:00-17:00
    - Tối: 17:00-18:00, 18:00-19:00, 19:00-20:00, 20:00-21:00, 21:00-22:00, 22:00-23:00
  - `🕡 Giờ rưỡi (:30)`:
    - Sáng: 06:30-07:30, 07:30-08:30, 08:30-09:30, 09:30-10:30, 10:30-11:30, 11:30-12:30
    - Chiều: 12:30-13:30, 13:30-14:30, 14:30-15:30, 15:30-16:30, 16:30-17:30
    - Tối: 16:30-17:30, 17:30-18:30, 18:30-19:30, 19:30-20:30, 20:30-21:30, 21:30-22:30

### 2.2. Interactive Visual Court Graphic (`VisualCourtWidget`)
- **Court Header Graphic**:
  - Each court column (Sân 1, Sân 2, Sân 3) has a stylized sports court banner:
    - **Badminton / Pickleball**:
      - Emerald mat background (`#047857`)
      - White court lines: boundary lines, service lines, center line, and net line (`--- NET ---`)
      - Court badge with icon: `🏸 Sân 1 (Thảm BWF)`
    - **Football**:
      - Deep turf green background (`#15803D`) with alternating turf stripe pattern
      - White goal box and center circle markings
      - Court badge with icon: `⚽ Sân 1 (Cỏ FIFA)`
- **Stylized Court Tile Slot Cells**:
  - Slot cells textured as court surface tiles:
    - `Available`: Emerald border glow, court floor styling, price in electric neon (`150.000 đ`), status `Còn trống`.
    - `Booked`: Dark muted red, padlock icon, status `Đã đặt`.
    - `Selected`: Radiant amber glow, checkmark icon, status `Đang chọn`.

### 2.3. Court Map Overview Layout (Sơ đồ mặt bằng 2D)
- Toggle between:
  - `📊 Lưới chọn giờ (Matrix View)`
  - `🏟️ Sơ đồ cụm sân (Overview Map)`: Shows layout of Court 1 (near entrance/canteen), Court 2 (center court), Court 3 (VIP court back) with live occupancy status.

---

## 3. Data Flow & State Management
- `BookingBloc` continues to manage slot selection via `ToggleSlotEvent` and `ClearSelectedSlotsEvent`.
- Slots are generated dynamically based on:
  - Active date (`_selectedDate`)
  - Active shift (`morning`, `afternoon`, `evening`)
  - Minute offset (`:00` or `:30`)
- Price calculation adapts: Morning/Afternoon at 120.000 đ/h, Evening at 150.000 đ/h.
- VietQR generation and dynamic payment checkout continue to accurately reflect chosen slots + add-ons.

---

## 4. Verification Plan
- Unit tests verifying:
  - Slot generation for `:00` and `:30` shifts across Morning, Afternoon, Evening.
  - Price tier allocation (120k for day, 150k for evening).
- Widget tests verifying:
  - Visual court header rendering with lines.
  - Shift filter switching and minute offset toggle switching.
- Regression testing: All 41 existing tests pass.
