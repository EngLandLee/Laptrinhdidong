# SportHub Partner Web Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full-featured, widescreen-optimized SaaS web portal (`PartnerWebScaffold`) for venue partners and front-desk staff on desktop browsers (`width >= 800px`) with 4 core modules: Dashboard, Master Schedule Matrix, Front-Desk POS Check-in, and Financial Analytics, while seamlessly preserving mobile frame preview flexibility.

**Architecture:** An integrated responsive architecture where `ResponsiveMobileWrapper` dynamically expands fullscreen for Venue Owner mode on desktop screens (`width >= 800px`), loading `PartnerWebScaffold` with a persistent 250px `PartnerWebSidebar`, a `PartnerWebTopBar` with operational badges and notification integration, and 4 dedicated desktop views powered directly by `VenueOwnerStore`, `NotificationStore`, and `ThemeStore`.

**Tech Stack:** Flutter 3.x, Dart 3.x, Clean Architecture, ValueNotifier / Reactive Store Pattern, Fresh Athletic Light Theme & Sporty Dark Luxury Theme.

## Global Constraints

- Platform: Android first, with global responsive smartphone viewport frame (`maxWidth: 420px`) for player mode, and responsive widescreen desktop mode (`width >= 800px`) for venue partner mode.
- UI Language: Vietnamese (all navigation, status chips, table headers, and alerts in natural Vietnamese).
- Theme: Theme-aware using dynamic `AppColors` (`background`, `surface`, `cardBorder`, `textPrimary`, `textSecondary`, `primary`, `onPrimary`, `warning`, `error`).
- State Management: 100% reactive using existing singletons `VenueOwnerStore.instance`, `NotificationStore.instance`, and `ThemeStore.instance`.
- Backward Compatibility: Keep existing 200 unit, widget, and integration tests passing with 0 analyzer issues.

---

### Task 1: Reactive State, Desktop Viewport Detection & Partner Web Scaffold Shell

**Files:**
- Modify: `lib/core/state/venue_owner_store.dart`
- Modify: `lib/presentation/widgets/responsive_mobile_wrapper.dart`
- Modify: `lib/presentation/screens/owner_navigation_screen.dart`
- Create: `lib/presentation/widgets/partner_web/partner_web_scaffold.dart`
- Create: `lib/presentation/widgets/partner_web/partner_web_sidebar.dart`
- Create: `lib/presentation/widgets/partner_web/partner_web_top_bar.dart`
- Test: `test/presentation/screens/partner_web_scaffold_test.dart`

**Interfaces:**
- Consumes:
  - `VenueOwnerStore.instance.isOwnerModeNotifier` (`ValueNotifier<bool>`)
  - `ThemeStore.instance.themeModeNotifier` (`ValueNotifier<ThemeMode>`)
  - `NotificationStore.instance.notificationsNotifier` (`ValueNotifier<List<AppNotification>>`)
- Produces:
  - `VenueOwnerStore.instance.isWebDesktopViewNotifier` (`ValueNotifier<bool>`)
  - `VenueOwnerStore.instance.isWebDesktopView` (`bool`)
  - `VenueOwnerStore.instance.toggleWebDesktopView([bool? enabled])` (`void`)
  - `PartnerWebScaffold` (`StatefulWidget`)
  - `PartnerWebSidebar` (`StatelessWidget`)
  - `PartnerWebTopBar` (`StatelessWidget`)

- [ ] **Step 1: Write the failing widget test for responsive desktop shell**

