# Tài Liệu Đặc Tả Thiết Kế Hệ Thống (Design Specification)
# SportHub - Ứng Dụng Đặt Sân Thể Thao & Ghép Kèo Thông Minh Với AI

- **Học phần**: Lập trình trên thiết bị di động (CMP177) - Khoa CNTT, Trường Đại học Công nghệ TP.HCM (HUTECH)
- **Hình thức thực hiện**: Cá nhân (Solo)
- **Ngày lập**: 2026-09-05
- **Trạng thái**: Đã phê duyệt (Approved for Implementation)

---

## 1. Tổng Quan Dự Án (Overview)

### 1.1. Bối cảnh & Vấn đề thực tế
Phong trào thể thao phong trào (Cầu lông, Pickleball, Bóng đá mini) tại các đô thị lớn đang phát triển rất mạnh mẽ. Tuy nhiên, người chơi thường xuyên gặp 2 vấn đề lớn:
1. **Khó khăn trong việc đặt sân**: Phải gọi điện thoại thủ công, không biết cụm sân nào còn khung giờ trống, quy trình thanh toán và giữ chỗ thiếu tính trực quan theo thời gian thực.
2. **Kèo đấu lệch trình độ**: Khi thiếu bạn chơi hoặc muốn tìm đối thủ, việc đăng bài tự do trên mạng xã hội thường dẫn đến những trận đấu quá chênh lệch trình độ (mới tập chơi gặp vận động viên chuyên nghiệp), làm giảm trải nghiệm thể thao.

### 1.2. Giải pháp: SportHub
**SportHub** là ứng dụng di động đa nền tảng phát triển bằng Flutter, kết nối người chơi với các cụm sân thể thao thông qua:
- Giao diện lưới ma trận khung giờ (Time-Slot Grid) trực quan, hỗ trợ cập nhật trạng thái giữ chỗ theo thời gian thực (Real-time Concurrency Control).
- Tích hợp thanh toán mô phỏng chuyển khoản qua chuẩn VietQR động.
- Sổ tay vé điện tử tích hợp mã QR Code lưu trữ cục bộ (SQLite) hỗ trợ xuất trình khi offline.
- Tính năng **Smart Matchmaking AI** sử dụng **Google Gemini 1.5 Flash** phân tích hồ sơ và đề xuất đối thủ thi đấu có độ tương thích cao nhất.

### 1.3. Đáp ứng Chuẩn đầu ra & Rubric Môn học (CMP177)
* **Giao diện & UI/UX (40%)**: Thiết kế Material 3 phong cách Thể thao Hiện đại, hỗ trợ Dark/Light Theme, hiệu ứng Hero Animation, phản hồi rung Haptics, giao diện Time-Slot Grid đẳng cấp.
* **Kỹ thuật lập trình & Kiến trúc (30%)**: Kiến trúc Clean Architecture phân tầng rõ ràng, quản lý trạng thái bằng Flutter BLoC/Cubit, đồng bộ Firestore thời gian thực kết hợp SQLite Offline Cache.
* **Ứng dụng AI sáng tạo (10%)**: Tích hợp Google Gemini API với kỹ thuật Structured JSON Output, chấm điểm tương thích đối thủ theo 4 trọng số và có cơ chế Dự phòng (Heuristic Fallback) khi mất mạng.
* **Làm việc & Thuyết trình (20%)**: Tài liệu hóa bài bản, Git commit history minh bạch, kịch bản demo mượt mà không độ trễ.

---

## 2. Kiến Trúc Hệ Thống & Công Nghệ (System Architecture)

### 2.1. Phân tầng Kiến trúc (Clean Architecture + BLoC)

Ứng dụng được tổ chức thành 3 tầng độc lập theo nguyên lý Separation of Concerns:

