# Design Spec: Authentication, Registration with OTP, Session Management & Guest Action Gates

## 1. Overview & Goals
Currently, SportHub opens directly with a pre-authenticated demo account (`user_demo_01` - Nguyễn Văn An). While convenient for quick testing, it lacks a standard mobile authentication lifecycle:
- Users cannot log in or log out.
- Users cannot register a new account with verification.
- Users cannot switch between different member roles (e.g., venue host vs regular player).
- Users who just want to browse (guests) are forced into a specific user identity.

This specification defines a comprehensive, production-grade authentication and session management system:
1. **Welcome & Authentication Screen (`AuthScreen`)** with Login and Register tabs.
2. **Interactive 6-digit OTP verification sheet** with demo auto-fill for registration.
3. **1-Tap Quick Demo Account Switcher** (Nguyễn Văn An, Lê Minh, Trần Thuỳ Linh).
4. **Guest Mode & Action Gates** allowing free browsing of venues and community posts while requiring login for bookings, recruitment, and tickets.
5. **Seamless Logout & Account Switching** in Profile tab.
6. **Reactive `AuthStore`** integrated with `UserProfileStore` and backward-compatible with the existing 104 tests.

---

## 2. Architecture & Data Model

### 2.1 `AuthState` & `AuthStore`
A reactive singleton managing the active user session and guest status:

```dart
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

Methods on `AuthStore`:
- `login(String phone, String password)`: Validates credentials against registered users and demo accounts.
- `register({required String fullName, required String phone, required String password, required String preferredSport})`: Stages a new user profile pending OTP verification.
- `verifyOtp(String otpCode)`: Verifies 6-digit OTP (accepts `123456` or any 6-digit sequence), commits the new profile to memory, and transitions to `AuthState.authenticated(newUser)`.
- `loginWithDemo(UserProfile demoUser)`: 1-tap login with one of the pre-configured demo users.
- `continueAsGuest()`: Transitions to `AuthState.guest()`.
- `logout()`: Clears active user, resets session, and transitions to `AuthState.unauthenticated()`.

### 2.2 Pre-Configured Demo Accounts (`SeedData.demoUsers`)
1. **Nguyễn Văn An** (`user_demo_01`):
   - Phone: `0909 123 456`, Password: `password123` (or `123456`)
   - Role: Active DUPR 3.5 Pickleball & Badminton player (18 matches, 4.9 rating).
2. **Lê Minh** (`user_demo_02`):
   - Phone: `0918 888 999`, Password: `password123`
   - Role: Thảo Điền Hub Community Host.
3. **Trần Thuỳ Linh** (`user_demo_03`):
   - Phone: `0977 666 555`, Password: `password123`
   - Role: New sports enthusiast (Beginner).

### 2.3 Backward Compatibility Integration
`UserProfileStore` will synchronize with `AuthStore`:
- When `AuthStore.instance.stateNotifier` emits a new authenticated user, `UserProfileStore.instance.profileNotifier` is updated with `state.user`.
- For test isolation, `AuthStore.instance.reset()` resets to pre-authenticated `user_demo_01` in test environments if `SportHubApp` is run without overriding, ensuring all 104 existing tests pass seamlessly.

---

## 3. UI Components & Screen Specifications

### 3.1 `AuthScreen` (`lib/presentation/screens/auth_screen.dart`)
- **Branding**: SportHub neon logo (`#10B981`), Sporty Dark Luxury theme (`AppColors.background #0B0F19`, `AppColors.surface #161F30`).
- **Tab Bar / Segmented Switch**:
  - `[⚡ Đăng nhập]` (`Key('auth_tab_login')`)
  - `[✨ Đăng ký mới]` (`Key('auth_tab_register')`)
- **Login Form**:
  - Phone input field (`Key('login_phone_input')`)
  - Password input field with visibility toggle (`Key('login_password_input')`, `Key('toggle_password_visibility')`)
  - Error message display (`Key('login_error_text')`)
  - Login submit button: `[⚡ Đăng nhập]` (`Key('login_submit_button')`)