Create `test/presentation/screens/partner_web_scaffold_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/presentation/screens/owner_navigation_screen.dart';
import 'package:sporthub/presentation/widgets/partner_web/partner_web_scaffold.dart';
import 'package:sporthub/presentation/widgets/responsive_mobile_wrapper.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
    VenueOwnerStore.instance.toggleOwnerMode(true);
    ThemeStore.instance.reset();
  });

  testWidgets('Renders PartnerWebScaffold when width >= 800 and isWebDesktopView is true',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PartnerWebScaffold), findsOneWidget);
    expect(find.byKey(const Key('web_nav_dashboard')), findsOneWidget);
    expect(find.byKey(const Key('web_nav_schedule')), findsOneWidget);
    expect(find.byKey(const Key('web_nav_pos')), findsOneWidget);
    expect(find.byKey(const Key('web_nav_revenue')), findsOneWidget);
    expect(find.byKey(const Key('web_topbar_notification_bell')), findsOneWidget);
  });

  testWidgets('Sidebar navigation switches active tab index and view',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default is Dashboard view (index 0)
    expect(find.byKey(const Key('partner_web_view_dashboard')), findsOneWidget);

    // Click Schedule tab
    await tester.tap(find.byKey(const Key('web_nav_schedule')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partner_web_view_schedule')), findsOneWidget);

    // Click POS tab
    await tester.tap(find.byKey(const Key('web_nav_pos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partner_web_view_pos')), findsOneWidget);

    // Click Revenue tab
    await tester.tap(find.byKey(const Key('web_nav_revenue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partner_web_view_revenue')), findsOneWidget);
  });

  testWidgets('Toggling mobile view switches to 420px mobile mockup',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Click toggle mobile view
    await tester.tap(find.byKey(const Key('web_toggle_mobile_view')));
    await tester.pumpAndSettle();

    expect(VenueOwnerStore.instance.isWebDesktopView, isFalse);
    expect(find.byType(PartnerWebScaffold), findsNothing);
    expect(find.byKey(const Key('owner_tab_schedule')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/partner_web_scaffold_test.dart`
Expected: Compilation errors (missing `isWebDesktopViewNotifier`, `PartnerWebScaffold`).

- [ ] **Step 3: Update `VenueOwnerStore`, `ResponsiveMobileWrapper`, `OwnerNavigationScreen` and implement `PartnerWebScaffold`, `PartnerWebSidebar`, `PartnerWebTopBar`**

In `lib/core/state/venue_owner_store.dart`:
```dart
  final ValueNotifier<bool> isWebDesktopViewNotifier = ValueNotifier<bool>(true);
  bool get isWebDesktopView => isWebDesktopViewNotifier.value;

  void toggleWebDesktopView([bool? enabled]) {
    isWebDesktopViewNotifier.value = enabled ?? !isWebDesktopViewNotifier.value;
  }
```
And in `reset()`:
```dart
  isWebDesktopViewNotifier.value = true;
```

In `lib/presentation/widgets/responsive_mobile_wrapper.dart`:
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/venue_owner_store.dart';

class ResponsiveMobileWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: VenueOwnerStore.instance.isOwnerModeNotifier,
      builder: (context, isOwnerMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: VenueOwnerStore.instance.isWebDesktopViewNotifier,
          builder: (context, isWebDesktopView, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;
                if (isOwnerMode && isWebDesktopView && isWide) {
                  return Container(
                    color: AppColors.background,
                    child: child,
                  );
                }

                if (constraints.maxWidth > 600) {
                  return Container(
                    color: const Color(0xFF030712),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 890),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 8,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(33),
                          child: child,
                        ),
                      ),
                    ),
                  );
                }

                return child;
              },
            );
          },
        );
      },
    );
  }
}
```

In `lib/presentation/screens/owner_navigation_screen.dart`:
Add top action toggle and widescreen check in `build`:
```dart
// Check desktop view:
final isDesktop = MediaQuery.of(context).size.width >= 800 && VenueOwnerStore.instance.isWebDesktopView;
if (isDesktop) {
  return const PartnerWebScaffold();
}
```
And add `owner_toggle_web_view_mode` icon in AppBar actions of the mobile owner view so users can toggle back to desktop mode anytime.

Create `lib/presentation/widgets/partner_web/partner_web_sidebar.dart`:
Sidebar with Tao Đàn venue badge, 4 navigation items with keys (`web_nav_dashboard`, `web_nav_schedule`, `web_nav_pos`, `web_nav_revenue`), theme toggle (`web_theme_toggle`), mobile view switcher (`web_toggle_mobile_view`), and exit owner mode (`web_exit_owner_mode_button`).

Create `lib/presentation/widgets/partner_web/partner_web_top_bar.dart`:
Breadcrumb with module title, occupancy rate pill, active court counter pill, interactive notification bell (`web_topbar_notification_bell`), and staff profile badge.

Create `lib/presentation/widgets/partner_web/partner_web_scaffold.dart`:
Stateful widget combining Sidebar, TopBar, and view switcher with placeholders for each view (`Key('partner_web_view_dashboard')`, `Key('partner_web_view_schedule')`, `Key('partner_web_view_pos')`, `Key('partner_web_view_revenue')`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/partner_web_scaffold_test.dart`
Expected: PASS (3 tests passed).

