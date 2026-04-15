class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImageUrl;
  final bool emailVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImageUrl,
    this.emailVerified = false,
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
      emailVerified:   json['emailVerified'] as bool? ?? false,
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
      'emailVerified':   emailVerified,
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    bool? emailVerified,
  }) {
    return UserModel(
      id:              id              ?? this.id,
      email:           email           ?? this.email,
      firstName:       firstName       ?? this.firstName,
      lastName:        lastName        ?? this.lastName,
      phone:           phone           ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emailVerified:   emailVerified   ?? this.emailVerified,
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