```
lib/
├── core/                       # Thành phần dùng chung
│   ├── constants/              # AppColors, AppTextStyles, AppEndpoints
│   ├── errors/                 # Failure & Exception definitions
│   ├── theme/                  # LightTheme, DarkTheme (Material 3)
│   └── utils/                  # CurrencyFormatter, DateHelper, VietQRGenerator
├── data/                       # Tầng Dữ liệu (Data Layer)
│   ├── datasources/
│   │   ├── remote/             # FirestoreService, GeminiAiService, FirebaseAuthService
│   │   └── local/              # SqfliteDatabaseHelper (SQLite offline storage)
│   ├── models/                 # Data Models (kèm toJson, fromJson, fromFirestore)
│   │   ├── venue_model.dart
│   │   ├── slot_model.dart
│   │   ├── ticket_model.dart
│   │   └── match_post_model.dart
│   └── repositories/           # Triển khai các Interface của Domain
│       ├── booking_repository_impl.dart
│       ├── matchmaking_repository_impl.dart
│       └── user_repository_impl.dart
├── domain/                     # Tầng Nghiệp vụ (Domain Layer)
│   ├── entities/               # Thực thể nghiệp vụ thuần Dart
│   │   ├── venue.dart
│   │   ├── time_slot.dart
│   │   ├── ticket.dart
│   │   └── match_post.dart
│   └── repositories/           # Khai báo Interfaces / Contracts
│       ├── i_booking_repository.dart
│       └── i_matchmaking_repository.dart
└── presentation/               # Tầng Giao diện (Presentation Layer)
    ├── blocs/                  # BLoC / Cubits
    │   ├── auth/               # AuthBloc, AuthEvent, AuthState
    │   ├── booking/            # BookingBloc, BookingEvent, BookingState
    │   ├── matchmaking/        # MatchmakingBloc, MatchmakingEvent, MatchmakingState
    │   └── ticket/             # TicketBloc, TicketEvent, TicketState
    ├── screens/                # Màn hình giao diện
    │   ├── home/               # ExploreVenuesScreen, VenueDetailScreen
    │   ├── booking/            # TimeSlotSelectionScreen, VietQRCheckoutDialog
    │   ├── matchmaking/        # MatchmakingFeedScreen, CreateMatchPostScreen
    │   ├── tickets/            # TicketListScreen, TicketQrDetailModal
    │   └── profile/            # ProfileScreen, ThemeToggleWidget
    └── widgets/                # Widgets dùng chung
        ├── custom_button.dart
        ├── venue_card.dart
        └── time_slot_matrix.dart
```

### 2.2. Danh mục Thư viện Cốt lõi (Dependencies)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Firebase Ecosystem
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4

  # Local Database (Offline Cache)
  sqflite: ^2.3.3+1
  path_provider: ^2.1.4
  path: ^1.9.0

  # AI Integration
  google_generative_ai: ^0.4.6

  # UI / UX Enhancements
  qr_flutter: ^4.1.0
  intl: ^0.19.0
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

---

## 3. Thiết Kế Dữ Liệu (Database Schema)

### 3.1. Cloud Firestore (Đám mây - Realtime DB)

#### Collection: users
Lưu trữ thông tin định danh và hồ sơ thể thao của người chơi:
- uid: string (Firebase Auth UID)
- displayName: string (ví dụ: 'Trần Minh Quân')
- email: string
- avatarUrl: string
- phoneNumber: string
- preferredSports: list of string (ví dụ: ['pickleball', 'badminton'])
- skillLevel: string ('Beginner' | 'Intermediate' | 'Advanced')
- district: string ('Bình Thạnh')
- bio: string
- createdAt: Timestamp

#### Collection: venues
Danh sách các cụm sân thể thao:
- id: string ('venue_bd_01')
- name: string ('CLB Cầu Lông & Pickleball Bình Thạnh Sport')
- sportTypes: list of string (['badminton', 'pickleball'])
- address: string
- district: string
- courtCount: number (4)
- hourlyRate: number (150000 VNĐ/giờ)
- rating: number (4.8)
- reviewCount: number (120)
- imageUrls: list of string
- amenities: list of string (['Bãi đỗ ô tô', 'Máy lạnh', 'Căn tin', 'WiFi'])
- openingTime: string ('06:00')
- closingTime: string ('22:00')

