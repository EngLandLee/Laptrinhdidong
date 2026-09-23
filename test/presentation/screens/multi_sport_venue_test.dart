import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/widgets/time_slot_matrix.dart';

void main() {
  Widget buildTestScreen(venue) {
    return BlocProvider(
      create: (_) => BookingBloc(),
      child: MaterialApp(
        home: VenueDetailScreen(venue: venue),
      ),
    );
  }

  testWidgets('VenueDetailScreen displays Sport Partition Bar for multi-sport venue', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    await tester.pumpWidget(buildTestScreen(tanBinhVenue));
    await tester.pumpAndSettle();

    // Verify Sport Partition Bar exists
    expect(find.byKey(const Key('venue_sport_filter_all')), findsOneWidget);
    expect(find.byKey(const Key('venue_sport_filter_badminton')), findsOneWidget);
    expect(find.byKey(const Key('venue_sport_filter_pickleball')), findsOneWidget);
    expect(find.byKey(const Key('venue_sport_filter_football')), findsOneWidget);

    // Scroll until view_mode_court_map is visible
    final courtMapToggle = find.byKey(const Key('view_mode_court_map'));
    await tester.scrollUntilVisible(
      courtMapToggle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Switch to 2D court overview map
    await tester.tap(courtMapToggle);
    await tester.pumpAndSettle();

    // In All mode: 10 courts
    expect(find.byKey(const Key('court_card_1')), findsOneWidget);
    expect(find.byKey(const Key('court_card_10')), findsOneWidget);

    // Filter to Football only
    final footballFilter = find.byKey(const Key('venue_sport_filter_football'));
    await tester.ensureVisible(footballFilter);
    await tester.tap(footballFilter);
    await tester.pumpAndSettle();

    // Only Courts 8, 9, 10 visible
    expect(find.byKey(const Key('court_card_1')), findsNothing);
    expect(find.byKey(const Key('court_card_5')), findsNothing);
    expect(find.byKey(const Key('court_card_8')), findsOneWidget);
    expect(find.byKey(const Key('court_card_9')), findsOneWidget);
    expect(find.byKey(const Key('court_card_10')), findsOneWidget);
    expect(find.text('Cỏ FIFA'), findsWidgets);

    // Filter to Pickleball only
    final pickleballFilter = find.byKey(const Key('venue_sport_filter_pickleball'));
    await tester.ensureVisible(pickleballFilter);
    await tester.tap(pickleballFilter);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('court_card_5')), findsOneWidget);
    expect(find.byKey(const Key('court_card_6')), findsOneWidget);
    expect(find.byKey(const Key('court_card_7')), findsOneWidget);
    expect(find.byKey(const Key('court_card_8')), findsNothing);
    expect(find.text('Mặt USAPA'), findsWidgets);
  });

  testWidgets('Matrix mode filters columns when sport filter is tapped', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    await tester.pumpWidget(buildTestScreen(tanBinhVenue));
    await tester.pumpAndSettle();

    // Default view mode is matrix
    expect(find.byType(TimeSlotMatrix), findsOneWidget);

    // Scroll until sport partition bar is visible
    final footballFilter = find.byKey(const Key('venue_sport_filter_football'));
    await tester.scrollUntilVisible(
      footballFilter,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Tap football filter
    await tester.tap(footballFilter);
    await tester.pumpAndSettle();

    // Matrix should be rendered with 3 football courts (Courts 8, 9, 10)
    expect(find.byType(TimeSlotMatrix), findsOneWidget);
    expect(find.text('SÂN 8'), findsWidgets);
    expect(find.text('SÂN 9'), findsWidgets);
    expect(find.text('SÂN 10'), findsWidgets);
    expect(find.text('SÂN 1'), findsNothing);
  });

  testWidgets('Sport Filter Safeguard overrides mismatched targetSport so target court is visible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    // Court 6 is pickleball, but passing mismatched targetSport 'football'
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(
            venue: tanBinhVenue,
            targetCourtNumber: 6,
            targetSport: 'football',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Court 6 card should be present because sport filter safeguard corrected filter to pickleball
    expect(find.byKey(const Key('court_card_6')), findsOneWidget);
    // Court 8 (football) should not be visible in pickleball filter
    expect(find.byKey(const Key('court_card_8')), findsNothing);
  });

  testWidgets('In-place court focus from Chatbot action card closes sheet and updates view without duplicate route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final tanBinhVenue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');
    await tester.pumpWidget(buildTestScreen(tanBinhVenue));
    await tester.pumpAndSettle();

    // Verify currently 1 VenueDetailScreen in tree
    expect(find.byType(VenueDetailScreen), findsOneWidget);

    // Tap FloatingChatBubble
    await tester.tap(find.byKey(const Key('floating_chat_bubble')));
    await tester.pumpAndSettle();

    // Ask to book court 6
    await tester.enterText(
      find.byKey(const Key('chat_input_field')),
      'Đặt sân 6 Tân Bình',
    );
    await tester.tap(find.byKey(const Key('btn_chat_send')));
    await tester.pumpAndSettle();

    // Tap "Xem trên sơ đồ"
    final viewCourtMapBtn = find.byKey(const Key('btn_chat_view_court_map'));
    expect(viewCourtMapBtn, findsOneWidget);
    await tester.tap(viewCourtMapBtn);
    await tester.pumpAndSettle();

    // Bottom sheet is closed
    expect(find.byKey(const Key('chat_input_field')), findsNothing);

    // STILL exactly 1 VenueDetailScreen (no duplicate route pushed)
    expect(find.byType(VenueDetailScreen), findsOneWidget);

    // In court_map view mode and court 6 is rendered
    expect(find.byKey(const Key('court_card_6')), findsOneWidget);
  });
}
