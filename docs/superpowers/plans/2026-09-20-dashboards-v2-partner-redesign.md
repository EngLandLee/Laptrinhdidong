# Dashboards V2 Partner Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Partner Venue Owner Dashboard on the Web Admin (`admin-web/src/views/partner/PartnerDashboardView.tsx`) to match the "Dashboards V2" design aesthetic with glassmorphism, wave/blob gradients, interactive spline bezier curves, pill buttons, progress bars, and floating switcher.

**Architecture:** Component-driven refactoring within `admin-web/src/views/partner/PartnerDashboardView.tsx` with reusable helper SVG sub-components for the Spline Bezier curve and wave backgrounds. Integrates directly with existing Zustand stores (`useVenueStore`, `useAuthStore`) without breaking any data contracts.

**Tech Stack:** React 19, TypeScript, Tailwind CSS v4, Lucide React, Vitest, Testing Library.

## Global Constraints
- Preserve exact test-critical strings: `Doanh thu hôm nay`, `Số ca đã đặt`, `Tỷ lệ lấp đầy`, `Khách đã check-in`, `Sân Cầu Lông 01`, `Sân Pickleball 05`.
- 100% of the 81 existing Vitest tests must pass (`npm --prefix admin-web test -- --run`).
- Zero build errors in `npm --prefix admin-web run build`.

---

### Task 1: CSS & Glassmorphism Micro-Interactions in `index.css`

**Files:**
- Modify: `admin-web/src/index.css`

- [ ] **Step 1: Update `admin-web/src/index.css` with smooth glassmorphism utility classes and keyframe animations**
- [ ] **Step 2: Verify `npm --prefix admin-web run build` compiles with Tailwind v4**
- [ ] **Step 3: Commit CSS utilities**

```bash
git add admin-web/src/index.css
git commit -m "style: add glassmorphism and wave utilities to index.css"
```

---

### Task 2: Implement Dashboards V2 in `PartnerDashboardView.tsx`

**Files:**
- Modify: `admin-web/src/views/partner/PartnerDashboardView.tsx`
- Test: `admin-web/src/views/partner/PartnerScheduleViews.test.tsx`

**Interfaces:**
- Consumes: `useVenueStore()`, `useAuthStore()`, `AddCourtModal`
- Produces: Complete V2 Dashboard containing:
  1. Top Header with user greeting, weather pill (`10:37 AM • Nắng ráo 29°C`), quick search input, and action pills (`+ Giữ chỗ`, `+ Thêm sân`).
  2. 4 Hero KPI Cards with Lime Wave Gradient, Peach Wave Gradient, Dashed Add Court Widget, and Partner Pro Card.
  3. Interactive SVG Spline Bezier Chart with 7 weekdays, glowing area fill, vertical dashed markers, floating node badges (`8h`, `12 ca`, `6 ca`, `14 ca`, `2h`, `1h`), and central pill toggle (`Ca đặt` | `Doanh thu`).
  4. Right column: "Tỷ lệ lấp đầy theo môn" with lime progress pills, and "Quầy soát vé & Check-in" with check-in counter and staff indicators.
  5. Bottom Table: "Lịch đặt sân & Trạng thái 8 cụm sân" styled after "Last notes" with sport badges, progress percentage pills (`43%`, `86%`, `100%`), and court live status.
  6. Bottom Floating Switcher Pill: `[Tổng quan] [Sơ đồ 8 sân] [Doanh thu & POS]`.

- [ ] **Step 1: Edit `PartnerDashboardView.tsx` to implement the Dashboards V2 visual structure**
- [ ] **Step 2: Run Vitest `npm --prefix admin-web test -- --run` to verify test suite passes**
- [ ] **Step 3: Run build `npm --prefix admin-web run build` to verify TypeScript type safety**
- [ ] **Step 4: Commit `PartnerDashboardView.tsx`**

```bash
git add admin-web/src/views/partner/PartnerDashboardView.tsx
git commit -m "feat: implement Dashboards V2 glassmorphism design for Partner Dashboard"
```

---

### Task 3: Visual Verification & End-to-End Test Check

- [ ] **Step 1: Check running Vite server and verify no runtime console errors**
- [ ] **Step 2: Run full test suites across admin-web**
- [ ] **Step 3: Commit all remaining changes and prepare summary**
