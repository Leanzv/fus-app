class ReviewModel {
  final String id;
  final String userId;
  final String venueId;
  final double rating;
  final String comment;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? userName;
  final String? userAvatarUrl;

  const ReviewModel({
    required this.id, required this.userId, required this.venueId,
    required this.rating, required this.comment,
    this.imageUrl, this.createdAt, this.userName, this.userAvatarUrl,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String, userId: json['user_id'] as String,
      venueId: json['venue_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String) : null,
      userName: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['name'] as String? : null,
      userAvatarUrl: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['avatar_url'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId, 'venue_id': venueId,
    'rating': rating, 'comment': comment, 'image_url': imageUrl,
  };
}
