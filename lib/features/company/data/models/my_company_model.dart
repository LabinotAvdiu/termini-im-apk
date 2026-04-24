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
  final int? maxConcurrent;

  const MyServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.maxConcurrent,
  });

  factory MyServiceModel.fromJson(Map<String, dynamic> json) {
    return MyServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      maxConcurrent: json['maxConcurrent'] as int? ??
          json['max_concurrent'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
        if (maxConcurrent != null) 'max_concurrent': maxConcurrent,
      };

  MyServiceModel copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    double? price,
    Object? maxConcurrent = _myServiceSentinel,
  }) =>
      MyServiceModel(
        id: id ?? this.id,
        name: name ?? this.name,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        price: price ?? this.price,
        maxConcurrent: maxConcurrent == _myServiceSentinel
            ? this.maxConcurrent
            : maxConcurrent as int?,
      );
}

const Object _myServiceSentinel = Object();

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
  /// Company_user pivot id — used by owner mutation endpoints (assign
  /// service, remove from team). NOT the user's id.
  final String id;

  /// Underlying User id — stable across salons. Used to match the logged-in
  /// user against the team for the "share as me" flow.
  final String userId;

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
    required this.userId,
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
    final rawUserId = json['userId']?.toString() ?? '';
    final rawId = json['id']?.toString() ?? '';
    return MyEmployeeModel(
      id: rawId,
      userId: rawUserId.isNotEmpty ? rawUserId : rawId,
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
    String? userId,
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
        userId: userId ?? this.userId,
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
  final String? phoneSecondary;
  final String email;
  final String? description;
  final String? profileImageUrl;
  final List<MyCategoryModel> categories;
  final List<MyEmployeeModel> employees;
  final List<OpeningHourModel> openingHours;
  final String bookingMode;
  // Auto-approve: when true, capacity_based bookings skip the pending queue
  // and land directly as confirmed. Ignored in employee_based mode.
  final bool capacityAutoApprove;
  // Feature 1 — Cancellation window set by the owner
  final int minCancelHours;
  // Geospatial fields — null when the salon hasn't been geocoded yet.
  // The owner's home + dashboard shows a red banner when these are null so
  // the salon shows up in search faster. Populated either by selecting a
  // Google Places suggestion or by capturing GPS from the owner's device.
  final double? latitude;
  final double? longitude;

  const MyCompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    this.phoneSecondary,
    required this.email,
    this.description,
    this.profileImageUrl,
    this.categories = const [],
    this.employees = const [],
    this.openingHours = const [],
    this.bookingMode = 'employee_based',
    this.capacityAutoApprove = false,
    this.minCancelHours = 2,
    this.latitude,
    this.longitude,
  });

  /// True when the salon has either a Google-validated address (lat/lng set
  /// by Places autocomplete) or manually captured GPS coordinates.
  bool get hasGeocoding => latitude != null && longitude != null;

  MyCompanyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? phone,
    String? phoneSecondary,
    String? email,
    String? description,
    String? profileImageUrl,
    List<MyCategoryModel>? categories,
    List<MyEmployeeModel>? employees,
    List<OpeningHourModel>? openingHours,
    String? bookingMode,
    bool? capacityAutoApprove,
    int? minCancelHours,
    double? latitude,
    double? longitude,
  }) {
    return MyCompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      email: email ?? this.email,
      description: description ?? this.description,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      categories: categories ?? this.categories,
      employees: employees ?? this.employees,
      openingHours: openingHours ?? this.openingHours,
      bookingMode: bookingMode ?? this.bookingMode,
      capacityAutoApprove: capacityAutoApprove ?? this.capacityAutoApprove,
      minCancelHours: minCancelHours ?? this.minCancelHours,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory MyCompanyModel.fromJson(Map<String, dynamic> json) {
    // Unwrap optional 'data' envelope
    final d = (json['data'] ?? json) as Map<String, dynamic>;

    return MyCompanyModel(
      id: d['id']?.toString() ?? '',
      name: d['name'] as String? ?? '',
      address: d['address'] as String? ?? '',
      city: d['city'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      phoneSecondary: d['phoneSecondary'] as String? ??
          d['phone_secondary'] as String?,
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
      bookingMode: d['bookingMode'] as String? ??
          d['booking_mode'] as String? ??
          'employee_based',
      capacityAutoApprove: d['capacityAutoApprove'] as bool? ??
          d['capacity_auto_approve'] as bool? ??
          false,
      minCancelHours: d['minCancelHours'] as int? ??
          d['min_cancel_hours'] as int? ??
          2,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'phone_secondary': phoneSecondary,
        'email': email,
        'description': description,
        'profileImageUrl': profileImageUrl,
        'categories': categories.map((c) => c.toJson()).toList(),
        'employees': employees.map((e) => e.toJson()).toList(),
        'openingHours': openingHours.map((h) => h.toJson()).toList(),
        'min_cancel_hours': minCancelHours,
      };

}

// Sentinel used by copyWith to distinguish "not provided" from explicit null.
const Object _sentinel = Object();

// ---------------------------------------------------------------------------
// Company break (capacity_based mode)
// ---------------------------------------------------------------------------

class CompanyBreakModel {
  final String id;
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final String? label;

  const CompanyBreakModel({
    required this.id,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.label,
  });

  factory CompanyBreakModel.fromJson(Map<String, dynamic> json) {
    return CompanyBreakModel(
      id: json['id']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek'] as int? ?? json['day_of_week'] as int?,
      startTime: json['startTime'] as String? ?? json['start_time'] as String? ?? '',
      endTime: json['endTime'] as String? ?? json['end_time'] as String? ?? '',
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        if (label != null && label!.isNotEmpty) 'label': label,
      };
}

// ---------------------------------------------------------------------------
// Capacity override (reduced-capacity date)
// ---------------------------------------------------------------------------

class CapacityOverrideModel {
  final String id;
  final String date;
  final int capacity;
  final String? notes;

  const CapacityOverrideModel({
    required this.id,
    required this.date,
    required this.capacity,
    this.notes,
  });

  factory CapacityOverrideModel.fromJson(Map<String, dynamic> json) {
    return CapacityOverrideModel(
      id: json['id']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'capacity': capacity,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
