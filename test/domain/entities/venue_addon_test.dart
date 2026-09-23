// test/domain/entities/venue_addon_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/venue_addon.dart';
import 'package:sporthub/core/utils/seed_data.dart';

void main() {
  test('VenueAddonItem instantiates correctly and is present in SeedData', () {
    const item = VenueAddonItem(
      id: 'a1',
      name: 'Vợt Cầu Lông Yonex',
      description: 'Dòng Astrox 88D chuyên công',
      price: 30000,
      unit: 'cây',
      category: AddonCategory.rental,
      icon: '🏸',
    );

    expect(item.id, 'a1');
    expect(item.price, 30000);
    expect(SeedData.sampleAddons.length, greaterThanOrEqualTo(6));
  });
}
