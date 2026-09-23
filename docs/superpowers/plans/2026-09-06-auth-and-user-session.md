# Authentication, Registration with OTP & User Session Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement full authentication lifecycle in SportHub with Login, Registration with 6-digit simulated OTP, 1-tap demo user switcher, Profile logout, Guest mode, and action gates for bookings/community interactions.

**Architecture:** A reactive singleton `AuthStore` managing `AuthState` with `ValueNotifier`, synchronized bidirectionally with `UserProfileStore`. An `AuthScreen` supporting Login, Register with OTP, quick demo switcher cards, and guest entry. Action gates (`AuthGuardSheet`) guarding protected actions for unauthenticated guests.

**Tech Stack:** Flutter 3.x, Dart 3.x, ValueNotifier reactive state, Sporty Dark Luxury styling.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese.
- Design Theme: Sporty Dark Luxury (AppColors.background #0B0F19, surface #161F30, primary #10B981, secondary #06B6D4, accent #F59E0B).
- Backward Compatibility: Keep all existing 104 tests passing.

---

### Task 1: AuthState, AuthStore & Demo Users Seed Data

**Files:**
- Create: `lib/domain/entities/auth_state.dart`
- Create: `lib/core/state/auth_store.dart`
- Modify: `lib/core/utils/seed_data.dart`
- Modify: `lib/main.dart` (wire `UserProfileStore` to `AuthStore`)
- Create: `test/core/state/auth_store_test.dart`

**Interfaces:**
- Produces:
  - `class AuthState { final bool isAuthenticated; final UserProfile? user; final bool isGuest; }`
  - `class AuthStore { static final instance; ValueNotifier<AuthState> stateNotifier; login(phone, pass); register(profile, pass); verifyOtp(code); loginWithDemo(user); continueAsGuest(); logout(); reset(); }`
  - `SeedData.demoUsers: List<UserProfile>`

- [ ] **Step 1: Write failing unit test for AuthStore**

Create `test/core/state/auth_store_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/user_profile.dart';

void main() {
  late AuthStore authStore;

  setUp(() {
    authStore = AuthStore.instance;
    authStore.reset();
  });

  test('initial state is authenticated with default demo user for backward compatibility', () {
    expect(authStore.state.isAuthenticated, isTrue);
    expect(authStore.currentUser?.userId, equals('user_demo_01'));
    expect(authStore.isGuest, isFalse);
  });

  test('logout sets state to unauthenticated', () {
    authStore.logout();
    expect(authStore.state.isAuthenticated, isFalse);
    expect(authStore.currentUser, isNull);
    expect(authStore.isGuest, isFalse);
  });

  test('continueAsGuest sets state to guest', () {
    authStore.continueAsGuest();
    expect(authStore.state.isAuthenticated, isFalse);
    expect(authStore.currentUser, isNull);
    expect(authStore.isGuest, isTrue);
  });

  test('loginWithDemo switches active user', () {
    final minh = SeedData.demoUsers.firstWhere((u) => u.userId == 'user_demo_02');
    authStore.loginWithDemo(minh);
    expect(authStore.state.isAuthenticated, isTrue);
    expect(authStore.currentUser?.userId, equals('user_demo_02'));
    expect(authStore.currentUser?.fullName, equals('Lê Minh'));
  });

  test('login with valid credentials succeeds', () {
    authStore.logout();
    final result = authStore.login('0909 123 456', '123456');
    expect(result.success, isTrue);
    expect(authStore.state.isAuthenticated, isTrue);
  });

  test('login with invalid credentials fails with message', () {
    authStore.logout();
    final result = authStore.login('0909 123 456', 'wrongpass');
    expect(result.success, isFalse);
    expect(result.errorMessage, isNotNull);
    expect(authStore.state.isAuthenticated, isFalse);
  });

  test('register stages pending profile and verifyOtp completes registration', () {
    authStore.logout();
    const newProfile = UserProfile(
      userId: 'user_new_01',
      fullName: 'Phạm Hoàng',
      phone: '0933 111 222',
      preferredSport: 'football',
      skillLevel: 'Cơ bản',
      district: 'Quận 1',
      playTimePreference: 'Tối',
    );

    final regResult = authStore.stageRegistration(profile: newProfile, password: 'password123');
    expect(regResult.success, isTrue);
    expect(authStore.hasPendingOtp, isTrue);

    final otpResult = authStore.verifyOtp('123456');
    expect(otpResult.success, isTrue);
    expect(authStore.state.isAuthenticated, isTrue);
    expect(authStore.currentUser?.phone, equals('0933 111 222'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/state/auth_store_test.dart`
Expected: FAIL (files missing).

- [ ] **Step 3: Implement AuthState, SeedData demoUsers, and AuthStore**

Create `lib/domain/entities/auth_state.dart`:
```dart
import 'package:sporthub/domain/entities/user_profile.dart';

class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final bool isGuest;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.isGuest = false,
  });

  bool get isLoggedIn => isAuthenticated && user != null;

  factory AuthState.unauthenticated() => const AuthState(isAuthenticated: false);
  factory AuthState.guest() => const AuthState(isAuthenticated: false, isGuest: true);
  factory AuthState.authenticated(UserProfile user) =>
      AuthState(isAuthenticated: true, user: user, isGuest: false);
}
```

Update `lib/core/utils/seed_data.dart`:
Add `static const List<UserProfile> demoUsers = [ ... ];` with An, Minh, Linh.

Create `lib/core/state/auth_store.dart`:
Implement `AuthStore` with in-memory users, `stateNotifier`, `login`, `stageRegistration`, `verifyOtp`, `loginWithDemo`, `continueAsGuest`, `logout`, and `reset`.

Sync with `UserProfileStore` in `lib/main.dart` so `UserProfileStore.instance.profile` reflects `AuthStore.instance.currentUser`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/state/auth_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: 104+ passed, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/domain/entities/auth_state.dart lib/core/state/auth_store.dart lib/core/utils/seed_data.dart lib/main.dart test/core/state/auth_store_test.dart
git commit -m "feat: implement AuthState, AuthStore, and demo user seed data"
```

---

### Task 2: AuthScreen with Login, Register, OTP Modal & Demo Switcher

**Files:**
- Create: `lib/presentation/screens/auth_screen.dart`
- Create: `test/presentation/screens/auth_screen_test.dart`

**Interfaces:**
- Consumes: `AuthStore.instance`, `SeedData.demoUsers`
- Produces: `AuthScreen` widget with Keys:
  - `auth_tab_login`, `auth_tab_register`
  - `login_phone_input`, `login_password_input`, `toggle_password_visibility`, `login_submit_button`, `login_error_text`
  - `register_name_input`, `register_phone_input`, `register_password_input`, `register_sport_chips`, `register_submit_button`
  - `otp_input_field`, `otp_autofill_button`, `otp_confirm_button`
  - `quick_login_user_demo_01`, `quick_login_user_demo_02`, `quick_login_user_demo_03`
  - `continue_as_guest_button`

- [ ] **Step 1: Write failing widget test for AuthScreen**

Create `test/presentation/screens/auth_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/presentation/screens/auth_screen.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    AuthStore.instance.logout();
  });

  testWidgets('AuthScreen displays login tab and allows quick demo login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
    expect(find.byKey(const Key('login_phone_input')), findsOneWidget);
    expect(find.byKey(const Key('quick_login_user_demo_01')), findsOneWidget);

    // Tap quick login An
    await tester.tap(find.byKey(const Key('quick_login_user_demo_01')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Nguyễn Văn An'));
  });

  testWidgets('AuthScreen allows switching to register tab, entering info and verifying OTP', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    // Switch to Register tab
    await tester.tap(find.byKey(const Key('auth_tab_register')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_name_input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register_name_input')), 'Trần Nam');
    await tester.enterText(find.byKey(const Key('register_phone_input')), '0988 777 666');
    await tester.enterText(find.byKey(const Key('register_password_input')), '123456');
    await tester.pumpAndSettle();

    // Tap continue to OTP
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    // OTP bottom sheet should appear
    expect(find.byKey(const Key('otp_input_field')), findsOneWidget);

    // Auto-fill OTP
    await tester.tap(find.byKey(const Key('otp_autofill_button')));
    await tester.pumpAndSettle();

    // Confirm OTP
    await tester.tap(find.byKey(const Key('otp_confirm_button')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Trần Nam'));
  });

  testWidgets('AuthScreen allows continuing as guest', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    final guestBtn = find.byKey(const Key('continue_as_guest_button'));
    expect(guestBtn, findsOneWidget);
    await tester.tap(guestBtn);
    await tester.pumpAndSettle();

    expect(AuthStore.instance.isGuest, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/auth_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement AuthScreen**

Create `lib/presentation/screens/auth_screen.dart`:
- Header with SportHub neon icon and title.
- Segmented control / Tab bar for Login and Register.
- Form inputs with validation, password visibility toggles.
- Quick demo login horizontal card list.
- OTP modal bottom sheet with 6-digit input, autofill button, and verification callback.
- "Bỏ qua, khám phá với tư cách Khách" button.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/screens/auth_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: PASS, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/screens/auth_screen.dart test/presentation/screens/auth_screen_test.dart
git commit -m "feat: implement AuthScreen with Login, Register, OTP verification, and demo switcher"
```

---

### Task 3: App Gate, Profile Logout & Account Switcher

**Files:**
- Modify: `lib/main.dart` (`SportHubApp`, `ProfileScreen`, `TicketsScreen`)
- Create: `test/presentation/screens/auth_navigation_and_logout_test.dart`

**Interfaces:**
- Consumes: `AuthStore.instance.stateNotifier`, `AuthScreen`
- Produces:
  - `SportHubApp` switches to `AuthScreen` when `!state.isAuthenticated && !state.isGuest`.
  - `ProfileScreen` renders `profile_logout_button`, `profile_quick_switch_button`, and guest profile banner when `isGuest`.
  - `TicketsScreen` renders guest state when `isGuest`.

- [ ] **Step 1: Write failing widget test for App Gate & Profile Logout**

Create `test/presentation/screens/auth_navigation_and_logout_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/auth_navigation_and_logout_test.dart`
Expected: FAIL.

- [ ] **Step 3: Update SportHubApp, ProfileScreen, and TicketsScreen in lib/main.dart**

1. Wrap `SportHubApp` root with `ValueListenableBuilder<AuthState>` on `AuthStore.instance.stateNotifier`:
   - If `!state.isAuthenticated && !state.isGuest`, render `const AuthScreen()`.
   - Else, render `_SportHubShell()`.
2. In `ProfileScreen`:
   - Add `[🚪 Đăng xuất]` button (`Key('profile_logout_button')`) with confirmation dialog.
   - Add `[🔄 Đổi tài khoản nhanh]` bottom sheet allowing 1-tap switch between demo users.
   - If `AuthStore.instance.isGuest`: render Guest banner with `[⚡ Đăng nhập / Đăng ký ngay]` (`Key('guest_profile_login_button')`).
3. In `TicketsScreen`:
   - If `AuthStore.instance.isGuest`: render locked empty state with `Key('tickets_guest_login_button')`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/auth_navigation_and_logout_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: 104+ passed, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/main.dart test/presentation/screens/auth_navigation_and_logout_test.dart
git commit -m "feat: integrate AuthScreen root gate, Profile logout, and Guest state in TicketsScreen"
```

---

### Task 4: Guest Action Gates (Booking & Community Recruitment)

**Files:**
- Create: `lib/presentation/widgets/auth_guard_sheet.dart`
- Modify: `lib/main.dart` (`VenueDetailScreen._showVietQRDialog`, `MatchmakingScreen._showCreatePostDialog`, `_joinPost`)
- Create: `test/presentation/screens/auth_guard_test.dart`

**Interfaces:**
- Produces: `AuthGuardSheet.show(BuildContext context, {required String actionName})`
  - Keys: `auth_guard_sheet`, `guard_login_now_button`, `guard_dismiss_button`
- Consumes: `AuthStore.instance.isGuest`

- [ ] **Step 1: Write failing widget test for AuthGuardSheet**

Create `test/presentation/screens/auth_guard_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/main.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    AuthStore.instance.continueAsGuest();
  });

  testWidgets('Guest user tapping + Đăng kèo in Community shows AuthGuardSheet', (tester) async {
    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Go to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Tap + Đăng kèo
    final postBtn = find.text('+ Đăng kèo');
    await tester.tap(postBtn);
    await tester.pumpAndSettle();

    // Expect auth guard sheet
    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);
    expect(find.text('Cần đăng nhập để tiếp tục'), findsOneWidget);

    // Tap dismiss
    await tester.tap(find.byKey(const Key('guard_dismiss_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/screens/auth_guard_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement AuthGuardSheet and wire into protected actions**

Create `lib/presentation/widgets/auth_guard_sheet.dart`:
- Sleek bottom sheet with lock icon, message explaining login requirement, `[⚡ Đăng nhập ngay]` button and `[Để sau]` button.
- Tapping `[⚡ Đăng nhập ngay]` calls `AuthStore.instance.logout()` which navigates to `AuthScreen`.

Integrate into `lib/main.dart`:
- In `_showCreatePostDialog`: if `AuthStore.instance.isGuest`, call `AuthGuardSheet.show(context, actionName: 'đăng kèo thể thao')` and return.
- In `_joinPost` / `request_join`: if `AuthStore.instance.isGuest`, call `AuthGuardSheet.show(context, actionName: 'tham gia kèo đấu')` and return.
- In `VenueDetailScreen._showVietQRDialog`: if `AuthStore.instance.isGuest`, call `AuthGuardSheet.show(context, actionName: 'đặt sân')` and return.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/presentation/screens/auth_guard_test.dart`
Expected: PASS.

- [ ] **Step 5: Run full test suite & analyze**

Run: `flutter test && flutter analyze`
Expected: 104+ passed, 0 issues.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/widgets/auth_guard_sheet.dart lib/main.dart test/presentation/screens/auth_guard_test.dart
git commit -m "feat: implement AuthGuardSheet for guest user booking and community actions"
```

---

### Task 5: Full Suite Verification, Web Hot Restart & Demo Handoff

**Files:**
- None (verification and demo)

- [ ] **Step 1: Run static analyzer**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run full test suite**
Run: `flutter test`
Expected: All 110+ tests pass across all test suites.

- [ ] **Step 3: Hot restart web server**
Send hot restart `R\n` to background task `task-673`.

- [ ] **Step 4: Demo handoff**
Present complete feature walkthrough in Vietnamese with link `http://localhost:46477/`.
