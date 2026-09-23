import 'join_request.dart';

class CommunityPost {
  final String id;
  final String title;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String sportType;
  final String district;
  final String skillLevel;
  final String venueName;
  final String scheduledTime;
  final int requiredPlayers;
  final int currentPlayers;
  final double shareFee;
  final String note;
  final bool isJoined;
  final bool requiresApproval;
  final bool isClosed;
  final List<JoinRequest> pendingRequests;
  final String? imageUrl;
  final int likesCount;
  final bool isLiked;

  const CommunityPost({
    required this.id,
    required this.title,
    this.authorId = 'user_demo_01',
    required this.authorName,
    String? authorAvatar,
    String? authorAvatarUrl,
    required this.sportType,
    required this.district,
    required this.skillLevel,
    required this.venueName,
    required this.scheduledTime,
    required this.requiredPlayers,
    required this.currentPlayers,
    required this.shareFee,
    required this.note,
    this.isJoined = false,
    this.requiresApproval = true,
    this.isClosed = false,
    this.pendingRequests = const [],
    this.imageUrl,
    this.likesCount = 0,
    this.isLiked = false,
  }) : authorAvatar = authorAvatarUrl ?? authorAvatar ?? 'QA';

  String get authorAvatarUrl => authorAvatar;
  int get remainingSlots => (requiredPlayers - currentPlayers).clamp(0, requiredPlayers);
  bool get isFull => currentPlayers >= requiredPlayers;
  bool isHost(String currentUserId) => authorId == currentUserId;
  int get pendingCount => pendingRequests.where((r) => r.status == 'pending').length;
  bool hasPendingRequest(String currentUserId) =>
      pendingRequests.any((r) => r.userId == currentUserId && r.status == 'pending');
  bool hasJoined(String currentUserId) =>
      authorId == currentUserId ||
      isJoined ||
      pendingRequests.any((r) => r.userId == currentUserId && r.status == 'approved');

  CommunityPost copyWith({
    String? id,
    String? title,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorAvatarUrl,
    String? sportType,
    String? district,
    String? skillLevel,
    String? venueName,
    String? scheduledTime,
    int? requiredPlayers,
    int? currentPlayers,
    double? shareFee,
    String? note,
    bool? isJoined,
    bool? requiresApproval,
    bool? isClosed,
    List<JoinRequest>? pendingRequests,
    String? imageUrl,
    int? likesCount,
    bool? isLiked,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      title: title ?? this.title,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? authorAvatarUrl ?? this.authorAvatar,
      sportType: sportType ?? this.sportType,
      district: district ?? this.district,
      skillLevel: skillLevel ?? this.skillLevel,
      venueName: venueName ?? this.venueName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      requiredPlayers: requiredPlayers ?? this.requiredPlayers,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      shareFee: shareFee ?? this.shareFee,
      note: note ?? this.note,
      isJoined: isJoined ?? this.isJoined,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      isClosed: isClosed ?? this.isClosed,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
