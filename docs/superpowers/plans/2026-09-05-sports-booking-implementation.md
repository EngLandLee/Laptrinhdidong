# SportHub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng hoàn chỉnh ứng dụng di động SportHub bằng Flutter phục vụ đặt sân thể thao thời gian thực, lưu vé QR offline với SQLite và ghép kèo thông minh với Google Gemini AI.

**Architecture:** Clean Architecture 3 tầng (Data, Domain, Presentation) kết hợp BLoC/Cubit để quản lý trạng thái. Xử lý đồng thời (concurrency) với Cloud Firestore Transactions và lưu trữ ngoại tuyến bằng SQLite (sqflite).

**Tech Stack:** Flutter 3.x, Dart 3.x, flutter_bloc, equatable, firebase_core, firebase_auth, cloud_firestore, sqflite, path_provider, google_generative_ai, qr_flutter, intl.

## Global Constraints

- Flutter SDK 3.x, Dart 3.x.
- Platform: Android ưu tiên (hỗ trợ responsive mobile).
- Ngôn ngữ giao diện & thông báo: Tiếng Việt.
- Mô hình kiến trúc: Clean Architecture + BLoC pattern.
- CSDL: Cloud Firestore (remote realtime) + SQLite (local offline cache).
- AI Model: Google Gemini 1.5 Flash (Structured JSON output).

---

### Task 1: Khởi tạo Cấu trúc Dự án & Cấu hình Dependencies

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `lib/core/constants/app_colors.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: None (Root initialization)
- Produces: Base Flutter project runnable, AppColors definitions

- [ ] **Step 1: Write the failing test**

```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/constants/app_colors.dart';