- [ ] **Step 5: Run full test suite and commit**

Run: `flutter test` and `flutter analyze`
```bash
git add lib/core/state/venue_owner_store.dart lib/presentation/widgets/responsive_mobile_wrapper.dart lib/presentation/screens/owner_navigation_screen.dart lib/presentation/widgets/partner_web/ test/presentation/screens/partner_web_scaffold_test.dart
git commit -m "feat: implement responsive desktop wrapper and PartnerWebScaffold shell"
```

---

### Task 2: PartnerWebDashboardView (KPIs, Live Feed, Court Quick Grid, Quick Actions)

**Files:**
- Create: `lib/presentation/widgets/partner_web/views/partner_web_dashboard_view.dart`
- Modify: `lib/presentation/widgets/partner_web/partner_web_scaffold.dart`
- Test: `test/presentation/screens/partner_web_dashboard_test.dart`

**Interfaces:**
- Consumes:
  - `VenueOwnerStore.instance.slotsNotifier`
  - `NotificationStore.instance.notificationsNotifier`
- Produces:
  - `PartnerWebDashboardView` (`StatelessWidget`)
  - Callbacks: `onNavigateToTab(int tabIndex)`

- [ ] **Step 1: Write the failing widget test for Dashboard view**

Create `test/presentation/screens/partner_web_dashboard_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/presentation/widgets/partner_web/views/partner_web_dashboard_view.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
    ThemeStore.instance.reset();
  });

  testWidgets('PartnerWebDashboardView renders 4 KPI cards and quick actions',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int navigatedTab = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerWebDashboardView(
            onNavigateToTab: (index) => navigatedTab = index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // KPI Cards
    expect(find.text('Tổng doanh thu hôm nay'), findsOneWidget);
    expect(find.text('Số ca đã đặt'), findsOneWidget);
    expect(find.text('Tỷ lệ lấp đầy'), findsOneWidget);
    expect(find.text('Khách đã check-in'), findsOneWidget);

    // Quick Action Buttons
    expect(find.byKey(const Key('dashboard_quick_reserve')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_quick_pos')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_quick_lock')), findsOneWidget);

    // Tapping Quick Action navigates
    await tester.tap(find.byKey(const Key('dashboard_quick_reserve')));
    await tester.pump();
    expect(navigatedTab, equals(1)); // Schedule tab

    await tester.tap(find.byKey(const Key('dashboard_quick_pos')));
    await tester.pump();
    expect(navigatedTab, equals(2)); // POS tab
  });

  testWidgets('PartnerWebDashboardView renders Live Court Status and Activity Feed',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PartnerWebDashboardView(
            onNavigateToTab: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trạng thái Sân trực tiếp'), findsOneWidget);
    expect(find.text('Nhật ký Đặt sân & Check-in'), findsOneWidget);
    expect(find.textContaining('Sân Cầu Lông 01'), findsWidgets);
    expect(find.textContaining('Sân Pickleball 05'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/partner_web_dashboard_test.dart`
Expected: Compilation errors (missing `PartnerWebDashboardView`).

- [ ] **Step 3: Implement `PartnerWebDashboardView` and connect in `PartnerWebScaffold`**

In `lib/presentation/widgets/partner_web/views/partner_web_dashboard_view.dart`:
- Calculate real KPI stats from `VenueOwnerStore.instance.slots`:
  - Total revenue: sum of prices of `bookedApp` and `reservedManual` slots.
  - Booked count: count of `bookedApp` + `reservedManual` slots.
  - Occupancy rate: percentage of booked slots over total available/booked slots.
  - Check-in count: count of slots where `VenueOwnerStore.instance.isCheckedIn(ticketId)`.
- 4 high-contrast KPI cards with icons and trend badges.
- 2-column grid:
  - Left column: Realtime status cards for 8 courts (badge for Available, Booked, Reserved, Maintenance, with current slot price and sport badge).
  - Right column: Realtime activity feed showing latest booking and check-in events.
