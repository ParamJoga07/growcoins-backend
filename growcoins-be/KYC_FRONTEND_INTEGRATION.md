# KYC Details - Frontend Integration Guide

## 🎯 Overview

This guide shows how to integrate the KYC Details API into your Flutter app for the "Enter KYC Details" screen.

**Screen Requirements:**
- PAN Number input field
- Aadhar Number input field
- Continue button
- Save data to backend

---

## 📡 API Endpoint

```
POST /api/onboarding/kyc-details
```

**Base URL Examples:**
- Android Emulator: `http://10.0.2.2:3001`
- iOS Simulator: `http://localhost:3001`
- Physical Device: `http://[YOUR_IP]:3001`

---

## 🔧 Step-by-Step Integration

### Step 1: Ensure OnboardingService Exists

Make sure you have `lib/services/onboarding_service.dart` with this method:

```dart
import 'api_service.dart';
import 'api_service.dart' show ApiException;

class OnboardingService {
  // Save KYC Details
  static Future<Map<String, dynamic>> saveKycDetails({
    required int userId,
    required String panNumber,
    required String aadharNumber,
  }) async {
    try {
      final response = await ApiService.post(
        '/api/onboarding/kyc-details',
        {
          'user_id': userId,
          'pan_number': panNumber.toUpperCase().trim(),
          'aadhar_number': aadharNumber.trim(),
        },
      );
      
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }
}
```

### Step 2: Create KYC Details Screen

Create `lib/screens/kyc_details_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/api_service.dart' show ApiException;

class KycDetailsScreen extends StatefulWidget {
  @override
  _KycDetailsScreenState createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _panController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  // Format PAN: ABCDE1234F (10 chars: 5 letters + 4 digits + 1 letter)
  String _formatPan(String value) {
    value = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (value.length > 10) value = value.substring(0, 10);
    return value;
  }

  // Format Aadhar: 12 digits only
  String _formatAadhar(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length > 12) value = value.substring(0, 12);
    return value;
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        _showError('Please login first');
        return;
      }

      final user = await OnboardingService.saveKycDetails(
        userId: userId,
        panNumber: _panController.text,
        aadharNumber: _aadharController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KYC details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to next screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on ApiException catch (e) {
      String errorMsg = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        errorMsg = e.errors!.first['msg'] ?? e.message;
      }
      _showError(errorMsg);
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E3A8A), // Blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Onboarding Personal Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                
                // Wallet Icon
                Container(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                
                SizedBox(height: 30),
                
                // User Profile Card
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Title
                Text(
                  'Enter KYC Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 40),
                
                // PAN Number Field
                TextFormField(
                  controller: _panController,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: _formatPan(newValue.text),
                        selection: newValue.selection,
                      );
                    }),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'PAN number is required';
                    }
                    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
                      return 'Invalid format. Use: ABCDE1234F';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 20),
                
                // Aadhar Number Field
                TextFormField(
                  controller: _aadharController,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Aadhar Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: _formatAadhar(newValue.text),
                        selection: newValue.selection,
                      );
                    }),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Aadhar number is required';
                    }
                    if (value.length != 12) {
                      return 'Aadhar must be 12 digits';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 40),
                
                // Continue Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Step 3: Add Route

In your `main.dart` or routing configuration:

```dart
routes: {
  '/kyc-details': (context) => KycDetailsScreen(),
  // ... other routes
}
```

### Step 4: Navigate to KYC Screen

From your personal details screen:

```dart
Navigator.pushNamed(context, '/kyc-details');
```

---

## 📋 API Request/Response

### Request Example

```json
{
  "user_id": 1,
  "pan_number": "ABCDE1234F",
  "aadhar_number": "123456789012"
}
```

### Success Response

```json
{
  "message": "KYC details saved successfully",
  "user": {
    "id": 1,
    "pan_number": "ABCDE1234F",
    "aadhar_number": "123456789012",
    "kyc_status": "submitted",
    // ... other user fields
  },
  "kyc_status": "submitted"
}
```

### Error Response Examples

**Invalid PAN Format:**
```json
{
  "errors": [
    {
      "msg": "Invalid PAN number format",
      "param": "pan_number"
    }
  ]
}
```

**PAN Already Exists:**
```json
{
  "error": "PAN number already in use"
}
```

**Aadhar Already Exists:**
```json
{
  "error": "Aadhar number already in use"
}
```

---

## ✅ Validation Rules

### PAN Number
- **Format:** `ABCDE1234F`
- **Length:** Exactly 10 characters
- **Pattern:** 5 uppercase letters + 4 digits + 1 uppercase letter
- **Example:** `ABCDE1234F`, `PANAB1234C`
- **Must be unique**

### Aadhar Number
- **Format:** 12 digits
- **Length:** Exactly 12 digits
- **Pattern:** Only numbers (0-9)
- **Example:** `123456789012`
- **Must be unique**

---

## 🧪 Testing

### Test with Valid Data

```dart
// In your Flutter app
final userId = await AuthService.getUserId(); // Get from login
await OnboardingService.saveKycDetails(
  userId: userId!,
  panNumber: 'ABCDE1234F',
  aadharNumber: '123456789012',
);
```

### Test with cURL

```bash
curl -X POST http://localhost:3001/api/onboarding/kyc-details \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "pan_number": "ABCDE1234F",
    "aadhar_number": "123456789012"
  }'
