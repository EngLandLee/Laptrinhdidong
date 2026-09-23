# SportHub Web Admin & Partner Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a modern, standalone React 19 + TypeScript + Vite + Tailwind CSS Web Management Portal in `admin-web/` featuring 2-tier role-based access control (Super Admin & Venue Partner) for full management of badminton & pickleball courts, live schedule matrices, POS front-desk check-in, and financial analytics.

**Architecture:** A standalone Single Page Application in `admin-web/` structured with React Router v6, Tailwind CSS, Lucide React Icons, and a reactive LocalStorage store engine (`venueStore`, `authStore`) pre-seeded with realistic data matching the mobile app (Tao Đàn, Kỳ Hòa, Tân Bình Arena, Phú Nhuận). The app features an interactive Role Switcher (`Super Admin` <-> `Chủ Sân Tao Đàn`) and Theme Switcher (Dark / Light) embedded in the top bar.

**Tech Stack:** React 19, TypeScript, Vite, Tailwind CSS v4, Lucide React Icons, React Router DOM v6, Vitest & React Testing Library.

## Global Constraints

- Location: `/home/quocanh/Projects/Mobile/admin-web`
- UI Language: Vietnamese (all navigation, status chips, table headers, forms, and alerts).
- Design Theme: Modern Athletic Dashboard supporting both Dark Mode (`#0B0F19` background) and Clean Light Mode (`#F8FAFC` background) with Emerald (`#10B981`) and Amber (`#F59E0B`) highlights.
- Testing: Vitest + Testing Library for unit and component tests.
- Code Quality: Zero TypeScript compiler errors (`tsc --noEmit`), clean production build (`npm run build`).

---

### Task 1: Project Scaffolding, TypeScript Config, Tailwind Setup & Reactive Store Engine

**Files:**
- Create: `admin-web/package.json`
- Create: `admin-web/vite.config.ts`
- Create: `admin-web/tsconfig.json`
- Create: `admin-web/index.html`
- Create: `admin-web/src/index.css`
- Create: `admin-web/src/types/index.ts`
- Create: `admin-web/src/store/seedData.ts`
- Create: `admin-web/src/store/venueStore.ts`
- Create: `admin-web/src/store/authStore.ts`
- Test: `admin-web/src/store/venueStore.test.ts`

**Interfaces:**
- Consumes: None (root scaffolding)
- Produces:
  - Domain Types: `Venue`, `Court`, `CourtSlot`, `Booking`, `UserRole`, `PartnerAccount`
  - `authStore`: `useAuthStore()` (current role: `superadmin` | `partner`, activeVenueId: string)
  - `venueStore`: `useVenueStore()` (venues, courts, slots, bookings, addVenue, addCourt, updateCourt, reserveSlot, updateSlotPrice, lockMaintenance, unlockSlot, checkInTicket)

- [ ] **Step 1: Write failing unit tests for `venueStore`**

Create `admin-web/src/store/venueStore.test.ts`:
```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { venueStore } from './venueStore';

describe('venueStore', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('initializes with seed venues including Tao Đàn', () => {
    const venues = venueStore.getVenues();
    expect(venues.length).toBeGreaterThanOrEqual(4);
    const taoDan = venues.find(v => v.id === 'venue_01');
    expect(taoDan).toBeDefined();
    expect(taoDan?.name).toContain('Tao Đàn');
  });

  it('allows adding a new sports venue', () => {
    venueStore.addVenue({
      id: 'venue_custom',
      name: 'CLB Cầu Lông Thủ Đức Arena',
      address: '12 Võ Văn Ngân, TP. Thủ Đức',
      district: 'Thủ Đức',
      hotline: '0901 234 567',
      sports: ['badminton', 'pickleball'],
      openTime: '06:00',
      closeTime: '22:00',
      baseHourlyRate: 150000,
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      isActive: true,
    });

    const venue = venueStore.getVenueById('venue_custom');
    expect(venue).toBeDefined();
    expect(venue?.name).toBe('CLB Cầu Lông Thủ Đức Arena');
  });

  it('allows adding a new court to Tao Đàn', () => {
    venueStore.addCourt('venue_01', {
      name: 'Sân Cầu Lông 09',
      sport: 'badminton',
      surfaceType: 'Thảm Yonex Tiêu Chuẩn',
      facilityType: 'indoor',
      regularPrice: 120000,
      peakPrice: 180000,
      isActive: true,
    });

    const courts = venueStore.getCourtsByVenue('venue_01');
    expect(courts.length).toBe(9);
    expect(courts.some(c => c.name === 'Sân Cầu Lông 09')).toBe(true);
  });

  it('allows reserving slot manually and checking in ticket', () => {
    // Reserve slot
    venueStore.reserveSlot('court_01_08_00', {
      customerName: 'Hoàng Long',
      customerPhone: '0912 345 678',
    });

    const slot = venueStore.getSlotById('court_01_08_00');
    expect(slot?.status).toBe('reservedManual');
    expect(slot?.customerName).toBe('Hoàng Long');

    // Check-in pre-seeded ticket SH-8291
    const checkInResult = venueStore.checkInTicket('SH-8291');
    expect(checkInResult).toBe(true);
    expect(venueStore.isCheckedIn('SH-8291')).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin-web && npm test`
