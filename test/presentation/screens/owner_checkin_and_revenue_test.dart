import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/venue_owner_store.dart';
import 'package:sporthub/presentation/screens/owner_navigation_screen.dart';

void main() {
  setUp(() {
    VenueOwnerStore.instance.reset();
  });

  testWidgets('OwnerCheckinTab displays bookings and handles check-in action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Check-in tab
    await tester.tap(find.byKey(const Key('owner_tab_checkin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkin_search_input')), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsWidgets);

    // Tap confirm checkin for ticket SH-8291
    final checkinBtn = find.byKey(const Key('confirm_checkin_SH-8291'));
    expect(checkinBtn, findsOneWidget);
    await tester.ensureVisible(checkinBtn);
    await tester.tap(checkinBtn);
    await tester.pumpAndSettle();
    expect(find.textContaining('Đã nhận sân'), findsWidgets);
    expect(VenueOwnerStore.instance.isCheckedIn('SH-8291'), isTrue);
  });

  testWidgets('OwnerCheckinTab search filter works by query and QR scanner modal checks in', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Check-in tab
    await tester.tap(find.byKey(const Key('owner_tab_checkin')));
    await tester.pumpAndSettle();

    // Search for Tran Thuy Linh
    final searchInput = find.byKey(const Key('checkin_search_input'));
    await tester.enterText(searchInput, 'Trần Thuỳ Linh');
    await tester.pumpAndSettle();

    expect(find.text('Trần Thuỳ Linh'), findsWidgets);
    expect(find.text('Nguyễn Văn An'), findsNothing);

    // Clear search
    await tester.enterText(searchInput, '');
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Văn An'), findsWidgets);

    // Open QR scanner simulation modal
    final qrBtn = find.byKey(const Key('open_qr_scanner_button'));
    expect(qrBtn, findsOneWidget);
    await tester.tap(qrBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qr_scanner_modal')), findsOneWidget);
    expect(find.byKey(const Key('qr_input_field')), findsOneWidget);

    // Enter ticket code SH-7714 and submit
    await tester.enterText(find.byKey(const Key('qr_input_field')), 'SH-7714');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qr_submit_checkin_button')));
    await tester.pumpAndSettle();

    // Verify modal dismissed and SH-7714 is checked in
    expect(find.byKey(const Key('qr_scanner_modal')), findsNothing);
    expect(VenueOwnerStore.instance.isCheckedIn('SH-7714'), isTrue);
  });

  testWidgets('OwnerRevenueTab displays revenue metrics, period filter, and occupancy stats', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OwnerNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Revenue tab
    await tester.tap(find.byKey(const Key('owner_tab_revenue')));
    await tester.pumpAndSettle();

    expect(find.text('Tổng doanh thu hôm nay'), findsOneWidget);
    expect(find.text('Tỷ lệ lấp đầy'), findsOneWidget);
    expect(find.text('Dịch vụ bán kèm (Add-ons)'), findsOneWidget);
    expect(find.text('Biểu đồ doanh thu 7 ngày qua'), findsOneWidget);

    // Test period switching
    expect(find.byKey(const Key('revenue_period_today')), findsOneWidget);
    expect(find.byKey(const Key('revenue_period_week')), findsOneWidget);
    expect(find.byKey(const Key('revenue_period_month')), findsOneWidget);

    await tester.tap(find.byKey(const Key('revenue_period_week')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('revenue_period_month')));
    await tester.pumpAndSettle();
  });
}