#### Sub-collection: venues/{venueId}/slots
Quản lý trạng thái khóa/đặt từng khung giờ của từng sân con theo ngày:
- id: string ('2026-09-06_C1_18:00')
- date: string ('2026-09-06')
- courtNumber: number (1)
- startTime: string ('18:00')
- endTime: string ('19:00')
- price: number (150000)
- status: string ('available' | 'locked' | 'booked')
- lockedBy: string or null
- lockedAt: Timestamp or null
- bookedBy: string or null
- bookingId: string or null

#### Collection: bookings
Lưu trữ thông tin giao dịch đặt sân:
- id: string (Mã vé: 'BK-20260906-889')
- userId: string
- venueId: string
- venueName: string
- sportType: string
- courtNumber: number
- date: string
- startTime: string
- endTime: string
- totalHours: number
- totalPrice: number
- paymentStatus: string ('paid' | 'cancelled')
- qrCodeData: string
- createdAt: Timestamp

#### Collection: matchmaking_posts
Bảng tin bài đăng tìm người chơi/đối thủ:
- id: string
- authorId: string
- authorName: string
- authorAvatar: string
- authorSkill: string ('Intermediate')
- sportType: string ('pickleball')
- venueName: string
- district: string
- matchDate: string
- matchTime: string
- playersNeeded: number (2)
- currentPlayers: number (2)
- description: string
- status: string ('open' | 'closed')
- createdAt: Timestamp

---

### 3.2. CSDL Cục bộ (SQLite - Offline Storage)

Sử dụng thư viện sqflite để lưu trữ dữ liệu tại máy người dùng:
- Tên CSDL: sporthub_local.db (Version 1)

#### Bảng tickets:
```sql
CREATE TABLE tickets (
    id TEXT PRIMARY KEY,
    booking_id TEXT NOT NULL,
    venue_name TEXT NOT NULL,
    sport_type TEXT NOT NULL,
    court_number INTEGER NOT NULL,
    match_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    total_price REAL NOT NULL,
    qr_code_data TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL
);
```

#### Bảng favorite_venues:
```sql
CREATE TABLE favorite_venues (
    venue_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    sport_types TEXT NOT NULL,
    address TEXT NOT NULL,
    image_url TEXT NOT NULL,
    hourly_rate REAL NOT NULL
);
```

---

## 4. Luồng Nghiệp Vụ Cốt Lõi (Core Business Flows)

### 4.1. Cơ chế Đặt Slot & Khóa Giữ Chỗ Đồng Thời (Real-time Concurrency Control)
1. Kiểm tra trạng thái khả dụng: Khi người dùng chạm vào một ô slot trống (màu xanh), ứng dụng kích hoạt Firestore.runTransaction().
2. Khóa slot (Locking): Nếu slot còn trống, hệ thống cập nhật status = 'locked', gán lockedBy = user.uid, lockedAt = FieldValue.serverTimestamp().
3. Phản hồi thời gian thực: Lắng nghe snapshots() của Firestore tự động kích hoạt cập nhật UI trên mọi máy khác đang mở màn hình đặt sân: slot đó đổi sang màu xám/đỏ (Đang giữ chỗ).
4. Hết giờ / Hủy: Nếu đồng hồ 5:00 kết thúc mà chưa thanh toán, hoặc người dùng chủ động bấm Hủy, transaction sẽ trả slot về status = 'available'.

### 4.2. Thanh Toán Mô Phỏng Chuẩn VietQR Động
- Ứng dụng tạo URL mã QR theo cấu trúc chuẩn VietQR:
  https://img.vietqr.io/image/<BANK_ID>-<ACCOUNT_NO>-compact2.png?amount=<TOTAL_PRICE>&addInfo=<BOOKING_ID>&accountName=<ACCOUNT_NAME>
- Giao diện hiển thị: Mã QR quét được bằng ứng dụng ngân hàng thật, nút sao chép nhanh số tài khoản, đồng hồ đếm ngược 04:59 và nút bấm xác nhận 'Tôi đã chuyển khoản'.

---

## 5. Tích Hợp AI Gemini (Smart Matchmaking Engine)

