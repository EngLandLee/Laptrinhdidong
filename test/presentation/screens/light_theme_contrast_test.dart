import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/core/constants/app_colors.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/theme/theme_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    ThemeStore.instance.setThemeMode(ThemeMode.light);
    AuthStore.instance.continueAsGuest();
  });

  testWidgets('VenueDetailScreen View Mode Toggle container is theme-aware and high contrast in Light Mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(BlocProvider(
      create: (_) => BookingBloc(),
      child: MaterialApp(
        home: VenueDetailScreen(venue: venue),
      ),
    ));
    await tester.pumpAndSettle();

    final matrixTabFinder = find.byKey(const Key('view_mode_matrix'));
    expect(matrixTabFinder, findsOneWidget);

    // Verify view mode toggle parent container has light background in Light Mode
    final toggleContainer = tester.widget<Container>(
      find.ancestor(of: matrixTabFinder, matching: find.byType(Container)).first,
    );
    final boxDec = toggleContainer.decoration as BoxDecoration;
    expect(boxDec.color, isNot(const Color(0xFF0F172A)));
  });

  testWidgets('VenueDetailScreen 2D Zone Header uses light pastel gradient and dark text in Light Mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(BlocProvider(
      create: (_) => BookingBloc(),
      child: MaterialApp(
        home: VenueDetailScreen(venue: venue),
      ),
    ));
    await tester.pumpAndSettle();

    // Switch to 2D court map
    final courtMapTab = find.byKey(const Key('view_mode_court_map'));
    await tester.ensureVisible(courtMapTab);
    await tester.tap(courtMapTab);
    await tester.pumpAndSettle();

    final zoneHeaderFinder = find.byKey(const Key('zone_header_badminton'));
    expect(zoneHeaderFinder, findsOneWidget);

    final zoneHeaderContainer = tester.widget<Container>(zoneHeaderFinder);
    final gradient = (zoneHeaderContainer.decoration as BoxDecoration).gradient as LinearGradient;
    
    // In light mode, the gradient must not contain the dark #0F172A
    expect(gradient.colors.contains(const Color(0xFF0F172A).withValues(alpha: 0.85)), isFalse);
  });

  testWidgets('TimeSlotMatrix toolbar and time column use light backgrounds in Light Mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(BlocProvider(
      create: (_) => BookingBloc(),
      child: MaterialApp(
        home: VenueDetailScreen(venue: venue),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify time column header 'Khung giờ' has light background
    final timeHeaderFinder = find.text('Khung giờ');
    expect(timeHeaderFinder, findsOneWidget);

    final timeHeaderContainer = tester.widget<Container>(
      find.ancestor(of: timeHeaderFinder, matching: find.byType(Container)).first,
    );
    final headerDec = timeHeaderContainer.decoration as BoxDecoration;
    expect(headerDec.color, equals(const Color(0xFFF1F5F9)));
  });

  testWidgets('ExploreVenuesScreen venue card rating badge has white text and high contrast in Light Mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    final venue = SeedData.sampleVenues.first;
    final ratingFinder = find.text('${venue.rating}');
    expect(ratingFinder, findsWidgets);

    final ratingTextWidget = tester.widget<Text>(ratingFinder.first);
    expect(ratingTextWidget.style?.color, equals(Colors.white));

    final reviewCountFinder = find.text(' (${venue.reviewCount})');
    expect(reviewCountFinder, findsWidgets);
    final reviewCountWidget = tester.widget<Text>(reviewCountFinder.first);
    expect(reviewCountWidget.style?.color, equals(Colors.white70));
  });

  testWidgets('ExploreVenuesScreen sport chips and CTA button use high contrast colors in Light Mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Selected sport chip 'Tất cả môn' should have white text
    final allSportTextFinder = find.text('Tất cả môn');
    expect(allSportTextFinder, findsOneWidget);
    final allSportTextWidget = tester.widget<Text>(allSportTextFinder);
    expect(allSportTextWidget.style?.color, equals(Colors.white));

    // CTA button 'Xem lịch sân' should have white text
    final ctaFinder = find.text('Xem lịch sân');
    expect(ctaFinder, findsWidgets);
    final ctaWidget = tester.widget<Text>(ctaFinder.first);
    expect(ctaWidget.style?.color, equals(Colors.white));

    // Bottom Navigation Bar is fully opaque
    final bottomNavContainer = tester.widget<Container>(
      find.byKey(const Key('consumer_bottom_nav_bar')),
    );
    final boxDec = bottomNavContainer.decoration as BoxDecoration;
    expect(boxDec.color, equals(AppColors.surface));
  });
}
