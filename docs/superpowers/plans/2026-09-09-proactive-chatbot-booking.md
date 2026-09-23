# Proactive Chatbot Booking & Quick Suggestion Chips Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate roundabout multi-question interrogation when users ask to book a court in the AI Chatbot by implementing proactive smart court recommendations with contextual district/sport matching and 1-tap dynamic quick action chips.

**Architecture:**
1. In `admin-web/src/server/apiSyncPlugin.ts`, enhance `/api/chatbot/message` to intelligently resolve venue by district/sport, inject strict anti-questionnaire instructions to the FPT Cloud AI system prompt, and return `quickSuggestions`.
2. In `lib/domain/entities/chat_message.dart` and `lib/core/services/chatbot_service.dart`, support `quickSuggestions: List<String>?` and align local fallback intent matching with the 5 key venues.
3. In `lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`, render dynamic 1-tap quick action chips above the chat input bar whenever `quickSuggestions` are present.

**Tech Stack:** Flutter 3.x, Dart 3.x, Node.js / Vite TypeScript plugin, FPT Cloud AI API.

## Global Constraints
- All 273 Flutter tests and 74 Admin Web Vitest tests must continue passing.
- Response time and fallback resilience must be maintained if FPT Cloud AI is unreachable.
- No memory leaks or unmounted context calls.

---

### Task 1: Backend Contextual Venue Resolution & Anti-Questionnaire System Prompt

**Files:**
- Modify: `admin-web/src/server/apiSyncPlugin.ts`
- Modify: `admin-web/src/store/chatbotStore.ts` (if default prompt needs alignment)
- Test: `admin-web/test/apiSyncPlugin.test.ts` (or curl verification)

**Interfaces:**
- `/api/chatbot/message` response:
  ```json
  {
    "reply": "string",
    "actionCard": { ... },
    "quickSuggestions": ["🏸 Cầu lông Q.1 (19h)", "🏓 Pickleball Thảo Điền", "🏸 Cầu lông Bình Thạnh", "⚽ Bóng đá mini Q.7"]
  }
  ```

- [ ] **Step 1: Write integration test in `admin-web/test/chatbotProactive.test.ts`**

```ts
import { describe, it, expect } from 'vitest';

describe('Chatbot Proactive Recommendation', () => {
  it('generates proactive Tao Dan card and quickSuggestions for generic booking query', async () => {
    const res = await fetch('http://localhost:5173/api/chatbot/message', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: 'tôi muốn đặt sân',
        context: { currentScreen: '/home', userName: 'Quốc Anh' }
      })
    });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.actionCard).toBeDefined();
    expect(data.actionCard.venueName).toContain('Tao Đàn');
    expect(Array.isArray(data.quickSuggestions)).toBe(true);
    expect(data.quickSuggestions.length).toBeGreaterThan(0);
    // Should NOT contain interrogative questionnaires
    expect(data.reply).not.toContain('1. Môn thể thao anh muốn chơi là gì');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm --prefix admin-web test -- test/chatbotProactive.test.ts`
Expected: FAIL.

- [ ] **Step 3: Update `admin-web/src/server/apiSyncPlugin.ts`**

1. Parse sport and district from user's message:
   - Bình Thạnh -> `venue_bt_01` ("CLB Cầu Lông & Pickleball Bình Thạnh Sport", sport: "Cầu lông" or "Pickleball", price: 150000)
   - Thảo Điền / Thủ Đức -> `venue_td_02` ("Thảo Điền Pickleball Hub", sport: "Pickleball", price: 200000)
   - Quận 7 / Nam Sài Gòn -> `venue_q7_03` ("Sân Bóng Đá Mini Nam Sài Gòn", sport: "Bóng đá", price: 280000)
   - Tân Bình -> `venue_tb_05` ("Khu Liên Hợp Thể Thao Tân Bình Arena", sport: "Cầu lông", price: 180000)
   - Tao Đàn / Quận 1 / default -> `venue_01` ("CLB Cầu Lông Tao Đàn", sport: "Cầu lông", price: 160000)

2. Inject strict anti-questionnaire system prompt to FPT AI:
   ```ts
   const proactiveSystemPrompt = `Bạn là SportHub AI - trợ lý ảo đặt sân thể thao thông minh tại TP.HCM.
Quy tắc phản hồi khi người dùng muốn đặt sân:
- TUYỆT ĐỐI KHÔNG hỏi dồn dập nhiều câu hỏi (không hỏi 1. Môn gì? 2. Khu vực nào? 3. Ngày giờ? 4. Bao nhiêu người?).
- Hãy CHỦ ĐỘNG giới thiệu ngay 1 sân phù hợp nhất (đã tạo sẵn thẻ đặt sân bên dưới) với thái độ nhiệt tình, ngắn gọn (1-2 câu).
- Nhắc người dùng họ có thể nhấn nút đặt ngay, hoặc chọn nhanh các môn/khu vực khác bằng các nút gợi ý bên dưới.`;
   ```

3. Return `quickSuggestions` array:
   ```ts
   const quickSuggestions = [
     "🏸 Cầu lông Q.1 (19h)",
     "🏓 Pickleball Thảo Điền",
     "🏸 Cầu lông Bình Thạnh",
     "⚽ Bóng đá mini Q.7",
   ];
   ```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm --prefix admin-web test -- test/chatbotProactive.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add admin-web/src/server/apiSyncPlugin.ts admin-web/test/chatbotProactive.test.ts
