# Design Specification: Context-Aware Chatbot & Admin Management Portal

- **Date:** 2026-09-08
- **Project:** SportHub Ecosystem (Flutter Mobile + React/Vite Admin Web)
- **Status:** Approved / In Progress

---

## 1. Executive Summary
SportHub requires an intelligent, context-aware chatbot embedded in the Flutter mobile application to assist players with sports queries, court availability, pricing, and seamless in-chat court booking. The system must understand real-time user context (who is asking, current screen/route, active venue) and operate in a dual-mode setup (working immediately via smart intent matching before an LLM API key is supplied, and delegating to LLM once configured in the Admin Web portal). The Admin Web portal provides full chatbot administration (API key management, system prompt persona, knowledge base FAQs, and conversation analytics).

---

## 2. Architecture & Data Flow

### 2.1 System Diagram
```
  ┌────────────────────────────────────────────────────────┐
  │                 MOBILE APP (Flutter)                   │
  │  ┌──────────────────────────────────────────────────┐  │
  │  │  Current App State Context Collector             │  │
  │  │  - User: AuthStore (Name, Phone, Role)           │  │
  │  │  - Location: Current Route & Active Venue Details│  │
  │  │  - System: Live Slots, Bookings, Tickets History │  │
  │  └──────────────────────┬───────────────────────────┘  │
  │                         ▼                              │
  │  ┌──────────────────────────────────────────────────┐  │
  │  │  ChatbotBloc / ChatEngine                        │  │
  │  │  - Dual-Mode Router (Local Intent vs LLM Proxy)  │  │
  │  │  - Interactive Card Generator (Booking / Promo)  │  │
  │  └──────────────────────┬───────────────────────────┘  │
  └─────────────────────────┼──────────────────────────────┘
                            │ REST / WebSocket
                            ▼
  ┌────────────────────────────────────────────────────────┐
  │                 ADMIN WEB & BACKEND API                │
  │  ┌──────────────────────────────────────────────────┐  │
  │  │  API Endpoints:                                  │  │
  │  │  - GET/POST /api/chatbot/config (API Key, Prompt)│  │
  │  │  - GET/POST/PATCH /api/chatbot/faqs (Knowledge)  │  │
  │  │  - GET/POST /api/chatbot/conversations (Logs)    │  │
  │  │  - POST /api/chatbot/message (LLM Proxy Runner)  │  │
  │  └──────────────────────────────────────────────────┘  │
  │  ┌──────────────────────────────────────────────────┐  │
  │  │  Admin Web Management Views:                     │  │
  │  │  - AI Settings & API Key Config                  │  │
  │  │  - Knowledge Base & Policy Management            │  │
  │  │  - Live Conversations & Booking Conversion KPI   │  │
  │  └──────────────────────────────────────────────────┘  │
  └────────────────────────────────────────────────────────┘
```

### 2.2 Context Payload Model
```dart
class ChatContext {
  final String userId;
  final String userName;
  final String userPhone;
  final bool isGuest;
  final String currentRoute; // e.g. '/venue_detail', '/home', '/tickets'
  final String? activeVenueId;
  final String? activeVenueName;
  final String? selectedSport;
  final List<String> recentBookingIds;

  Map<String, dynamic> toJson();
}
```

### 2.3 Dual-Mode Processing Flow
1. **Local Intent Processor (Offline / No API Key Mode):**
   - Matches intent via regex & keyword NLP: booking intent, pricing queries, venue amenities, house policies, ticket status.
   - Extracts entities: date, start time, sport, court number.
   - Generates typed message payloads containing interactive action cards (e.g. `TimeSlotBookingCard`).
2. **LLM Provider Mode (Activated via Admin API Key):**
   - Admin enters Gemini / OpenAI key in Admin Web.
   - Key and System Prompt are saved in `.data/sync_store.json` via `/api/chatbot/config`.
   - Message requests pass through `/api/chatbot/message` where prompt context is merged with knowledge base FAQs and injected user context.

---

## 3. Mobile UI Specifications

### 3.1 Floating AI Bubble (`FloatingChatBubble`)
- Appears on all primary tabs (Home, Venues, Tickets, Community, Profile) and VenueDetailScreen.
- Floating design with emerald circular glow (`AppColors.primary`), sparkle icon, and smart context badge.
- Tapping expands the `ChatbotModalBottomSheet` with smooth cubic curve animation.

