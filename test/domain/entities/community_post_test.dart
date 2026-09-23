import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/community_post.dart';

void main() {
  group('CommunityPost', () {
    test('holds properties and copyWith correctly', () {
      const post = CommunityPost(
        id: 'post_01',
        title: 'Tuyển 2 bạn đánh cầu lông tối nay',
        authorName: 'Quốc Anh',
        authorAvatar: 'QA',
        sportType: 'badminton',
        district: 'Bình Thạnh',
        skillLevel: 'Trung bình',
        venueName: 'CLB Cầu Lông Bình Thạnh Sport',
        scheduledTime: '19:00 - 21:00 Hôm nay',
        requiredPlayers: 4,
        currentPlayers: 2,
        shareFee: 40000,
        note: 'Giao lưu vui vẻ, thiếu 2 chân đánh đôi.',
        isJoined: false,
      );

      expect(post.remainingSlots, 2);
      expect(post.isFull, isFalse);

      final joined = post.copyWith(isJoined: true, currentPlayers: 3);
      expect(joined.isJoined, isTrue);
      expect(joined.currentPlayers, 3);
      expect(joined.remainingSlots, 1);
    });

    test('remainingSlots and isFull handle full and overflow cases correctly', () {
      const post = CommunityPost(
        id: 'post_02',
        title: 'Kèo đủ người',
        authorName: 'Nam',
        sportType: 'pickleball',
        district: 'Thủ Đức',
        skillLevel: 'Nâng cao',
        venueName: 'Thảo Điền Hub',
        scheduledTime: '19:00 - 21:00',
        requiredPlayers: 4,
        currentPlayers: 4,
        shareFee: 50000,
        note: 'Đủ người',
      );

      expect(post.remainingSlots, 0);
      expect(post.isFull, isTrue);
      expect(post.authorAvatar, 'QA');
      expect(post.isJoined, isFalse);

      final overfilled = post.copyWith(currentPlayers: 5);
      expect(overfilled.remainingSlots, 0);
      expect(overfilled.isFull, isTrue);
    });

    test('SeedData.sampleCommunityPosts contains valid posts across multiple sports', () {
      final posts = SeedData.sampleCommunityPosts;
      expect(posts.length, greaterThanOrEqualTo(4));

      final sportTypes = posts.map((p) => p.sportType).toSet();
      expect(sportTypes, containsAll(['badminton', 'pickleball', 'football']));

      for (final post in posts) {
        expect(post.id, isNotEmpty);
        expect(post.title, isNotEmpty);
        expect(post.authorName, isNotEmpty);
        expect(post.requiredPlayers, greaterThan(0));
        expect(post.currentPlayers, greaterThanOrEqualTo(0));
        expect(post.shareFee, greaterThanOrEqualTo(0));
        expect(post.remainingSlots, greaterThanOrEqualTo(0));
      }
    });

    test('supports imageUrl, likesCount, and isLiked in constructor and copyWith', () {
      final post = CommunityPost(
        id: 'post_img_1',
        title: 'Kèo chiều nay',
        authorName: 'Tuấn',
        sportType: 'badminton',
        district: 'Thủ Đức',
        skillLevel: 'Khá',
        venueName: 'Sân Thủ Đức',
        scheduledTime: '18:00 - 20:00',
        requiredPlayers: 4,
        currentPlayers: 2,
        shareFee: 40000,
        note: 'Giao lưu',
        imageUrl: 'https://images.unsplash.com/photo-court',
        likesCount: 5,
        isLiked: true,
      );

      expect(post.imageUrl, 'https://images.unsplash.com/photo-court');
      expect(post.likesCount, 5);
      expect(post.isLiked, isTrue);

      final updated = post.copyWith(
        imageUrl: 'https://images.unsplash.com/photo-new',
        likesCount: 6,
        isLiked: false,
      );

      expect(updated.imageUrl, 'https://images.unsplash.com/photo-new');
      expect(updated.likesCount, 6);
      expect(updated.isLiked, isFalse);

      const defaultPost = CommunityPost(
        id: 'post_default',
        title: 'Kèo mặc định',
        authorName: 'Tuấn',
        sportType: 'badminton',
        district: 'Thủ Đức',
        skillLevel: 'Khá',
        venueName: 'Sân Thủ Đức',
        scheduledTime: '18:00 - 20:00',
        requiredPlayers: 4,
        currentPlayers: 2,
        shareFee: 40000,
        note: 'Giao lưu',
      );
      expect(defaultPost.imageUrl, isNull);
      expect(defaultPost.likesCount, 0);
      expect(defaultPost.isLiked, isFalse);
    });
  });
}
