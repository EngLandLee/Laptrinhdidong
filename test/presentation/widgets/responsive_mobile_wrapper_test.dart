import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/responsive_mobile_wrapper.dart';

void main() {
  testWidgets('ResponsiveMobileWrapper renders child widget on standard screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: Text('Mobile Content Test'),
        ),
      ),
    );

    expect(find.text('Mobile Content Test'), findsOneWidget);
  });

  testWidgets('ResponsiveMobileWrapper renders smartphone frame when width > 600', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: Text('Desktop Frame Test'),
        ),
      ),
    );

    expect(find.text('Desktop Frame Test'), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('ResponsiveMobileWrapper renders directly when width <= 600', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveMobileWrapper(
          child: Text('Mobile Direct Test'),
        ),
      ),
    );

    expect(find.text('Mobile Direct Test'), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
  });
}
