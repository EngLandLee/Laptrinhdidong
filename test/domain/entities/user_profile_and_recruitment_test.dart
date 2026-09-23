import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/join_request.dart';
import 'package:sporthub/domain/entities/user_profile.dart';
import 'package:sporthub/domain/entities/community_post.dart';
import 'package:sporthub/main.dart';

void main() {
  group('JoinRequest & UserProfile Entities', () {
    test('JoinRequest instantiates correctly and supports copyWith', () {
      final req = JoinRequest(
        id: 'req_01',
        postId: 'post_01',
        userId: 'user_02',
        userName: 'Lê Minh',
        userPhone: '0901234567',
        skillLevel: 'Intermediate',
        preferredSport: 'pickleball',
        createdAt: DateTime.parse('2026-09-06 10:00:00'),
        status: 'pending',
      );

      expect(req.userName, 'Lê Minh');
      expect(req.status, 'pending');

      final approved = req.copyWith(status: 'approved');
      expect(approved.status, 'approved');
      expect(approved.id, 'req_01');
    });

    test('UserProfile instantiates and updates fields via copyWith', () {
      final profile = UserProfile(
        userId: 'user_demo_01',
        fullName: 'Nguyễn Văn An',
        phone: '0909 123 456',
        preferredSport: 'pickleball',
        skillLevel: 'Intermediate',
        district: 'Bình Thạnh',
        playTimePreference: 'Buổi tối (18:00 - 21:00)',
        matchesPlayed: 18,
        reputationRating: 4.9,
        onTimeRate: 98,
      );

      expect(profile.fullName, 'Nguyễn Văn An');
      expect(profile.matchesPlayed, 18);

      final updated = profile.copyWith(fullName: 'Trần Bình', district: 'Quận 1');
      expect(updated.fullName, 'Trần Bình');
      expect(updated.district, 'Quận 1');
      expect(updated.phone, '0909 123 456');
    });

    test('UserProfileStore updates profile reactively', () {
      final store = UserProfileStore.instance;
      final initialName = store.profile.fullName;
      expect(initialName, isNotEmpty);

      store.updateProfile(fullName: 'Võ Minh Quân', district: 'Thủ Đức');
      expect(store.profile.fullName, 'Võ Minh Quân');
      expect(store.profile.district, 'Thủ Đức');
    });

    test('CommunityPost helper getters evaluate correctly', () {
      final req1 = JoinRequest(
        id: 'req_01',
        postId: 'post_test',
        userId: 'user_pending',
        userName: 'User Pending',
        userPhone: '0901111111',
        skillLevel: 'Beginner',
        preferredSport: 'badminton',
        createdAt: DateTime.now(),
        status: 'pending',
      );
      final req2 = JoinRequest(
        id: 'req_02',
        postId: 'post_test',
        userId: 'user_approved',
        userName: 'User Approved',
        userPhone: '0902222222',
        skillLevel: 'Advanced',
        preferredSport: 'badminton',
        createdAt: DateTime.now(),
        status: 'approved',
      );

      final post = CommunityPost(
        id: 'post_test',
        title: 'Test Post',
        authorId: 'host_01',
        authorName: 'Host User',
        sportType: 'badminton',
        district: 'Bình Thạnh',
        skillLevel: 'Intermediate',
        venueName: 'Test Venue',
        scheduledTime: '18:00 - 20:00',
        requiredPlayers: 4,
        currentPlayers: 2,
        shareFee: 40000,
        note: 'Note',
        requiresApproval: true,
        pendingRequests: [req1, req2],
      );

      expect(post.isHost('host_01'), isTrue);
      expect(post.isHost('other_user'), isFalse);
      expect(post.pendingCount, 1);
      expect(post.hasPendingRequest('user_pending'), isTrue);
      expect(post.hasPendingRequest('user_approved'), isFalse);
      expect(post.hasJoined('user_approved'), isTrue);
      expect(post.hasJoined('host_01'), isTrue);
      expect(post.hasJoined('random_user'), isFalse);
    });
  });

  group('CommunityFeedStore Approval & Request Workflow', () {
    setUp(() {
      CommunityFeedStore.instance.reset();
    });

    test('sendJoinRequest adds pending request to post', () {
      final post = CommunityFeedStore.instance.posts.first;
      final applicant = UserProfile(
        userId: 'user_applicant_99',
        fullName: 'Phạm Hùng',
        phone: '0988776655',
        preferredSport: 'badminton',
        skillLevel: 'Advanced',
        district: 'Quận 7',
        playTimePreference: 'Sáng',
        matchesPlayed: 5,
        reputationRating: 4.8,
        onTimeRate: 100,
      );

      CommunityFeedStore.instance.sendJoinRequest(post.id, applicant);
      final updatedPost = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);

      expect(updatedPost.pendingRequests.length, 1);
      expect(updatedPost.pendingRequests.first.userName, 'Phạm Hùng');
      expect(updatedPost.pendingRequests.first.status, 'pending');
      expect(updatedPost.pendingCount, 1);
    });

    test('approveJoinRequest approves request and increments currentPlayers', () {
      final post = CommunityFeedStore.instance.posts.first;
      final initialPlayers = post.currentPlayers;
      final applicant = UserProfile(
        userId: 'user_applicant_99',
        fullName: 'Phạm Hùng',
        phone: '0988776655',
        preferredSport: 'badminton',
        skillLevel: 'Advanced',
        district: 'Quận 7',
        playTimePreference: 'Sáng',
        matchesPlayed: 5,
        reputationRating: 4.8,
        onTimeRate: 100,
      );

      CommunityFeedStore.instance.sendJoinRequest(post.id, applicant);
      final reqId = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id).pendingRequests.first.id;

      CommunityFeedStore.instance.approveJoinRequest(post.id, reqId);
      final afterApproval = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);

      expect(afterApproval.currentPlayers, initialPlayers + 1);
      expect(afterApproval.pendingRequests.first.status, 'approved');
      expect(afterApproval.pendingCount, 0);
    });

    test('rejectJoinRequest marks request as rejected without incrementing players', () {
      final post = CommunityFeedStore.instance.posts.first;
      final initialPlayers = post.currentPlayers;
      final applicant = UserProfile(
        userId: 'user_applicant_99',
        fullName: 'Phạm Hùng',
        phone: '0988776655',
        preferredSport: 'badminton',
        skillLevel: 'Advanced',
        district: 'Quận 7',
        playTimePreference: 'Sáng',
        matchesPlayed: 5,
        reputationRating: 4.8,
        onTimeRate: 100,
      );

      CommunityFeedStore.instance.sendJoinRequest(post.id, applicant);
      final reqId = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id).pendingRequests.first.id;

      CommunityFeedStore.instance.rejectJoinRequest(post.id, reqId);
      final afterReject = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);

      expect(afterReject.currentPlayers, initialPlayers);
      expect(afterReject.pendingRequests.first.status, 'rejected');
      expect(afterReject.pendingCount, 0);
    });

    test('approveJoinRequest marks isClosed if requiredPlayers reached', () {
      final post = CommunityFeedStore.instance.posts.first;
      // Set current players to requiredPlayers - 1
      final almostFull = post.copyWith(currentPlayers: post.requiredPlayers - 1, isClosed: false);
      CommunityFeedStore.instance.updatePost(almostFull);

      final applicant = UserProfile(
        userId: 'user_applicant_last',
        fullName: 'Người Cuối',
        phone: '0911223344',
        preferredSport: 'badminton',
        skillLevel: 'Intermediate',
        district: 'Quận 1',
        playTimePreference: 'Tối',
      );

      CommunityFeedStore.instance.sendJoinRequest(almostFull.id, applicant);
      final reqId = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == almostFull.id).pendingRequests.first.id;

      CommunityFeedStore.instance.approveJoinRequest(almostFull.id, reqId);
      final fullPost = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == almostFull.id);

      expect(fullPost.currentPlayers, fullPost.requiredPlayers);
      expect(fullPost.isFull, isTrue);
      expect(fullPost.isClosed, isTrue);
    });

    test('closePost sets isClosed to true', () {
      final post = CommunityFeedStore.instance.posts.first;
      CommunityFeedStore.instance.closePost(post.id);
      final closedPost = CommunityFeedStore.instance.posts.firstWhere((p) => p.id == post.id);
      expect(closedPost.isClosed, isTrue);
    });
  });
}
