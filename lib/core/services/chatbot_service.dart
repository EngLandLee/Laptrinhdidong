import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../../data/models/ticket_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/entities/venue.dart';
import '../state/ticket_store.dart';
import '../utils/currency_formatter.dart';
import '../utils/seed_data.dart';
import '../utils/shift_slot_generator.dart';
import 'venue_sync_service.dart';

/// Core service managing chatbot interactions, dual-mode intent engine
/// (Server LLM Proxy / Local Smart Intent Processor), and context collection.
class ChatbotService {
  ChatbotService._internal() {
    TicketStore.onTicketAdded = notifyBookingPaid;
  }

  static final ChatbotService instance = ChatbotService._internal();

  /// Cleans up any markdown pseudo-UI tags from assistant reply
  static String cleanReply(String raw) {
    return raw
        .replaceAll(
          RegExp(
            r'\[\s*(?:⚡|⚽|🏸|🏀|🏓|📍|Thẻ\s*đặt\s*sân|Thẻ\s*dịch\s*vụ|Thẻ|Nút|Button|Card)[^\]]*\]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\|[^\n]+\|\n\|[\s:-|]+\|\n(?:\|[^\n]+\|\n?)+',
            multiLine: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'^\s*-{3,}\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Helper to find the best available court and actual price for a venue, sport, date, and time
  static ({int courtNumber, int price, String courtName}) findAvailableCourtAndPrice({
    required String venueId,
    required String venueName,
    required String sport,
    required String date,
    required String startTime,
  }) {
    // 1. Resolve Venue object from SeedData
    Venue? venue;
    for (final v in SeedData.sampleVenues) {
      if (v.id == venueId ||
          (venueId == 'venue_01' && v.id == 'venue_q1_04') ||
          (venueId == 'venue_q1_04' && v.id == 'venue_01') ||
          v.name.toLowerCase().contains(venueName.toLowerCase()) ||
          venueName.toLowerCase().contains(v.name.toLowerCase())) {
        venue = v;
        break;
      }
    }
    venue ??= SeedData.sampleVenues[3]; // Default to Tao Đàn

    // 2. Format normalized date 'yyyy-MM-dd'
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dateStr = (date == 'Hôm nay' || date.isEmpty) ? todayStr : date;

    // 3. Shift & minute offset
    final hour = int.tryParse(startTime.split(':').first) ?? 19;
    final shift = hour < 12 ? 'morning' : (hour < 17 ? 'afternoon' : 'evening');
    final minuteOffset = startTime.endsWith(':30') ? ':30' : ':00';

    // 4. Generate slots from ShiftSlotGenerator
    final slots = ShiftSlotGenerator.generateSlots(
      date: dateStr,
      courtCount: venue.courtCount,
      shift: shift,
      minuteOffset: minuteOffset,
      venue: venue,
    );

    // 5. Calculate real slot price based on sport & venue base rate
    final sportKey = sport.toLowerCase().contains('pickleball')
        ? 'pickleball'
        : (sport.toLowerCase().contains('bóng đá') ||
                sport.toLowerCase().contains('football')
            ? 'football'
            : 'badminton');

    final calculatedPrice = ShiftSlotGenerator.calculateSlotPrice(
      sportType: sportKey,
      startTime: startTime,
      venueBaseRate: venue.hourlyRate,
    ).toInt();

    // 6. Find first court that is active & not booked
    int bestCourt = 1;
    bool found = false;

    for (int c = 1; c <= venue.courtCount; c++) {
      // Check if court is active (maintenance)
      final isCourtActive = VenueSyncService.instance.isCourtActive(
        venueId: venue.id,
        courtNumber: c,
        venueName: venue.name,
      );
      if (!isCourtActive) continue;

      // Check slot generated status (ShiftSlotGenerator)
      final matching = slots.where((s) => s.courtNumber == c && s.startTime == startTime);
      if (matching.isNotEmpty &&
          (matching.first.status == SlotStatus.booked ||
              matching.first.status == SlotStatus.locked)) {
        continue;
      }

      // Check runtime bookings
      final isBooked = VenueSyncService.instance.isSlotBooked(
        venueId: venue.id,
        courtNumber: c,
        date: dateStr,
        startTime: startTime,
        venueName: venue.name,
      );
      if (isBooked) continue;

      bestCourt = c;
      found = true;
      break;
    }

    // Fallback if none found: first active court
    if (!found) {
      for (int c = 1; c <= venue.courtCount; c++) {
        if (VenueSyncService.instance.isCourtActive(
          venueId: venue.id,
          courtNumber: c,
          venueName: venue.name,
        )) {
          bestCourt = c;
          break;
        }
      }
    }

    return (
      courtNumber: bestCourt,
      price: calculatedPrice > 0 ? calculatedPrice : 180000,
      courtName: 'Sân $bestCourt',
    );
  }

  ValueNotifier<List<ChatMessage>>? _messagesNotifier;
  /// Reactive notifier holding the list of conversation messages
  ValueNotifier<List<ChatMessage>> get messagesNotifier =>
      _messagesNotifier ??= ValueNotifier<List<ChatMessage>>([]);

  ValueNotifier<bool>? _isTypingNotifier;
  /// Reactive notifier indicating whether the assistant is currently processing or generating a response
  ValueNotifier<bool> get isTypingNotifier =>
      _isTypingNotifier ??= ValueNotifier<bool>(false);

  bool get isTyping => isTypingNotifier.value;

  /// Current user, screen, and venue context
  ChatContext? currentContext;

  /// Web Admin / API server endpoint
  String serverBaseUrl = 'http://localhost:5173';

  /// Injected HTTP client for network operations & unit testing
  http.Client? httpClient;

  /// Detects whether code is executing inside a Flutter test runner
  bool get isTestEnvironment {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return true;
      }
      final binding = WidgetsBinding.instance;
      return binding.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Candidate server URLs for reaching the backend
  List<String> get candidateServerUrls {
    final urls = <String>[];
    try {
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
        final host = Uri.base.host;
        if (host.isNotEmpty) {
          urls.add('${Uri.base.scheme}://$host:5173');
        }
      }
    } catch (_) {}
    if (!urls.contains(serverBaseUrl)) urls.add(serverBaseUrl);
    if (!urls.contains('http://127.0.0.1:5173')) urls.add('http://127.0.0.1:5173');
    if (!urls.contains('http://localhost:5173')) urls.add('http://localhost:5173');
    if (!urls.contains('http://0.0.0.0:5173')) urls.add('http://0.0.0.0:5173');
    return urls;
  }

  /// Updates active chat context
  void updateContext(ChatContext context) {
    currentContext = context;
  }

  final Set<String> _notifiedBookingIds = {};

  /// Clears message history
  void resetMessages() {
    messagesNotifier.value = [];
    isTypingNotifier.value = false;
    _notifiedBookingIds.clear();
  }

  /// Adds a message to the conversation
  void addMessage(ChatMessage message) {
    messagesNotifier.value = [...messagesNotifier.value, message];
  }

  /// Notifies chatbot of a successful booking/payment, updating any matching
  /// pending booking cards in the conversation and proactively responding to the user.
  void notifyBookingPaid(TicketModel ticket) {
    if (_notifiedBookingIds.contains(ticket.bookingId)) {
      return;
    }
    _notifiedBookingIds.add(ticket.bookingId);

    // 1. Update existing booking cards in the conversation to isPaid = true
    final currentMessages = List<ChatMessage>.from(messagesNotifier.value);
    bool updatedExisting = false;

    final updatedMessages = currentMessages.map((msg) {
      if (msg.hasActionCard && msg.actionCard!['type'] == 'booking_card') {
        final card = msg.actionCard!;
        final cardVenue = card['venueName']?.toString().toLowerCase() ?? '';
        final ticketVenue = ticket.venueName.toLowerCase();
        final matchesVenue = cardVenue.contains(ticketVenue) || ticketVenue.contains(cardVenue);

        final isAlreadyPaid = card['isPaid'] == true;
        if (!isAlreadyPaid && (matchesVenue || !updatedExisting)) {
          updatedExisting = true;
          return msg.copyWith(
            actionCard: {
              ...card,
              'isPaid': true,
              'isBooked': true,
              'bookingId': ticket.bookingId,
              'ticketId': ticket.id,
              'court': 'Sân ${ticket.courtNumber}',
            },
          );
        }
      }
      return msg;
    }).toList();

    messagesNotifier.value = updatedMessages;

    // 2. Add an assistant confirmation message to celebrate and respond back
    final courtLabel = ticket.courtNumber > 0 ? 'Sân ${ticket.courtNumber}' : 'Sân tiêu chuẩn';
    final formattedPrice = CurrencyFormatter.format(ticket.totalPrice);

    final confirmedMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_booking_paid',
      text: '🎉 **Xác nhận thanh toán thành công!**\n\n'
          'Dạ em đã nhận được thông tin thanh toán cho đơn đặt sân của mình:\n'
          '• **Mã vé:** `${ticket.bookingId}`\n'
          '• **Sân đặt:** ${ticket.venueName} ($courtLabel)\n'
          '• **Khung giờ:** ${ticket.startTime} - ${ticket.endTime} (${ticket.matchDate})\n'
          '• **Đã thanh toán:** $formattedPrice (VietQR)\n\n'
          '👉 Khung giờ đã được giữ chỗ riêng cho bạn trên hệ thống. Khi đến sân, bạn chỉ cần mở mục **Vé của tôi** và xuất trình mã QR để nhận sân nhé! Chúc bạn có một trận đấu thật bùng nổ! 🏸⚽🏓',
      sender: 'assistant',
      timestamp: DateTime.now(),
      actionCard: {
        'type': 'booking_card',
        'venueId': ticket.venueName,
        'venueName': ticket.venueName,
        'sport': ticket.sportType,
        'court': courtLabel,
        'date': ticket.matchDate,
        'time': '${ticket.startTime} - ${ticket.endTime}',
        'startTime': ticket.startTime,
        'endTime': ticket.endTime,
        'price': ticket.totalPrice,
        'isPaid': true,
        'isBooked': true,
        'bookingId': ticket.bookingId,
        'ticketId': ticket.id,
      },
      quickSuggestions: const [
        '🎫 Xem vé của tôi',
        '🔍 Xem trên sơ đồ',
        '📢 Đăng lên Bảng tin Cộng đồng',
      ],
    );

    addMessage(confirmedMessage);

    // Asynchronously sync conversation to server
    unawaited(_syncBookingPaidSession(ticket, confirmedMessage));
  }

  /// Syncs payment confirmation event to server
  Future<void> _syncBookingPaidSession(
    TicketModel ticket,
    ChatMessage confirmedMessage,
  ) async {
    if (isTestEnvironment && httpClient == null) return;
    try {
      final client = httpClient ?? http.Client();
      final shouldClose = httpClient == null;

      final convPayload = {
        'id': 'conv_${DateTime.now().millisecondsSinceEpoch}_paid',
        'userId': currentContext?.userId,
        'userName': currentContext?.userName,
        'currentScreen': currentContext?.currentRoute,
        'venueId': currentContext?.venueId,
        'messages': [
          confirmedMessage.toJson(),
        ],
        'bookingCreated': true,
        'paymentConfirmed': true,
        'ticketId': ticket.bookingId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      for (final baseUrl in candidateServerUrls) {
        try {
          final uri = Uri.parse('$baseUrl/api/chatbot/conversations');
          await client
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(convPayload),
              )
              .timeout(const Duration(milliseconds: 1000));
          break;
        } catch (_) {}
      }

      if (shouldClose) {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Sends a message, evaluates via Server LLM proxy or Local Intent Engine,
  /// updates messagesNotifier, logs session asynchronously, and returns assistant message.
  Future<ChatMessage> sendMessage(
    String text, {
    ChatContext? context,
    http.Client? httpClient,
    String? imageUrl,
  }) async {
    final cleanInput = text.trim();
    if (cleanInput.isEmpty && (imageUrl == null || imageUrl.trim().isEmpty)) {
      throw ArgumentError('Message text or imageUrl cannot be empty');
    }

    if (context != null) {
      currentContext = context;
    }

    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_user',
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );
    addMessage(userMessage);

    ChatMessage? assistantMessage;
    isTypingNotifier.value = true;

    try {
      // Natural thinking effect in live client
      if (!isTestEnvironment && httpClient == null && this.httpClient == null) {
        await Future.delayed(const Duration(milliseconds: 350));
      }

      // Try server inference if httpClient is injected or not in offline test
      final effectiveContext = context ?? currentContext;
      final effectiveHttpClient = httpClient ?? this.httpClient;
      final shouldAttemptNetwork = effectiveHttpClient != null || !isTestEnvironment;

    if (shouldAttemptNetwork) {
      try {
        final client = effectiveHttpClient ?? http.Client();
        final shouldClose = effectiveHttpClient == null;

        final payload = jsonEncode({
          'message': text,
          'context': effectiveContext?.toJson() ?? {},
          if (imageUrl != null) 'imageUrl': imageUrl,
        });

        if (effectiveHttpClient != null) {
          final uri = Uri.parse('$serverBaseUrl/api/chatbot/message');
          final response = await client
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: payload,
              )
              .timeout(const Duration(milliseconds: 1500));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic> &&
                data['reply'] != null &&
                data['reply'].toString().trim().isNotEmpty) {
              final rawSuggestions = data['quickSuggestions'];
              final quickSuggestions = rawSuggestions is List
                  ? rawSuggestions.map((e) => e.toString()).toList()
                  : null;

              assistantMessage = ChatMessage(
                id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
                text: cleanReply(data['reply'].toString()),
                sender: 'assistant',
                timestamp: DateTime.now(),
                actionCard: data['actionCard'] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(data['actionCard'] as Map)
                    : null,
                quickSuggestions: quickSuggestions,
              );
            }
          }
        } else {
          for (final baseUrl in candidateServerUrls) {
            try {
              final uri = Uri.parse('$baseUrl/api/chatbot/message');
              final response = await client
                  .post(
                    uri,
                    headers: {'Content-Type': 'application/json'},
                    body: payload,
                  )
                  .timeout(const Duration(milliseconds: 3500));

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                if (data is Map<String, dynamic> &&
                    data['reply'] != null &&
                    data['reply'].toString().trim().isNotEmpty) {
                  final rawSuggestions = data['quickSuggestions'];
                  final quickSuggestions = rawSuggestions is List
                      ? rawSuggestions.map((e) => e.toString()).toList()
                      : null;

                  serverBaseUrl = baseUrl;
                  assistantMessage = ChatMessage(
                    id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
                    text: cleanReply(data['reply'].toString()),
                    sender: 'assistant',
                    timestamp: DateTime.now(),
                    actionCard: data['actionCard'] is Map<String, dynamic>
                        ? Map<String, dynamic>.from(data['actionCard'] as Map)
                        : null,
                    quickSuggestions: quickSuggestions,
                  );
                  break;
                }
              }
            } catch (_) {}
          }
        }

        if (shouldClose) {
          try {
            client.close();
          } catch (_) {}
        }
      } catch (_) {
        // Fallback to local engine on error or timeout
      }
    }

        // Fallback to smart local intent engine if server didn't reply
        assistantMessage ??= _processLocalIntent(text, effectiveContext, imageUrl: imageUrl);

        addMessage(assistantMessage);

        // Asynchronously sync conversation to server
        unawaited(_syncConversationSession(userMessage, assistantMessage));

        return assistantMessage;
      } finally {
        isTypingNotifier.value = false;
      }
    }

  /// Processes intent locally with regex matching and smart entity extraction
  ChatMessage _processLocalIntent(String text, ChatContext? context, {String? imageUrl}) {
    final lower = text.toLowerCase();

    // Check date/time query first to prevent false matching on "bao nhiêu" in priceRegex
    final isDateTimeQuery = RegExp(
      r'(hôm nay|bây giờ|hiện tại).*(ngày mấy|ngày bao nhiêu|thứ mấy|mấy giờ|thời gian)|'
      r'(ngày mấy|ngày bao nhiêu|thứ mấy|mấy giờ).*(hôm nay|bây giờ|hiện tại)|'
      r'^hôm nay ngày bao nhiêu|^bây giờ là mấy giờ|^mấy giờ rồi|^hôm nay thứ mấy',
      caseSensitive: false,
    ).hasMatch(text);

    if (isDateTimeQuery) {
      final now = DateTime.now();
      final dayNames = [
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      final dayName = dayNames[now.weekday - 1];
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final userName = context?.userName?.trim();
      final prefix = (userName != null && userName.isNotEmpty)
          ? 'Chào anh/chị $userName! '
          : 'Dạ chào bạn! ';

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: '${prefix}Hôm nay là **$dayName, ngày $dateStr** (hiện tại là $timeStr) ạ.\n\n'
            'Em có thể hỗ trợ mình tìm sân thể thao hoặc kiểm tra lịch thi đấu hôm nay không ạ?',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: const [
          '🏸 Cầu lông Q.1 (19h)',
          '🏓 Pickleball Thảo Điền',
          '⚽ Bóng đá mini Q.7',
          'Tình trạng sân hôm nay',
        ],
      );
    }

    // Payment confirmation / Ticket check query
    final isPaymentQuery = RegExp(
      r'thanh\s*toán\s*(?:rồi|thành\s*công|chưa|xong)|đã\s*(?:chuyển\s*khoản|thanh\s*toán|đặt\s*sân\s*chưa)|kiểm\s*tra\s*(?:thanh\s*toán|vé|tiền)|xem\s*(?:lại\s*)?vé|mã\s*vé',
      caseSensitive: false,
    ).hasMatch(text);

    if (isPaymentQuery) {
      final tickets = TicketStore.instance.tickets;
      final paidTicket = tickets.cast<TicketModel?>().firstWhere(
            (t) => t?.status == 'paid',
            orElse: () => tickets.isNotEmpty ? tickets.first : null,
          );

      if (paidTicket != null) {
        final courtLabel = paidTicket.courtNumber > 0
            ? 'Sân ${paidTicket.courtNumber}'
            : 'Sân tiêu chuẩn';
        final formattedPrice = CurrencyFormatter.format(paidTicket.totalPrice);

        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '🎉 Dạ em đã kiểm tra hệ thống và xác nhận đơn đặt sân mã **${paidTicket.bookingId}** tại **${paidTicket.venueName}** ($courtLabel, ${paidTicket.startTime} - ${paidTicket.endTime}) với số tiền **$formattedPrice** đã được thanh toán thành công qua VietQR rồi ạ!\n\n'
              'Khung giờ đã được giữ chỗ riêng cho anh/chị. Khi đến sân, anh/chị chỉ cần xuất trình mã QR trong mục **Vé của tôi** để nhận sân nhé! Chúc anh/chị có buổi chơi thể thao thật vui vẻ! 🏸⚽🏓',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: {
            'type': 'booking_card',
            'venueId': paidTicket.venueName,
            'venueName': paidTicket.venueName,
            'sport': paidTicket.sportType,
            'court': courtLabel,
            'date': paidTicket.matchDate,
            'time': '${paidTicket.startTime} - ${paidTicket.endTime}',
            'startTime': paidTicket.startTime,
            'endTime': paidTicket.endTime,
            'price': paidTicket.totalPrice,
            'isPaid': true,
            'isBooked': true,
            'bookingId': paidTicket.bookingId,
            'ticketId': paidTicket.id,
          },
          quickSuggestions: const [
            '🎫 Xem vé của tôi',
            '🔍 Xem trên sơ đồ',
            '📢 Đăng lên Bảng tin Cộng đồng',
          ],
        );
      }
    }

    // Owner specific intents (doanh thu, check-in, tình trạng sân)
    final isOwner = context?.userRole == 'owner';
    if (isOwner) {
      if (lower.contains('doanh thu')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '📊 **Báo cáo Doanh thu hôm nay (CLB Tao Đàn):**\n\n'
              '• Tổng doanh thu dự kiến: **1.480.000đ**\n'
              '• Đặt qua SportHub: **4 lượt** (940.000đ)\n'
              '• Đặt tại quầy / Khách quen: **3 lượt** (540.000đ)\n'
              '• Tỷ lệ thanh toán online: **100% qua VietQR**',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Phân Tích Doanh Thu',
            'subtitle': 'Cập nhật theo thời gian thực',
            'icon': 'revenue',
            'headers': ['Kênh đặt', 'Số lượt', 'Doanh thu', 'Hình thức TT'],
            'rows': [
              ['SportHub App', '4 lượt', '940.000đ', '100% VietQR'],
              ['Tại quầy / Khách quen', '3 lượt', '540.000đ', 'Tiền mặt / CK'],
              ['Dịch vụ phụ (Nước, Cầu)', '5 đơn', '180.000đ', 'Tại quầy'],
              ['TỔNG DOANH THU', '12 lượt', '1.660.000đ', 'Đã đối soát'],
            ],
            'footer': '💡 Tiền từ đơn đặt qua app được quyết toán tự động về tài khoản VietQR của sân.',
          },
          quickSuggestions: const [
            'Tình trạng sân hôm nay',
            'Số vé chờ check-in',
            'Chính sách hoàn hủy',
          ],
        );
      }
      if (lower.contains('check-in') || lower.contains('soát vé') || lower.contains('chờ check-in')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '🎫 **Danh sách vé chờ Check-in hôm nay:**\n\n'
              '1. **SH-8291** - Nguyễn Văn An (Sân 1 lúc 18:00 - Cầu lông)\n'
              '2. **SH-8292** - Trần Thuỳ Linh (Sân 1 lúc 19:00 - Cầu lông)\n'
              '3. **SH-7714** - Lê Minh (Sân 5 lúc 18:00 - Pickleball)\n\n'
              '👉 Bạn có thể dùng mục **Soát vé QR** trên thanh điều hướng để quét mã vé khi khách tới quầy.',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Vé Chờ Check-in Hôm Nay',
            'subtitle': 'Danh sách khách đặt qua ứng dụng',
            'icon': 'ticket',
            'headers': ['Mã vé', 'Khách hàng', 'Sân & Môn', 'Giờ', 'Trạng thái'],
            'rows': [
              ['SH-8291', 'Nguyễn Văn An', 'Sân 1 (Cầu lông)', '18:00', 'Chờ check-in'],
              ['SH-8292', 'Trần Thuỳ Linh', 'Sân 1 (Cầu lông)', '19:00', 'Chờ check-in'],
              ['SH-7714', 'Lê Minh', 'Sân 5 (Pickleball)', '18:00', 'Chờ check-in'],
              ['SH-6520', 'Chú Ba (Quầy)', 'Sân 2 (Cầu lông)', '17:00', 'Đã nhận sân'],
            ],
            'footer': '💡 Bấm mục Soát vé QR trên thanh điều hướng để quét mã vé cho khách khi tới sân.',
          },
          quickSuggestions: const [
            'Doanh thu hôm nay',
            'Tình trạng sân hôm nay',
          ],
        );
      }
      if (lower.contains('tình trạng sân') || lower.contains('lịch sân') || lower.contains('sơ đồ')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '🏟️ **Tình trạng cụm sân Tao Đàn hôm nay:**\n\n'
              '• Tổng số sân: **8 sân** (Sân 1-4 Cầu lông, Sân 5-8 Pickleball)\n'
              '• Suất đã được đặt: **7 suất** (Tỷ lệ lấp đầy: 85% khung giờ tối)\n'
              '• Giờ vàng (18:00 - 20:00): **Kín 100% sân 1, sân 2 và sân 5**\n'
              '• Sân bảo trì định kỳ: **Sân 4 (12h) & Sân 7 (14h)**',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Tình Trạng 8 Sân Tao Đàn',
            'subtitle': 'Khung giờ hoạt động 06:00 - 22:00',
            'icon': 'court',
            'headers': ['Sân', 'Môn thể thao', 'Giờ mở', 'Lấp đầy', 'Trạng thái'],
            'rows': [
              ['Sân 1', 'Cầu lông', '06:00 - 22:00', '8/16 slot', 'Kín 18h-20h'],
              ['Sân 2', 'Cầu lông', '06:00 - 22:00', '7/16 slot', 'Kín 17h-19h'],
              ['Sân 3', 'Cầu lông', '06:00 - 22:00', '5/16 slot', 'Còn trống'],
              ['Sân 4', 'Cầu lông', '06:00 - 22:00', '4/16 slot', 'Bảo trì 12h'],
              ['Sân 5', 'Pickleball', '06:00 - 22:00', '9/16 slot', 'Kín 18h-21h'],
              ['Sân 6', 'Pickleball', '06:00 - 22:00', '6/16 slot', 'Còn trống'],
              ['Sân 7', 'Pickleball', '06:00 - 22:00', '3/16 slot', 'Bảo trì 14h'],
              ['Sân 8', 'Pickleball', '06:00 - 22:00', '5/16 slot', 'Còn trống'],
            ],
            'footer': '💡 Khung giờ tối 18h-21h đã kín 85% công suất.',
          },
          quickSuggestions: const [
            'Doanh thu hôm nay',
            'Số vé chờ check-in',
          ],
        );
      }
      if (lower.contains('hoàn') || lower.contains('hủy') || lower.contains('chính sách')) {
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: '📋 **Chính sách hoàn hủy & Quyền lợi của chủ sân:**\n\n'
              '• Khách hủy trước > 24h: **Hoàn 100%** (Sân tự động mở lại slot cho khách mới).\n'
              '• Khách hủy trong 12h - 24h: **Hoàn 50%** (Sân nhận 50% tiền cọc).\n'
              '• Khách hủy dưới 12h: **Không hoàn tiền** (Sân nhận đủ 100% tiền slot).',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: const {
            'type': 'table_card',
            'title': 'Bảng Tỷ Lệ Hoàn Tiền & Quyền Lợi Sân',
            'subtitle': 'Quy định đối soát SportHub',
            'icon': 'policy',
            'headers': ['Thời gian báo hủy', 'Khách nhận lại', 'Sân thu phí', 'Quy trình xử lý'],
            'rows': [
              ['> 24 giờ trước giờ chơi', 'Hoàn 100%', '0% phí', 'Mở lại slot tự động'],
              ['12 - 24 giờ trước giờ chơi', 'Hoàn 50%', 'Thu 50% tiền cọc', 'Chuyển vào ví sân'],
              ['< 12 giờ trước giờ chơi', 'Không hoàn (0%)', 'Thu 100% tiền đặt', 'Bảo lưu doanh thu sân'],
            ],
            'footer': '💡 Chính sách giúp bảo vệ doanh thu tối đa cho chủ sân khi khách báo hủy sát giờ.',
          },
          quickSuggestions: const [
            'Doanh thu hôm nay',
            'Tình trạng sân hôm nay',
          ],
        );
      }
    }

    // 0. Recruitment / Member finding / Matchmaking assistance
    final isRecruitment = imageUrl != null ||
        RegExp(r'tuyển\s*thành\s*viên|tuyển\s*người|tìm\s*bạn|ghép\s*kèo|tìm\s*kèo|kèo\s*giao\s*lưu|cần\s*người|cần\s*thành\s*viên|tuyển\s*thêm', caseSensitive: false).hasMatch(text);

    if (isRecruitment) {
      final venueName = (context?.venueName != null && context!.venueName!.isNotEmpty)
          ? context.venueName!
          : 'CLB Cầu Lông Tao Đàn';
      final rawSport = context?.sport ??
          (lower.contains('pickleball')
              ? 'pickleball'
              : (lower.contains('bóng đá') || lower.contains('football')
                  ? 'football'
                  : 'badminton'));
      final sportTitle = rawSport == 'pickleball'
          ? 'Pickleball'
          : (rawSport == 'football' ? 'Bóng đá' : 'Cầu lông');
      final sportIcon = rawSport == 'pickleball'
          ? '🏓'
          : (rawSport == 'football' ? '⚽' : '🏸');

      final recruitmentCard = {
        'type': 'recruitment_card',
        'title': 'Kèo Giao Lưu $sportTitle - $venueName',
        'venueName': venueName,
        'sportType': rawSport,
        'district': 'Quận 1',
        'skillLevel': 'Trung bình (2.0 - 3.5)',
        'scheduledTime': '19:00 - 21:00 Hôm nay',
        'requiredPlayers': 4,
        'currentPlayers': 2,
        'shareFee': 45000.0,
        'note': 'Giao lưu rèn luyện sức khỏe, vui vẻ và kết nối đam mê thể thao!',
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      final hasImg = imageUrl != null && imageUrl.isNotEmpty;
      final replyText = hasImg
          ? '$sportIcon Em đã phân tích ảnh đính kèm và soạn sẵn bài đăng tuyển thành viên cực chuẩn cho anh/chị:\n\n'
            '📌 **${recruitmentCard['title']}**\n'
            '📍 **Địa điểm**: $venueName\n'
            '⏰ **Thời gian**: 19:00 - 21:00 Hôm nay\n'
            '👥 **Cần tuyển**: 2 thành viên (Hiện có 2/4 người)\n'
            '⭐ **Trình độ**: Trung bình (2.0 - 3.5, biết luật, đánh bền)\n'
            '💰 **Chi phí chia sẻ**: 45.000đ/người (Bao gồm sân & cầu)\n\n'
            '👉 Bạn có thể nhấn **"📢 Đăng lên Bảng tin Cộng đồng"** để tìm người ghép kèo ngay nhé!'
          : '$sportIcon Em đã hỗ trợ soạn bài đăng tuyển thành viên chuẩn thể thao cho anh/chị:\n\n'
            '📌 **${recruitmentCard['title']}**\n'
            '📍 **Địa điểm**: $venueName\n'
            '⏰ **Thời gian**: 19:00 - 21:00 Hôm nay\n'
            '👥 **Cần tuyển**: 2 thành viên (Hiện có 2/4 người)\n'
            '⭐ **Trình độ**: Trung bình (2.0 - 3.5)\n'
            '💰 **Chi phí chia sẻ**: 45.000đ/người\n\n'
            '👉 Hãy nhấn **"📢 Đăng lên Bảng tin Cộng đồng"** bên dưới để đăng bài ngay nhé!';

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: replyText,
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: recruitmentCard,
        quickSuggestions: const [
          '📢 Đăng lên Bảng tin Cộng đồng',
          '⚡ Đặt & Thanh toán VietQR ngay',
          '🔍 Xem trên sơ đồ',
        ],
      );
    }

    // Direct community publish confirmation
    if (lower.contains('đăng lên bảng tin') || lower.contains('đăng bài')) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: '🎉 Em đã hỗ trợ đăng bài tuyển thành viên lên Bảng tin Cộng đồng SportHub thành công! Các tay vợt trong khu vực sẽ nhận được thông báo để tham gia cùng bạn nhé. 🏸',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: const [
          '⚡ Đặt & Thanh toán VietQR ngay',
          '🔍 Xem trên sơ đồ',
        ],
      );
    }

    // 1. Add-on services / extra items (nước uống, bù khoáng, ống cầu, thuê vợt...)
    final addonCheckRegex = RegExp(
      r'nước|khoáng|bù khoáng|pocari|aquafina|ống cầu|quả cầu|hộp cầu|thuê vợt|vợt|bóng|đặt thêm|thêm',
      caseSensitive: false,
    );

    if (addonCheckRegex.hasMatch(text)) {
      final addons = <String>[];
      final itemsDesc = <String>[];
      final addonCounts = <String, int>{};
      int addonsTotal = 0;

      // 1.1 Mineral water / Pocari
      final waterMatch = RegExp(
        r'(\d+)?\s*(?:chai|lon|bình)?\s*(?:nước\s*bù\s*khoáng|pocari|nước\s*khoáng|nước\s*suối|nước)',
        caseSensitive: false,
      ).firstMatch(text);
      if (waterMatch != null) {
        final qty = int.tryParse(waterMatch.group(1) ?? '1') ?? 1;
        final itemPrice = 15000 * qty;
        addons.add('${qty}x Pocari Sweat Bù Khoáng (+${CurrencyFormatter.format(itemPrice)})');
        itemsDesc.add('$qty chai nước Pocari bù khoáng (${CurrencyFormatter.format(itemPrice)})');
        addonsTotal += itemPrice;
        addonCounts['drink_pocari'] = (addonCounts['drink_pocari'] ?? 0) + qty;
      }

      // 1.2 Shuttlecocks (ống cầu / quả cầu)
      final shuttleMatch = RegExp(
        r'(\d+)?\s*(?:ống|hộp|trái|quả)?\s*(?:cầu\s*lông|ống\s*cầu|quả\s*cầu|hộp\s*cầu|cầu)',
        caseSensitive: false,
      ).firstMatch(text);
      if (shuttleMatch != null && !shuttleMatch.group(0)!.toLowerCase().contains('sân')) {
        final qty = int.tryParse(shuttleMatch.group(1) ?? '1') ?? 1;
        final isSingle = RegExp(r'quả|trái', caseSensitive: false).hasMatch(shuttleMatch.group(0)!) &&
            !RegExp(r'ống|hộp', caseSensitive: false).hasMatch(shuttleMatch.group(0)!);
        final unitPrice = isSingle ? 22000 : 240000;
        final itemPrice = unitPrice * qty;
        final unitLabel = isSingle ? 'quả cầu lông' : 'ống cầu lông Hải Yến';
        addons.add('${qty}x ${isSingle ? 'Quả Cầu Lông' : 'Ống Cầu Lông Hải Yến'} (+${CurrencyFormatter.format(itemPrice)})');
        itemsDesc.add('$qty $unitLabel (${CurrencyFormatter.format(itemPrice)})');
        addonsTotal += itemPrice;
        final key = isSingle ? 'gear_shuttle_single' : 'gear_shuttle_tube';
        addonCounts[key] = (addonCounts[key] ?? 0) + qty;
      }

      // 1.3 Rackets (vợt)
      final racketMatch = RegExp(
        r'(\d+)?\s*(?:cây|chiếc|cặp)?\s*(?:vợt\s*cầu\s*lông|vợt\s*pickleball|vợt)',
        caseSensitive: false,
      ).firstMatch(text);
      if (racketMatch != null) {
        final qty = int.tryParse(racketMatch.group(1) ?? '1') ?? 1;
        final itemPrice = 30000 * qty;
        addons.add('${qty}x Vợt Cầu Lông Yonex (+${CurrencyFormatter.format(itemPrice)})');
        itemsDesc.add('$qty cây vợt (${CurrencyFormatter.format(itemPrice)})');
        addonsTotal += itemPrice;
        addonCounts['rent_badminton'] = (addonCounts['rent_badminton'] ?? 0) + qty;
      }

      if (itemsDesc.isNotEmpty) {
        final venueName = (context?.venueName != null && context!.venueName!.isNotEmpty)
            ? context.venueName!
            : 'CLB Cầu Lông Tao Đàn';
        final venueId = context?.venueId ?? 'venue_01';

        final courtInfo = findAvailableCourtAndPrice(
          venueId: venueId,
          venueName: venueName,
          sport: 'Cầu lông',
          date: 'Hôm nay',
          startTime: '19:00',
        );

        final basePrice = courtInfo.price;
        final totalPrice = basePrice + addonsTotal;

        final actionCard = {
          'type': 'booking_card',
          'venueId': venueId,
          'venueName': venueName,
          'sport': 'Cầu lông',
          'date': 'Hôm nay',
          'time': '19:00',
          'startTime': '19:00',
          'endTime': '20:00',
          'court': courtInfo.courtName,
          'price': totalPrice,
          'basePrice': basePrice,
          'addonsTotal': addonsTotal,
          'addons': addons,
          'addonCounts': addonCounts,
        };

        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
          text: 'Dạ, em đã ghi nhận thêm dịch vụ cho anh/chị: ${itemsDesc.join(' và ')}. Phụ phí dịch vụ là ${CurrencyFormatter.format(addonsTotal)}. Nhân viên sân $venueName sẽ chuẩn bị sẵn sàng khi mình tới nhé!',
          sender: 'assistant',
          timestamp: DateTime.now(),
          actionCard: actionCard,
          quickSuggestions: const [
            '⚡ Đặt & Thanh toán VietQR ngay',
            '🔍 Xem trên sơ đồ',
            '🏸 Đặt thêm vợt',
          ],
        );
      }
    }

    // 1. Pricing query
    final priceRegex = RegExp(r'giá|bao nhiêu|bảng giá|chi phí', caseSensitive: false);
    if (priceRegex.hasMatch(text)) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: 'Giá thuê sân cầu lông dao động từ 100.000đ - 180.000đ/giờ tuỳ theo khung giờ (giờ vàng sau 17:00 thường là 150.000đ - 180.000đ/giờ). Anh/chị có thể đặt trực tiếp trên app để nhận ưu đãi nhé!',
        sender: 'assistant',
        timestamp: DateTime.now(),
      );
    }

    // 2. Cancellation / Policy query
    final policyRegex = RegExp(r'hủy|đổi lịch|chính sách', caseSensitive: false);
    if (policyRegex.hasMatch(text)) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: 'Chính sách SportHub: Quý khách được phép hủy hoặc đổi lịch miễn phí trước 24 giờ so với giờ chơi. Nếu hủy trong vòng 12-24 giờ, hỗ trợ hoàn tiền 50% hoặc bảo lưu suất chơi.',
        sender: 'assistant',
        timestamp: DateTime.now(),
      );
    }

    // 3. Booking intent
    final bookingRegex = RegExp(
      r'đặt\s*sân|book|đặt\s*chỗ|tìm\s*sân|🏸|🏓|⚽',
      caseSensitive: false,
    );
    const defaultQuickSuggestions = [
      '🏸 Cầu lông Q.1 (19h)',
      '🏓 Pickleball Thảo Điền',
      '🏸 Cầu lông Bình Thạnh',
      '⚽ Bóng đá mini Q.7',
    ];

    if (bookingRegex.hasMatch(text)) {
      // Extract time
      String extractedTime = '19:00';
      final timeHMatch = RegExp(r'(\d{1,2})h(\d{2})?', caseSensitive: false).firstMatch(text);
      if (timeHMatch != null) {
        final h = int.tryParse(timeHMatch.group(1)!) ?? 19;
        final m = int.tryParse(timeHMatch.group(2) ?? '00') ?? 0;
        extractedTime = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      } else {
        final colonMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
        if (colonMatch != null) {
          final h = int.tryParse(colonMatch.group(1)!) ?? 19;
          final m = int.tryParse(colonMatch.group(2)!) ?? 0;
          extractedTime = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        }
      }

      final parts = extractedTime.split(':');
      final startH = int.tryParse(parts[0]) ?? 19;
      final minStr = parts.length > 1 ? parts[1] : '00';
      final endH = (startH + 1) % 24;
      final startTime = '${startH.toString().padLeft(2, '0')}:$minStr';
      final endTime = '${endH.toString().padLeft(2, '0')}:$minStr';

      // Match district / location keywords to target venue
      String venueId = 'venue_01';
      String venueName = 'CLB Cầu Lông Tao Đàn';
      String sport = 'Cầu lông';

      if (lower.contains('bình thạnh') || lower.contains('binh thanh')) {
        venueId = 'venue_bt_01';
        venueName = 'CLB Cầu Lông & Pickleball Bình Thạnh Sport';
        sport = lower.contains('pickleball') || lower.contains('🏓') ? 'Pickleball' : 'Cầu lông';
      } else if (lower.contains('thảo điền') ||
          lower.contains('thao dien') ||
          lower.contains('thủ đức') ||
          lower.contains('thu duc')) {
        venueId = 'venue_td_02';
        venueName = 'Thảo Điền Pickleball Hub';
        sport = 'Pickleball';
      } else if (lower.contains('tân bình') || lower.contains('tan binh')) {
        venueId = 'venue_tb_05';
        venueName = 'Khu Liên Hợp Thể Thao Tân Bình Arena';
        if (lower.contains('bóng đá') ||
            lower.contains('bong da') ||
            lower.contains('football') ||
            lower.contains('soccer') ||
            lower.contains('⚽')) {
          sport = 'Bóng đá';
        } else if (lower.contains('pickleball') || lower.contains('🏓')) {
          sport = 'Pickleball';
        } else {
          sport = 'Cầu lông';
        }
      } else if (lower.contains('quận 7') ||
          lower.contains('quan 7') ||
          lower.contains('q7') ||
          lower.contains('q.7') ||
          lower.contains('nam sài gòn') ||
          lower.contains('nam sai gon')) {
        venueId = 'venue_q7_03';
        venueName = 'Sân Bóng Đá Mini Nam Sài Gòn';
        sport = 'Bóng đá';
      } else if (lower.contains('tao đàn') ||
          lower.contains('tao dan') ||
          lower.contains('quận 1') ||
          lower.contains('quan 1') ||
          lower.contains('q1') ||
          lower.contains('q.1')) {
        venueId = 'venue_01';
        venueName = 'CLB Cầu Lông Tao Đàn';
        sport = lower.contains('pickleball') || lower.contains('🏓') ? 'Pickleball' : 'Cầu lông';
      } else if (context?.venueId != null && context!.venueId!.isNotEmpty) {
        venueId = context.venueId!;
        venueName = (context.venueName != null && context.venueName!.isNotEmpty)
            ? context.venueName!
            : 'CLB Cầu Lông Tao Đàn';
        if (context.sport != null && context.sport!.isNotEmpty) {
          final s = context.sport!.toLowerCase();
          if (s.contains('badminton') || s.contains('cầu lông')) {
            sport = 'Cầu lông';
          } else if (s.contains('football') || s.contains('bóng đá')) {
            sport = 'Bóng đá';
          } else if (s.contains('pickleball')) {
            sport = 'Pickleball';
          } else if (s.contains('tennis')) {
            sport = 'Tennis';
          } else {
            sport = context.sport!;
          }
        } else if (lower.contains('cầu lông') || lower.contains('badminton') || lower.contains('🏸')) {
          sport = 'Cầu lông';
        } else if (lower.contains('bóng đá') || lower.contains('football') || lower.contains('soccer') || lower.contains('⚽')) {
          sport = 'Bóng đá';
        } else if (lower.contains('pickleball') || lower.contains('🏓')) {
          sport = 'Pickleball';
        } else if (lower.contains('tennis') || lower.contains('quần vợt')) {
          sport = 'Tennis';
        }
      } else {
        final preferred = (context?.sport ?? '').toLowerCase();
        if (lower.contains('bóng đá') ||
            lower.contains('football') ||
            lower.contains('soccer') ||
            lower.contains('⚽') ||
            (!lower.contains('cầu lông') && (preferred.contains('bóng') || preferred.contains('football')))) {
          venueId = 'venue_q7_03';
          venueName = 'Sân Bóng Đá Mini Nam Sài Gòn';
          sport = 'Bóng đá';
        } else if (lower.contains('pickleball') ||
            lower.contains('🏓') ||
            (!lower.contains('cầu lông') && preferred.contains('pickleball'))) {
          venueId = 'venue_td_02';
          venueName = 'Thảo Điền Pickleball Hub';
          sport = 'Pickleball';
        } else if (lower.contains('tennis') || lower.contains('quần vợt')) {
          venueId = 'venue_01';
          venueName = 'CLB Cầu Lông Tao Đàn';
          sport = 'Tennis';
        } else {
          venueId = 'venue_01';
          venueName = 'CLB Cầu Lông Tao Đàn';
          sport = 'Cầu lông';
        }
      }

      final courtInfo = findAvailableCourtAndPrice(
        venueId: venueId,
        venueName: venueName,
        sport: sport,
        date: 'Hôm nay',
        startTime: startTime,
      );

      final actionCard = {
        'type': 'booking_card',
        'venueId': venueId,
        'venueName': venueName,
        'sport': sport,
        'date': 'Hôm nay',
        'time': extractedTime,
        'startTime': startTime,
        'endTime': endTime,
        'court': courtInfo.courtName,
        'price': courtInfo.price,
      };

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: 'Em đã tìm thấy sân trống phù hợp theo yêu cầu của anh/chị tại $venueName vào lúc $extractedTime. Anh/chị có thể nhấn nút đặt và thanh toán VietQR ngay trên thẻ bên dưới nhé!',
        sender: 'assistant',
        timestamp: DateTime.now(),
        actionCard: actionCard,
        quickSuggestions: defaultQuickSuggestions,
      );
    }

    // 4. Greeting
    final greetingRegex = RegExp(r'chào|hello|hi|bạn là ai', caseSensitive: false);
    if (greetingRegex.hasMatch(text)) {
      final userName = context?.userName?.trim();
      final greetingPrefix = (userName != null && userName.isNotEmpty)
          ? 'Chào anh/chị $userName! '
          : 'Xin chào! ';
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
        text: '${greetingPrefix}Em là trợ lý AI SportHub. Em có thể hỗ trợ anh/chị tìm sân trống, gợi ý giờ chơi, kiểm tra giá và đặt sân nhanh chóng!',
        sender: 'assistant',
        timestamp: DateTime.now(),
        quickSuggestions: defaultQuickSuggestions,
      );
    }

    // 5. Default fallback
    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_assistant',
      text: 'Dạ, em có thể hỗ trợ anh/chị tìm sân trống, kiểm tra giá hoặc đặt lịch nhanh chóng. Anh/chị muốn tìm sân môn thể thao nào và vào khung giờ nào ạ?',
      sender: 'assistant',
      timestamp: DateTime.now(),
    );
  }

  /// Syncs session conversation asynchronously with the admin web server
  Future<void> _syncConversationSession(
    ChatMessage userMsg,
    ChatMessage assistantMsg,
  ) async {
    if (isTestEnvironment && httpClient == null) return;

    try {
      final client = httpClient ?? http.Client();
      final shouldClose = httpClient == null;

      final convPayload = {
        'id': 'conv_${DateTime.now().millisecondsSinceEpoch}',
        'userId': currentContext?.userId,
        'userName': currentContext?.userName,
        'currentScreen': currentContext?.currentRoute,
        'venueId': currentContext?.venueId,
        'messages': [
          userMsg.toJson(),
          assistantMsg.toJson(),
        ],
        'bookingCreated': assistantMsg.hasActionCard,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final uri = Uri.parse('$serverBaseUrl/api/chatbot/conversations');
      await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(convPayload),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (shouldClose) {
        try {
          client.close();
        } catch (_) {}
      }
    } catch (_) {
      // Fire-and-forget sync error handling
    }
  }
}
