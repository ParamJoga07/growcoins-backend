# KYC Details API - Frontend Integration Guide

## 📋 API Endpoint

**POST** `/api/onboarding/kyc-details`

Save KYC (Know Your Customer) details including PAN Number and Aadhar Number.

---

## 🔌 API Details

### Request

**URL:** `POST http://[BASE_URL]/api/onboarding/kyc-details`

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "user_id": 1,
  "pan_number": "ABCDE1234F",
  "aadhar_number": "123456789012"
}
```

### Request Parameters

| Field | Type | Required | Format | Description |
|-------|------|----------|--------|-------------|
| `user_id` | integer | ✅ Yes | - | User ID from registration/login |
| `pan_number` | string | ✅ Yes | `ABCDE1234F` | PAN number (5 letters + 4 digits + 1 letter) |
| `aadhar_number` | string | ✅ Yes | `123456789012` | Aadhar number (12 digits) |

### Validation Rules

- **PAN Number:**
  - Must be exactly 10 characters
  - Format: 5 uppercase letters + 4 digits + 1 uppercase letter
  - Example: `ABCDE1234F`
  - Must be unique (not used by another user)

- **Aadhar Number:**
  - Must be exactly 12 digits
  - Example: `123456789012`
  - Must be unique (not used by another user)

### Success Response (200 OK)

```json
{
  "message": "KYC details saved successfully",
  "user": {
    "id": 1,
    "user_id": 1,
    "username": "johndoe",
    "full_legal_name": "John Doe",
    "email": "john@example.com",
    "pan_number": "ABCDE1234F",
    "aadhar_number": "123456789012",
    "kyc_status": "submitted",
    "account_number": "GC1734890123456",
    "account_balance": "0.00",
    // ... other user fields
  },
  "kyc_status": "submitted"
}
```

### Error Responses

#### 400 Bad Request - Validation Error
```json
{
  "errors": [
    {
      "msg": "Invalid PAN number format",
      "param": "pan_number",
      "location": "body"
    }
  ]
}
```

#### 400 Bad Request - PAN Already Exists
```json
{
  "error": "PAN number already in use"
}
```

#### 400 Bad Request - Aadhar Already Exists
```json
{
  "error": "Aadhar number already in use"
}
```

#### 400 Bad Request - Personal Details Not Completed
```json
{
  "error": "Please complete personal details first"
}
```

#### 404 Not Found
```json
{
  "error": "User not found"
}
```

#### 500 Internal Server Error
```json
{
  "error": "Failed to save KYC details"
}
```

---

## 📱 Flutter Integration

### Step 1: Add to OnboardingService

If you haven't already, add this method to `lib/services/onboarding_service.dart`:

```dart
import 'api_service.dart';

class OnboardingService {
  // Save KYC Details
  static Future<Map<String, dynamic>> saveKycDetails({
    required int userId,
    required String panNumber,
    required String aadharNumber,
  }) async {
    try {
      // Validate PAN format (optional client-side validation)
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(panNumber.toUpperCase())) {
        throw Exception('Invalid PAN number format. Format: ABCDE1234F');
      }
      
      // Validate Aadhar format (optional client-side validation)
      if (!RegExp(r'^[0-9]{12}$').hasMatch(aadharNumber)) {
        throw Exception('Aadhar number must be exactly 12 digits');
      }
      
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
}
```

### Step 2: Create KYC Details Screen

Create `lib/screens/kyc_details_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/api_service.dart';

class KycDetailsScreen extends StatefulWidget {
  @override
  _KycDetailsScreenState createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePan = true;
  bool _obscureAadhar = true;

  @override
  void dispose() {
    _panController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  // PAN Number formatter (ABCDE1234F)
  String _formatPanNumber(String value) {
    // Remove all non-alphanumeric characters
    value = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    
    // Limit to 10 characters
    if (value.length > 10) {
      value = value.substring(0, 10);
    }
    
    return value;
  }

  // Aadhar Number formatter (12 digits)
  String _formatAadharNumber(String value) {
    // Remove all non-digit characters
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 12 digits
    if (value.length > 12) {
      value = value.substring(0, 12);
    }
    
    return value;
  }

  Future<void> _saveKycDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user ID
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login first.');
      }

