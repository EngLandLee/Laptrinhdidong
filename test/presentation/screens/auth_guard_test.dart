import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/main.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/widgets/auth_guard_sheet.dart';
import 'package:sporthub/domain/entities/community_post.dart';

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

  setUp(() {
    AuthStore.instance.reset();
    CommunityFeedStore.instance.reset();
    AuthStore.instance.continueAsGuest();
  });

  testWidgets('Guest user tapping + Đăng kèo in Community shows AuthGuardSheet and dismisses cleanly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Go to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Tap + Đăng kèo
    final postBtn = find.text('+ Đăng kèo');
    await tester.tap(postBtn);
    await tester.pumpAndSettle();

    // Expect auth guard sheet
    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);
    expect(find.text('Cần đăng nhập để tiếp tục'), findsOneWidget);

    // Tap dismiss
    await tester.tap(find.byKey(const Key('guard_dismiss_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsNothing);
  });

  testWidgets('Guest user tapping guard_login_now_button logs out and navigates to AuthScreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Go to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Tap + Đăng kèo
    await tester.tap(find.text('+ Đăng kèo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);

    // Tap login now
    await tester.tap(find.byKey(const Key('guard_login_now_button')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isFalse);
    expect(AuthStore.instance.isGuest, isFalse);
    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
  });

  testWidgets('Guest user tapping booking in VenueDetailScreen triggers AuthGuardSheet', (tester) async {
    final venue = SeedData.sampleVenues.first;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => BookingBloc(),
        child: MaterialApp(
          home: VenueDetailScreen(venue: venue),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select add-on to show bottom booking bar
    final incBtn = find.byKey(const Key('addon_inc_rent_badminton'));
    await tester.scrollUntilVisible(
      incBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(incBtn, findsOneWidget);
    await tester.tap(incBtn);
    await tester.pumpAndSettle();

    // Tap Thanh toán VietQR
    await tester.tap(find.text('Thanh toán VietQR'));
    await tester.pumpAndSettle();

    // Expect AuthGuardSheet instead of VietQR dialog
    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);
    expect(find.text('Cần đăng nhập để tiếp tục'), findsOneWidget);
    expect(find.text('Thanh Toán VietQR'), findsNothing);
  });

  testWidgets('Guest user tapping join post in Community triggers AuthGuardSheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Go to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Find "Tham gia ngay"
    final joinBtn = find.text('Tham gia ngay').first;
    await tester.tap(joinBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);
    expect(find.text('Cần đăng nhập để tiếp tục'), findsOneWidget);
  });

  testWidgets('Guest user tapping Gửi yêu cầu for approval post in Community triggers AuthGuardSheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const SportHubApp());
    await tester.pumpAndSettle();

    // Go to Community tab
    await tester.tap(find.byIcon(Icons.groups_rounded));
    await tester.pumpAndSettle();

    // Seed post requiring approval
    CommunityFeedStore.instance.addPost(
      const CommunityPost(
        id: 'post_approval_test_01',
        title: 'Kèo thử thách phê duyệt',
        authorId: 'user_other_99',
        authorName: 'Trần Văn Host',
        sportType: 'badminton',
        district: 'Bình Thạnh',
        venueName: 'CLB Cầu Lông Bình Thạnh',
        scheduledTime: '20:00 - 22:00',
        skillLevel: 'Khá',
        requiredPlayers: 4,
        currentPlayers: 1,
        shareFee: 50000,
        note: 'Cần duyệt trước',
        requiresApproval: true,
      ),
    );
    await tester.pumpAndSettle();

    final requestBtn = find.byKey(const Key('request_join_post_approval_test_01'));
    expect(requestBtn, findsOneWidget);

    await tester.tap(requestBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);
    expect(find.text('Cần đăng nhập để tiếp tục'), findsOneWidget);
  });

  testWidgets('AuthGuardSheet.show displays actionName and dismisses cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AuthGuardSheet.show(context, actionName: 'tuyển người chơi'),
            child: const Text('Show Guard'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Guard'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsOneWidget);
    expect(find.text('Cần đăng nhập để tiếp tục'), findsOneWidget);
    expect(find.textContaining('tuyển người chơi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guard_dismiss_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_guard_sheet')), findsNothing);
  });
}
