# Design Spec: SportHub Partner - Venue Owner Management Dashboard & Role Switching

## 1. Overview & Goals
SportHub currently provides a consumer-facing mobile experience for players (court booking, 2D map, VietQR payments, community recruitment, and user profiles). However, sports facility owners (venue managers) have distinct operational workflows:
- Visualizing all courts in a real-time timeline/matrix across shifts.
- Blocking courts for maintenance or reserving slots for offline/phone-in walk-in customers to prevent double-booking.
- Checking in players who present their SportHub QR pass at the front desk.
- Tracking daily revenue from court fees and add-on refreshments/gear.
- Toggling between player mode and venue owner mode seamlessly.

This specification introduces **SportHub Partner (Chế độ Chủ Sân)**:
1. **Role Switcher & Partner Account**: A dedicated venue owner profile (Trần Văn Chủ Sân managing CLB Cầu Lông & Pickleball Tao Đàn) and a quick switch button between Player Mode and Owner Mode.
2. **Owner Mode Bottom Navigation**:
   - Tab 1: **Lịch sân (Live Court Schedule Matrix)** with quick actions (Lock maintenance, Reserve walk-in, Unlock).
   - Tab 2: **Soát vé (Check-in & Booking Manager)** with QR ticket scanning and 1-tap check-in confirmation.
   - Tab 3: **Doanh thu (Revenue & Occupancy Analytics)** with daily breakdown, add-on sales, and 7-day trend chart.
   - Tab 4: **Cài đặt (Venue Settings)** with court details, add-on pricing, and exit back to Player Mode.
3. **Reactive State Synchronization**: Managed through `VenueOwnerStore` synchronizing with `SeedData.sampleVenues` and tickets.

---

## 2. Architecture & Data Model

### 2.1 Court Slot Reservation Model (`CourtSlotState`)
A court slot represents an hourly block on a specific court:
```dart
enum CourtSlotStatus {
  available,      // Trống, mở bán trên app
  bookedApp,      // Khách đặt qua app SportHub (đã thanh toán)
  reservedManual, // Chủ sân giữ chỗ khách gọi điện/vãng lai
  maintenance,    // Sân đang bảo trì/khóa
}

class CourtSlotItem {
  final String slotId;           // e.g. "court_01_19_00"
  final String courtName;        // e.g. "Sân 01 (Cầu lông)"
  final String timeRange;        // e.g. "19:00 - 20:00"
  final CourtSlotStatus status;
  final String? customerName;    // e.g. "Nguyễn Văn An" or "Anh Tuấn (Khách quen)"
  final String? customerPhone;   // e.g. "0909 123 456"
  final String? ticketId;        // e.g. "SH-8291"
  final double price;

  const CourtSlotItem({
    required this.slotId,
    required this.courtName,
    required this.timeRange,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.ticketId,
    required this.price,
  });

  CourtSlotItem copyWith({
    CourtSlotStatus? status,
    String? customerName,
    String? customerPhone,
    String? ticketId,
  }) { ... }
}
```

### 2.2 `VenueOwnerStore` Singleton
Reactive store managing the venue owner's state:
- `isOwnerMode: ValueNotifier<bool>`: Defaults to `false` (Player mode).
- `activeVenueId: String`: Defaults to `'venue_01'` (CLB Cầu Lông & Pickleball Tao Đàn).
- `slotsNotifier: ValueNotifier<List<CourtSlotItem>>`: List of slots for the selected date.
- Methods:
  - `toggleOwnerMode(bool enabled)`: Switches between Player mode and Owner mode.
  - `reserveSlot(String slotId, {required String customerName, required String customerPhone})`: Marks slot as `reservedManual`.
  - `lockMaintenance(String slotId)`: Marks slot as `maintenance`.
  - `unlockSlot(String slotId)`: Reverts slot to `available`.
  - `checkInTicket(String ticketId)`: Marks ticket as checked in.
  - `reset()`: Restores initial seed data.

### 2.3 Seed Partner Account
- **Trần Văn Chủ Sân**:
  - `userId`: `'user_owner_01'`
  - `phone`: `'0988 888 777'`
  - `password`: `'123456'`
  - `fullName`: `'Trần Văn Chủ Sân'`
  - `role`: `'venue_owner'`
  - `managedVenueName`: `'CLB Cầu Lông & Pickleball Tao Đàn'`

---

## 3. Screen Specifications & User Experience

### 3.1 Mode Switching Entry Points
- **In `ProfileScreen` (Player Mode - Tab 4)**:
  - Promotional Card:
    - Title: `"Dành cho Chủ sân & Quản lý"`
    - Subtitle: `"Quản lý ma trận lịch sân, soát vé QR và theo dõi doanh thu thời gian thực."`
    - Action button: `[⚡ Chuyển sang Chế độ Chủ Sân]` (`Key('switch_to_owner_mode_button')`).