void main() {
  test('AppColors defines primary and status colors correctly', () {
    expect(AppColors.primary.value, 0xFF00C853);
    expect(AppColors.available.value, 0xFF4CAF50);
    expect(AppColors.booked.value, 0xFFE53935);
    expect(AppColors.selected.value, 0xFFFFB300);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL with "Target of URI doesn't exist: 'package:sporthub/core/constants/app_colors.dart'"

- [ ] **Step 3: Write minimal implementation**

```yaml
# pubspec.yaml
name: sporthub
description: "SportHub - Ứng dụng đặt sân thể thao và ghép kèo AI"
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  sqflite: ^2.3.3+1
  path_provider: ^2.1.4
  path: ^1.9.0
  google_generative_ai: ^0.4.6
  qr_flutter: ^4.1.0
  intl: ^0.19.0
  cached_network_image: ^3.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

```dart
// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF00C853);
  static const Color secondary = Color(0xFF1565C0);
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Status Colors for Slots
  static const Color available = Color(0xFF4CAF50);
  static const Color booked = Color(0xFFE53935);
  static const Color selected = Color(0xFFFFB300);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml lib/core/constants/app_colors.dart test/widget_test.dart
git commit -m "feat: initialize project dependencies and core app colors"
```

---

### Task 2: CSDL Cục bộ (SQLite Local Storage) cho Vé Điện Tử

**Files:**
- Create: `lib/data/datasources/local/database_helper.dart`
- Create: `lib/data/models/ticket_model.dart`
- Test: `test/data/datasources/database_helper_test.dart`

**Interfaces:**
- Consumes: `sqflite`, `path`
- Produces: `DatabaseHelper.instance.insertTicket(TicketModel)`, `getTickets()`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/datasources/database_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/data/models/ticket_model.dart';

void main() {
  test('TicketModel converts to and from Map correctly', () {
    final ticket = TicketModel(
      id: 'ticket_1',
      bookingId: 'BK-001',
      venueName: 'Sân Cầu Lông Bình Thạnh',
      sportType: 'badminton',
      courtNumber: 1,
      matchDate: '2026-09-06',
      startTime: '18:00',
      endTime: '19:00',
      totalPrice: 150000.0,
      qrCodeData: 'SPORTHUB|BK-001|150000',
      status: 'paid',
      createdAt: '2026-09-05T10:00:00Z',
    );

    final map = ticket.toMap();
    final reconstructed = TicketModel.fromMap(map);

    expect(reconstructed.id, ticket.id);
    expect(reconstructed.venueName, ticket.venueName);
    expect(reconstructed.totalPrice, 150000.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/datasources/database_helper_test.dart`
Expected: FAIL with "Target of URI doesn't exist"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/ticket_model.dart
class TicketModel {
  final String id;
  final String bookingId;
  final String venueName;
  final String sportType;
  final int courtNumber;
  final String matchDate;
  final String startTime;
  final String endTime;
  final double totalPrice;
  final String qrCodeData;
  final String status;
  final String createdAt;

  TicketModel({
    required this.id,
    required this.bookingId,
    required this.venueName,
    required this.sportType,
    required this.courtNumber,
    required this.matchDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.qrCodeData,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'venue_name': venueName,
      'sport_type': sportType,
      'court_number': courtNumber,
      'match_date': matchDate,
      'start_time': startTime,
      'end_time': endTime,
      'total_price': totalPrice,
      'qr_code_data': qrCodeData,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    return TicketModel(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      venueName: map['venue_name'] as String,
      sportType: map['sport_type'] as String,
      courtNumber: map['court_number'] as int,
      matchDate: map['match_date'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      totalPrice: (map['total_price'] as num).toDouble(),
      qrCodeData: map['qr_code_data'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}
```

```dart
// lib/data/datasources/local/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/ticket_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sporthub_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
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
      )
    ''');
  }

  Future<int> insertTicket(TicketModel ticket) async {
    final db = await instance.database;
    return await db.insert('tickets', ticket.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TicketModel>> getTickets() async {
    final db = await instance.database;
    final maps = await db.query('tickets', orderBy: 'created_at DESC');
    return maps.map((e) => TicketModel.fromMap(e)).toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/datasources/database_helper_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/ticket_model.dart lib/data/datasources/local/database_helper.dart test/data/datasources/database_helper_test.dart
git commit -m "feat: implement SQLite database helper and ticket model for offline pass"
```

---

### Task 3: Entity & Model Quản lý Sân và Khung Giờ (Venues & TimeSlots)

**Files:**
- Create: `lib/domain/entities/venue.dart`
- Create: `lib/domain/entities/time_slot.dart`
- Create: `lib/data/models/venue_model.dart`
- Create: `lib/data/models/time_slot_model.dart`
- Test: `test/domain/entities/venue_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `Venue`, `TimeSlot`, `TimeSlotModel.fromMap()`

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/entities/venue_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/data/models/time_slot_model.dart';
import 'package:sporthub/domain/entities/time_slot.dart';

void main() {
  test('TimeSlotModel parses JSON and calculates availability correctly', () {
    final slot = TimeSlotModel(
      id: '2026-09-06_C1_18:00',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '18:00',
      endTime: '19:00',
      price: 150000.0,
      status: SlotStatus.available,
      lockedBy: null,
      lockedAt: null,
    );

    expect(slot.isAvailable, true);
    expect(slot.formattedPrice, '150.000 đ');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/entities/venue_test.dart`
Expected: FAIL with compilation error

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/domain/entities/time_slot.dart
enum SlotStatus { available, locked, booked }

class TimeSlot {
  final String id;
  final String date;
  final int courtNumber;
  final String startTime;
  final String endTime;
  final double price;
  final SlotStatus status;
  final String? lockedBy;
  final DateTime? lockedAt;

  const TimeSlot({
    required this.id,
    required this.date,
    required this.courtNumber,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    this.lockedBy,
    this.lockedAt,
  });

  bool get isAvailable => status == SlotStatus.available;
}
```

```dart
// lib/data/models/time_slot_model.dart
import 'package:intl/intl.dart';
import '../../domain/entities/time_slot.dart';

class TimeSlotModel extends TimeSlot {
  const TimeSlotModel({
    required super.id,
    required super.date,
    required super.courtNumber,
    required super.startTime,
    required super.endTime,
    required super.price,
    required super.status,
    super.lockedBy,
    super.lockedAt,
  });

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} đ';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'courtNumber': courtNumber,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'status': status.name,
      'lockedBy': lockedBy,
      'lockedAt': lockedAt?.toIso8601String(),
    };
  }

  factory TimeSlotModel.fromMap(Map<String, dynamic> map, String id) {
    return TimeSlotModel(
      id: id,
      date: map['date'] as String,
      courtNumber: map['courtNumber'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      price: (map['price'] as num).toDouble(),
      status: SlotStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SlotStatus.available,
      ),
      lockedBy: map['lockedBy'] as String?,
      lockedAt: map['lockedAt'] != null ? DateTime.tryParse(map['lockedAt']) : null,
    );
  }
}
```

```dart
// lib/domain/entities/venue.dart
class Venue {
  final String id;
  final String name;
  final List<String> sportTypes;
  final String address;
  final String district;
  final int courtCount;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final List<String> amenities;

  const Venue({
    required this.id,
    required this.name,
    required this.sportTypes,
    required this.address,
    required this.district,
    required this.courtCount,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.imageUrls,
    required this.amenities,
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/entities/venue_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/entities/venue.dart lib/domain/entities/time_slot.dart lib/data/models/time_slot_model.dart test/domain/entities/venue_test.dart
git commit -m "feat: implement Venue and TimeSlot entities and models"
```

---

### Task 4: Booking BLoC & Quản Lý Trạng Thái Giữ Chỗ (Selection & Calculation Logic)

**Files:**
- Create: `lib/presentation/blocs/booking/booking_event.dart`
- Create: `lib/presentation/blocs/booking/booking_state.dart`
- Create: `lib/presentation/blocs/booking/booking_bloc.dart`
- Test: `test/presentation/blocs/booking_bloc_test.dart`

**Interfaces:**
- Consumes: `TimeSlot`
- Produces: `BookingBloc` handles `ToggleSlotEvent`, `ClearSelectedSlotsEvent`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/blocs/booking_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_event.dart';
import 'package:sporthub/presentation/blocs/booking/booking_state.dart';

void main() {
  group('BookingBloc', () {
    const slot1 = TimeSlot(
      id: 'slot_1',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '18:00',
      endTime: '19:00',
      price: 150000.0,
      status: SlotStatus.available,
    );

    blocTest<BookingBloc, BookingState>(
      'emits updated selected slots and total price when ToggleSlotEvent is added',
      build: () => BookingBloc(),
      act: (bloc) => bloc.add(const ToggleSlotEvent(slot1)),
      expect: () => [
        isA<BookingSlotsUpdated>()
            .having((s) => s.selectedSlots.length, 'selectedSlots length', 1)
            .having((s) => s.totalPrice, 'totalPrice', 150000.0),
      ],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/blocs/booking_bloc_test.dart`
Expected: FAIL with compilation error

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/blocs/booking/booking_event.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/time_slot.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class ToggleSlotEvent extends BookingEvent {
  final TimeSlot slot;
  const ToggleSlotEvent(this.slot);
  @override
  List<Object?> get props => [slot];
}

class ClearSelectedSlotsEvent extends BookingEvent {}
```

```dart
// lib/presentation/blocs/booking/booking_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/time_slot.dart';

abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingSlotsUpdated extends BookingState {
  final List<TimeSlot> selectedSlots;
  final double totalPrice;

  const BookingSlotsUpdated({
    required this.selectedSlots,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [selectedSlots, totalPrice];
}
```

```dart
// lib/presentation/blocs/booking/booking_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';
import '../../../domain/entities/time_slot.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(BookingInitial()) {
    on<ToggleSlotEvent>(_onToggleSlot);
    on<ClearSelectedSlotsEvent>(_onClearSlots);
  }

  void _onToggleSlot(ToggleSlotEvent event, Emitter<BookingState> emit) {
    final currentSlots = state is BookingSlotsUpdated
        ? List<TimeSlot>.from((state as BookingSlotsUpdated).selectedSlots)
        : <TimeSlot>[];

    final exists = currentSlots.any((s) => s.id == event.slot.id);
    if (exists) {
      currentSlots.removeWhere((s) => s.id == event.slot.id);
    } else {
      currentSlots.add(event.slot);
    }

    final total = currentSlots.fold<double>(0.0, (sum, item) => sum + item.price);
    emit(BookingSlotsUpdated(selectedSlots: currentSlots, totalPrice: total));
  }

  void _onClearSlots(ClearSelectedSlotsEvent event, Emitter<BookingState> emit) {
    emit(const BookingSlotsUpdated(selectedSlots: [], totalPrice: 0.0));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/blocs/booking_bloc_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/blocs/booking/ test/presentation/blocs/booking_bloc_test.dart
git commit -m "feat: implement BookingBloc for time-slot selection and price calculation"
```

---

### Task 5: Tiện ích Sinh Mã VietQR Động (Dynamic VietQR Generator)

**Files:**
- Create: `lib/core/utils/vietqr_generator.dart`
- Test: `test/core/utils/vietqr_generator_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `VietQRGenerator.generateUrl({bankId, accountNo, amount, memo, accountName})`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/utils/vietqr_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/vietqr_generator.dart';

void main() {
  test('VietQRGenerator creates correct image URL with required query parameters', () {
    final url = VietQRGenerator.generateUrl(
      bankId: 'MB',
      accountNo: '0901234567',
      amount: 150000,
      memo: 'BK-001',
      accountName: 'NGUYEN VAN A',
    );

    expect(url.startsWith('https://img.vietqr.io/image/MB-0901234567-compact2.png'), true);
    expect(url.contains('amount=150000'), true);
    expect(url.contains('addInfo=BK-001'), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/vietqr_generator_test.dart`
Expected: FAIL with compilation error

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/utils/vietqr_generator.dart
class VietQRGenerator {
  static String generateUrl({
    required String bankId,
    required String accountNo,
    required int amount,
    required String memo,
    required String accountName,
  }) {
    final encodedMemo = Uri.encodeComponent(memo);
    final encodedName = Uri.encodeComponent(accountName);
    return 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$amount&addInfo=$encodedMemo&accountName=$encodedName';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/vietqr_generator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/vietqr_generator.dart test/core/utils/vietqr_generator_test.dart
git commit -m "feat: implement dynamic VietQR URL generator"
```

---

### Task 6: Tích Hợp Google Gemini 1.5 Flash cho Smart Matchmaking AI

**Files:**
- Create: `lib/data/models/match_recommendation.dart`
- Create: `lib/data/datasources/remote/gemini_service.dart`
- Test: `test/data/datasources/gemini_service_test.dart`

**Interfaces:**
- Consumes: `google_generative_ai`, User Profile, Matchmaking Posts
- Produces: `GeminiService.getMatchRecommendations({userProfile, posts})` returns `List<MatchRecommendation>`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/datasources/gemini_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/data/models/match_recommendation.dart';

void main() {
  test('MatchRecommendation parses JSON schema from Gemini response correctly', () {
    const jsonString = '''[
      {
        "postId": "post_101",
        "matchScore": 92,
        "compatibilityLevel": "HIGH",
        "matchReason": "Cùng trình độ Intermediate và cùng ở quận Bình Thạnh"
      }
    ]''';

    final List<dynamic> decoded = jsonDecode(jsonString);
    final list = decoded.map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>)).toList();

    expect(list.length, 1);
    expect(list.first.postId, 'post_101');
    expect(list.first.matchScore, 92);
    expect(list.first.compatibilityLevel, 'HIGH');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/datasources/gemini_service_test.dart`
Expected: FAIL with "Target of URI doesn't exist"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/models/match_recommendation.dart
class MatchRecommendation {
  final String postId;
  final int matchScore;
  final String compatibilityLevel;
  final String matchReason;

  const MatchRecommendation({
    required this.postId,
    required this.matchScore,
    required this.compatibilityLevel,
    required this.matchReason,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      postId: json['postId'] as String,
      matchScore: (json['matchScore'] as num).toInt(),
      compatibilityLevel: json['compatibilityLevel'] as String,
      matchReason: json['matchReason'] as String,
    );
  }
}
```

```dart
// lib/data/datasources/remote/gemini_service.dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/match_recommendation.dart';

class GeminiService {
  final String apiKey;
  GeminiService({required this.apiKey});

  Future<List<MatchRecommendation>> getMatchRecommendations({
    required Map<String, dynamic> userProfile,
    required List<Map<String, dynamic>> posts,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        systemInstruction: Content.text(
          'Bạn là chuyên gia phân tích dữ liệu thể thao (Sports Matchmaker AI). '
          'Hãy so khớp hồ sơ người dùng và danh sách bài đăng ghép kèo, trả về JSON gồm: '
          'postId, matchScore (0-100), compatibilityLevel (HIGH/MEDIUM/LOW), matchReason (1-2 câu tiếng Việt).'
        ),
      );

      final prompt = 'Hồ sơ người chơi: ${jsonEncode(userProfile)}\n'
                     'Danh sách bài đăng: ${jsonEncode(posts)}';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.isEmpty) return _fallback(userProfile, posts);

      final List<dynamic> parsed = jsonDecode(text);
      return parsed.map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Heuristic Fallback khi rớt mạng hoặc lỗi API
      return _fallback(userProfile, posts);
    }
  }

  List<MatchRecommendation> _fallback(Map<String, dynamic> user, List<Map<String, dynamic>> posts) {
    return posts.map((post) {
      int score = 50;
      if (post['sportType'] == user['preferredSport']) score += 30;
      if (post['district'] == user['district']) score += 15;
      return MatchRecommendation(
        postId: post['id'] as String,
        matchScore: score,
        compatibilityLevel: score >= 80 ? 'HIGH' : 'MEDIUM',
        matchReason: 'Gợi ý dự phòng dựa trên khu vực và môn thể thao yêu thích.',
      );
    }).toList();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/datasources/gemini_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/match_recommendation.dart lib/data/datasources/remote/gemini_service.dart test/data/datasources/gemini_service_test.dart
git commit -m "feat: implement Gemini 1.5 Flash sports matchmaking service with heuristic fallback"
```

---

### Task 7: Thiết Kế Giao Diện Lưới Chọn Slot (Time-Slot Matrix Widget - Tâm Điểm UI 40%)

**Files:**
- Create: `lib/presentation/widgets/time_slot_matrix.dart`
- Test: `test/presentation/widgets/time_slot_matrix_test.dart`

**Interfaces:**
- Consumes: `TimeSlot`, `SlotStatus`, `AppColors`
- Produces: Visual Time-Slot Grid Widget with 3 status colors (Green, Red, Amber)

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/widgets/time_slot_matrix_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/widgets/time_slot_matrix.dart';

void main() {
  testWidgets('TimeSlotMatrix renders available and booked slots with correct texts', (tester) async {
    const slots = [
      TimeSlot(id: '1', date: '2026-09-06', courtNumber: 1, startTime: '18:00', endTime: '19:00', price: 150000, status: SlotStatus.available),
      TimeSlot(id: '2', date: '2026-09-06', courtNumber: 1, startTime: '19:00', endTime: '20:00', price: 150000, status: SlotStatus.booked),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TimeSlotMatrix(
          slots: slots,
          selectedSlotIds: const {},
          onSlotTapped: (_) {},
        ),
      ),
    ));

    expect(find.text('18:00 - 19:00 (Sân 1)'), findsOneWidget);
    expect(find.text('19:00 - 20:00 (Sân 1)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/time_slot_matrix_test.dart`
Expected: FAIL with compilation error

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/widgets/time_slot_matrix.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/time_slot.dart';

class TimeSlotMatrix extends StatelessWidget {
  final List<TimeSlot> slots;
  final Set<String> selectedSlotIds;
  final Function(TimeSlot) onSlotTapped;

  const TimeSlotMatrix({
    super.key,
    required this.slots,
    required this.selectedSlotIds,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = selectedSlotIds.contains(slot.id);

        Color bgColor = AppColors.available;
        String statusText = 'Còn trống';

        if (slot.status == SlotStatus.booked) {
          bgColor = AppColors.booked;
          statusText = 'Đã đặt';
        } else if (isSelected) {
          bgColor = AppColors.selected;
          statusText = 'Đang chọn';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: bgColor.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: bgColor, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            enabled: slot.isAvailable,
            leading: Icon(
              slot.isAvailable ? Icons.event_available : Icons.event_busy,
              color: bgColor,
            ),
            title: Text(
              '${slot.startTime} - ${slot.endTime} (Sân ${slot.courtNumber})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(statusText, style: TextStyle(color: bgColor)),
            trailing: Text(
              '${slot.price.toInt()} đ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: slot.isAvailable ? () => onSlotTapped(slot) : null,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/time_slot_matrix_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/time_slot_matrix.dart test/presentation/widgets/time_slot_matrix_test.dart
git commit -m "feat: implement TimeSlotMatrix widget with interactive slot status states"
```

---

### Task 8: Dữ Liệu Mẫu Khởi Tạo (Mock Data Seeding Script)

**Files:**
- Create: `lib/core/utils/seed_data.dart`
- Test: `test/core/utils/seed_data_test.dart`

**Interfaces:**
- Consumes: `Venue`
- Produces: `SeedData.sampleVenues`

- [ ] **Step 1: Write the failing test**

```dart
// test/core/utils/seed_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/seed_data.dart';

void main() {
  test('SeedData contains realistic venues in Ho Chi Minh City', () {
    final venues = SeedData.sampleVenues;
    expect(venues.length, greaterThanOrEqualTo(3));
    expect(venues.any((v) => v.district.contains('Bình Thạnh')), true);
    expect(venues.any((v) => v.sportTypes.contains('pickleball')), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils/seed_data_test.dart`
Expected: FAIL with compilation error

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/core/utils/seed_data.dart
import '../../domain/entities/venue.dart';

class SeedData {
  static const List<Venue> sampleVenues = [
    Venue(
      id: 'venue_bt_01',
      name: 'CLB Cầu Lông & Pickleball Bình Thạnh Sport',
      sportTypes: ['badminton', 'pickleball'],
      address: '123 Chu Văn An, Phường 12',
      district: 'Bình Thạnh',
      courtCount: 6,
      hourlyRate: 150000.0,
      rating: 4.8,
      reviewCount: 142,
      imageUrls: [
        'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      ],
      amenities: ['Bãi đỗ ô tô', 'Máy lạnh', 'Căn tin', 'WiFi'],
    ),
    Venue(
      id: 'venue_td_02',
      name: 'Thảo Điền Pickleball Hub',
      sportTypes: ['pickleball'],
      address: '45 Quốc Hương, Thảo Điền',
      district: 'Thủ Đức',
      courtCount: 8,
      hourlyRate: 200000.0,
      rating: 4.9,
      reviewCount: 98,
      imageUrls: [
        'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800',
      ],
      amenities: ['Tủ locker', 'Phòng tắm nóng lạnh', 'Cho thuê vợt', 'Huấn luyện viên'],
    ),
    Venue(
      id: 'venue_q7_03',
      name: 'Sân Bóng Đá Mini Nam Sài Gòn',
      sportTypes: ['football'],
      address: '78 Nguyễn Hữu Thọ, Tân Hưng',
      district: 'Quận 7',
      courtCount: 4,
      hourlyRate: 280000.0,
      rating: 4.7,
      reviewCount: 215,
      imageUrls: [
        'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
      ],
      amenities: ['Đèn chiếu sáng tiêu chuẩn', 'Trọng tài', 'Bãi giữ xe rộng'],
    ),
  ];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils/seed_data_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/seed_data.dart test/core/utils/seed_data_test.dart
git commit -m "feat: add comprehensive seed data for demo venues in HCMC"
```
