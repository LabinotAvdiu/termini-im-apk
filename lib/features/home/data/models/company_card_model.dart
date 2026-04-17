import '../../../../core/utils/extensions.dart';

/// Represents a single time slot for a given day on the home card.
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

  factory DaySlot.fromJson(Map<String, dynamic> json) {
    return DaySlot(
      label: json['label'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      available: json['available'] as bool? ?? true,
    );
  }

  /// Build from an availability item returned by the API:
  /// { "date": "2026-04-17", "morning": true, "afternoon": false }
  factory DaySlot.fromAvailabilityItem(
    Map<String, dynamic> json, {
    required bool useMorning,
  }) {
    final date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();
    final available =
        (useMorning ? json['morning'] : json['afternoon']) as bool? ?? false;
    return DaySlot(
      label: date.dayAbbreviation,
      date: date,
      available: available,
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

  final List<DaySlot> morningSlots;
  final List<DaySlot> afternoonSlots;

  const CompanyCardModel({
    required this.id,
    required this.name,
    required this.address,
    required this.photoUrl,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.morningSlots,
    required this.afternoonSlots,
  });

  /// Convenience getter — returns "€", "€€", "€€€" or "€€€€"
  String get priceLevelDisplay => priceLevel.priceLevel;

  factory CompanyCardModel.fromJson(Map<String, dynamic> json) {
    // The API returns a single `availability` array:
    // [{ "date": "2026-04-17", "morning": true, "afternoon": false }, ...]
    // We fan it out into two DaySlot lists — one per period.
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
      morningSlots: availability
          .map((item) => DaySlot.fromAvailabilityItem(item, useMorning: true))
          .toList(),
      afternoonSlots: availability
          .map((item) => DaySlot.fromAvailabilityItem(item, useMorning: false))
          .toList(),
    );
  }
}
