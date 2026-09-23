import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/presentation/widgets/visual_court_header.dart';

void main() {
  testWidgets('VisualCourtHeader renders badminton court markings and court number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisualCourtHeader(courtNumber: 1, sportType: 'badminton'),
        ),
      ),
    );

    expect(find.text('SÂN 1'), findsOneWidget);
    expect(find.text('Thảm BWF'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('VisualCourtHeader renders football pitch markings and court number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisualCourtHeader(courtNumber: 2, sportType: 'football'),
        ),
      ),
    );

    expect(find.text('SÂN 2'), findsOneWidget);
    expect(find.text('Cỏ FIFA'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('VisualCourtHeader renders pickleball court markings and court number', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisualCourtHeader(courtNumber: 3, sportType: 'pickleball'),
        ),
      ),
    );

    expect(find.text('SÂN 3'), findsOneWidget);
    expect(find.text('Mặt USAPA'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