- Top quick action shortcut buttons (`dashboard_quick_reserve`, `dashboard_quick_pos`, `dashboard_quick_lock`).

Connect into `PartnerWebScaffold`:
Replace dashboard placeholder with `PartnerWebDashboardView(onNavigateToTab: (index) => setState(() => _activeNavIndex = index))`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/partner_web_dashboard_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite and commit**

Run: `flutter test` and `flutter analyze`
```bash
git add lib/presentation/widgets/partner_web/views/partner_web_dashboard_view.dart lib/presentation/widgets/partner_web/partner_web_scaffold.dart test/presentation/screens/partner_web_dashboard_test.dart
git commit -m "feat: implement PartnerWebDashboardView with KPIs and realtime court feeds"
```

---

### Task 3: PartnerWebScheduleView (16h x 8 Courts Master Matrix, Shift/Sport Filters, Inline Actions)

**Files:**
- Create: `lib/presentation/widgets/partner_web/views/partner_web_schedule_view.dart`
- Modify: `lib/presentation/widgets/partner_web/partner_web_scaffold.dart`
- Test: `test/presentation/screens/partner_web_schedule_test.dart`

**Interfaces:**
- Consumes:
  - `VenueOwnerStore.instance.slotsNotifier`
  - `VenueOwnerStore.instance.reserveSlot(...)`
  - `VenueOwnerStore.instance.updateSlotPrice(...)`
  - `VenueOwnerStore.instance.lockMaintenance(...)`
  - `VenueOwnerStore.instance.unlockSlot(...)`
- Produces:
  - `PartnerWebScheduleView` (`StatefulWidget`)

- [ ] **Step 1: Write the failing widget test for Master Court Schedule Matrix**

Create `test/presentation/screens/partner_web_schedule_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/domain/entities/court_slot_item.dart';
import 'package:sporthub/presentation/widgets/partner_web/views/partner_web_schedule_view.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
    ThemeStore.instance.reset();
  });

  testWidgets('PartnerWebScheduleView renders matrix with sport and shift filters',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebScheduleView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Filters exist
    expect(find.byKey(const Key('web_filter_all')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_badminton')), findsOneWidget);
    expect(find.byKey(const Key('web_filter_pickleball')), findsOneWidget);
    expect(find.byKey(const Key('web_shift_morning')), findsOneWidget);
    expect(find.byKey(const Key('web_shift_afternoon')), findsOneWidget);
    expect(find.byKey(const Key('web_shift_evening')), findsOneWidget);

    // Matrix headers exist
    expect(find.textContaining('Sân Cầu Lông 01'), findsWidgets);
    expect(find.textContaining('Sân Pickleball 05'), findsWidgets);
    expect(find.text('06:00'), findsWidgets);
    expect(find.text('18:00'), findsWidgets);
  });

  testWidgets('Clicking available slot allows phone reservation in dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebScheduleView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap available slot cell for court 01 at 08:00
    final slotFinder = find.byKey(const Key('web_slot_cell_court_01_08_00'));
    expect(slotFinder, findsOneWidget);
    await tester.tap(slotFinder);
    await tester.pumpAndSettle();

    // Action dialog appears
    expect(find.text('Quản lý Ca Sân'), findsOneWidget);
    expect(find.byKey(const Key('web_dialog_customer_name_input')), findsOneWidget);
    expect(find.byKey(const Key('web_dialog_customer_phone_input')), findsOneWidget);

    // Enter reservation info
    await tester.enterText(
        find.byKey(const Key('web_dialog_customer_name_input')), 'Lê Hoàng Nam');
    await tester.enterText(
        find.byKey(const Key('web_dialog_customer_phone_input')), '0933 111 222');
    await tester.tap(find.byKey(const Key('web_dialog_confirm_reserve_button')));
    await tester.pumpAndSettle();

    // Verify slot updated in store
    final updatedSlot = VenueOwnerStore.instance.slots
        .firstWhere((s) => s.slotId == 'court_01_08_00');
    expect(updatedSlot.status, equals(CourtSlotStatus.reservedManual));
    expect(updatedSlot.customerName, equals('Lê Hoàng Nam'));
  });

  testWidgets('Slot dialog allows quick price adjustment and maintenance lock',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebScheduleView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap slot court 02 at 09:00
    await tester.tap(find.byKey(const Key('web_slot_cell_court_02_09_00')));
    await tester.pumpAndSettle();

    // Lock for maintenance
    await tester.tap(find.byKey(const Key('web_dialog_lock_maintenance_button')));
    await tester.pumpAndSettle();

    final lockedSlot = VenueOwnerStore.instance.slots
        .firstWhere((s) => s.slotId == 'court_02_09_00');
    expect(lockedSlot.status, equals(CourtSlotStatus.maintenance));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/partner_web_schedule_test.dart`
