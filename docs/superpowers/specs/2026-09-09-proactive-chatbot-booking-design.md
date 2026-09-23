# Design Spec: Proactive Chatbot Booking & 1-Tap Quick Suggestion Chips

## 1. Overview & Objective
Currently, when a user says generic booking intents like *"tôi muốn đặt sân"*, *"đặt sân"*, or *"tìm sân"* without specifying a venue, sport, or time:
- The AI assistant outputs an overwhelming 4-question interrogation questionnaire (*1. Môn gì? 2. Khu vực nào? 3. Ngày giờ nào? 4. Bao nhiêu sân?*).
- Simultaneously, the backend attaches a static booking card for Tao Đàn at 19:00. This creates an awkward, roundabout (*"vòng vo"*), and contradictory user experience.

The objective of this design is to streamline the booking UX into a **Proactive 1-Tap Experience**:
1. **No Roundabout Interrogation**: The AI never asks multiple questions at once. Instead, it proactively recommends the #1 best slot immediately (e.g., Badminton at CLB Tao Đàn Q.1 at 19:00, or a venue matched to current user context/district).
2. **Contextual Venue & Sport Matching**: If the user mentions any district (*Bình Thạnh, Thủ Đức, Quận 7, Tân Bình, Quận 1*) or sport (*Pickleball, Bóng đá, Cầu lông*), the system instantly selects the matching venue.
3. **Dynamic 1-Tap Quick Action Chips**: Underneath the recommendation, provide 1-tap quick action chips (e.g., `[🏓 Pickleball Thảo Điền]`, `[🏸 Cầu lông Bình Thạnh]`, `[⚽ Bóng đá Q.7]`, `[🏸 Tao Đàn Q.1 19h]`). Tapping a chip immediately switches to that court's booking card.

---

## 2. Architecture & Data Flow

```
[User Message: "tôi muốn đặt sân"]
               │
               ▼
[apiSyncPlugin.ts / Chatbot Message API]
   - Detects booking intent.
   - Extracts sport and district/venue if present; otherwise picks best default (Tao Đàn 19:00).
   - Injects venue catalog and strict anti-interrogation system prompt to FPT AI:
     "KHÔNG hỏi dồn dập 4-5 câu hỏi. Hãy CHỦ ĐỘNG gợi ý ngay 1 cụm sân tốt nhất..."
   - Returns reply + actionCard + quickSuggestions array.
               │
               ▼
[ChatbotService & ChatMessage]
   - Parses `actionCard` and `quickSuggestions: List<String>`.
               │
               ▼
[ChatbotBottomSheet UI]
   - Renders assistant bubble with proactive, concise text and interactive `ChatBookingCard`.
   - Renders 1-tap quick suggestion chips right above the text input bar.
   - User taps a chip -> instantly sends targeted query -> receives that venue's card immediately.
```

---

## 3. Detailed Component Modifications

### 3.1. Backend (`admin-web/src/server/apiSyncPlugin.ts`)
- Enhance `/api/chatbot/message`:
  - Extract sport: Badminton, Pickleball, Football, Tennis.
  - Extract district/venue from message:
    - Bình Thạnh -> `venue_bt_01` (Bình Thạnh Sport)
    - Thủ Đức / Thảo Điền -> `venue_td_02` (Thảo Điền Pickleball Hub)
    - Quận 7 / Nam Sài Gòn -> `venue_q7_03` (Sân Bóng Đá Mini Nam Sài Gòn)
    - Tân Bình -> `venue_tb_05` (Khu Liên Hợp Thể Thao Tân Bình Arena)
    - Quận 1 / Tao Đàn / default -> `venue_01` (CLB Cầu Lông Tao Đàn)
  - Refine System Prompt for FPT AI:
    ```
    Quy tắc cốt lõi khi người dùng muốn đặt sân:
    - Tuyệt đối KHÔNG hỏi dồn dập 4-5 câu hỏi để tra khảo người dùng.
    - Luôn CHỦ ĐỘNG gợi ý ngay 1 sân hot phù hợp nhất với khung giờ vàng (19:00 tối nay).
    - Giới thiệu ngắn gọn 1-2 câu thân thiện rằng em đã chọn sẵn sân bên dưới, khách có thể nhấn đặt ngay hoặc chọn đổi sang môn/khu vực khác bằng các nút bấm nhanh.
    ```
  - Include `quickSuggestions` in response JSON:
    ```json
    {
      "reply": "...",
      "actionCard": { ... },
      "quickSuggestions": [
        "🏸 Cầu lông Q.1 (19h)",
        "🏓 Pickleball Thảo Điền",
        "🏸 Cầu lông Bình Thạnh",
        "⚽ Bóng đá mini Q.7"
      ]
    }
    ```

### 3.2. Mobile Entity (`lib/domain/entities/chat_message.dart`)
- Add field to `ChatMessage`:
  ```dart
  final List<String>? quickSuggestions;
  ```
- Support `quickSuggestions` in `fromJson` and `toJson`.

### 3.3. Mobile Chatbot Service (`lib/core/services/chatbot_service.dart`)
- Update `_processLocalIntent`:
  - When user has booking intent:
    - Match district or sport to the 5 standard venues (Tao Đàn, Bình Thạnh Sport, Thảo Điền Hub, Nam Sài Gòn, Tân Bình Arena).
    - Provide concise, non-interrogating greeting text.
    - Attach `quickSuggestions`.

### 3.4. Mobile UI (`lib/presentation/widgets/chat/chatbot_bottom_sheet.dart`)
- Display dynamic `quickSuggestions` from the latest assistant message:
  - If the latest assistant message has `quickSuggestions`, display them as clickable prompt chips directly above the text input bar.
  - Tapping a chip sends that message into the chat, seamlessly updating the recommendation.

---

## 4. Testing & Verification Plan
1. **API Unit Test / Integration Test**:
   - Send `{"message": "tôi muốn đặt sân"}` to `/api/chatbot/message`.
   - Verify reply does NOT contain bulleted questionnaires (`1. Môn gì? 2. Khu vực nào?`).
   - Verify response includes `actionCard` and `quickSuggestions`.
2. **Flutter Widget Test**:
   - Verify `ChatbotBottomSheet` renders `quickSuggestions` chips when present on the message.
   - Verify tapping a quick suggestion chip sends the message to `ChatbotService`.
3. **Full Suite Regression**:
   - Run `flutter test` (all 273 tests pass).
   - Hot reload Chrome and verify interactive response.