- **In `AuthScreen`**:
  - Quick demo login button for `'Trần Văn (Chủ sân)'` (`Key('quick_login_user_owner_01')`) which logs in and activates Owner mode.

### 3.2 Owner Mode Scaffold (`OwnerNavigationScreen`)
When `isOwnerMode` is `true`, `_SportHubShell` renders `OwnerNavigationScreen` with 4 bottom tabs:
1. **Lịch sân** (`Icons.calendar_month_rounded`): `Key('owner_tab_schedule')`
2. **Soát vé** (`Icons.qr_code_scanner_rounded`): `Key('owner_tab_checkin')`
3. **Doanh thu** (`Icons.insights_rounded`): `Key('owner_tab_revenue')`
4. **Cài đặt** (`Icons.tune_rounded`): `Key('owner_tab_settings')`

### 3.3 Tab 1: Live Court Schedule Matrix (`OwnerScheduleTab`)
- **Header**:
  - Venue Title: `"CLB Cầu Lông & Pickleball Tao Đàn"`
  - Shift filter chips: `"Tất cả ca"`, `"Ca Sáng (06:00 - 12:00)"`, `"Ca Tối (17:00 - 23:00)"`
  - Sport filter: `"🏸 Cầu lông (Sân 1-4)"`, `"🏓 Pickleball (Sân 5-8)"`
- **Slot Grid**:
  - Slots rendered with distinct visual colors:
    - 🟢 Green: `bookedApp` (Shows customer name & ticket ID)
    - 🟡 Amber: `reservedManual` (Shows customer name & phone)
    - 🔴 Red: `maintenance` (Shows "Đang bảo trì")
    - ⚪ Dark with border: `available` (Shows price and "Trống")
- **Quick Action Bottom Sheet** (`Key('owner_slot_action_sheet')`):
  - When tapping an `available` slot:
    - Option 1: `[📞 Giữ chỗ khách gọi điện]` (`Key('action_manual_reserve')`) with name & phone input dialog.
    - Option 2: `[🔒 Khóa sân bảo trì]` (`Key('action_lock_maintenance')`).
  - When tapping `reservedManual` or `maintenance` slot:
    - Option: `[🔓 Mở khóa sân (Trả lại sân trống)]` (`Key('action_unlock_slot')`).

### 3.4 Tab 2: Check-in & Booking Manager (`OwnerCheckinTab`)
- **Header**:
  - Search bar (`Key('checkin_search_input')`) filtering by customer name, phone, or ticket ID.
  - QR Scan simulation button `[📷 Quét mã QR]` (`Key('open_qr_scanner_button')`).
- **Ticket List**:
  - Cards displaying: Ticket ID, Customer Name, Phone, Court, Time Slot, Paid Amount, Addons summary.
  - Status indicator: `"Chờ nhận sân"` (amber) or `"Đã nhận sân lúc HH:mm"` (green).
  - Check-in button: `[✅ Xác nhận Check-in]` (`Key('confirm_checkin_${ticket.id}')`).

### 3.5 Tab 3: Revenue & Occupancy Analytics (`OwnerRevenueTab`)
- **Metric Cards**:
  - 💵 **Tổng Doanh thu Hôm nay**: `1.850.000 đ` (Sân: `1.600.000 đ`, Dịch vụ: `250.000 đ`).
  - 📈 **Tỷ lệ lấp đầy**: `82%` (23/28 slots).
  - 👥 **Lượt khách**: `32 lượt`.
- **Add-on Revenue Breakdown**:
  - Pocari Sweat: `12 chai` (180.000 đ)
  - Quấn cán vợt: `4 cái` (70.000 đ)
- **7-Day Trend Chart**:
  - Clean bar indicators showing daily revenue across the current week.

### 3.6 Tab 4: Venue Settings & Exit (`OwnerSettingsTab`)
- Displays venue summary: Name, Address, Number of courts (8), Shift hours.
- Add-on inventory toggles: Enable/disable refreshment or gear rental.
- Primary Exit Action:
  - Button: `[🔄 Quay lại Chế độ Người Chơi]` (`Key('exit_owner_mode_button')`) which sets `isOwnerMode = false` and returns to standard player tabs.

---

## 4. Verification & Testing Strategy
- **Unit Tests**:
  - `VenueOwnerStore`: test reserving slots, locking maintenance, unlocking slots, checking in tickets, and toggling modes.
- **Widget Tests**:
  - Mode switching from Profile and back.
  - Schedule matrix slot interaction (reserve, lock, unlock).
  - Check-in tab search and 1-tap check-in action.
  - Revenue analytics rendering.
- **Regression**:
  - 100% pass on all existing 135 tests.
  - 0 analyzer warnings/errors.
