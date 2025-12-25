# User Profile API Documentation

## 📋 Overview

The User Profile API allows frontend applications to retrieve and update user profile information. The API provides structured endpoints for managing personal information, address details, financial information, and KYC details.

---

## 🔗 Base URL

```
http://localhost:3001/api/users
```

**Note:** For Android Emulator, use `http://10.0.2.2:3001/api/users`  
**Note:** For iOS Simulator, use `http://localhost:3001/api/users`  
**Note:** For physical devices, use your computer's IP address: `http://YOUR_IP:3001/api/users`

---

## 📡 API Endpoints

### 1. Get User Profile

**Endpoint:** `GET /api/users/profile/:user_id`

**Description:** Retrieve complete user profile information including personal details, address, financial info, and KYC status.

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Success Response (200 OK):**
```json
{
  "success": true,
  "profile": {
    "id": 1,
    "username": "john_doe",
    "account_created_at": "2025-01-15T10:30:00.000Z",
    "last_login": "2025-01-20T14:25:00.000Z",
    "is_active": true,
    "biometric_enabled": false,
    "personal_info": {
      "first_name": "John",
      "last_name": "Doe",
      "full_legal_name": "John Doe",
      "email": "john.doe@example.com",
      "phone_number": "+1234567890",
      "date_of_birth": "1990-05-15",
      "profile_picture_url": "https://example.com/profile.jpg"
    },
    "address": {
      "address": "123 Main Street",
      "city": "Mumbai",
      "state": "Maharashtra",
      "zip_code": "400001",
      "country": "India"
    },
    "financial_info": {
      "account_number": "ACC123456789",
      "routing_number": "RTN987654321",
      "account_balance": 50000.00,
      "currency": "INR"
    },
    "kyc_info": {
      "kyc_status": "verified",
      "kyc_verified_at": "2025-01-18T12:00:00.000Z",
      "pan_number": "ABCDE1234F",
      "aadhar_number": "123456789012"
    },
    "timestamps": {
      "created_at": "2025-01-15T10:30:00.000Z",
      "updated_at": "2025-01-20T14:25:00.000Z"
    }
  }
}
```

**Error Responses:**
- `404 Not Found`: User not found
  ```json
  {
    "success": false,
    "error": "User not found"
  }
  ```
- `500 Internal Server Error`: Server error
  ```json
  {
    "success": false,
    "error": "Failed to fetch user profile"
  }
  ```

---

### 2. Update User Profile

**Endpoint:** `PUT /api/users/profile/:user_id`

**Description:** Update user profile information. All fields are optional - only send the fields you want to update.

**URL Parameters:**
- `user_id` (required): Integer - The user's ID

**Request Body (all fields optional):**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "full_legal_name": "John Doe",
  "email": "john.doe@example.com",
  "phone_number": "+1234567890",
  "date_of_birth": "1990-05-15",
  "address": "123 Main Street",
  "city": "Mumbai",
  "state": "Maharashtra",
  "zip_code": "400001",
  "country": "India",
  "profile_picture_url": "https://example.com/profile.jpg",
  "pan_number": "ABCDE1234F",
  "aadhar_number": "123456789012"
}
```

**Validation Rules:**
- `email`: Must be a valid email format
- `phone_number`: Must be a valid phone number format
- `date_of_birth`: Must be in ISO 8601 format (YYYY-MM-DD)
- `pan_number`: Must match format: 5 letters, 4 digits, 1 letter (e.g., ABCDE1234F)
- `aadhar_number`: Must be exactly 12 digits

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "profile": {
    "id": 1,
    "username": "john_doe",
    "account_created_at": "2025-01-15T10:30:00.000Z",
    "last_login": "2025-01-20T14:25:00.000Z",
    "is_active": true,
    "biometric_enabled": false,
    "personal_info": {
      "first_name": "John",
      "last_name": "Doe",
      "full_legal_name": "John Doe",
      "email": "john.doe@example.com",
      "phone_number": "+1234567890",
      "date_of_birth": "1990-05-15",
      "profile_picture_url": "https://example.com/profile.jpg"
    },
    "address": {
      "address": "123 Main Street",
      "city": "Mumbai",
      "state": "Maharashtra",
      "zip_code": "400001",
      "country": "India"
    },
    "financial_info": {
      "account_number": "ACC123456789",
      "routing_number": "RTN987654321",
      "account_balance": 50000.00,
      "currency": "INR"
    },
    "kyc_info": {
      "kyc_status": "verified",
      "kyc_verified_at": "2025-01-18T12:00:00.000Z",
      "pan_number": "ABCDE1234F",
      "aadhar_number": "123456789012"
    },
    "timestamps": {
      "created_at": "2025-01-15T10:30:00.000Z",
      "updated_at": "2025-01-20T15:30:00.000Z"
    }
  }
}
```

