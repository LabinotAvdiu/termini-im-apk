// Model for a single gallery photo owned by the company.
// Backend returns camelCase fields.

class GalleryPhotoModel {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final int position;

  const GalleryPhotoModel({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.position,
  });

  String get displayUrl => thumbnailUrl ?? url;

  factory GalleryPhotoModel.fromJson(Map<String, dynamic> json) {
    return GalleryPhotoModel(
      id: json['id']?.toString() ?? '',
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'position': position,
      };

  GalleryPhotoModel copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    int? position,
  }) =>
      GalleryPhotoModel(
        id: id ?? this.id,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        position: position ?? this.position,
      );
}
