import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/sport_image_catalog.dart';

void main() {
  group('SportImageCatalog', () {
    test('returns preset images for badminton, pickleball, and football', () {
      final badmintonImages = SportImageCatalog.getPresetsForSport('badminton');
      expect(badmintonImages.length, greaterThanOrEqualTo(3));
      expect(badmintonImages.first, startsWith('http'));

      final pickleballImages = SportImageCatalog.getPresetsForSport('pickleball');
      expect(pickleballImages.length, greaterThanOrEqualTo(3));
      expect(pickleballImages.first, startsWith('http'));

      final footballImages = SportImageCatalog.getPresetsForSport('football');
      expect(footballImages.length, greaterThanOrEqualTo(3));
      expect(footballImages.first, startsWith('http'));
    });

    test('returns default fallback image for unknown sport', () {
      final defaultImages = SportImageCatalog.getPresetsForSport('unknown');
      expect(defaultImages.isNotEmpty, isTrue);
      expect(SportImageCatalog.getDefaultImageForSport('pickleball'), startsWith('http'));
    });
  });
}
