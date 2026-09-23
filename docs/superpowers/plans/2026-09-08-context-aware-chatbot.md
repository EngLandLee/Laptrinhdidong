# Context-Aware Chatbot & Admin Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a context-aware chatbot in the SportHub Flutter mobile app that assists users and supports in-chat court bookings via interactive cards, paired with an Admin Web management portal for API keys, system prompts, knowledge base FAQs, and conversation logs.

**Architecture:** Hybrid Context Engine. The mobile app automatically injects user identity and current screen route context into every message. A dual-mode engine handles queries via local intent processing (booking card generation, pricing, house rules) without requiring an API key, and automatically activates LLM proxying when an API key is configured via the Admin Web management portal.

**Tech Stack:** Flutter 3 / Dart (Bloc, ValueNotifier, Http), React 18 / TypeScript / Vite / Tailwind CSS / Lucide icons, Vitest.

## Global Constraints
- Mobile app must function smoothly and handle booking requests even before an external LLM API key is provided.
- In-chat bookings must create real `TicketModel` tickets, update court slot availability immediately, and sync with Admin Web via `/api/bookings`.
- Chatbot must understand real-time user identity (`AuthStore`), current screen route, active venue details, and live available slots.
- All existing tests (228 Flutter tests, 58 Admin Web tests) must continue to pass with zero regressions and zero linter warnings.

---

### Task 1: Backend API & Storage for Chatbot (`admin-web/src/server/apiSyncPlugin.ts`)

**Files:**
- Modify: `admin-web/src/server/apiSyncPlugin.ts`
- Modify: `.data/sync_store.json`
- Test: `admin-web/src/server/apiSyncPlugin.test.ts`

**Interfaces:**
- Produces endpoints:
  - `GET /api/chatbot/config` & `POST /api/chatbot/config`: returns/updates `{ provider, apiKey, model, systemPrompt, temperature, isActive }`.
  - `GET /api/chatbot/faqs` & `POST /api/chatbot/faqs` & `DELETE /api/chatbot/faqs/:id`: manages knowledge base items.
  - `GET /api/chatbot/conversations` & `POST /api/chatbot/conversations`: logs conversation sessions.
  - `POST /api/chatbot/message`: processes chat messages with context and FAQs.

- [ ] **Step 1: Write test for chatbot API endpoints**
Create `admin-web/src/server/apiSyncPlugin.test.ts` to test chatbot config, FAQ CRUD, and conversation logging.

- [ ] **Step 2: Run test to verify it fails**
Run: `npm --prefix admin-web test -- src/server/apiSyncPlugin.test.ts`
Expected: FAIL (endpoints not implemented).

- [ ] **Step 3: Implement chatbot interfaces and endpoints in `apiSyncPlugin.ts`**
Add `ChatbotConfig`, `ChatbotFaq`, `ChatbotConversation` types to `SyncStoreData`.
Implement router branches in `apiSyncPlugin.ts` for `/api/chatbot/config`, `/api/chatbot/faqs`, `/api/chatbot/conversations`, and `/api/chatbot/message`.

