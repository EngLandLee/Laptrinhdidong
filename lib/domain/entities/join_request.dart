class JoinRequest {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userPhone;
  final String skillLevel;
  final String preferredSport;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'

  const JoinRequest({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.skillLevel,
    required this.preferredSport,
    required this.createdAt,
    this.status = 'pending',
  });

  JoinRequest copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userPhone,
    String? skillLevel,
    String? preferredSport,
    DateTime? createdAt,
    String? status,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredSport: preferredSport ?? this.preferredSport,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