      // Save KYC details
      final user = await OnboardingService.saveKycDetails(
        userId: userId,
        panNumber: _panController.text.trim(),
        aadharNumber: _aadharController.text.trim(),
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KYC details saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to next screen (e.g., home or onboarding complete)
        Navigator.pushReplacementNamed(context, '/home');
        // Or: Navigator.pushReplacementNamed(context, '/onboarding-complete');
      }
    } on ApiException catch (e) {
      // Handle API errors
      if (mounted) {
        String errorMessage = e.message;
        
        // Show validation errors if available
        if (e.errors != null && e.errors!.isNotEmpty) {
          errorMessage = e.errors!.first['msg'] ?? e.message;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
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
                // Icon/Logo
                Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(top: 20, bottom: 40),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 40,
                      color: Colors.blue[900],
                    ),
                  ),
                ),

                // Title
                Text(
                  'Enter KYC Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),

                // PAN Number Field
                TextFormField(
                  controller: _panController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'PAN Number',
                    hintText: 'ABCDE1234F',
                    prefixIcon: Icon(Icons.badge, color: Colors.blue[900]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorStyle: TextStyle(color: Colors.yellow[300]),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: _formatPanNumber(newValue.text),
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
                      return 'Invalid PAN format. Use: ABCDE1234F';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Aadhar Number Field
                TextFormField(
                  controller: _aadharController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Aadhar Number',
                    hintText: '123456789012',
                    prefixIcon: Icon(Icons.credit_card, color: Colors.blue[900]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorStyle: TextStyle(color: Colors.yellow[300]),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: _formatAadharNumber(newValue.text),
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
                      return 'Aadhar number must be 12 digits';
                    }
                    if (!RegExp(r'^[0-9]{12}$').hasMatch(value)) {
                      return 'Aadhar number must contain only digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),

                // Continue Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveKycDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

### Step 3: Update Routes

Add the route in your `main.dart` or routing file:

```dart
routes: {
  '/kyc-details': (context) => KycDetailsScreen(),
  // ... other routes
}
```

### Step 4: Navigate to KYC Screen

From your personal details screen or onboarding flow:

```dart
Navigator.pushNamed(context, '/kyc-details');
// Or
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => KycDetailsScreen()),
);
```

---

## 🧪 Testing

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

### Test in Flutter

1. Make sure user is logged in (has `user_id`)
2. Fill in PAN and Aadhar fields
3. Tap "Continue" button
4. Check for success message
5. Verify data is saved by checking user profile

---

## ✅ Complete Onboarding Flow

After saving KYC details, you can complete the onboarding:

```dart
// After saving KYC details successfully
final userId = await AuthService.getUserId();
if (userId != null) {
  await OnboardingService.completeOnboarding(userId);
  Navigator.pushReplacementNamed(context, '/home');
}
```

---

## 🔍 Error Handling Examples

### Handle PAN Already Exists

```dart
try {
  await OnboardingService.saveKycDetails(...);
} on ApiException catch (e) {
  if (e.message.contains('PAN number already in use')) {
    // Show specific error for PAN
    showError('This PAN number is already registered');
  } else {
    showError(e.message);
  }
}
```

### Handle Validation Errors

```dart
try {
  await OnboardingService.saveKycDetails(...);
} on ApiException catch (e) {
  if (e.errors != null) {
    // Show first validation error
    for (var error in e.errors!) {
      showError(error['msg']);
      break;
    }
  } else {
    showError(e.message);
  }
}
```

---

## 📝 Notes

1. **PAN Format**: Always convert to uppercase before sending
2. **Aadhar Format**: Must be exactly 12 digits, no spaces or dashes
3. **User ID**: Must be obtained from login/registration first
4. **Personal Details**: Must be completed before KYC details
5. **Validation**: Both client-side and server-side validation are performed
6. **KYC Status**: Automatically set to "submitted" after saving

---

## 🚀 Quick Integration Checklist

- [ ] Add `saveKycDetails` method to `OnboardingService`
- [ ] Create `KycDetailsScreen` widget
- [ ] Add form validation for PAN and Aadhar
- [ ] Add input formatters for proper formatting
- [ ] Handle API errors gracefully
- [ ] Show loading state during API call
- [ ] Navigate to next screen on success
- [ ] Test with valid and invalid data
- [ ] Test error scenarios (duplicate PAN/Aadhar)