### 5.1. Mô hình & Mục tiêu
- Mô hình: Google Gemini 1.5 Flash (gemini-1.5-flash).
- Mục tiêu: Phân tích danh sách bài đăng ghép kèo, so khớp với hồ sơ người dùng và xếp hạng độ tương thích từ 0% đến 100%.

### 5.2. Thuật toán Phân Tích & Trọng Số
Trí tuệ nhân tạo Gemini được hướng dẫn tính điểm dựa trên 4 tiêu chí:
1. Trình độ kỹ năng (Skill Level - 40%): Tránh chênh lệch trình độ (Beginner vs Advanced). Ưu tiên cùng mức hoặc chênh lệch tối đa 1 bậc.
2. Môn thể thao ưu tiên (Sport Match - 30%): Phải đúng môn người dùng yêu thích.
3. Khu vực địa lý (Location / District - 20%): Ưu tiên cùng quận hoặc các quận lân cận để thuận tiện đi lại.
4. Khung giờ thi đấu (Time Compatibility - 10%): Khớp với khung giờ rảnh trong hồ sơ người dùng.

### 5.3. Định Dạng Prompt & Structured JSON Output
- System Prompt:
  Bạn là Trợ lý Thể thao Chuyên nghiệp (Sports Matchmaker AI) của SportHub.
  Nhiệm vụ: Hãy phân tích hồ sơ người chơi (User Profile) và danh sách các bài đăng tìm bạn chơi (Match Posts).
  Chấm điểm độ tương thích (matchScore từ 0 đến 100) cho từng bài đăng.
  BẮT BUỘC chỉ trả về duy nhất chuỗi JSON hợp lệ theo schema sau:
  [
    {
      "postId": "string",
      "matchScore": number,
      "compatibilityLevel": "HIGH" | "MEDIUM" | "LOW",
      "matchReason": "string (Giải thích súc tích 1-2 câu lý do tại sao hợp hoặc chưa hợp bằng tiếng Việt)"
    }
  ]

- Cơ chế Dự phòng Cục bộ (Heuristic Fallback):
  Nếu thiết bị mất kết nối mạng hoặc Gemini API gặp sự cố (vượt quota, lỗi HTTP), tầng Repository tự động kích hoạt thuật toán so khớp nội bộ dựa trên môn chơi, khoảng cách và trình độ.
  Đảm bảo khi giảng viên chấm thi, ứng dụng luôn trả về kết quả mượt mà, không bao giờ bị crash.

---

## 6. Thiết Kế Giao Diện & Trải Nghiệm Người Dùng (UI/UX)

