# Flutter Integration Guide

## Setup

### 1. Add HTTP Package

Add the `http` package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2 # For storing auth tokens/user data
```

Run:

```bash
flutter pub get
```

---

## 2. Create API Service Class

Create a file `lib/services/api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ IMPORTANT: Change baseUrl based on where you're running the app!
  //
  // For Android Emulator: http://10.0.2.2:3001
  // For iOS Simulator: http://localhost:3001
  // For Physical Device: http://[YOUR_COMPUTER_IP]:3001
  //
  // To find your IP: Mac/Linux: ifconfig | grep "inet "
  //                   Windows: ipconfig
  //
  static const String baseUrl = 'http://10.0.2.2:3001'; // ⚠️ Change this!

  // Common configurations (uncomment the one you need):
  // static const String baseUrl = 'http://localhost:3001';        // iOS Simulator
  // static const String baseUrl = 'http://10.0.2.2:3001';         // Android Emulator ✅
  // static const String baseUrl = 'http://192.168.1.100:3001';    // Physical Device (change IP!)

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper method for GET requests
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for POST requests
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PUT requests
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PATCH requests
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else {
      throw ApiException(
        message: responseBody['error'] ?? 'An error occurred',
        statusCode: statusCode,
        errors: responseBody['errors'],
      );
    }
  }
}

// Custom Exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}
```

---

## 3. Create Auth Service

Create a file `lib/services/auth_service.dart`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _userIdKey = 'user_id';

  // Register User
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? dateOfBirth,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/register', {
        'username': username,
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      });

      // Save user ID locally
      if (response['user_id'] != null) {
        await _saveUserId(response['user_id']);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/login', {
        'username': username,
        'password': password,
      });

      // Save user data locally
      if (response['user'] != null) {
        await _saveUserData(response['user']);
        await _saveUserId(response['user']['id']);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        return jsonDecode(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null;
  }

  // Save user data
  static Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Save user ID
  static Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }
}
```

---

## 4. Create Onboarding Service

Create a file `lib/services/onboarding_service.dart`:

```dart
import 'api_service.dart';

class OnboardingService {
  // Save Personal Details (Screen 1)
  static Future<Map<String, dynamic>> savePersonalDetails({
    required int userId,
    required String fullLegalName,
    required String email,
    required String dateOfBirth, // Format: YYYY-MM-DD
  }) async {
    try {
      final response = await ApiService.post(
        '/api/onboarding/personal-details',
        {
          'user_id': userId,
          'full_legal_name': fullLegalName,
          'email': email,
          'date_of_birth': dateOfBirth,
        },
      );
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }

  // Save KYC Details (Screen 2)
  static Future<Map<String, dynamic>> saveKycDetails({
    required int userId,
    required String panNumber, // Format: ABCDE1234F
    required String aadharNumber, // Format: 12 digits
  }) async {
    try {
      final response = await ApiService.post(
        '/api/onboarding/kyc-details',
        {
          'user_id': userId,
          'pan_number': panNumber.toUpperCase(), // Ensure uppercase
          'aadhar_number': aadharNumber,
        },
      );
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }

  // Get Onboarding Status
  static Future<Map<String, dynamic>> getOnboardingStatus(int userId) async {
    try {
      final response = await ApiService.get('/api/onboarding/status/$userId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Complete Onboarding
  static Future<Map<String, dynamic>> completeOnboarding(int userId) async {
    try {
      final response = await ApiService.post(
        '/api/onboarding/complete/$userId',
        {},
      );
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }
}
```

---

## 5. Create User Service

Create a file `lib/services/user_service.dart`:

```dart
import 'api_service.dart';

class UserService {
  // Get user by ID
  static Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final response = await ApiService.get('/api/users/$userId');
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }

  // Get all users
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await ApiService.get('/api/users');
      return response['users'];
    } catch (e) {
      rethrow;
    }
  }

  // Update user
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (zipCode != null) body['zip_code'] = zipCode;
      if (country != null) body['country'] = country;

      final response = await ApiService.put('/api/users/$userId', body);
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }

  // Update account balance
  static Future<Map<String, dynamic>> updateBalance({
    required int userId,
    required double amount,
    required String operation, // 'add', 'subtract', or 'set'
  }) async {
    try {
      final response = await ApiService.patch(
        '/api/users/$userId/balance',
        {
          'amount': amount,
          'operation': operation,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
```

---

## 6. Usage Examples

### Register User