**Error Responses:**
- `400 Bad Request`: Validation errors
  ```json
  {
    "errors": [
      {
        "param": "email",
        "msg": "Please provide a valid email"
      }
    ]
  }
  ```
- `400 Bad Request`: Email/PAN/Aadhar already in use
  ```json
  {
    "error": "Email already in use"
  }
  ```
- `404 Not Found`: User not found
  ```json
  {
    "success": false,
    "error": "User not found"
  }
  ```
- `500 Internal Server Error`: Server error
  ```json
  {
    "success": false,
    "error": "Failed to update user profile"
  }
  ```

---

## 📱 Flutter Integration Guide

### 1. Setup

Add the `http` package to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.0
```

### 2. Create Profile Service

Create a new file `lib/services/profile_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  // Base URL - adjust based on your environment
  static const String baseUrl = 'http://localhost:3001/api/users';
  // For Android Emulator: 'http://10.0.2.2:3001/api/users'
  // For iOS Simulator: 'http://localhost:3001/api/users'
  // For physical device: 'http://YOUR_IP:3001/api/users'

  // Get stored user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'profile': data['profile'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'profile': data['profile'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to update profile',
          'errors': error['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
```

### 3. Create Profile Model

Create a new file `lib/models/profile_model.dart`:

```dart
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
      biometricEnabled: json['biometric_enabled'],
      personalInfo: PersonalInfo.fromJson(json['personal_info']),
      address: Address.fromJson(json['address']),
      financialInfo: FinancialInfo.fromJson(json['financial_info']),
      kycInfo: KYCInfo.fromJson(json['kyc_info']),
      timestamps: Timestamps.fromJson(json['timestamps']),
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
      accountBalance: (json['account_balance'] as num).toDouble(),
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
```

### 4. Usage Example

```dart
import 'package:flutter/material.dart';
import 'services/profile_service.dart';
import 'models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? profile;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await ProfileService.getProfile(widget.userId);

    setState(() {
      isLoading = false;
      if (result['success']) {
        profile = UserProfile.fromJson(result['profile']);
      } else {
        error = result['error'];
      }
    });
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await ProfileService.updateProfile(widget.userId, data);

    setState(() {
      isLoading = false;
      if (result['success']) {
        profile = UserProfile.fromJson(result['profile']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        error = result['error'];
        if (result['errors'] != null) {
          // Handle validation errors
          for (var err in result['errors']) {
            print('${err['param']}: ${err['msg']}');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              ElevatedButton(
                onPressed: loadProfile,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('No profile data')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${profile!.personalInfo.fullLegalName ?? "N/A"}'),
            Text('Email: ${profile!.personalInfo.email ?? "N/A"}'),
            Text('Phone: ${profile!.personalInfo.phoneNumber ?? "N/A"}'),
            Text('Balance: ₹${profile!.financialInfo.accountBalance}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                updateProfile({
                  'first_name': 'Updated',
                  'last_name': 'Name',
                });
              },
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing with cURL

### Get Profile
```bash
curl -X GET http://localhost:3001/api/users/profile/1
```

### Update Profile
```bash
curl -X PUT http://localhost:3001/api/users/profile/1 \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone_number": "+1234567890",
    "city": "Mumbai",
    "state": "Maharashtra"
  }'
```

---

## 📝 Notes

1. **All fields in update request are optional** - only send the fields you want to update
2. **Email, PAN, and Aadhar are unique** - cannot be used by multiple users
3. **Account balance and financial info** are read-only through this endpoint (use balance endpoint for updates)
4. **Date format**: Use ISO 8601 format (YYYY-MM-DD) for dates
5. **Response structure**: Profile is organized into logical sections (personal_info, address, financial_info, kyc_info)

---

## 🔒 Security Considerations

- Always validate user input on the frontend before sending requests
- Store user credentials securely using `SharedPreferences` or secure storage
- Implement proper error handling for network failures
- Consider adding authentication tokens for production use

