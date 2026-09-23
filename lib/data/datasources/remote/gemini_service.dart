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
      int score = 45;
      if (post['sportType'] == user['preferredSport']) score += 30;
      if (post['district'] == user['district']) score += 15;
      if ((post['authorSkill'] ?? post['skillLevel']) != null &&
          (post['authorSkill'] ?? post['skillLevel']) == (user['skillLevel'] ?? user['authorSkill'])) {
        score += 10;
      }
      if (score > 100) score = 100;
      return MatchRecommendation(
        postId: (post['id'] ?? post['postId'] ?? '') as String,
        matchScore: score,
        compatibilityLevel: score >= 80 ? 'HIGH' : 'MEDIUM',
        matchReason: 'Gợi ý dự phòng dựa trên khu vực, môn thể thao và trình độ.',
      );
    }).toList();
  }
}
