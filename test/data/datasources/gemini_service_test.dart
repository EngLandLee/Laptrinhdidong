import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/data/datasources/remote/gemini_service.dart';
import 'package:sporthub/data/models/match_recommendation.dart';

void main() {
  group('MatchRecommendation', () {
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
      final list = decoded
          .map((e) => MatchRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.length, 1);
      expect(list.first.postId, 'post_101');
      expect(list.first.matchScore, 92);
      expect(list.first.compatibilityLevel, 'HIGH');
      expect(list.first.matchReason,
          'Cùng trình độ Intermediate và cùng ở quận Bình Thạnh');
    });

    test('MatchRecommendation serializes to JSON correctly', () {
      const recommendation = MatchRecommendation(
        postId: 'post_102',
        matchScore: 85,
        compatibilityLevel: 'HIGH',
        matchReason: 'Phù hợp trình độ và giờ giấc',
      );

      final json = recommendation.toJson();
      expect(json['postId'], 'post_102');
      expect(json['matchScore'], 85);
      expect(json['compatibilityLevel'], 'HIGH');
      expect(json['matchReason'], 'Phù hợp trình độ và giờ giấc');
    });
  });

  group('GeminiService', () {
    test('falls back to heuristic matching with sport, district, and skill matching when API call fails', () async {
      final service = GeminiService(apiKey: 'dummy_invalid_api_key');
      final userProfile = {
        'preferredSport': 'Badminton',
        'district': 'Bình Thạnh',
        'skillLevel': 'Intermediate',
      };
      final posts = [
        {
          'id': 'post_1',
          'sportType': 'Badminton',
          'district': 'Bình Thạnh',
          'skillLevel': 'Intermediate',
        },
        {
          'id': 'post_2',
          'sportType': 'Football',
          'district': 'Quận 1',
          'skillLevel': 'Advanced',
        },
        {
          'postId': 'post_3',
          'sportType': 'Badminton',
          'district': 'Quận 7',
          'authorSkill': 'Intermediate',
        },
        {
          'id': 'post_4',
          'sportType': 'Tennis',
          'district': 'Bình Thạnh',
          'skillLevel': 'Beginner',
        },
      ];

      final recommendations = await service.getMatchRecommendations(
        userProfile: userProfile,
        posts: posts,
      );

      expect(recommendations.length, 4);

      // Post 1: base (45) + sport (+30) + district (+15) + skill (+10) = 100 -> HIGH
      expect(recommendations[0].postId, 'post_1');
      expect(recommendations[0].matchScore, 100);
      expect(recommendations[0].compatibilityLevel, 'HIGH');

      // Post 2: base (45) + no match = 45 -> MEDIUM
      expect(recommendations[1].postId, 'post_2');
      expect(recommendations[1].matchScore, 45);
      expect(recommendations[1].compatibilityLevel, 'MEDIUM');

      // Post 3: base (45) + sport (+30) + authorSkill (+10) = 85 -> HIGH (uses postId key fallback)
      expect(recommendations[2].postId, 'post_3');
      expect(recommendations[2].matchScore, 85);
      expect(recommendations[2].compatibilityLevel, 'HIGH');

      // Post 4: base (45) + district (+15) = 60 -> MEDIUM
      expect(recommendations[3].postId, 'post_4');
      expect(recommendations[3].matchScore, 60);
      expect(recommendations[3].compatibilityLevel, 'MEDIUM');
    });

    test('skill matching supports authorSkill in userProfile and capped at 100', () async {
      final service = GeminiService(apiKey: 'dummy_invalid_api_key');
      final userProfile = {
        'preferredSport': 'Pickleball',
        'district': 'Thủ Đức',
        'authorSkill': 'Advanced',
      };
      final posts = [
        {
          'id': 'post_x',
          'sportType': 'Pickleball',
          'district': 'Thủ Đức',
          'skillLevel': 'Advanced',
        },
      ];

      final recommendations = await service.getMatchRecommendations(
        userProfile: userProfile,
        posts: posts,
      );

      expect(recommendations.first.matchScore, 100);
      expect(recommendations.first.compatibilityLevel, 'HIGH');
    });
  });
}