### 3.2 Chat Header & Context Badge
- Displays active user and screen context:
  `📍 Đang ở: CLB Tao Đàn - Quận 1 • 👤 Khách hàng: Nguyễn Văn An`
- Quick prompt suggestion chips dynamically update based on current screen:
  - On VenueDetailScreen: `[Sân trống tối nay?]`, `[Quy định giày]`, `[Đặt sân 19:00]`, `[Chính sách hủy]`
  - On TicketsScreen: `[Cách quét mã QR]`, `[Hoàn tiền vé]`
  - On HomeScreen: `[Tìm sân gần tôi]`, `[Sân hot cuối tuần]`

### 3.3 Interactive Booking Card (`ChatBookingCard`)
- Embedded directly within the assistant's chat bubble.
- Displays sport icon, venue name, court number, time slot, hourly rate, and status.
- Primary Action: **"⚡ Đặt & Thanh toán VietQR ngay"** -> directly triggers `VietQrPaymentDialog` with full countdown timer and sync flow.
- Secondary Action: **"🔍 Xem trên sơ đồ"** -> closes modal and scrolls to the selected court/slot in `TimeSlotMatrix`.

---

## 4. Admin Web Management Specifications

### 4.1 Route & Access Control
- Super Admin: `/admin/chatbot` -> Global system configuration, master API Key, multi-venue analytics.
- Venue Partner: `/partner/chatbot` -> Venue-specific FAQs, local court policies, customer chat history for their venue.

### 4.2 Views & Tabs
1. **Tab 1: AI Engine & API Key (`ChatbotConfigTab`)**
   - System On/Off master toggle.
   - Provider selector: Google Gemini (default), OpenAI, Anthropic.
   - Secret API Key input with visibility toggle, validation indicator, and "Test Connection" button.
   - System Prompt editor with live preview and temperature slider (0.2 to 0.9).
2. **Tab 2: Knowledge Base & FAQs (`ChatbotFaqTab`)**
   - Table of FAQs filterable by sport (Badminton, Football, Pickleball) and venue.
   - Add/Edit/Delete modal for custom questions, answers, and policy overrides.
3. **Tab 3: Conversation Logs & Analytics (`ChatbotAnalyticsTab`)**
   - KPI metrics: Total Sessions, Booking Conversion Rate (%), Average Response Latency.
   - Chat log viewer: Table of past user conversations with click-to-inspect transcript modal.

---

## 5. API Endpoints & Persistence

### 5.1 Endpoints in `apiSyncPlugin.ts`
- `GET /api/chatbot/config` -> Returns current bot config (masked API key, model, prompt, active state).
- `POST /api/chatbot/config` -> Updates bot config and persists to `.data/sync_store.json`.
- `GET /api/chatbot/faqs` -> Lists active knowledge base items.
- `POST /api/chatbot/faqs` -> Adds or updates FAQ items.
- `DELETE /api/chatbot/faqs/:id` -> Removes FAQ item.
- `GET /api/chatbot/conversations` -> Returns recent conversation logs.
- `POST /api/chatbot/conversations` -> Logs a new conversation session or message.
- `POST /api/chatbot/message` -> Handles chat message with dual-mode fallback.

---

## 6. Verification & Testing Strategy
1. **Unit Tests:**
   - Flutter: `test/core/services/chatbot_service_test.dart` (context injection, intent parsing, booking card generation).
   - Admin Web: `admin-web/src/store/chatbotStore.test.ts` (config updates, FAQ CRUD, conversation logging).
2. **Widget & Integration Tests:**
   - Flutter: `test/presentation/widgets/chatbot_bottom_sheet_test.dart` (floating bubble tap, context banner render, booking card click triggers VietQR dialog).
   - Admin Web: `admin-web/src/views/admin/ChatbotManagementView.test.tsx` (tab switching, API key form submit, FAQ filter).
3. **End-to-End Verification:**
   - Run `flutter analyze` with 0 warnings.
   - Run `flutter test` (all 228+ existing tests + new chatbot tests).
   - Run `npm --prefix admin-web test` (all 58+ existing tests + new chatbot tests).
