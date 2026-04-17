// Models for the authenticated company owner's own salon data.
//
// These are distinct from CompanyDetailModel (used for the public-facing
// detail view) because the owner has access to extra fields: opening hours,
// employee status, internal IDs for mutations, etc.

// ---------------------------------------------------------------------------
// Opening hours
// ---------------------------------------------------------------------------

class OpeningHourModel {
  final int dayOfWeek; // 0 = Monday … 6 = Sunday
  final String? openTime; // "HH:mm" – null when isClosed
  final String? closeTime; // "HH:mm" – null when isClosed
  final bool isClosed;

  const OpeningHourModel({
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
  });

  factory OpeningHourModel.fromJson(Map<String, dynamic> json) {
    return OpeningHourModel(
      dayOfWeek: json['dayOfWeek'] as int? ?? 1,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'open_time': openTime != null && openTime!.length > 5
            ? openTime!.substring(0, 5)
            : openTime,
        'close_time': closeTime != null && closeTime!.length > 5
            ? closeTime!.substring(0, 5)
            : closeTime,
        'is_closed': isClosed,
      };

  OpeningHourModel copyWith({
    int? dayOfWeek,
    String? openTime,
    String? closeTime,
    bool? isClosed,
  }) =>
      OpeningHourModel(
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        isClosed: isClosed ?? this.isClosed,
      );
}

// ---------------------------------------------------------------------------
// Service (owned by a category)
// ---------------------------------------------------------------------------

class MyServiceModel {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;

  const MyServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });

  factory MyServiceModel.fromJson(Map<String, dynamic> json) {
    return MyServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
      };

  MyServiceModel copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    double? price,
  }) =>
      MyServiceModel(
        id: id ?? this.id,
        name: name ?? this.name,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        price: price ?? this.price,
      );
}

// ---------------------------------------------------------------------------
// Category (owns services)
// ---------------------------------------------------------------------------

class MyCategoryModel {
  final String id;
  final String name;
  final List<MyServiceModel> services;

  const MyCategoryModel({
    required this.id,
    required this.name,
    this.services = const [],
  });

  factory MyCategoryModel.fromJson(Map<String, dynamic> json) {
    return MyCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => MyServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'services': services.map((s) => s.toJson()).toList(),
      };

  MyCategoryModel copyWith({
    String? id,
    String? name,
    List<MyServiceModel>? services,
  }) =>
      MyCategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        services: services ?? this.services,
      );
}

// ---------------------------------------------------------------------------
// Employee
// ---------------------------------------------------------------------------

class MyEmployeeModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role; // owner, employee
  final List<String> specialties;
  final List<String> serviceIds;
  final bool isActive;
  final String? photoUrl;

  const MyEmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.role = 'employee',
    this.specialties = const [],
    this.serviceIds = const [],
    this.isActive = true,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MyEmployeeModel.fromJson(Map<String, dynamic> json) {
    return MyEmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'employee',
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceIds: (json['serviceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      photoUrl: json['profilePhoto'] as String? ?? json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': role,
        'specialties': specialties,
        'serviceIds': serviceIds,
        'isActive': isActive,
      };

  MyEmployeeModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    List<String>? specialties,
    List<String>? serviceIds,
    bool? isActive,
    String? photoUrl,
  }) =>
      MyEmployeeModel(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        specialties: specialties ?? this.specialties,
        serviceIds: serviceIds ?? this.serviceIds,
        isActive: isActive ?? this.isActive,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}

// ---------------------------------------------------------------------------
// My Company (root model returned by GET /my-company)
// ---------------------------------------------------------------------------

class MyCompanyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String? description;
  final String? profileImageUrl;
  final List<MyCategoryModel> categories;
  final List<MyEmployeeModel> employees;
  final List<OpeningHourModel> openingHours;

  const MyCompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    this.description,
    this.profileImageUrl,
    this.categories = const [],
    this.employees = const [],
    this.openingHours = const [],
  });

  factory MyCompanyModel.fromJson(Map<String, dynamic> json) {
    // Unwrap optional 'data' envelope
    final d = (json['data'] ?? json) as Map<String, dynamic>;

    return MyCompanyModel(
      id: d['id']?.toString() ?? '',
      name: d['name'] as String? ?? '',
      address: d['address'] as String? ?? '',
      city: d['city'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      description: d['description'] as String?,
      profileImageUrl: d['profileImageUrl'] as String?,
      categories: (d['categories'] as List<dynamic>?)
              ?.map((e) => MyCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees: (d['employees'] as List<dynamic>?)
              ?.map((e) => MyEmployeeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      openingHours: (d['openingHours'] as List<dynamic>?)
              ?.map((e) => OpeningHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'email': email,
        'description': description,
        'profileImageUrl': profileImageUrl,
        'categories': categories.map((c) => c.toJson()).toList(),
        'employees': employees.map((e) => e.toJson()).toList(),
        'openingHours': openingHours.map((h) => h.toJson()).toList(),
      };

  MyCompanyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? phone,
    String? email,
    String? description,
    String? profileImageUrl,
    List<MyCategoryModel>? categories,
    List<MyEmployeeModel>? employees,
    List<OpeningHourModel>? openingHours,
  }) =>
      MyCompanyModel(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        city: city ?? this.city,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        description: description ?? this.description,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        categories: categories ?? this.categories,
        employees: employees ?? this.employees,
        openingHours: openingHours ?? this.openingHours,
      );
}