Expected: FAIL (file or dependencies not found).

- [ ] **Step 3: Scaffold `admin-web`, configure TypeScript, Tailwind, types and implement `venueStore` & `authStore`**

In `admin-web/package.json`:
Set up scripts (`dev`, `build`, `test`), dependencies (`react`, `react-dom`, `react-router-dom`, `lucide-react`, `clsx`, `tailwind-merge`), and devDependencies (`vite`, `@vitejs/plugin-react`, `typescript`, `tailwindcss`, `@tailwindcss/vite`, `vitest`, `@testing-library/react`, `jsdom`).

In `admin-web/src/types/index.ts`:
Define data types:
- `Venue`, `Court`, `CourtSlot`, `SlotStatus`, `BookingTicket`, `AddOnItem`, `PartnerAccount`, `UserRole`.

In `admin-web/src/store/seedData.ts`:
Populate realistic seed data:
- 4 Venues: CLB Tao Đàn (8 courts), CLB Kỳ Hòa (6 courts), Tân Bình Arena (10 courts), CLB Phú Nhuận (4 courts).
- 8 Courts for Tao Đàn: Courts 1-4 Badminton, Courts 5-8 Pickleball.
- 16-hour slots (06:00 - 22:00) per court with realistic bookings (`SH-8291`, `SH-8292`, `SH-7714`), manual phone bookings, and maintenance slots.
- Add-on products: Pocari, Revive, Nước suối, Thuê vợt, Hộp bóng.

In `admin-web/src/store/venueStore.ts` & `authStore.ts`:
Implement reactive store with event listeners (`window.addEventListener('sporthub_store_change')`) and LocalStorage persistence.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin-web && npm test`
Expected: PASS (4 tests passed).

- [ ] **Step 5: Commit scaffolding and store engine**

```bash
git add admin-web/
git commit -m "feat(admin-web): scaffold React 19 app and implement reactive venueStore"
```

---

### Task 2: Layout Shell, Responsive Navigation, Role Switcher & Theme Switcher

**Files:**
- Create: `admin-web/src/components/layout/Topbar.tsx`
- Create: `admin-web/src/components/layout/Sidebar.tsx`
- Create: `admin-web/src/components/layout/AdminLayout.tsx`
- Create: `admin-web/src/App.tsx`
- Create: `admin-web/src/main.tsx`
- Test: `admin-web/src/components/layout/AdminLayout.test.tsx`

**Interfaces:**
- Consumes:
  - `authStore`: `useAuthStore()`
  - `venueStore`: `useVenueStore()`
- Produces:
  - `AdminLayout`: Renders Topbar + Sidebar + `<Outlet />`
  - `Topbar`: Includes Role Switcher (`Super Admin` <-> `Chủ Sân Tao Đàn`), Dark/Light mode toggle, Venue selector, Notification icon, Staff profile.
  - `Sidebar`: Dynamic navigation items depending on current role:
    - Super Admin: Dashboard (`/admin`), Cụm Sân (`/admin/venues`), Tài Khoản Đối Tác (`/admin/accounts`).
    - Venue Owner: Tổng Quan (`/partner`), Quản Lý Sân (`/partner/courts`), Lịch Sân Master (`/partner/schedule`), Quầy Lễ Tân & Soát Vé (`/partner/pos`), Báo Cáo Doanh Thu (`/partner/revenue`).

- [ ] **Step 1: Write failing component test for AdminLayout & Role Switcher**

Create `admin-web/src/components/layout/AdminLayout.test.tsx`:
```tsx
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AdminLayout } from './AdminLayout';
import { authStore } from '../../store/authStore';