Expected: Compilation errors (missing `PartnerWebScheduleView`).

- [ ] **Step 3: Implement `PartnerWebScheduleView` and connect in `PartnerWebScaffold`**

In `lib/presentation/widgets/partner_web/views/partner_web_schedule_view.dart`:
- Filter toolbar:
  - Sport filter tabs (`Tất cả`, `🏸 Sân Cầu Lông 1-4`, `🎾 Sân Pickleball 5-8`).
  - Shift filter chips (`Tất cả`, `Ca Sáng 06-12h`, `Ca Chiều 12-17h`, `Ca Tối 17-22h`).
- 2D Matrix Table:
  - Header Row: Sticky court cards with sport badge, court name, surface type.
  - Left Column: Sticky hour labels (06:00 to 21:00) with shift indicators.
  - Grid Cells:
    - Keyed by `web_slot_cell_${slot.slotId}`.
    - Status styling: Available (surface with border, price, peak tag), BookedApp (primary emerald with customer name & ticket), ReservedManual (amber with customer name), Maintenance (red stripe with lock icon).
  - Tapping cell opens `_showSlotManagementDialog`:
    - Reserving slot: Customer name & phone fields + `[Xác nhận giữ chỗ]` (`web_dialog_confirm_reserve_button`).
    - Adjusting price: Preset chips (80k, 100k, 120k, 150k, 180k, 240k) + custom input + `[Lưu giá mới]` (`web_dialog_save_price_button`).
    - Locking maintenance: `[Khóa sân bảo trì]` (`web_dialog_lock_maintenance_button`).
    - Unlocking: `[Mở lại ca sân trống]` (`web_dialog_unlock_slot_button`).