- **Registration Form**:
  - Full Name field (`Key('register_name_input')`)
  - Phone field (`Key('register_phone_input')`)
  - Password field (`Key('register_password_input')`)
  - Sport selection chips (Cầu lông, Pickleball, Bóng đá) (`Key('register_sport_chips')`)
  - Register submit button: `[Tiếp tục xác thực OTP ➔]` (`Key('register_submit_button')`)
- **OTP Verification Bottom Sheet** (`Key('otp_verification_sheet')`):
  - 6-digit input cells (`Key('otp_input_field')`)
  - Demo hint: `"Mã OTP thử nghiệm: 123456"`
  - Quick button: `[⚡ Tự động điền 123456]` (`Key('otp_autofill_button')`)
  - Confirm button: `[Xác nhận & Hoàn tất]` (`Key('otp_confirm_button')`)
- **1-Tap Quick Demo Switcher** (`Key('demo_account_switcher')`):
  - Row / list of compact cards for An, Minh, Linh: `Key('quick_login_an')`, `Key('quick_login_minh')`, `Key('quick_login_linh')`.
- **Guest Access**:
  - Text button: `[Bỏ qua, khám phá với tư cách Khách ➔]` (`Key('continue_as_guest_button')`).

### 3.2 Action Gates for Guest Mode (`AuthActionGate`)
When an unauthenticated guest user performs an action requiring an account, the app shows a sleek modal bottom sheet (`Key('auth_guard_sheet')`):
- Actions triggering the gate:
  - Tapping `Xác nhận đặt sân & thanh toán VietQR`
  - Tapping `+ Đăng kèo` or `Tham gia ngay` / `Gửi yêu cầu` in Community tab
  - Tapping `📢 Tuyển thêm người chơi` in Tickets tab
- Modal content:
  - Icon: `Icons.lock_person_rounded` with neon green accent
  - Title: `"Yêu cầu Đăng nhập"`
  - Subtitle: `"Vui lòng đăng nhập hoặc tạo tài khoản miễn phí để tiếp tục thao tác này."`
  - Action buttons:
    - `[⚡ Đăng nhập ngay]` (`Key('guard_login_now_button')`) -> Opens `AuthScreen` / Login sheet.
    - `[Để sau]` (`Key('guard_dismiss_button')`) -> Closes sheet.

### 3.3 Profile Screen Updates (`ProfileScreen` in Tab 4)
- When Authenticated:
  - Quick Account Switcher dropdown or chips at the bottom of the profile.
  - Logout button `[🚪 Đăng xuất]` (`Key('profile_logout_button')`):
    - Confirmation dialog: `"Bạn có chắc muốn đăng xuất?"`
    - Tapping `"Đăng xuất"` (`Key('confirm_logout_button')`) logs out and returns to `AuthScreen`.
- When in Guest Mode:
  - Header displays `👤 Khách vãng lai`.
  - Prominent banner: `"Đăng nhập để lưu lịch sử đặt sân và tham gia cộng đồng thể thao SportHub!"`
  - Action button: `[⚡ Đăng nhập / Đăng ký ngay]` (`Key('guest_profile_login_button')`).

### 3.4 Tickets Screen Updates (`TicketsScreen` in Tab 3)
- When in Guest Mode:
  - Empty state with lock icon: `"Bạn chưa đăng nhập. Vui lòng đăng nhập để xem và quản lý vé đặt sân của bạn."`
  - Button `[⚡ Đăng nhập ngay]` (`Key('tickets_guest_login_button')`).

---

## 4. Key Verification & Testing Strategy
- **Unit Tests**:
  - `AuthStore`: test login with valid/invalid credentials, registration with OTP, demo switching, and logout.
- **Widget Tests**:
  - `test/presentation/screens/auth_screen_test.dart`:
    - Tests login with valid/invalid input.
    - Tests 1-tap quick demo login.
    - Tests registration flow through OTP verification.
    - Tests guest mode entry.
  - `test/presentation/screens/auth_guard_test.dart`:
    - Tests action gates when guest tries to book or create community post.
    - Tests logout flow from Profile screen.
- **Full Suite Regression**:
  - Run full `flutter test` (104+ tests) ensuring 100% pass rate.
  - Run `flutter analyze` ensuring 0 warnings/errors.
