import '../../../../core/utils/extensions.dart';

/// A single day chip on the home card: "date + is there room?".
class DaySlot {
  final String label; // e.g. "Mer.15"
  final DateTime date;
  final bool available;

  const DaySlot({
    required this.label,
    required this.date,
    required this.available,
  });

  /// Build a DaySlot from a DateTime using the DateTimeExtensions helper.
  factory DaySlot.fromDate(DateTime date, {bool available = true}) {
    return DaySlot(
      label: date.dayAbbreviation,
      date: date,
      available: available,
    );
  }

  /// Build from an availability item returned by the API:
  /// { "date": "2026-04-17", "available": true }
  factory DaySlot.fromAvailabilityItem(Map<String, dynamic> json) {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    return DaySlot(
      label: date.dayAbbreviation,
      date: date,
      available: json['available'] as bool? ?? false,
    );
  }
}

/// Model displayed in each company card on the home screen.
class CompanyCardModel {
  final String id;
  final String name;
  final String address;
  final String photoUrl;
  final double rating;
  final int reviewCount;

  /// 1 = €, 2 = €€, 3 = €€€, 4 = €€€€
  final int priceLevel;

  /// Up to 4 upcoming day chips (was split into morning + afternoon before —
  /// the backend now ships a single `available` flag per day and the home
  /// card displays 4 chips side by side).
  final List<DaySlot> slots;
  final String bookingMode;

  /// Whether the authenticated user has marked this company as a favorite.
  /// Defaults to `false` when unauthenticated or when the field is absent.
  final bool isFavorite;

  const CompanyCardModel({
    required this.id,
    required this.name,
    required this.address,
    required this.photoUrl,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.slots,
    this.bookingMode = 'employee_based',
    this.isFavorite = false,
  });

  CompanyCardModel copyWith({
    String? id,
    String? name,
    String? address,
    String? photoUrl,
    double? rating,
    int? reviewCount,
    int? priceLevel,
    List<DaySlot>? slots,
    String? bookingMode,
    bool? isFavorite,
  }) {
    return CompanyCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      slots: slots ?? this.slots,
      bookingMode: bookingMode ?? this.bookingMode,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Convenience getter — returns "€", "€€", "€€€" or "€€€€"
  String get priceLevelDisplay => priceLevel.priceLevel;

  factory CompanyCardModel.fromJson(Map<String, dynamic> json) {
    final availability =
        (json['availability'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];

    return CompanyCardModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      priceLevel: json['priceLevel'] as int? ?? 2,
      slots: availability.map(DaySlot.fromAvailabilityItem).toList(),
      bookingMode: json['bookingMode'] as String? ??
          json['booking_mode'] as String? ??
          'employee_based',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
