import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/venue_addon.dart';
import 'package:sporthub/presentation/widgets/venue_addon_selector.dart';

void main() {
  testWidgets('VenueAddonSelector displays items and increments quantity', (tester) async {
    const items = [
      VenueAddonItem(
        id: 'r1',
        name: 'Vợt Cầu Lông Yonex',
        description: 'Chuyên công',
        price: 30000,
        unit: 'cây',
        category: AddonCategory.rental,
        icon: '🏸',
      ),
    ];

    int currentQty = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VenueAddonSelector(
                items: items,
                selectedCounts: {'r1': currentQty},
                onQuantityChanged: (item, qty) {
                  setState(() => currentQty = qty);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Vợt Cầu Lông Yonex'), findsOneWidget);
    expect(find.text('30.000 đ/cây'), findsOneWidget);

    // Tap increment icon
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(currentQty, 1);
  });

  testWidgets('VenueAddonSelector decrements quantity and does not decrement below 0', (tester) async {
    const items = [
      VenueAddonItem(
        id: 'r1',
        name: 'Vợt Cầu Lông Yonex',
        description: 'Chuyên công',
        price: 30000,
        unit: 'cây',
        category: AddonCategory.rental,
        icon: '🏸',
      ),
    ];

    int currentQty = 2;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VenueAddonSelector(
                items: items,
                selectedCounts: {'r1': currentQty},
                onQuantityChanged: (item, qty) {
                  setState(() => currentQty = qty);
                },
              );
            },
          ),
        ),
      ),
    );

    // Tap decrement icon
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(currentQty, 1);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(currentQty, 0);

    // Tap decrement icon when 0 (should not call onQuantityChanged or go below 0)
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(currentQty, 0);
  });

  testWidgets('VenueAddonSelector filters items by category tab', (tester) async {
    const items = [
      VenueAddonItem(
        id: 'r1',
        name: 'Vợt Cầu Lông Yonex',
        description: 'Chuyên công',
        price: 30000,
        unit: 'cây',
        category: AddonCategory.rental,
        icon: '🏸',
      ),
      VenueAddonItem(
        id: 'd1',
        name: 'Pocari Sweat',
        description: 'Nước bù khoáng',
        price: 15000,
        unit: 'chai',
        category: AddonCategory.beverage,
        icon: '🥤',
      ),
      VenueAddonItem(
        id: 'g1',
        name: 'Bóng Pickleball X-40',
        description: 'Bóng thi đấu',
        price: 45000,
        unit: 'quả',
        category: AddonCategory.gear,
        icon: '🎾',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VenueAddonSelector(
            items: items,
            selectedCounts: const {},
            onQuantityChanged: (_, __) {},
          ),
        ),
      ),
    );

    // Initially "Tất cả" is selected, all items visible
    expect(find.text('Vợt Cầu Lông Yonex'), findsOneWidget);
    expect(find.text('Pocari Sweat'), findsOneWidget);
    expect(find.text('Bóng Pickleball X-40'), findsOneWidget);

    // Tap "🏸 Thuê dụng cụ"
    await tester.tap(find.text('🏸 Thuê dụng cụ'));
    await tester.pumpAndSettle();

    expect(find.text('Vợt Cầu Lông Yonex'), findsOneWidget);
    expect(find.text('Pocari Sweat'), findsNothing);
    expect(find.text('Bóng Pickleball X-40'), findsNothing);

    // Tap "🥤 Nước & Căng tin"
    await tester.tap(find.text('🥤 Nước & Căng tin'));
    await tester.pumpAndSettle();

    expect(find.text('Vợt Cầu Lông Yonex'), findsNothing);
    expect(find.text('Pocari Sweat'), findsOneWidget);
    expect(find.text('Bóng Pickleball X-40'), findsNothing);

    // Tap "🎾 Phụ kiện"
    await tester.tap(find.text('🎾 Phụ kiện'));
    await tester.pumpAndSettle();

    expect(find.text('Vợt Cầu Lông Yonex'), findsNothing);
    expect(find.text('Pocari Sweat'), findsNothing);
    expect(find.text('Bóng Pickleball X-40'), findsOneWidget);

    // Tap "Tất cả"
    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();

    expect(find.text('Vợt Cầu Lông Yonex'), findsOneWidget);
    expect(find.text('Pocari Sweat'), findsOneWidget);
    expect(find.text('Bóng Pickleball X-40'), findsOneWidget);
  });

  testWidgets('VenueAddonSelector displays subtotal when items are selected', (tester) async {
    const items = [
      VenueAddonItem(
        id: 'r1',
        name: 'Vợt Cầu Lông Yonex',
        description: 'Chuyên công',
        price: 30000,
        unit: 'cây',
        category: AddonCategory.rental,
        icon: '🏸',
      ),
      VenueAddonItem(
        id: 'd1',
        name: 'Pocari Sweat',
        description: 'Nước bù khoáng',
        price: 15000,
        unit: 'chai',
        category: AddonCategory.beverage,
        icon: '🥤',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VenueAddonSelector(
            items: items,
            selectedCounts: const {'r1': 2, 'd1': 1}, // 2 * 30000 + 1 * 15000 = 75000
            onQuantityChanged: (_, __) {},
          ),
        ),
      ),
    );

    // 75.000 đ subtotal should be shown
    expect(find.textContaining('75.000 đ'), findsOneWidget);
  });
}
