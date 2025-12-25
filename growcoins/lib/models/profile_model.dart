class UserProfile {
  final int id;
  final String username;
  final DateTime accountCreatedAt;
  final DateTime? lastLogin;
  final bool isActive;
  final bool biometricEnabled;
  final PersonalInfo personalInfo;
  final Address address;
  final FinancialInfo financialInfo;
  final KYCInfo kycInfo;
  final Timestamps timestamps;

  UserProfile({
    required this.id,
    required this.username,
    required this.accountCreatedAt,
    this.lastLogin,
    required this.isActive,
    required this.biometricEnabled,
    required this.personalInfo,
    required this.address,
    required this.financialInfo,
    required this.kycInfo,
    required this.timestamps,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      accountCreatedAt: DateTime.parse(json['account_created_at']),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      isActive: json['is_active'],
      biometricEnabled: json['biometric_enabled'] ?? false,
      personalInfo: PersonalInfo.fromJson(json['personal_info'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
      financialInfo: FinancialInfo.fromJson(json['financial_info'] ?? {}),
      kycInfo: KYCInfo.fromJson(json['kyc_info'] ?? {}),
      timestamps: Timestamps.fromJson(json['timestamps'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'account_created_at': accountCreatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'is_active': isActive,
      'biometric_enabled': biometricEnabled,
      'personal_info': personalInfo.toJson(),
      'address': address.toJson(),
      'financial_info': financialInfo.toJson(),
      'kyc_info': kycInfo.toJson(),
      'timestamps': timestamps.toJson(),
    };
  }
}

class PersonalInfo {
  final String? firstName;
  final String? lastName;
  final String? fullLegalName;
  final String? email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? profilePictureUrl;

  PersonalInfo({
    this.firstName,
    this.lastName,
    this.fullLegalName,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.profilePictureUrl,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullLegalName: json['full_legal_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'full_legal_name': fullLegalName,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'profile_picture_url': profilePictureUrl,
    };
  }

  String get displayName {
    if (fullLegalName != null && fullLegalName!.isNotEmpty) {
      return fullLegalName!;
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) {
      return firstName!;
    }
    return 'User';
  }
}

class Address {
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  Address({
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      address: json['address'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zip_code'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }
}

class FinancialInfo {
  final String? accountNumber;
  final String? routingNumber;
  final double accountBalance;
  final String currency;

  FinancialInfo({
    this.accountNumber,
    this.routingNumber,
    required this.accountBalance,
    this.currency = 'INR',
  });

  factory FinancialInfo.fromJson(Map<String, dynamic> json) {
    return FinancialInfo(
      accountNumber: json['account_number'],
      routingNumber: json['routing_number'],
      accountBalance: (json['account_balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'account_balance': accountBalance,
      'currency': currency,
    };
  }
}

class KYCInfo {
  final String? kycStatus;
  final DateTime? kycVerifiedAt;
  final String? panNumber;
  final String? aadharNumber;

  KYCInfo({
    this.kycStatus,
    this.kycVerifiedAt,
    this.panNumber,
    this.aadharNumber,
  });

  factory KYCInfo.fromJson(Map<String, dynamic> json) {
    return KYCInfo(
      kycStatus: json['kyc_status'],
      kycVerifiedAt: json['kyc_verified_at'] != null
          ? DateTime.parse(json['kyc_verified_at'])
          : null,
      panNumber: json['pan_number'],
      aadharNumber: json['aadhar_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kyc_status': kycStatus,
      'kyc_verified_at': kycVerifiedAt?.toIso8601String(),
      'pan_number': panNumber,
      'aadhar_number': aadharNumber,
    };
  }

  bool get isVerified => kycStatus == 'verified' || kycStatus == 'approved';
  bool get isPending => !isVerified; // Show KYC options if not verified
}

class Timestamps {
  final DateTime createdAt;
  final DateTime updatedAt;

  Timestamps({
    required this.createdAt,
    required this.updatedAt,
  });

  factory Timestamps.fromJson(Map<String, dynamic> json) {
    return Timestamps(
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