describe('AdminLayout', () => {
  beforeEach(() => {
    authStore.reset();
  });

  it('renders Super Admin navigation items when role is superadmin', () => {
    authStore.setRole('superadmin');
    render(
      <MemoryRouter>
        <AdminLayout />
      </MemoryRouter>
    );

    expect(screen.getByText('Tổng quan Sàn')).toBeInTheDocument();
    expect(screen.getByText('Quản lý Cụm Sân')).toBeInTheDocument();
    expect(screen.getByText('Tài khoản Chủ Sân')).toBeInTheDocument();
  });

  it('renders Venue Partner navigation items when role is partner', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter>
        <AdminLayout />
      </MemoryRouter>
    );

    expect(screen.getByText('Tổng quan Cụm Sân')).toBeInTheDocument();
    expect(screen.getByText('Quản lý Sân')).toBeInTheDocument();
    expect(screen.getByText('Lịch Sân Master')).toBeInTheDocument();
    expect(screen.getByText('Quầy Lễ Tân & Soát Vé')).toBeInTheDocument();
    expect(screen.getByText('Báo cáo Doanh thu')).toBeInTheDocument();
  });

  it('allows switching roles from the topbar switcher', () => {
    render(
      <MemoryRouter>
        <AdminLayout />
      </MemoryRouter>
    );

    const roleButton = screen.getByTestId('role-switcher-button');
    fireEvent.click(roleButton);

    // Switch to partner
    const partnerOption = screen.getByTestId('role-option-partner');
    fireEvent.click(partnerOption);

    expect(authStore.getRole()).toBe('partner');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin-web && npm test AdminLayout`
Expected: Compilation failure (missing `AdminLayout`).

- [ ] **Step 3: Implement `Topbar`, `Sidebar`, `AdminLayout`, and configure routes in `App.tsx`**

- `Topbar.tsx`:
  - Brand header "SportHub Admin Portal" with sports badge.
  - Role switcher dropdown with icons: Super Admin (Shield icon) vs Chủ Sân Tao Đàn (Storefront icon).
  - Venue selector (when in partner role, displays Tao Đàn).
  - Theme toggle button (Sun / Moon) updating document class `dark`.
  - Staff info avatar badge "Trần Văn (Quản lý ca)".
- `Sidebar.tsx`:
  - 250px sticky sidebar with clean athletic styling.
  - Active navigation links with high-contrast indicator pill and icons (`LayoutDashboard`, `Building2`, `Users`, `CalendarRange`, `QrCode`, `BarChart3`).
- `AdminLayout.tsx`:
  - Wraps `Sidebar` and `Topbar` around `<Outlet />`.
- `App.tsx`:
  - React Router configuration providing all routes for both Super Admin and Partner.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin-web && npm test AdminLayout`
Expected: PASS (3 tests passed).

- [ ] **Step 5: Commit layout shell**

```bash
git add admin-web/
git commit -m "feat(admin-web): implement Topbar, Sidebar, role switcher, and theme support"
```

---

### Task 3: Super Admin Views (Platform Dashboard, Venues Management, Partner Accounts)

**Files:**
- Create: `admin-web/src/views/superadmin/SuperAdminDashboardView.tsx`
- Create: `admin-web/src/views/superadmin/VenuesManagementView.tsx`
- Create: `admin-web/src/views/superadmin/PartnerAccountsView.tsx`
- Create: `admin-web/src/components/venues/AddVenueModal.tsx`
- Test: `admin-web/src/views/superadmin/SuperAdminViews.test.tsx`

**Interfaces:**
- Consumes:
  - `venueStore.getVenues()`, `addVenue()`, `updateVenue()`, `deleteVenue()`
  - `authStore.getPartnerAccounts()`, `addPartnerAccount()`, `toggleAccountStatus()`
- Produces:
  - `SuperAdminDashboardView`: 4 Platform KPIs, platform activity stream, venue distribution chart.
  - `VenuesManagementView`: List/Grid of venues with status pills, "Thêm Cụm Sân Mới" modal with full form fields, edit modal, delete action.
  - `PartnerAccountsView`: Table of partner accounts, create account modal, assign venue modal.

- [ ] **Step 1: Write failing component tests for Super Admin views**

Create `admin-web/src/views/superadmin/SuperAdminViews.test.tsx`:
```tsx
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { SuperAdminDashboardView } from './SuperAdminDashboardView';
import { VenuesManagementView } from './VenuesManagementView';
import { venueStore } from '../../store/venueStore';

describe('SuperAdmin Views', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('SuperAdminDashboardView renders system KPIs and venue counts', () => {
    render(
      <MemoryRouter>
        <SuperAdminDashboardView />
      </MemoryRouter>
    );

    expect(screen.getByText('Tổng Cụm Sân Hoạt Động')).toBeInTheDocument();
    expect(screen.getByText('Tổng Sân Thể Thao')).toBeInTheDocument();
    expect(screen.getByText('Lượt Đặt Sân Hôm Nay')).toBeInTheDocument();
    expect(screen.getByText('Doanh Thu Toàn Sàn')).toBeInTheDocument();
  });

  it('VenuesManagementView lists existing venues and allows searching', () => {
    render(
      <MemoryRouter>
        <VenuesManagementView />
      </MemoryRouter>
    );

    expect(screen.getByText(/Tao Đàn/i)).toBeInTheDocument();
    expect(screen.getByText(/Kỳ Hòa/i)).toBeInTheDocument();

    // Search
    const searchInput = screen.getByPlaceholderText(/Tìm kiếm cụm sân/i);
    fireEvent.change(searchInput, { target: { value: 'Kỳ Hòa' } });

    expect(screen.getByText(/Kỳ Hòa/i)).toBeInTheDocument();
    expect(screen.queryByText(/Tao Đàn/i)).not.toBeInTheDocument();
  });

  it('VenuesManagementView allows opening Add Venue modal and creating a venue', () => {
    render(
      <MemoryRouter>
        <VenuesManagementView />
      </MemoryRouter>
    );

    const addBtn = screen.getByTestId('btn-add-venue');
    fireEvent.click(addBtn);

    expect(screen.getByText('Thêm Cụm Sân Mới')).toBeInTheDocument();
    fireEvent.change(screen.getByTestId('input-venue-name'), {
      target: { value: 'CLB Cầu Lông Quận 7 VIP' },
    });
    fireEvent.change(screen.getByTestId('input-venue-address'), {
      target: { value: '100 Nguyễn Thị Thập, Q7' },
    });
    fireEvent.change(screen.getByTestId('input-venue-district'), {
      target: { value: 'Quận 7' },
    });
    fireEvent.click(screen.getByTestId('btn-submit-venue'));

    expect(venueStore.getVenues().some(v => v.name === 'CLB Cầu Lông Quận 7 VIP')).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin-web && npm test SuperAdminViews`
Expected: Compilation error (missing Super Admin views).

- [ ] **Step 3: Implement `SuperAdminDashboardView`, `VenuesManagementView`, `AddVenueModal`, and `PartnerAccountsView`**

- `SuperAdminDashboardView`:
  - 4 large KPI cards: Total venues (4), Total sports courts (28), Total bookings today, Platform revenue.
  - Venue distribution visual chart cards.
  - Platform activity stream (live feed of bookings placed on mobile app).
- `VenuesManagementView`:
  - Search input by name/district + sport filter pills.
  - Venue cards with photo, address, hotline, active badge, and action buttons (Edit, Deactivate, Delete).
  - `AddVenueModal`: Modal with input fields for Name, Address, District, Hotline, Sports checkboxes (Badminton, Pickleball, Football), Base hourly rate, Image URL, and Save button.
- `PartnerAccountsView`:
  - Table of partner accounts: Full Name, Email/Username, Managed Venue, Role, Status, Actions.
  - Modal to create a new partner account and assign to a venue.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin-web && npm test SuperAdminViews`
Expected: PASS (3 tests passed).

- [ ] **Step 5: Commit Super Admin views**

```bash
git add admin-web/
git commit -m "feat(admin-web): implement SuperAdminDashboard, VenuesManagement, and PartnerAccounts"
```

---

### Task 4: Venue Owner Views - Management & Master Schedule Matrix

**Files:**
- Create: `admin-web/src/views/partner/PartnerDashboardView.tsx`
- Create: `admin-web/src/views/partner/CourtsManagementView.tsx`
- Create: `admin-web/src/views/partner/ScheduleMatrixView.tsx`
- Create: `admin-web/src/components/courts/AddCourtModal.tsx`
- Create: `admin-web/src/components/schedule/SlotActionModal.tsx`
- Test: `admin-web/src/views/partner/PartnerScheduleViews.test.tsx`

**Interfaces:**
- Consumes:
  - `venueStore.getCourtsByVenue(venueId)`
  - `venueStore.getSlotsByVenue(venueId)`
  - `venueStore.reserveSlot()`, `updateSlotPrice()`, `lockMaintenance()`, `unlockSlot()`
- Produces:
  - `PartnerDashboardView`: Venue-level KPIs, live court radar, quick shortcuts.
  - `CourtsManagementView`: Courts list, add new court modal, edit court pricing and surface.
  - `ScheduleMatrixView`: Full 16h x 8 courts matrix with sport/shift filters and inline slot management dialog (`SlotActionModal`).

- [ ] **Step 1: Write failing component tests for Partner Dashboard, Courts & Schedule Matrix**

Create `admin-web/src/views/partner/PartnerScheduleViews.test.tsx`:
```tsx
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { PartnerDashboardView } from './PartnerDashboardView';
import { CourtsManagementView } from './CourtsManagementView';
import { ScheduleMatrixView } from './ScheduleMatrixView';
import { venueStore } from '../../store/venueStore';

describe('Partner Schedule & Courts Views', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('PartnerDashboardView renders venue KPIs and 8 courts status', () => {
    render(
      <MemoryRouter>
        <PartnerDashboardView />
      </MemoryRouter>
    );

    expect(screen.getByText('Doanh thu hôm nay')).toBeInTheDocument();
    expect(screen.getByText('Số ca đã đặt')).toBeInTheDocument();
    expect(screen.getByText('Tỷ lệ lấp đầy')).toBeInTheDocument();
    expect(screen.getByText('Khách đã check-in')).toBeInTheDocument();
    expect(screen.getByText('Sân Cầu Lông 01')).toBeInTheDocument();
    expect(screen.getByText('Sân Pickleball 05')).toBeInTheDocument();
  });

  it('CourtsManagementView displays 8 courts and allows adding a new court', () => {
    render(
      <MemoryRouter>
        <CourtsManagementView />
      </MemoryRouter>
    );

    expect(screen.getAllByText(/Sân Cầu Lông/i).length).toBeGreaterThanOrEqual(4);
    expect(screen.getAllByText(/Sân Pickleball/i).length).toBeGreaterThanOrEqual(4);

    // Open add court modal
    fireEvent.click(screen.getByTestId('btn-add-court'));
    expect(screen.getByText('Thêm Sân Thể Thao Mới')).toBeInTheDocument();

    fireEvent.change(screen.getByTestId('input-court-name'), {
      target: { value: 'Sân Cầu Lông VIP 05' },
    });
    fireEvent.click(screen.getByTestId('btn-submit-court'));

    expect(venueStore.getCourtsByVenue('venue_01').some(c => c.name === 'Sân Cầu Lông VIP 05')).toBe(true);
  });

  it('ScheduleMatrixView renders matrix cells and allows phone reservation in modal', () => {
    render(
      <MemoryRouter>
        <ScheduleMatrixView />
      </MemoryRouter>
    );

    expect(screen.getByText('Lịch Sân Master')).toBeInTheDocument();
    expect(screen.getByText('06:00')).toBeInTheDocument();
    expect(screen.getByText('21:00')).toBeInTheDocument();

    // Click available cell court 01 at 08:00
    const cell = screen.getByTestId('slot-cell-court_01_08_00');
    fireEvent.click(cell);

    expect(screen.getByText('Quản lý Ca Sân')).toBeInTheDocument();
    fireEvent.change(screen.getByTestId('input-customer-name'), {
      target: { value: 'Trịnh Thăng Bình' },
    });
    fireEvent.change(screen.getByTestId('input-customer-phone'), {
      target: { value: '0988 999 888' },
    });
    fireEvent.click(screen.getByTestId('btn-confirm-reserve'));

    const updated = venueStore.getSlotById('court_01_08_00');
    expect(updated?.status).toBe('reservedManual');
    expect(updated?.customerName).toBe('Trịnh Thăng Bình');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin-web && npm test PartnerScheduleViews`
Expected: Compilation failure (missing Partner views).

- [ ] **Step 3: Implement `PartnerDashboardView`, `CourtsManagementView`, `AddCourtModal`, `ScheduleMatrixView`, and `SlotActionModal`**

- `PartnerDashboardView`:
  - 4 high-contrast KPI cards.
  - Live Court Status Grid showing 8 courts with instant status (Trống, Đặt qua App, Đặt thủ công, Bảo trì) and sport badges.
  - Realtime booking & check-in activity feed.
  - Quick action buttons (Giữ chỗ nhanh, Quầy soát vé, Khóa bảo trì, Thêm sân).
- `CourtsManagementView`:
  - Grid of all courts under the complex.
  - Each card shows Court Name, Sport Icon, Surface Type, Base & Peak Rates, Status toggle.
  - `AddCourtModal`: Input for Court Name, Sport (Badminton / Pickleball / Football), Surface, Facilities, Regular Price, Peak Price.
- `ScheduleMatrixView`:
  - High-density widescreen matrix: 8 court columns x 16 hour rows (06:00 to 22:00).
  - Filter bar: Sport tabs (`Tất cả`, `Cầu Lông 1-4`, `Pickleball 5-8`) and Shift chips (`Tất cả`, `Sáng 06-12h`, `Chiều 12-17h`, `Tối 17-22h`).
  - Cells color-coded: Available (bordered with price + peak tag), BookedApp (emerald with customer & ticket), ReservedManual (amber with customer), Maintenance (red stripe).
  - `SlotActionModal`:
    - Tab 1: Đặt chỗ thủ công (Customer Name, Phone, Note).
    - Tab 2: Điều chỉnh giá ca (Quick chips: 80k, 100k, 120k, 150k, 180k, 240k or custom input).
    - Tab 3: Khóa sân bảo trì / Mở lại sân hoạt động.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin-web && npm test PartnerScheduleViews`
Expected: PASS (3 tests passed).

- [ ] **Step 5: Commit Partner management & schedule matrix**

```bash
git add admin-web/
git commit -m "feat(admin-web): implement PartnerDashboard, CourtsManagement, and ScheduleMatrixView"
```

---

### Task 5: Venue Owner Views - POS Check-in Desk, Financial Analytics & Build Verification

**Files:**
- Create: `admin-web/src/views/partner/PosCheckinView.tsx`
- Create: `admin-web/src/views/partner/RevenueAnalyticsView.tsx`
- Test: `admin-web/src/views/partner/PartnerPosRevenueViews.test.tsx`

**Interfaces:**
- Consumes:
  - `venueStore.checkInTicket(ticketId)`
  - `venueStore.isCheckedIn(ticketId)`
  - `venueStore.getSlotsByVenue(venueId)`
- Produces:
  - `PosCheckinView`: Rapid QR/barcode check-in input, Today's arrivals table, Add-on POS quick sales counter.
  - `RevenueAnalyticsView`: 7-day revenue chart, revenue breakdown cards, transaction log table with CSV export.

- [ ] **Step 1: Write failing component tests for POS Check-in & Revenue Analytics**

Create `admin-web/src/views/partner/PartnerPosRevenueViews.test.tsx`:
```tsx
import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { PosCheckinView } from './PosCheckinView';
import { RevenueAnalyticsView } from './RevenueAnalyticsView';
import { venueStore } from '../../store/venueStore';

describe('Partner POS & Revenue Views', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('PosCheckinView allows rapid ticket check-in via input and Enter key', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    expect(venueStore.isCheckedIn('SH-8291')).toBe(false);

    const input = screen.getByPlaceholderText(/Nhập mã vé hoặc quét QR/i);
    fireEvent.change(input, { target: { value: 'SH-8291' } });
    fireEvent.click(screen.getByTestId('btn-rapid-checkin'));

    expect(venueStore.isCheckedIn('SH-8291')).toBe(true);
    expect(screen.getByText(/Check-in thành công vé SH-8291/i)).toBeInTheDocument();
  });

  it('PosCheckinView calculates add-on product totals and completes checkout', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    // Initial bill
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('0 đ');

    // Add Pocari (20k)
    fireEvent.click(screen.getByTestId('btn-inc-pocari'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('20.000 đ');

    // Add Thuê vợt (50k)
    fireEvent.click(screen.getByTestId('btn-inc-racket'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('70.000 đ');

    // Checkout
    fireEvent.click(screen.getByTestId('btn-pos-checkout'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('0 đ');
  });

  it('RevenueAnalyticsView displays 7-day revenue chart and breakdown metrics', () => {
    render(
      <MemoryRouter>
        <RevenueAnalyticsView />
      </MemoryRouter>
    );

    expect(screen.getByText('Doanh thu 7 ngày gần nhất')).toBeInTheDocument();
    expect(screen.getByText('Doanh thu tiền sân')).toBeInTheDocument();
    expect(screen.getByText('Dịch vụ phụ trợ')).toBeInTheDocument();
    expect(screen.getByText('Cầu lông')).toBeInTheDocument();
    expect(screen.getByText('Pickleball')).toBeInTheDocument();
    expect(screen.getByText('Lịch sử giao dịch gần nhất')).toBeInTheDocument();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd admin-web && npm test PartnerPosRevenueViews`
Expected: Compilation failure (missing views).

- [ ] **Step 3: Implement `PosCheckinView`, `RevenueAnalyticsView`, and finalize routing**

- `PosCheckinView`:
  - Rapid Check-in Bar: Auto-focused input, keyboard `Enter` listener, `Check-in ngay` button, and visual toast banner.
  - Today's Arrivals Table: Columns for Ticket ID, Customer, Court, Time, Status (Chờ check-in vs Đã vào sân), and 1-click Check-in action button.
  - Add-on POS Quick Counter: Items: Pocari Sweat (20k), Nước suối (10k), Revive chanh muối (18k), Thuê vợt thi đấu (50k), Hộp bóng (60k). Increment/decrement buttons, live bill total, and "Thanh toán tại quầy" action.
- `RevenueAnalyticsView`:
  - 7-Day Revenue Bar Chart with daily bars (Thứ 2 đến Chủ nhật) and formatted Vietnamese currency tooltips.
  - Revenue Breakdown Cards (Tiền sân vs Dịch vụ, Cầu lông vs Pickleball, Giờ vàng vs Giờ ưu đãi).
  - Transaction Log Table with status chips and `Xuất file CSV / Excel` button.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd admin-web && npm test PartnerPosRevenueViews`
Expected: PASS (3 tests passed).

- [ ] **Step 5: Run full test suite, build check, start dev server and commit**

Run:
```bash
cd admin-web
npm test -- --run
npm run build
```
Expected: All tests PASS, TypeScript builds without error (`dist/` generated).
Start Vite dev server in background on port `5173`.
Commit all changes:
```bash
git add admin-web/
git commit -m "feat(admin-web): implement PosCheckinView and RevenueAnalyticsView with full build verification"
```

---

## Self-Review Checklist

1. **Spec Coverage:**
   - Dedicated standalone web app in `admin-web/`? -> Yes (Task 1).
   - Super Admin dashboard, venues management, partner accounts? -> Yes (Task 3).
   - Venue Owner dashboard, courts CRUD, 16h x 8 courts master schedule matrix? -> Yes (Task 4).
   - Front-desk POS with rapid check-in & add-on sales counter? -> Yes (Task 5).
   - Revenue analytics with 7-day chart & transactions log? -> Yes (Task 5).
   - 2-tier role switcher & dark/light theme support? -> Yes (Task 2).
2. **Placeholder Scan:**
   - No "TODO", "TBD", or incomplete code blocks.
3. **Type Consistency:**
   - All shared types (`Venue`, `Court`, `CourtSlot`, `UserRole`) are centrally defined in `types/index.ts` and consumed consistently.
