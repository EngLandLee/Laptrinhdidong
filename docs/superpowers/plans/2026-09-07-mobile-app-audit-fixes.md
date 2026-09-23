# Mobile App Audit Fixes & Multi-Sport Ticket Persistence Implementation Plan

**Goal:** Address 4 audit findings in the SportHub Mobile App: create a reactive `TicketStore` for automatic ticket persistence from booking flows and 3-sport seed tickets, add sport badges to ticket cards, dynamic sport copy in VietQR checkout, refine AI matchmaking reasons, and support cross-platform check-in for `BK-*` tickets in Web Admin POS.

**Architecture:** ValueNotifier singleton reactive pattern (`TicketStore`), Clean Architecture, integrated with `VenueDetailScreen` booking confirmation and `TicketsScreen`, coupled with test coverage for ticket creation and rendering.

**Tech Stack:** Flutter 3.x, Dart 3.x, React 19 / TypeScript / Vitest (admin-web).

## Global Constraints
- Flutter SDK 3.x, Dart 3.x.
- Platform: Android first, with global responsive smartphone viewport frame (maxWidth 420px) for Web/Desktop.
- UI Language: Vietnamese for all copy, chips, labels, and dialogs.
- 100% test pass rate across all unit and widget tests with 0 analyzer errors (`flutter analyze`).
- Theme: Theme-aware (`AppColors` tokens, dynamic getters).

---

### Task 1: Create TicketStore Singleton and Seed Data Across All 3 Sports

**Files:**
- Create: `lib/core/state/ticket_store.dart`
- Test: `test/core/state/ticket_store_test.dart`

**Interfaces:**
- Produces:
  - `class TicketStore`:
    - `static TicketStore get instance`
    - `ValueNotifier<List<TicketModel>> ticketsNotifier`
    - `List<TicketModel> get tickets`
    - `void addTicket(TicketModel ticket)`
    - `void removeTicket(String id)`
    - `void updateTicketStatus(String id, String status)`
    - `void reset()`
    - `static final List<TicketModel> defaultSampleTickets` (containing 3 sample tickets: Badminton, Pickleball, Football)

---

### Task 2: Integrate TicketStore into TicketsScreen with Multi-Sport Badges

**Files:**
- Modify: `lib/main.dart` (`TicketsScreen`, `_buildTicketCard`)
- Test: `test/presentation/screens/tickets_screen_test.dart`

**Interfaces:**
- Consumes: `TicketStore.instance.ticketsNotifier`
- Produces: Sport badge rendered next to `SPORTHUB PASS` on ticket card (`🏸 CẦU LÔNG`, `🏓 PICKLEBALL`, `⚽ BÓNG ĐÁ`).

---

### Task 3: Hook Booking Confirmation in VenueDetailScreen to TicketStore & Dynamic Sport Copy in VietQR Dialog

**Files:**
- Modify: `lib/main.dart` (`_showVietQrDialog` in `_VenueDetailScreenState`)
- Test: `test/presentation/screens/booking_to_ticket_integration_test.dart`

**Interfaces:**
- Consumes: `TicketStore.instance.addTicket`, `widget.venue.sportTypes`
- Produces: Dynamic header in VietQR dialog (`⚽ Khung giờ sân bóng đá`, `🏓 Khung giờ sân Pickleball`, `🏸 Khung giờ sân cầu lông`), saves `TicketModel` upon payment confirmation.

---

### Task 4: Refine AI Matchmaking Reason & Admin Web POS Interoperability

**Files:**
- Modify: `lib/main.dart` (`_MatchmakingScreenState._runAiMatchmaking`)
- Modify: `admin-web/src/views/partner/PosCheckinView.tsx`
- Test: `admin-web/src/views/partner/PartnerPosRevenueViews.test.tsx`

**Interfaces:**
- Produces: Football match reason in AI recommendations, POS check-in accepts `BK-*` tickets as well as `SH-*`.
