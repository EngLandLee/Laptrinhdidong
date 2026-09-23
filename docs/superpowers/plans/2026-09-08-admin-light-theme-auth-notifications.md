# Admin Web Light Theme, Auth (Login/Logout), and Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform Admin Web to default to the Wimbledon Minimalist light palette, add a full authentication system with dedicated `/login` page and logout actions, and implement a live notification dropdown center.

**Architecture:**
- **Theme:** Remove dark mode hardcoding from `index.html`, initialize theme state to light mode by default in `Topbar.tsx`, preserving toggle capability in `localStorage`.
- **Auth:** Extend `authStore.ts` with `isAuthenticated: boolean`, `login()`, `logout()`. Add `/login` route with `LoginView.tsx` supporting quick-login credentials for Super Admin and Club Owner. Protect all private routes with `ProtectedRoute`.
- **Notifications:** Create `notificationStore.ts` with unread badge counter, category-based notifications, `markAsRead()`, and `markAllAsRead()`. Integrate interactive `NotificationDropdown.tsx` attached to Topbar bell icon.

**Tech Stack:** React 19, TypeScript, Vite, Tailwind CSS v4, Lucide React, Vitest, React Testing Library.

## Global Constraints
- Preserve 100% test pass rate across all existing Admin Web (43+ tests) and Mobile Flutter tests (223+ tests).
- All new components must meet WCAG 2.1 AA contrast standards and include proper ARIA roles and labels.

---

### Task 1: Default Light Theme & Styling Polish

**Files:**
- Modify: `admin-web/index.html`
- Modify: `admin-web/src/components/layout/Topbar.tsx`
- Test: `admin-web/src/components/layout/AdminLayout.test.tsx`

- [ ] **Step 1: Update AdminLayout.test.tsx to assert default light mode**
- [ ] **Step 2: Run vitest to verify test failure/baseline**
- [ ] **Step 3: Update `admin-web/index.html` and `Topbar.tsx` to default to light mode**
- [ ] **Step 4: Run vitest to verify test passes**
- [ ] **Step 5: Commit light theme changes**

---

### Task 2: Auth Store (Login / Logout) & Protected Routing

**Files:**
- Modify: `admin-web/src/store/authStore.ts`
- Test: `admin-web/src/store/authStore.test.ts`
- Create: `admin-web/src/views/auth/LoginView.tsx`
- Test: `admin-web/src/views/auth/LoginView.test.tsx`
- Modify: `admin-web/src/App.tsx`
- Test: `admin-web/src/App.test.tsx`
- Modify: `admin-web/src/components/layout/Topbar.tsx`
- Modify: `admin-web/src/components/layout/Sidebar.tsx`

- [ ] **Step 1: Write unit tests in `authStore.test.ts` for `isAuthenticated`, `login()`, `logout()`**
- [ ] **Step 2: Implement `isAuthenticated`, `login()`, and `logout()` in `authStore.ts`**
- [ ] **Step 3: Write component tests in `LoginView.test.tsx`**
- [ ] **Step 4: Implement `LoginView.tsx` with email/password and quick-login buttons**
- [ ] **Step 5: Add `/login` and `ProtectedRoute` in `App.tsx`**
- [ ] **Step 6: Add Logout buttons to `Topbar.tsx` and `Sidebar.tsx`**
- [ ] **Step 7: Run vitest and ensure all auth tests pass**
- [ ] **Step 8: Commit auth changes**

---

### Task 3: Notification Store & Topbar Notification Dropdown

**Files:**
- Create: `admin-web/src/store/notificationStore.ts`
- Test: `admin-web/src/store/notificationStore.test.ts`
- Create: `admin-web/src/components/notifications/NotificationDropdown.tsx`
- Modify: `admin-web/src/components/layout/Topbar.tsx`
- Modify: `admin-web/src/components/layout/AdminLayout.test.tsx`

- [ ] **Step 1: Write unit tests in `notificationStore.test.ts`**
- [ ] **Step 2: Implement `notificationStore.ts`**
- [ ] **Step 3: Implement `NotificationDropdown.tsx`**
- [ ] **Step 4: Wire up Bell button in `Topbar.tsx` to toggle `NotificationDropdown` with badge count**
- [ ] **Step 5: Add tests for notification dropdown in `AdminLayout.test.tsx`**
- [ ] **Step 6: Run vitest to verify all tests pass**
- [ ] **Step 7: Commit notification changes**

---

### Task 4: Full Verification & E2E Confirmation

**Files:**
- Run: `npm --prefix admin-web test -- --run`
- Run: `flutter test`
- Verify: HTTP 200 on `http://localhost:5173/` and `http://localhost:46477/`

- [ ] **Step 1: Run all vitest suites**
- [ ] **Step 2: Run Flutter test suite**
- [ ] **Step 3: Verify local dev servers**