```dart
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/onboarding_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.register(
        username: _usernameController.text,
        password: _passwordController.text,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful! Account: ${response['account_number']}'),
        ),
      );

      // Navigate to login or home screen
      Navigator.pushReplacementNamed(context, '/login');
    } on ApiException catch (e) {
      // Handle API errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            // Add other form fields...
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Login User

```dart
Future<void> _login() async {
  setState(() => _isLoading = true);

  try {
    final response = await AuthService.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    // Navigate to home screen
    Navigator.pushReplacementNamed(context, '/home');
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Get User Profile

```dart
Future<void> _loadUserProfile() async {
  try {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final user = await UserService.getUser(userId);
      // Use user data
      print('User: ${user['first_name']} ${user['last_name']}');
      print('Balance: \$${user['account_balance']}');
    }
  } catch (e) {
    print('Error loading profile: $e');
  }
}
```

### Save Personal Details (Onboarding Screen 1)

```dart
Future<void> _savePersonalDetails() async {
  setState(() => _isLoading = true);

  try {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final user = await OnboardingService.savePersonalDetails(
      userId: userId,
      fullLegalName: _fullNameController.text,
      email: _emailController.text,
      dateOfBirth: _dateOfBirthController.text, // Format: YYYY-MM-DD
    );

    // Navigate to next screen
    Navigator.pushNamed(context, '/kyc-details');
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Save KYC Details (Onboarding Screen 2)

```dart
Future<void> _saveKycDetails() async {
  setState(() => _isLoading = true);

  try {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final user = await OnboardingService.saveKycDetails(
      userId: userId,
      panNumber: _panController.text,
      aadharNumber: _aadharController.text,
    );

    // Complete onboarding
    await OnboardingService.completeOnboarding(userId);

    // Navigate to home screen
    Navigator.pushReplacementNamed(context, '/home');
  } on ApiException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Check Onboarding Status

```dart
Future<void> _checkOnboardingStatus() async {
  try {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final status = await OnboardingService.getOnboardingStatus(userId);

      if (!status['personal_details_completed']) {
        // Navigate to personal details screen
        Navigator.pushNamed(context, '/personal-details');
      } else if (!status['kyc_details_completed']) {
        // Navigate to KYC details screen
        Navigator.pushNamed(context, '/kyc-details');
      } else {
        // Onboarding complete, go to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  } catch (e) {
    print('Error checking onboarding status: $e');
  }
}
```

### Update Balance

```dart
Future<void> _addBalance(double amount) async {
  try {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final response = await UserService.updateBalance(
        userId: userId,
        amount: amount,
        operation: 'add',
      );

      print('Previous balance: ${response['previous_balance']}');
      print('New balance: ${response['new_balance']}');
    }
  } catch (e) {
    print('Error updating balance: $e');
  }
}
```

---

## 7. Network Configuration

### For Android Emulator:

```dart
static const String baseUrl = 'http://10.0.2.2:3001';
```

### For iOS Simulator:

```dart
static const String baseUrl = 'http://localhost:3001';
```

### For Physical Device:

1. Find your computer's IP address:

   - Mac/Linux: `ifconfig | grep "inet "`
   - Windows: `ipconfig`

2. Update base URL:

```dart
static const String baseUrl = 'http://192.168.1.100:3001'; // Your IP
```

3. Make sure your phone and computer are on the same WiFi network

### Android Network Security Config

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

Or create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">192.168.1.100</domain>
    </domain-config>
</network-security-config>
```

Then reference it in `AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

### iOS Info.plist (for HTTP)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 8. Error Handling Best Practices

```dart
try {
  final response = await AuthService.login(
    username: username,
    password: password,
  );
} on ApiException catch (e) {
  if (e.statusCode == 401) {
    // Handle authentication error
    showError('Invalid credentials');
  } else if (e.statusCode == 400) {
    // Handle validation errors
    if (e.errors != null) {
      for (var error in e.errors!) {
        showError(error['msg']);
      }
    } else {
      showError(e.message);
    }
  } else {
    // Handle other errors
    showError('An error occurred: ${e.message}');
  }
} catch (e) {
  // Handle network errors
  showError('Network error: Please check your connection');
}
```

---

## 9. Testing Connection

Create a simple test widget:

```dart
class ConnectionTest extends StatelessWidget {
  Future<void> testConnection() async {
    try {
      final response = await ApiService.get('/health');
      print('Connection successful: ${response['message']}');
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: testConnection,
      child: Text('Test Connection'),
    );
  }
}
```

---

## Quick Start Checklist

- [ ] Add `http` and `shared_preferences` packages
- [ ] Create `api_service.dart`
- [ ] Create `auth_service.dart`
- [ ] Create `onboarding_service.dart`
- [ ] Create `user_service.dart`
- [ ] Configure base URL for your environment
- [ ] Set up Android network security config (if needed)
- [ ] Set up iOS Info.plist (if needed)
- [ ] Test connection with health check endpoint
- [ ] Implement register/login screens
- [ ] Implement onboarding screens (personal details & KYC)
- [ ] Test API calls

---

## Support

For issues or questions:

1. Check API documentation for endpoint details
2. Verify base URL is correct for your environment
3. Check network connectivity
4. Review error messages in API responses