- [ ] **Step 4: Run test to verify it passes**
Run: `npm --prefix admin-web test -- src/server/apiSyncPlugin.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**
Run:
```bash
git add admin-web/src/server/apiSyncPlugin.ts admin-web/src/server/apiSyncPlugin.test.ts .data/sync_store.json
git commit -m "feat(api): add chatbot config, faqs, and conversation endpoints"
```

---

### Task 2: Admin Web Chatbot Store (`admin-web/src/store/chatbotStore.ts`)

**Files:**
- Create: `admin-web/src/store/chatbotStore.ts`
- Create: `admin-web/src/store/chatbotStore.test.ts`

**Interfaces:**
- Produces: `useChatbotStore()` hook and `chatbotStore` engine with methods:
  - `getConfig(): ChatbotConfig`
  - `updateConfig(updates: Partial<ChatbotConfig>): Promise<boolean>`
  - `getFaqs(): ChatbotFaq[]`
  - `addFaq(faq: Omit<ChatbotFaq, 'id'>): Promise<ChatbotFaq>`
  - `deleteFaq(id: string): Promise<boolean>`
  - `getConversations(): ChatbotConversation[]`
  - `logConversation(convo: ChatbotConversation): void`

- [ ] **Step 1: Write unit tests for `chatbotStore`**
Test initial state loading, `updateConfig`, FAQ add/delete, and conversation logging in `chatbotStore.test.ts`.

- [ ] **Step 2: Run test to verify it fails**
Run: `npm --prefix admin-web test -- src/store/chatbotStore.test.ts`
Expected: FAIL (`chatbotStore` not defined).

- [ ] **Step 3: Implement `chatbotStore.ts`**
Create singleton store with reactive listener pattern, syncing with `/api/chatbot/*`.

- [ ] **Step 4: Run test to verify it passes**
Run: `npm --prefix admin-web test -- src/store/chatbotStore.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**
Run:
```bash
git add admin-web/src/store/chatbotStore.ts admin-web/src/store/chatbotStore.test.ts
git commit -m "feat(admin-store): implement chatbotStore with config and knowledge base sync"
```

---

### Task 3: Admin Web Chatbot Management Views (`admin-web/src/views/admin/ChatbotManagementView.tsx`)

**Files:**
- Create: `admin-web/src/views/admin/ChatbotManagementView.tsx`
- Modify: `admin-web/src/App.tsx` (register `/admin/chatbot` and `/partner/chatbot` routes)
- Modify: `admin-web/src/components/layout/Sidebar.tsx` (add "Trợ lý AI" menu item)
- Test: `admin-web/src/views/admin/ChatbotManagementView.test.tsx`

**Interfaces:**
- Renders:
  - Tab 1: AI Config & API Key (provider picker, secret key input, test connection button, prompt editor, temperature slider, On/Off toggle).
  - Tab 2: Knowledge Base & FAQs (category filters, FAQ table, add/edit modal).
  - Tab 3: Conversation Logs & Analytics (KPI stats, chat sessions list, transcript viewer).

- [ ] **Step 1: Write UI component tests for `ChatbotManagementView`**
Test rendering of tabs, form submission for API key and prompt, FAQ creation modal, and conversation viewer.

- [ ] **Step 2: Run test to verify it fails**
Run: `npm --prefix admin-web test -- src/views/admin/ChatbotManagementView.test.tsx`
Expected: FAIL.

- [ ] **Step 3: Implement `ChatbotManagementView.tsx` and integrate with routing**
Build the tabbed management UI and add route to `App.tsx` and navigation item to `Sidebar.tsx`.

- [ ] **Step 4: Run test to verify it passes**
Run: `npm --prefix admin-web test -- src/views/admin/ChatbotManagementView.test.tsx`
Expected: PASS.

- [ ] **Step 5: Commit**
Run:
```bash
git add admin-web/src/views/admin/ChatbotManagementView.tsx admin-web/src/views/admin/ChatbotManagementView.test.tsx admin-web/src/App.tsx admin-web/src/components/layout/Sidebar.tsx
git commit -m "feat(admin-ui): add ChatbotManagementView with AI config, FAQs, and analytics"
```

---

### Task 4: Mobile Context Collector & Chatbot Service (`lib/core/services/chatbot_service.dart`)

**Files:**
- Create: `lib/core/services/chatbot_service.dart`
- Create: `lib/domain/entities/chat_message.dart`
- Test: `test/core/services/chatbot_service_test.dart`

**Interfaces:**
- Produces:
  - `ChatContext`: encapsulates user info (`AuthStore`), active screen/route, active venue name/id, and live slots.
  - `ChatMessage`: `id`, `text`, `sender` ('user' | 'assistant'), `timestamp`, optional `bookingSlot` or `actionCard`.
  - `ChatbotService`:
    - `ValueNotifier<List<ChatMessage>> messagesNotifier`
    - `Future<void> sendMessage(String text, ChatContext context)`
    - `void resetMessages()`

- [ ] **Step 1: Write unit tests for `ChatbotService` and intent extraction**
Test context construction, booking intent parsing ("đặt sân lúc 19h", "tìm sân cầu lông"), FAQ matching, and card payload generation.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/services/chatbot_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `ChatMessage` and `ChatbotService`**
Implement entity extraction, smart local intent fallback, and HTTP dispatch to `/api/chatbot/message` when server has API key configured.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/services/chatbot_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run:
```bash
git add lib/core/services/chatbot_service.dart lib/domain/entities/chat_message.dart test/core/services/chatbot_service_test.dart
git commit -m "feat(mobile-service): add ChatbotService with smart context extraction and dual-mode intent engine"
```

---

### Task 5: Mobile Interactive Booking Card & Chat Widgets (`lib/presentation/widgets/chat/`)

**Files:**
- Create: `lib/presentation/widgets/chat/chat_booking_card.dart`
- Create: `lib/presentation/widgets/chat/chat_message_bubble.dart`
- Test: `test/presentation/widgets/chat_booking_card_test.dart`

**Interfaces:**
- Produces:
  - `ChatBookingCard`: renders court card with venue name, time slot, pricing, status, and buttons:
    - "⚡ Đặt & Thanh toán VietQR ngay" (triggers `onBookNow`)
    - "🔍 Xem trên sơ đồ" (triggers `onViewCourtMap`)
  - `ChatMessageBubble`: formats message with user/bot avatar, time, and optional action card.

- [ ] **Step 1: Write widget test for `ChatBookingCard`**
Verify display of court details, pricing, and button tap callbacks.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/chat_booking_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `ChatBookingCard` and `ChatMessageBubble`**
Build responsive, accessible widgets with theme colors and clear typography.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/chat_booking_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run:
```bash
git add lib/presentation/widgets/chat/chat_booking_card.dart lib/presentation/widgets/chat/chat_message_bubble.dart test/presentation/widgets/chat_booking_card_test.dart
git commit -m "feat(mobile-chat-ui): create ChatBookingCard and ChatMessageBubble widgets"
```

---

### Task 6: Mobile Floating AI Bubble & Chat Modal Bottom Sheet (`lib/presentation/widgets/chat/`)

**Files:**
- Create: `lib/presentation/widgets/chat/floating_chat_bubble.dart`
- Create: `lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`
- Modify: `lib/main.dart` (embed floating bubble and hook booking flow)
- Test: `test/presentation/widgets/chatbot_bottom_sheet_test.dart`

**Interfaces:**
- Produces:
  - `FloatingChatBubble`: persistent floating bubble with context badge and pulse effect.
  - `ChatbotBottomSheet`: full-featured modal with:
    - Context awareness banner (`📍 Đang ở: ... • 👤 ...`)
    - Quick prompt chips (`[Sân trống tối nay?]`, `[Quy định giày]`, etc.)
    - Messages list with smooth autoscroll
    - Text input with send button and speech-to-text placeholder
    - Direct integration with `VietQrPaymentDialog` when booking card is confirmed.

- [ ] **Step 1: Write widget test for `ChatbotBottomSheet`**
Test opening modal, displaying context banner, typing message, receiving booking card, and tapping "Đặt & Thanh toán VietQR ngay" to launch payment.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/chatbot_bottom_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `ChatbotBottomSheet` and `FloatingChatBubble`, integrate into `lib/main.dart`**
Connect to `ChatbotService`, capture `_selectedDate`, `widget.venue`, and `AuthStore` context.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/chatbot_bottom_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Run:
```bash
git add lib/presentation/widgets/chat/floating_chat_bubble.dart lib/presentation/widgets/chat/chatbot_bottom_sheet.dart lib/main.dart test/presentation/widgets/chatbot_bottom_sheet_test.dart
git commit -m "feat(mobile-chat): embed FloatingChatBubble and ChatbotBottomSheet with context-aware booking flow"
```

---

### Task 7: Full System Verification & End-to-End Tests

**Files:**
- Test: `test/presentation/screens/chatbot_end_to_end_test.dart`

**Interfaces:**
- Verifies end-to-end:
  1. Opening chatbot from VenueDetailScreen (Tao Đàn).
  2. Context banner confirms user and venue.
  3. Asking "Đặt sân 19h tối nay" returns interactive booking card for Tao Đàn.
  4. Tapping "Đặt & Thanh toán VietQR ngay" opens payment dialog.
  5. Confirming payment locks court slot as "Đã đặt" and logs booking to `/api/bookings`.
  6. Admin Web receives conversation log and booking notification.

- [ ] **Step 1: Write end-to-end test**
Create `test/presentation/screens/chatbot_end_to_end_test.dart`.

- [ ] **Step 2: Run test to verify it passes**
Run: `flutter test test/presentation/screens/chatbot_end_to_end_test.dart`
Expected: PASS.

- [ ] **Step 3: Run full verification suite**
Run:
```bash
flutter analyze
flutter test
npm --prefix admin-web test -- --run
```
Expected: 0 warnings, all tests pass.

- [ ] **Step 4: Commit**
Run:
```bash
git add test/presentation/screens/chatbot_end_to_end_test.dart
git commit -m "test: add comprehensive end-to-end test for context-aware chatbot and booking flow"
```