```

---

## 🔍 Error Handling

### Handle Different Error Types

```dart
try {
  await OnboardingService.saveKycDetails(...);
} on ApiException catch (e) {
  if (e.statusCode == 400) {
    if (e.message.contains('PAN number already in use')) {
      // Show specific error for duplicate PAN
      showError('This PAN number is already registered');
    } else if (e.message.contains('Aadhar number already in use')) {
      // Show specific error for duplicate Aadhar
      showError('This Aadhar number is already registered');
    } else if (e.errors != null) {
      // Show validation errors
      for (var error in e.errors!) {
        showError(error['msg']);
      }
    } else {
      showError(e.message);
    }
  } else if (e.statusCode == 404) {
    showError('User not found. Please login again.');
  } else {
    showError('An error occurred: ${e.message}');
  }
} catch (e) {
  showError('Network error: Please check your connection');
}
```

---

## 📱 Complete Flow Example

```dart
// 1. User registers/logs in
final loginResponse = await AuthService.login(
  username: 'johndoe',
  password: 'password123',
);
final userId = loginResponse['user']['id'];

// 2. Save personal details (Screen 1)
await OnboardingService.savePersonalDetails(
  userId: userId,
  fullLegalName: 'John Doe',
  email: 'john@example.com',
  dateOfBirth: '1990-01-15',
);

// 3. Save KYC details (Screen 2 - Current Screen)
await OnboardingService.saveKycDetails(
  userId: userId,
  panNumber: 'ABCDE1234F',
  aadharNumber: '123456789012',
);

// 4. Complete onboarding
await OnboardingService.completeOnboarding(userId);

// 5. Navigate to home
Navigator.pushReplacementNamed(context, '/home');
```

---

## 🎨 UI Styling Tips

Match your design with these colors:
- Background: `Color(0xFF1E3A8A)` (Dark blue)
- Card/Button: `Color(0xFF3B82F6)` (Light blue)
- Text: `Colors.white`
- Input fields: `Colors.white` with rounded corners

---

## ✅ Checklist

Before deploying:
- [ ] PAN input formats correctly (auto-uppercase, 10 chars max)
- [ ] Aadhar input accepts only digits (12 max)
- [ ] Form validation works
- [ ] Loading state shows during API call
- [ ] Error messages display correctly
- [ ] Success navigation works
- [ ] User ID is retrieved correctly
- [ ] API base URL is correct for your environment
- [ ] Tested with valid data
- [ ] Tested with invalid data
- [ ] Tested duplicate PAN/Aadhar scenarios

---

## 🚀 Quick Start

1. Copy the `KycDetailsScreen` code above
2. Ensure `OnboardingService.saveKycDetails()` exists
3. Add route: `'/kyc-details': (context) => KycDetailsScreen()`
4. Navigate from previous screen: `Navigator.pushNamed(context, '/kyc-details')`
5. Test with valid PAN and Aadhar numbers

---

## 📞 Support

If you encounter issues:
1. Check API base URL is correct
2. Verify user is logged in (has user_id)
3. Check server is running: `curl http://localhost:3001/health`
4. Review error messages in console
5. Test API directly with cURL first

