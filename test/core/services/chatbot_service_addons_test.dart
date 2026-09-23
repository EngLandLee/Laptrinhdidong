import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/chatbot_service.dart';

void main() {
  group('ChatbotService Add-ons & Reply Cleaning', () {
    test('cleanReply strips hallucinated markdown pseudo tags and buttons', () {
      const rawText = '''
Chào anh An! Em đề xuất sân CLB Cầu Lông Tao Đàn nhé!

[Thẻ đặt sân: CLB Cầu Lông Tao Đàn | Môn: Cầu lông | Thời gian: 19:00 | Giá: 160.000đ/h]
[Nút: ĐẶT NGAY]

---
[Nút: Xem thêm sân Cầu lông]
[Nút: Tìm sân khu vực Quận 1]
''';

      final cleaned = ChatbotService.cleanReply(rawText);
      expect(cleaned, isNot(contains('[Thẻ đặt sân')));
      expect(cleaned, isNot(contains('[Nút:')));
      expect(cleaned, isNot(contains('---')));
      expect(cleaned, contains('Chào anh An! Em đề xuất sân CLB Cầu Lông Tao Đàn nhé!'));
    });

    test('Local intent correctly handles ordering 2 chai nước bù khoáng and 1 ống cầu', () async {
      ChatbotService.instance.resetMessages();

      final response = await ChatbotService.instance.sendMessage(
        'đặt thêm cho tôi 2 chai nước bù khoáng, với 1 ống cầu',
      );

      expect(response.text, isNot(contains('Dạ, em có thể hỗ trợ anh/chị tìm sân trống, kiểm tra giá')));
      expect(response.text, contains('2 chai nước Pocari bù khoáng'));
      expect(response.text, contains('1 ống cầu lông Hải Yến'));
      expect(response.text, contains('270.000 đ'));
      expect(response.actionCard, isNotNull);
      expect(response.actionCard!['addonsTotal'], equals(270000));
      expect(response.actionCard!['price'], anyOf(equals(430000), equals(450000)));
      expect(response.actionCard!['addons'], isList);
      expect((response.actionCard!['addons'] as List).length, equals(2));
      expect(response.actionCard!['addonCounts'], isNotNull);
      final counts = response.actionCard!['addonCounts'] as Map<String, int>;
      expect(counts['drink_pocari'], equals(2));
      expect(counts['gear_shuttle_tube'], equals(1));
    });

    test('Chatbot handles image upload and recruitment intent', () async {
      ChatbotService.instance.resetMessages();

      final response = await ChatbotService.instance.sendMessage(
        'Tìm giúp tôi 2 người đánh đôi cầu lông 19h',
        imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136',
      );

      expect(response.actionCard, isNotNull);
      expect(response.actionCard!['type'], equals('recruitment_card'));
      expect(response.actionCard!['requiredPlayers'], equals(4));
      expect(response.actionCard!['currentPlayers'], equals(2));
      expect(response.actionCard!['imageUrl'], isNotNull);
      expect(response.quickSuggestions, contains('📢 Đăng lên Bảng tin Cộng đồng'));
      expect(response.text, contains('bài đăng tuyển thành viên'));
    });
  });
}
