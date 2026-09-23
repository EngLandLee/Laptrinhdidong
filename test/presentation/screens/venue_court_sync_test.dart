import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/core/services/venue_sync_service.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/venue.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
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
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
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

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  late Venue taoDanVenue;

  setUp(() {
    VenueSyncService.instance.reset();

    taoDanVenue = SeedData.sampleVenues.firstWhere(
      (v) => v.name.contains('Tao Đàn'),
    );
  });

  tearDown(() {
    VenueSyncService.instance.stopPolling();
  });

  testWidgets(
      'VenueDetailScreen displays court 1 as paused and slots as disabled when court is inactive',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Initial state: Court 1 of Tao Dan is inactive
    expect(
      VenueSyncService.instance.isCourtActive(
        venueId: taoDanVenue.id,
        courtNumber: 1,
        venueName: taoDanVenue.name,
      ),
      isFalse,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => BookingBloc(),
          child: Scaffold(
            body: VenueDetailScreen(venue: taoDanVenue),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In matrix view: VisualCourtHeader has "🔒 Tạm dừng" tag for Court 1
    expect(find.text('🔒 Tạm dừng'), findsWidgets);

    // Switch to court map overview mode
    final courtMapToggle = find.byKey(const Key('view_mode_court_map'));
    await tester.scrollUntilVisible(
      courtMapToggle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(courtMapToggle);
    await tester.pumpAndSettle();

    // Scroll to court card 1
    final courtCard1 = find.byKey(const Key('court_card_1'));
    await tester.scrollUntilVisible(
      courtCard1,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Court 1 card has the "🔒 Tạm dừng hoạt động" badge and "Đang bảo trì" price
    expect(find.text('🔒 Tạm dừng hoạt động'), findsWidgets);
    expect(find.text('Đang bảo trì'), findsWidgets);

    // Court 2 should still be active ("slot trống")
    expect(find.textContaining('slot trống'), findsWidgets);

    // Dynamically re-enable Court 1 via VenueSyncService (as if toggled back ON in Admin Web)
    VenueSyncService.instance.setCourtActive(
      venueId: 'venue_01',
      courtNumber: 1,
      isActive: true,
    );
    await tester.pumpAndSettle();

    // After re-enabling, Court 1 should now be active
    expect(
      VenueSyncService.instance.isCourtActive(
        venueId: taoDanVenue.id,
        courtNumber: 1,
        venueName: taoDanVenue.name,
      ),
      isTrue,
    );
    expect(find.text('🔒 Tạm dừng hoạt động'), findsNothing);
  });
}
