import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/seed_data.dart';

void main() {
  group('SeedData - Sample Venues', () {
    test('SeedData contains realistic venues in Ho Chi Minh City', () {
      final venues = SeedData.sampleVenues;
      expect(venues.length, greaterThanOrEqualTo(3));
      expect(venues.any((v) => v.district.contains('Bình Thạnh')), true);
      expect(venues.any((v) => v.sportTypes.contains('pickleball')), true);
    });

    test('All sample venues have valid and complete attributes', () {
      final venues = SeedData.sampleVenues;
      for (final venue in venues) {
        expect(venue.id, isNotEmpty);
        expect(venue.name, isNotEmpty);
        expect(venue.sportTypes, isNotEmpty);
        expect(venue.address, isNotEmpty);
        expect(venue.district, isNotEmpty);
        expect(venue.courtCount, greaterThan(0));
        expect(venue.hourlyRate, greaterThan(0));
        expect(venue.rating, inInclusiveRange(0.0, 5.0));
        expect(venue.reviewCount, greaterThanOrEqualTo(0));
        expect(venue.imageUrls, isNotEmpty);
        expect(venue.amenities, isNotEmpty);
      }
    });
  });

  group('SeedData - Matchmaking & User Demo Data', () {
    test('SeedData contains realistic matchmaking posts for AI demonstration', () {
      final posts = SeedData.sampleMatchmakingPosts;
      expect(posts.length, greaterThanOrEqualTo(5));
      expect(posts.any((p) => p['district'] == 'Bình Thạnh'), true);
      expect(posts.any((p) => p['sportType'] == 'pickleball'), true);
      expect(posts.any((p) => p['skillLevel'] == 'Intermediate'), true);
      for (final post in posts) {
        expect(post['id'], isNotNull);
        expect(post['title'], isNotNull);
        expect(post['sportType'], isNotNull);
        expect(post['district'], isNotNull);
        expect(post['skillLevel'], isNotNull);
      }
    });

    test('SeedData contains sample user profile for AI matching demo', () {
      final user = SeedData.sampleUserProfile;
      expect(user['userId'], isNotNull);
      expect(user['preferredSport'], isNotNull);
      expect(user['district'], isNotNull);
      expect(user['skillLevel'], isNotNull);
    });
  });
}
