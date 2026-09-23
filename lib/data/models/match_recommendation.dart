class MatchRecommendation {
  final String postId;
  final int matchScore;
  final String compatibilityLevel;
  final String matchReason;

  const MatchRecommendation({
    required this.postId,
    required this.matchScore,
    required this.compatibilityLevel,
    required this.matchReason,
  });

  factory MatchRecommendation.fromJson(Map<String, dynamic> json) {
    return MatchRecommendation(
      postId: json['postId'] as String,
      matchScore: (json['matchScore'] as num).toInt(),
      compatibilityLevel: json['compatibilityLevel'] as String,
      matchReason: json['matchReason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'matchScore': matchScore,
      'compatibilityLevel': compatibilityLevel,
      'matchReason': matchReason,
    };
  }
}