### 6.1. Design System
- Triết lý thiết kế: Thể thao, Năng động, Tối giản, Bố cục rõ ràng (Sporty Minimalist).
- Màu sắc:
  - Primary: Xanh ngọc thể thao (Sport Green #00C853)
  - Secondary: Xanh lam đậm (#1565C0)
  - Background Light: #F8F9FA | Background Dark: #121212
  - Surface Card Light: #FFFFFF | Surface Card Dark: #1E1E1E
  - Status Colors:
    - Trống (Available): Xanh lá (#4CAF50)
    - Giữ chỗ / Đã đặt (Booked): Đỏ nhạt (#E53935)
    - Đang chọn (Selected): Vàng hổ phách (#FFB300)
- Hỗ trợ Chủ đề: Tự động nhận diện Light/Dark Mode theo hệ điều hành hoặc cho phép chuyển đổi thủ công trong Profile.

### 6.2. 4 Màn hình Chính
1. Màn hình Khám Phá (Explore Screen):
   - Thanh tìm kiếm bo góc kèm bộ lọc môn thể thao dạng Tabs chip có icon (Cầu lông, Pickleball, Bóng đá).
   - Danh sách cụm sân hiển thị dưới dạng Card: Ảnh cover 16:9, nhãn đánh giá sao, giá tiền/giờ nổi bật.
   - Hero Animation chuyển tiếp mượt mà khi xem chi tiết sân.
2. Màn hình Chọn Khung Giờ (Time-Slot Matrix Screen - Tâm điểm UI):
   - Thanh trượt ngang chọn ngày (Horizontal Calendar Strip).
   - Lưới ma trận trực quan: Cột là từng sân con, hàng là khung giờ từ 06:00 đến 22:00.
   - Chạm để chọn slot (kèm hiệu ứng rung nhẹ Haptic).
   - Bottom Bar cố định hiển thị: Tổng giờ chọn, Tổng chi phí và nút Giữ chỗ & Thanh toán.
3. Màn hình Ghép Kèo (Matchmaking Screen):
   - Banner AI phía trên cùng với hiệu ứng Gradient rực rỡ và nút bấm: '✨ Phân Tích & Gợi Ý Bạn Đấu Bằng AI'.
   - Loading Shimmer sang trọng -> danh sách bài đăng ghép kèo được gắn huy hiệu tương thích (Ví dụ: Hợp 95% - Cùng trình độ & cùng quận).
   - Nút Floating Action Button (+) để đăng bài tìm bạn đấu mới.
4. Màn hình Vé của tôi (My Tickets Screen):
   - 2 tab: 'Sắp diễn ra' và 'Lịch sử'.
   - Thẻ vé phong cách vé thể thao điện tử (Ticket Pass) có viền răng cưa và mã QR sắc nét.
   - Hoạt động hoàn toàn Offline nhờ CSDL SQLite.

---

## 7. Chiến Lược Kiểm Thử & Kịch Bản Demo (Verification & Demo Plan)

### 7.1. Kiểm thử Đơn vị (Unit Tests)
- Viết kịch bản kiểm thử cho BookingBloc:
  - Test case: Chọn 1 slot -> State chuyển sang BookingSlotSelected.
  - Test case: Tính toán đúng tổng tiền khi chọn nhiều slot.
  - Test case: Bắt lỗi khi slot vừa bị người khác đặt mất (SlotConflictFailure).
- Test case cho MatchmakingBloc:
  - Test case: Parse thành công JSON từ Gemini API thành danh sách MatchRecommendation.
  - Test case: Tự động kích hoạt Fallback khi API trả về mã lỗi hoặc Timeout.

### 7.2. Dữ liệu Mẫu Khởi tạo (Mock Data Seeding Script)
- Chuẩn bị sẵn file seed_data.dart để tự động bơm dữ liệu mẫu vào Firestore:
  - 3 cụm sân đẹp tại TP.HCM (Sân Cầu lông Chu Văn An - Bình Thạnh, CLB Pickleball Thảo Điền - Thủ Đức, Sân Bóng đá PMH - Quận 7).
  - 5 bài đăng ghép kèo với các cấp độ trình độ khác nhau để trình diễn tính năng AI.

### 7.3. Kịch bản Trình diễn Demo trước Giảng viên (Rubric 20%)
1. Bước 1: Mở app, trình bày giao diện Dark/Light mode và kiến trúc Clean Architecture trên slide.
2. Bước 2: Tìm kiếm sân Pickleball tại Bình Thạnh -> vào màn hình chọn slot -> chọn slot 18:00 - 19:00.
3. Bước 3: Giữ chỗ -> popup VietQR hiện ra với đồng hồ đếm ngược. Mở máy thứ 2 cùng vào sân đó để chứng minh slot đã tự động chuyển sang màu Đỏ theo thời gian thực (Real-time Concurrency).
4. Bước 4: Xác nhận thanh toán -> app thông báo thành công -> bật chế độ Máy bay (Tắt WiFi/4G) -> vào mục 'Vé của tôi' để chứng minh vé QR vẫn mở mượt mà nhờ CSDL SQLite.
5. Bước 5: Chuyển sang Tab 'Ghép kèo' -> bấm nút AI Gemini -> giải thích cách AI đọc hồ sơ người chơi và tính điểm tương thích.

---

## 8. Kế Hoạch Triển Khai Tiếp Theo (Next Steps)
Sau khi tài liệu đặc tả thiết kế này được rà soát và thông qua, bước tiếp theo là chuyển sang kỹ năng writing-plans để lập kế hoạch triển khai từng bước chi tiết (Task-by-task implementation plan) và tiến hành lập trình.
