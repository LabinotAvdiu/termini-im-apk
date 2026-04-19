class ReviewModel {
  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String authorFirstName;
  final String authorLastInitial;
  final String? authorProfileImageUrl;
  // 'published' | 'hidden'
  final String status;

  const ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.authorFirstName,
    required this.authorLastInitial,
    this.authorProfileImageUrl,
    this.status = 'published',
  });

  String get authorDisplay => '$authorFirstName $authorLastInitial.';

  bool get isHidden => status == 'hidden';

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    final createdRaw = json['createdAt'] as String? ??
        json['created_at'] as String? ??
        DateTime.now().toIso8601String();

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 1,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(createdRaw),
      authorFirstName: author['firstName'] as String? ?? '',
      authorLastInitial: author['lastInitial'] as String? ?? '',
      authorProfileImageUrl: author['profileImageUrl'] as String?,
      status: json['status'] as String? ?? 'published',
    );
  }
}

class PaginatedReviews {
  final List<ReviewModel> reviews;
  final int total;
  final int currentPage;
  final int lastPage;

  const PaginatedReviews({
    required this.reviews,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedReviews.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>?) ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    return PaginatedReviews(
      reviews: data
          .cast<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList(),
      total: meta['total'] as int? ?? data.length,
      currentPage: meta['currentPage'] as int? ??
          meta['current_page'] as int? ??
          1,
      lastPage: meta['lastPage'] as int? ??
          meta['last_page'] as int? ??
          1,
    );
  }
}