Connect into `PartnerWebScaffold`:
Replace schedule placeholder with `PartnerWebScheduleView()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/partner_web_schedule_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite and commit**

Run: `flutter test` and `flutter analyze`
```bash
git add lib/presentation/widgets/partner_web/views/partner_web_schedule_view.dart lib/presentation/widgets/partner_web/partner_web_scaffold.dart test/presentation/screens/partner_web_schedule_test.dart
git commit -m "feat: implement PartnerWebScheduleView master court schedule matrix"
```

---

### Task 4: PartnerWebPosView (Rapid QR/Ticket Check-in Bar, Arrivals Table, Add-on POS Counter)

**Files:**
- Create: `lib/presentation/widgets/partner_web/views/partner_web_pos_view.dart`
- Modify: `lib/presentation/widgets/partner_web/partner_web_scaffold.dart`
- Test: `test/presentation/screens/partner_web_pos_test.dart`

**Interfaces:**
- Consumes:
  - `VenueOwnerStore.instance.slotsNotifier`
  - `VenueOwnerStore.instance.checkInTicket(ticketId)`
  - `VenueOwnerStore.instance.isCheckedIn(ticketId)`
  - `VenueOwnerStore.instance.getCheckInTime(ticketId)`
- Produces:
  - `PartnerWebPosView` (`StatefulWidget`)

- [ ] **Step 1: Write the failing widget test for POS & Check-in View**

Create `test/presentation/screens/partner_web_pos_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/presentation/widgets/partner_web/views/partner_web_pos_view.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
    ThemeStore.instance.reset();
  });

  testWidgets('Rapid ticket check-in bar validates ticket on button tap and Enter',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebPosView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check pre-seeded ticket SH-8291 is not checked in yet
    expect(VenueOwnerStore.instance.isCheckedIn('SH-8291'), isFalse);

    // Enter ticket SH-8291 into rapid input
    final inputFinder = find.byKey(const Key('web_pos_ticket_input'));
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, 'SH-8291');
    await tester.tap(find.byKey(const Key('web_pos_checkin_button')));
    await tester.pumpAndSettle();

    // Verify checked in
    expect(VenueOwnerStore.instance.isCheckedIn('SH-8291'), isTrue);
    expect(find.textContaining('Check-in thành công'), findsOneWidget);
  });

  testWidgets('Arrivals table allows 1-click check-in from table row',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebPosView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Confirm check-in button for SH-8292
    final rowBtn = find.byKey(const Key('web_confirm_checkin_SH-8292'));
    expect(rowBtn, findsOneWidget);
    await tester.tap(rowBtn);
    await tester.pumpAndSettle();

    expect(VenueOwnerStore.instance.isCheckedIn('SH-8292'), isTrue);
  });

  testWidgets('Add-on POS Counter calculates bill and checks out',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebPosView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial bill is 0đ
    expect(find.text('0 đ'), findsWidgets);

    // Increment Pocari Sweat (20k)
    await tester.tap(find.byKey(const Key('addon_inc_pocari')));
    await tester.pump();
    expect(find.text('20.000 đ'), findsOneWidget);

    // Increment Thuê vợt (50k)
    await tester.tap(find.byKey(const Key('addon_inc_racket')));
    await tester.pump();
    expect(find.text('70.000 đ'), findsOneWidget);

    // Checkout button
    await tester.tap(find.byKey(const Key('web_pos_pay_counter_button')));
    await tester.pumpAndSettle();

    // Counter resets
    expect(find.text('0 đ'), findsWidgets);
    expect(find.textContaining('Thanh toán dịch vụ thành công'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/partner_web_pos_test.dart`
Expected: Compilation errors (missing `PartnerWebPosView`).

- [ ] **Step 3: Implement `PartnerWebPosView` and connect in `PartnerWebScaffold`**

In `lib/presentation/widgets/partner_web/views/partner_web_pos_view.dart`:
- Top Rapid Check-in Bar:
  - Input `Key('web_pos_ticket_input')` with keyboard submit (`onSubmitted`).
  - Button `Key('web_pos_checkin_button')`.
  - Alert message banner indicating check-in status (success or ticket not found).
- 2-Column or split layout:
  - Left / Main Table (65%): Today's Arrivals Table:
    - Lists all booked slots with ticket ID or customer name.
    - Columns: Mã vé, Khách hàng, Sân, Khung giờ, Trạng thái (Đã vào sân vs Chờ check-in), Thao tác (`Key('web_confirm_checkin_${ticketId}')`).
  - Right / Sidebar (35%): Add-on POS Quick Counter:
    - 5 popular items: Pocari Sweat (20k), Nước suối Aquafina (10k), Revive chanh muối (18k), Thuê vợt thi đấu (50k), Hộp bóng thi đấu (60k).
    - Increment/decrement buttons: `addon_inc_${id}`, `addon_dec_${id}`.
    - Live bill total calculation: `${total.toString()} đ`.
    - Checkout button `Key('web_pos_pay_counter_button')`: "Thanh toán tại quầy (Tiền mặt / QR)" with confirmation feedback.

Connect into `PartnerWebScaffold`:
Replace POS placeholder with `PartnerWebPosView()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/partner_web_pos_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite and commit**

Run: `flutter test` and `flutter analyze`
```bash
git add lib/presentation/widgets/partner_web/views/partner_web_pos_view.dart lib/presentation/widgets/partner_web/partner_web_scaffold.dart test/presentation/screens/partner_web_pos_test.dart
git commit -m "feat: implement PartnerWebPosView for rapid front-desk check-in and add-on sales"
```

---

### Task 5: PartnerWebRevenueView & Full End-to-End Verification

**Files:**
- Create: `lib/presentation/widgets/partner_web/views/partner_web_revenue_view.dart`
- Modify: `lib/presentation/widgets/partner_web/partner_web_scaffold.dart`
- Test: `test/presentation/screens/partner_web_revenue_test.dart`

**Interfaces:**
- Consumes:
  - `VenueOwnerStore.instance.slotsNotifier`
  - `ThemeStore.instance.themeModeNotifier`
- Produces:
  - `PartnerWebRevenueView` (`StatelessWidget`)

- [ ] **Step 1: Write the failing widget test for Revenue & Analytics View**

Create `test/presentation/screens/partner_web_revenue_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/presentation/widgets/partner_web/views/partner_web_revenue_view.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
    ThemeStore.instance.reset();
  });

  testWidgets('PartnerWebRevenueView renders 7-day revenue chart and breakdown metrics',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartnerWebRevenueView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Chart header & days
    expect(find.text('Biểu đồ Doanh thu 7 ngày gần nhất'), findsOneWidget);
    expect(find.text('Th 2'), findsOneWidget);
    expect(find.text('Chủ nhật'), findsOneWidget);

    // Breakdown cards
    expect(find.text('Doanh thu tiền sân'), findsOneWidget);
    expect(find.text('Dịch vụ phụ trợ'), findsOneWidget);
    expect(find.text('Cầu lông'), findsWidgets);
    expect(find.text('Pickleball'), findsWidgets);

    // Transaction table
    expect(find.text('Lịch sử Giao dịch gần nhất'), findsOneWidget);
    expect(find.text('SH-8291'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/partner_web_revenue_test.dart`
Expected: Compilation errors (missing `PartnerWebRevenueView`).

- [ ] **Step 3: Implement `PartnerWebRevenueView` and connect in `PartnerWebScaffold`**

In `lib/presentation/widgets/partner_web/views/partner_web_revenue_view.dart`:
- 7-Day Revenue Bar Chart:
  - Custom visual bar chart displaying revenues from Monday to Sunday.
  - Tooltips with formatted Vietnamese currency (`3.450.000 đ`).
- Revenue Breakdown Cards:
  - Sân đấu vs Dịch vụ phụ trợ (82% vs 18%).
  - Môn thể thao: Cầu lông vs Pickleball (58% vs 42%).
  - Ca giờ: Giờ vàng (Peak 64%) vs Giờ ưu đãi (Off-peak 36%).
- Transaction Log Table:
  - Rows showing: Thời gian, Khách hàng, Sân / Nội dung, Phương thức thanh toán (VietQR vs Tiền mặt), Trạng thái (Thành công), Số tiền.

Connect into `PartnerWebScaffold`:
Replace revenue placeholder with `PartnerWebRevenueView()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/partner_web_revenue_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite, analyzer, hot restart and commit**

Run full suite:
```bash
flutter test
flutter analyze
```
Commit changes:
```bash
git add lib/presentation/widgets/partner_web/views/partner_web_revenue_view.dart lib/presentation/widgets/partner_web/partner_web_scaffold.dart test/presentation/screens/partner_web_revenue_test.dart
git commit -m "feat: implement PartnerWebRevenueView with 7-day revenue chart and analytics"
```
Send Hot Restart `R` to background web server on port `46477`.

---

## Self-Review Checklist

1. **Spec Coverage:**
   - Responsive desktop viewport detection (`width >= 800`) & mobile frame switcher? -> Covered in Task 1.
   - Persistent 250px Sidebar with 4 nav items & Top Bar with notification integration? -> Covered in Task 1.
   - Module 1: Dashboard with KPIs, live feed, court status, quick actions? -> Covered in Task 2.
   - Module 2: Master Court Schedule Matrix for 16h x 8 courts, sport/shift filters, inline reservation/price modal? -> Covered in Task 3.
   - Module 3: Front-desk POS with rapid barcode/keyboard check-in, arrivals table, add-on sales counter? -> Covered in Task 4.
   - Module 4: Financial analytics with 7-day revenue bar chart, breakdown cards, transaction table? -> Covered in Task 5.
   - Theme adaptiveness (Light & Dark)? -> Built into all views via dynamic `AppColors`.

2. **Placeholder Scan:**
   - No "TBD", "TODO", "implement later", or empty placeholders.
   - Every step contains specific code, exact file paths, and assertions.

3. **Type Consistency:**
   - `VenueOwnerStore.instance.isWebDesktopViewNotifier`, `toggleWebDesktopView()` match across all tasks.
   - Statuses `CourtSlotStatus.available`, `bookedApp`, `reservedManual`, `maintenance` match existing domain entity.
   - Keys (`web_nav_dashboard`, `web_nav_schedule`, `web_nav_pos`, `web_nav_revenue`, `web_toggle_mobile_view`, etc.) are consistently defined and asserted.
