class CompanyDetailModel {
  final String id;
  final String name;
  final String address;
  final int priceLevel;
  final double rating;
  final int reviewCount;
  final List<String> photos;
  final List<ServiceCategoryModel> categories;
  final List<EmployeeModel> employees;
  final String? phone;
  final String? phoneSecondary;
  final String bookingMode;
  /// Salon's target gender — 'men' | 'women' | 'both'. Defaults to 'both'
  /// when the backend doesn't specify.
  final String gender;
  /// Minimum hours before the appointment after which client cancellation
  /// is no longer allowed. `0` = no restriction. Displayed on the booking
  /// confirmation so clients know their cancellation window upfront.
  final int minCancelHours;

  /// Whether the authenticated user has marked this company as a favorite.
  /// Defaults to `false` when unauthenticated or when the field is absent.
  final bool isFavorite;

  const CompanyDetailModel({
    required this.id,
    required this.name,
    required this.address,
    required this.priceLevel,
    required this.rating,
    required this.reviewCount,
    required this.photos,
    required this.categories,
    this.employees = const [],
    this.phone,
    this.phoneSecondary,
    this.bookingMode = 'employee_based',
    this.gender = 'both',
    this.minCancelHours = 2,
    this.isFavorite = false,
  });

  CompanyDetailModel copyWith({
    String? id,
    String? name,
    String? address,
    int? priceLevel,
    double? rating,
    int? reviewCount,
    List<String>? photos,
    List<ServiceCategoryModel>? categories,
    List<EmployeeModel>? employees,
    String? phone,
    String? phoneSecondary,
    String? bookingMode,
    String? gender,
    int? minCancelHours,
    bool? isFavorite,
  }) {
    return CompanyDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      priceLevel: priceLevel ?? this.priceLevel,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photos: photos ?? this.photos,
      categories: categories ?? this.categories,
      employees: employees ?? this.employees,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      bookingMode: bookingMode ?? this.bookingMode,
      gender: gender ?? this.gender,
      minCancelHours: minCancelHours ?? this.minCancelHours,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory CompanyDetailModel.fromJson(Map<String, dynamic> json) {
    // Unwrap 'data' envelope if present
    final data = (json['data'] ?? json) as Map<String, dynamic>;

    return CompanyDetailModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      priceLevel: data['priceLevel'] as int? ?? 2,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      photos: (data['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      categories: (data['categories'] as List<dynamic>?)
              ?.map((e) =>
                  ServiceCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees: (data['employees'] as List<dynamic>?)
              ?.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      phone: data['phone'] as String?,
      phoneSecondary: data['phoneSecondary'] as String? ??
          data['phone_secondary'] as String?,
      bookingMode: data['bookingMode'] as String? ??
          data['booking_mode'] as String? ??
          'employee_based',
      gender: (data['gender'] as String?) ?? 'both',
      minCancelHours: data['minCancelHours'] as int? ??
          data['min_cancel_hours'] as int? ??
          2,
      isFavorite: data['isFavorite'] as bool? ?? false,
    );
  }
}

class ServiceCategoryModel {
  final String id;
  final String name;
  final List<ServiceModel> services;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.services,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ServiceModel {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final int? maxConcurrent;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.maxConcurrent,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      maxConcurrent: json['maxConcurrent'] as int? ??
          json['max_concurrent'] as int?,
    );
  }
}

class EmployeeModel {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> specialties;
  final List<String> serviceIds;

  const EmployeeModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.specialties = const [],
    this.serviceIds = const [],
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceIds: (json['serviceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
