class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImageUrl;
  final String? thumbnailUrl;
  final bool emailVerified;
  // Present when the user belongs to a company: 'owner' or 'employee'.
  // Null for regular (client) accounts.
  final String? companyRole;
  final String? locale;
  /// Personal gender — 'men' / 'women' / null. Drives the default home
  /// gender filter for clients.
  final String? gender;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImageUrl,
    this.thumbnailUrl,
    this.emailVerified = false,
    this.locale,
    this.companyRole,
    this.gender,
  });

  /// Deserialises from the Laravel UserResource JSON shape:
  /// {
  ///   "id":              "string",
  ///   "email":           "string",
  ///   "firstName":       "string",   ← camelCase from UserResource
  ///   "lastName":        "string",   ← camelCase from UserResource
  ///   "phone":           "string|null",
  ///   "profileImageUrl": "string|null"
  /// }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:              json['id'] as String,
      email:           json['email'] as String,
      firstName:       (json['firstName'] as String?) ?? '',
      lastName:        (json['lastName'] as String?) ?? '',
      phone:           json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      thumbnailUrl:    json['thumbnailUrl'] as String?,
      emailVerified:   json['emailVerified'] as bool? ?? false,
      companyRole:     json['companyRole'] as String?,
      locale:          json['locale'] as String?,
      gender:          json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':              id,
      'email':           email,
      'firstName':       firstName,
      'lastName':        lastName,
      'phone':           phone,
      'profileImageUrl': profileImageUrl,
      'thumbnailUrl':    thumbnailUrl,
      'emailVerified':   emailVerified,
      'companyRole':     companyRole,
      'gender':          gender,
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  /// Sentinel to explicitly clear a nullable field via [copyWith].
  /// Pass [UserModel.clearUrl] as the value to set a `String?` field to null.
  static const _clearSentinel = Object();

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    // Use [UserModel.clearUrl] to explicitly set these to null.
    Object? profileImageUrl = _clearSentinel,
    Object? thumbnailUrl    = _clearSentinel,
    bool? emailVerified,
    String? companyRole,
    String? locale,
    String? gender,
  }) {
    return UserModel(
      id:              id              ?? this.id,
      email:           email           ?? this.email,
      firstName:       firstName       ?? this.firstName,
      lastName:        lastName        ?? this.lastName,
      phone:           phone           ?? this.phone,
      profileImageUrl: identical(profileImageUrl, _clearSentinel)
          ? this.profileImageUrl
          : profileImageUrl as String?,
      thumbnailUrl:    identical(thumbnailUrl, _clearSentinel)
          ? this.thumbnailUrl
          : thumbnailUrl as String?,
      emailVerified:   emailVerified   ?? this.emailVerified,
      companyRole:     companyRole     ?? this.companyRole,
      locale:          locale          ?? this.locale,
      gender:          gender          ?? this.gender,
    );
  }
}

// ---------------------------------------------------------------------------
// Company user — separate model for company accounts
// ---------------------------------------------------------------------------
class CompanyUserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profileImageUrl;

  const CompanyUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profileImageUrl,
  });

  factory CompanyUserModel.fromJson(Map<String, dynamic> json) {
    return CompanyUserModel(
      id:              json['id'] as String,
      name:            json['name'] as String,
      email:           json['email'] as String,
      phone:           json['phone'] as String?,
      address:         json['address'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':              id,
      'name':            name,
      'email':           email,
      'phone':           phone,
      'address':         address,
      'profileImageUrl': profileImageUrl,
    };
  }
}