git commit -m "feat(api): implement proactive booking recommendations and quickSuggestions"
```

---

### Task 2: Update Mobile Entity & Local Intent Fallback in ChatbotService

**Files:**
- Modify: `lib/domain/entities/chat_message.dart`
- Modify: `lib/core/services/chatbot_service.dart`
- Test: `test/core/services/chatbot_service_test.dart`

**Interfaces:**
- `ChatMessage`:
  - `final List<String>? quickSuggestions;`
  - `toJson()` / `fromJson()`
- `ChatbotService`:
  - `sendMessage` populates `quickSuggestions` from server JSON or local intent fallback.

- [ ] **Step 1: Write test in `test/core/services/chatbot_service_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/domain/entities/chat_message.dart';

void main() {
  test('ChatMessage serializes and deserializes quickSuggestions', () {
    final msg = ChatMessage(
      id: '1',
      text: 'Gợi ý sân',
      sender: 'assistant',
      timestamp: DateTime.now(),
      quickSuggestions: ['🏸 Q.1', '🏓 Thảo Điền'],
    );
    final json = msg.toJson();
    expect(json['quickSuggestions'], equals(['🏸 Q.1', '🏓 Thảo Điền']));
    final fromJson = ChatMessage.fromJson(json);
    expect(fromJson.quickSuggestions, equals(['🏸 Q.1', '🏓 Thảo Điền']));
  });

  test('ChatbotService local fallback generates proactive card and quickSuggestions', () async {
    final service = ChatbotService.instance;
    final reply = await service.sendMessage('tôi muốn đặt sân');
    expect(reply.hasActionCard, isTrue);
    expect(reply.quickSuggestions, isNotNull);
    expect(reply.quickSuggestions!.isNotEmpty, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/services/chatbot_service_test.dart`
Expected: FAIL (quickSuggestions parameter not found on `ChatMessage`).

- [ ] **Step 3: Update `ChatMessage` and `ChatbotService`**

In `lib/domain/entities/chat_message.dart`:
Add `quickSuggestions` field, constructor parameter, `toJson`, and `fromJson`.

In `lib/core/services/chatbot_service.dart`:
- Parse `quickSuggestions` in network response.
- In `_processLocalIntent`:
  - Match district (Bình Thạnh, Thủ Đức, Quận 7, Tân Bình, Tao Đàn) to target venue.
  - Return `quickSuggestions: ['🏸 Cầu lông Q.1 (19h)', '🏓 Pickleball Thảo Điền', '🏸 Cầu lông Bình Thạnh', '⚽ Bóng đá mini Q.7']`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/services/chatbot_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/domain/entities/chat_message.dart lib/core/services/chatbot_service.dart test/core/services/chatbot_service_test.dart
git commit -m "feat(chat): add quickSuggestions to ChatMessage and ChatbotService local fallback"
```

---

### Task 3: Render Dynamic 1-Tap Quick Action Chips in ChatbotBottomSheet

**Files:**
- Modify: `lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`
- Test: `test/presentation/widgets/chat/chatbot_quick_suggestions_test.dart`

**Interfaces:**
- Whenever the latest assistant message contains `quickSuggestions`, render a horizontal scrolling list of quick chips above the text input bar.
- Tapping a chip calls `_onChipTap(suggestionText)`, which sends the query and automatically updates the chat.

- [ ] **Step 1: Write test in `test/presentation/widgets/chat/chatbot_quick_suggestions_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';
import 'package:sporthub/domain/entities/chat_message.dart';
import 'package:sporthub/presentation/widgets/chat/chatbot_bottom_sheet.dart';

void main() {
  testWidgets('ChatbotBottomSheet renders dynamic quick suggestions from latest message',
      (tester) async {
    ChatbotService.instance.resetMessages();
    ChatbotService.instance.addMessage(
      ChatMessage(
        id: 'msg_1',
        text: 'Em đã chọn sẵn sân cho anh',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: ['🏓 Pickleball Thảo Điền', '🏸 Cầu lông Bình Thạnh'],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatbotBottomSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('🏓 Pickleball Thảo Điền'), findsOneWidget);
    expect(find.text('🏸 Cầu lông Bình Thạnh'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/chat/chatbot_quick_suggestions_test.dart`
Expected: FAIL.

- [ ] **Step 3: Update `ChatbotBottomSheet`**

In `lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`:
- In `build()`, inspect the latest message in `ChatbotService.instance.messagesNotifier.value`:
  - If the latest message has `quickSuggestions != null && quickSuggestions.isNotEmpty`, use those as the active prompt chips.
  - Render them cleanly with horizontal scrolling above the input field with styling (pill container, icon, primary border).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/chat/chatbot_quick_suggestions_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/widgets/chat/chatbot_bottom_sheet.dart test/presentation/widgets/chat/chatbot_quick_suggestions_test.dart
git commit -m "feat(chat): render dynamic 1-tap quick suggestions above input bar"
```

---

### Task 4: Full Suite Regression & Live Verification

**Files:**
- Test: all unit and widget tests
- Live Chrome Web verification

- [ ] **Step 1: Run full Flutter test suite**

Run: `flutter test`
Expected: All 275+ tests pass.

- [ ] **Step 2: Trigger Hot Reload on Chrome**

Send hot reload `r` to the running Flutter task terminal.

- [ ] **Step 3: Live Verification with curl**

Send `tôi muốn đặt sân` to `/api/chatbot/message` and verify no interrogation questions.
