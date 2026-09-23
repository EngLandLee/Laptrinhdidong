# Admin Web Light Theme, Auth (Login/Logout), & Notifications Design

## 1. Overview & Goals
- **Default Light Theme**: Transition Admin Web to default to a clean, eye-friendly Wimbledon Minimalist light palette (`bg-slate-50`, crisp cards `bg-white`, subtle borders `border-slate-200`, deep emerald accents), while maintaining the option to toggle to dark mode.
- **Authentication (Login / Logout)**: Provide a dedicated, responsive `/login` screen with rapid 1-click test credentials (Super Admin and Partner Club Owner), route protection via `ProtectedRoute`, and accessible Logout actions in the Topbar and Sidebar.
- **Notifications Center**: A notification drawer/dropdown activated by the Topbar bell button (🔔), showing unread badge counters, actionable status updates (new app bookings, check-ins, maintenance alerts), and "Mark all as read".

---

## 2. Architecture & Components

### 2.1 Default Light Theme
- **`admin-web/index.html`**:
  - Remove hardcoded `class="dark"` from `<html>`.
  - Update `<body>` classes to: `bg-slate-50 text-slate-900 dark:bg-[#0B0F19] dark:text-slate-100`.
- **`admin-web/src/components/layout/Topbar.tsx`**:
  - Update initial state of `isDarkMode` to check `localStorage.getItem('sporthub_theme') === 'dark'` (defaulting to `false`/light mode if unset).

### 2.2 Auth Store & Login/Logout Flow
- **`admin-web/src/store/authStore.ts`**:
  - Add `isAuthenticated: boolean` to `AuthStoreState` (default `true` for development or initialized from `localStorage`).
  - Add methods:
    - `login(email: string, role?: UserRole): boolean`
    - `logout(): void`
- **`admin-web/src/views/auth/LoginView.tsx`**:
  - Clean card with SportHub Admin branding.
  - Standard email/password inputs.
  - Quick action buttons:
    - "Đăng nhập nhanh Super Admin" (`admin@sporthub.vn`)
    - "Đăng nhập nhanh Chủ Sân Tao Đàn" (`partner@taodan.vn`)
- **`admin-web/src/App.tsx`**:
  - Add `/login` route.
  - Add `ProtectedRoute` component: redirects to `/login` when `!isAuthenticated`.
- **Topbar & Sidebar**:
  - Add "Đăng xuất" button with `LogOut` icon.
  - Clicking calls `authStore.logout()` and navigates to `/login`.

### 2.3 Notifications Center
- **`admin-web/src/store/notificationStore.ts`**:
  - Notification items: id, title, message, time, isRead, type (`booking` | `checkin` | `maintenance` | `revenue`).
  - Methods: `markAsRead(id)`, `markAllAsRead()`, `getUnreadCount()`.
- **Topbar Bell Dropdown**:
  - Bell icon with unread badge counter (e.g. `3`).
  - Dropdown menu showing the list of recent notifications with timestamps and type icons.
  - "Đánh dấu tất cả đã đọc" button.

---

## 3. Testing & Verification
- Unit & Component tests with Vitest:
  - `LoginView.test.tsx` (renders form, quick login buttons trigger auth, redirects on submit).
  - `authStore.test.ts` (verifies `login` and `logout` state transitions).
  - `notificationStore.test.ts` (verifies unread counter and marking as read).
  - `Topbar.test.tsx` / `AdminLayout.test.tsx` (verifies bell opens notification panel, logout action triggers redirect).
- Maintain 100% test pass rate across all test suites.
