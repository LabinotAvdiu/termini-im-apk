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

  /// Preferred employee for this favorite (employee_based + favorite + saved
  /// preference). Null when capacity_based, not favorited, or no preference.
  /// When non-null, the favorites screen shows TWO cards: one with the
  /// employee locked, one for free employee selection.
  final String? preferredEmployeeId;
  final String? preferredEmployeeName;

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
    this.preferredEmployeeId,
    this.preferredEmployeeName,
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
    String? preferredEmployeeId,
    String? preferredEmployeeName,
    bool clearPreferredEmployee = false,
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
      preferredEmployeeId: clearPreferredEmployee
          ? null
          : (preferredEmployeeId ?? this.preferredEmployeeId),
      preferredEmployeeName: clearPreferredEmployee
          ? null
          : (preferredEmployeeName ?? this.preferredEmployeeName),
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
      preferredEmployeeId: json['preferredEmployeeId'] as String?,
      preferredEmployeeName: json['preferredEmployeeName'] as String?,
    );
  }
}

/// Dual-entry expansion for the home / favorites listings.
///
/// When a favorite has a preferred employee AND the salon is in
/// `employee_based` mode, two entries are emitted: the original (Card A —
/// favorite + employee badge, taps lock the booking to that pro) and a
/// plain twin (Card B — same salon, no heart, no employee filter, taps
/// open the regular booking flow).
///
/// Other favorites and non-favorites are passed through unchanged.
extension CompanyCardListDualEntry on List<CompanyCardModel> {
  List<CompanyCardModel> expandFavoritesDualEntry() {
    final result = <CompanyCardModel>[];
    for (final c in this) {
      final hasPreferredEmployee = c.isFavorite &&
          c.preferredEmployeeId != null &&
          c.preferredEmployeeId!.isNotEmpty &&
          c.bookingMode == 'employee_based';

      if (hasPreferredEmployee) {
        // Card A — keeps preferredEmployee + heart.
        result.add(c);
        // Card B — same salon, no heart, no employee filter, no slots
        // pre-bias (we keep slots since they reflect availability either way).
        result.add(c.copyWith(
          isFavorite: false,
          clearPreferredEmployee: true,
        ));
      } else {
        result.add(c);
      }
    }
    return result;
  }
}
