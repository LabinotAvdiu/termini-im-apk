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
  });

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

  const ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EmployeeModel {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> specialties;

  const EmployeeModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.specialties = const [],
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
    );
  }
}
