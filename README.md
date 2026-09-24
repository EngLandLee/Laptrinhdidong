# SportHub - Ứng Dụng Đặt Sân Thể Thao & Ghép Kèo AI

> **SportHub** là nền tảng quản lý, đặt sân thể thao thông minh và kết nối cộng đồng người chơi (Cầu lông, Pickleball, Bóng đá) tích hợp trợ lý ảo AI Chatbot đa kênh tại TP.HCM.

---

## 🚀 Công Nghệ Chính Được Sử Dụng (Tech Stack)

### 1. Phía Mobile App (Flutter / Dart)
- **Framework:** Flutter SDK `>= 3.0.0` (Dart 3, Material 3)
- **Quản lý trạng thái:** `flutter_bloc` (^8.1.6), `equatable` (^2.0.5)
- **Thanh toán & QR:** `qr_flutter` (^4.1.0) sinh mã VietQR động trực tiếp trên thẻ
- **Mạng & AI:** `http` (^1.6.0), `google_generative_ai` (^0.4.6)
- **Định dạng & Tiện ích:** `intl` (^0.19.0), `cached_network_image` (^3.4.1)
- **Lưu trữ Offline:** `sqflite` (^2.3.3+1), `path_provider` (^2.1.4)
- **Kiểm thử tự động:** `flutter_test`, `bloc_test` (^9.1.7), `mocktail` (^1.0.4)

### 2. Phía Web Admin & Backend Sync Server
- **Frontend SPA:** React 19, TypeScript, React Router DOM 7, Tailwind CSS v4, Lucide React
- **Build tool & API Server:** Vite 6, Custom Vite Middleware Plugin (`apiSyncPlugin.ts`)
- **Kiểm thử Web:** Vitest 3, Testing Library React (81/81 tests pass)

### 3. Trí Tuệ Nhân Tạo (Chatbot AI Core)
- **Mô hình Cloud LLM:** FPT Cloud AI endpoint (`https://mkp-api.fptcloud.com/v1/chat/completions`), model `gemma-4-26B-A4B-it` (26B tham số tối ưu tiếng Việt)
- **Local Smart Intent Engine:** Bộ bóc tách thực thể Regex NLP chạy offline trên Flutter khi mất mạng hoặc timeout
- **Kiến trúc tương tác:** Native Action Cards (`ChatBookingCard`, `ChatTableCard`, `RecruitmentCard`), Realtime Clock Context Injection, Reactive Event Bus (`TicketStore.onTicketAdded`)

---

## 🛠️ Hướng Dẫn Cài Đặt & Khởi Chạy (Git & Setup)

### Bước 1: Clone mã nguồn
```bash
git clone https://github.com/EngLandLee/Laptrinhdidong.git
cd Laptrinhdidong
git checkout main
```

### Bước 2: Chạy Web Admin & API Backend
```bash
cd admin-web
npm install
npm run dev
```
Cổng Web Admin & API Backend sẽ khởi chạy tại: `http://localhost:5173`.

### Bước 3: Chạy Ứng dụng Di động Flutter
Mở một Terminal mới tại thư mục gốc `Laptrinhdidong`:
```bash
flutter pub get
flutter run -d chrome
```

### Bước 4: Chạy Kiểm Thử Tự Động (Automated Tests)
```bash
# Kiểm thử Flutter Chatbot (27/27 tests pass)
flutter test test/core/services/chatbot_service_test.dart test/core/services/chatbot_service_addons_test.dart

# Kiểm thử Web Admin & Chatbot API (81/81 tests pass)
cd admin-web && npm test -- --run
```

---

## 📚 Tài Liệu Thuyết Trình
Xem chi tiết tài liệu thuyết trình, kịch bản demo và bảng phân công vai trò tại:
👉 [Tài liệu Thuyết trình Chatbot & Kịch bản Demo](docs/CHATBOT_PRESENTATION_AND_SETUP.md)
