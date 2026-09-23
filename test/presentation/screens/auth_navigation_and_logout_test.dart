import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
  });

  testWidgets('When unauthenticated, SportHubApp renders AuthScreen', (tester) async {
    AuthStore.instance.logout();
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
  });

  testWidgets('ProfileScreen renders logout button and tapping it logs out to AuthScreen', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Profile tab
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    final logoutBtn = find.byKey(const Key('profile_logout_button'));
    await tester.ensureVisible(logoutBtn);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Xác nhận đăng xuất'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_logout_button')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isFalse);
    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
  });

  testWidgets('ProfileScreen renders quick switch button and switches account', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Profile tab
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    final switchBtn = find.byKey(const Key('profile_quick_switch_button'));
    await tester.ensureVisible(switchBtn);
    await tester.tap(switchBtn);
    await tester.pumpAndSettle();

    // Select second demo user: Trần Thị Bình
    final secondUser = SeedData.demoUsers[1];
    final userTile = find.text(secondUser.fullName);
    expect(userTile, findsOneWidget);
    await tester.tap(userTile);
    await tester.pumpAndSettle();

    expect(AuthStore.instance.currentUser?.userId, secondUser.userId);
    expect(find.text(secondUser.fullName), findsWidgets);
  });

  testWidgets('Guest mode renders guest banner in ProfileScreen with login button', (tester) async {
    AuthStore.instance.continueAsGuest();
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Profile tab
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Khách vãng lai'), findsOneWidget);
    final guestLoginBtn = find.byKey(const Key('guest_profile_login_button'));
    expect(guestLoginBtn, findsOneWidget);

    await tester.tap(guestLoginBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
  });

  testWidgets('Guest mode renders guest locked state in TicketsScreen with login button', (tester) async {
    AuthStore.instance.continueAsGuest();
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Switch to Tickets tab
    await tester.tap(find.byIcon(Icons.confirmation_number_rounded));
    await tester.pumpAndSettle();

    final ticketsGuestLoginBtn = find.byKey(const Key('tickets_guest_login_button'));
    expect(ticketsGuestLoginBtn, findsOneWidget);

    await tester.tap(ticketsGuestLoginBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
  });
}
