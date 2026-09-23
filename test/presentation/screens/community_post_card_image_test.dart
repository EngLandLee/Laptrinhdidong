import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/community_post.dart';
import 'package:sporthub/main.dart';

void main() {
  testWidgets('renders hero image and handles like tap on post card', (tester) async {
    final testPost = CommunityPost(
      id: 'post_hero_test',
      title: 'LÊN SÂN CHỦ NHẬT HĂNG HÁI',
      authorName: 'Đỗ Nguyễn Thanh Tú',
      sportType: 'badminton',
      district: 'Thủ Đức',
      skillLevel: 'Mọi trình độ',
      venueName: 'CLB Cầu Lông Vãng Lai Thủ Đức',
      scheduledTime: '20:00 - 22:00 Tối CN',
      requiredPlayers: 6,
      currentPlayers: 3,
      shareFee: 45000,
      note: 'Nhậu nhẹt giao lưu vui vẻ',
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      likesCount: 12,
      isLiked: false,
    );

    CommunityFeedStore.instance.reset();
    CommunityFeedStore.instance.addPost(testPost);

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: MatchmakingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify hero image key exists
    expect(find.byKey(const Key('post_hero_image_post_hero_test')), findsOneWidget);

    // Verify like button
    final likeButton = find.byKey(const Key('post_like_button_post_hero_test'));
    expect(likeButton, findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    // Tap like button
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('does not render hero image when imageUrl is null, and toggles like off', (tester) async {
    final testPostNoImage = CommunityPost(
      id: 'post_no_image_test',
      title: 'KÈO KHÔNG ẢNH TEST',
      authorName: 'Trần Văn B',
      sportType: 'pickleball',
      district: 'Quận 1',
      skillLevel: 'Cơ bản',
      venueName: 'CLB Pickleball Q1',
      scheduledTime: '18:00 - 20:00 Tối T7',
      requiredPlayers: 4,
      currentPlayers: 2,
      shareFee: 50000,
      note: 'Giao lưu',
      imageUrl: null,
      likesCount: 5,
      isLiked: true,
    );

    CommunityFeedStore.instance.reset();
    CommunityFeedStore.instance.addPost(testPostNoImage);

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: MatchmakingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify hero image key does NOT exist
    expect(find.byKey(const Key('post_hero_image_post_no_image_test')), findsNothing);

    // Verify like button is present and liked count is 5
    final likeButton = find.byKey(const Key('post_like_button_post_no_image_test'));
    expect(likeButton, findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    // Tap like button to toggle off
    await tester.tap(likeButton);
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
  });
}
