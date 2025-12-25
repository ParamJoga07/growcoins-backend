# KYC Details API - Quick Start Guide

## ✅ API is Ready!

The KYC Details API is working and tested. Here's everything you need:

---

## 📡 API Endpoint

```
POST /api/onboarding/kyc-details
```

**Full URL Examples:**
- Android: `http://10.0.2.2:3001/api/onboarding/kyc-details`
- iOS: `http://localhost:3001/api/onboarding/kyc-details`
- Physical Device: `http://[YOUR_IP]:3001/api/onboarding/kyc-details`

---

## 📤 Request

```json
{
  "user_id": 1,
  "pan_number": "ABCDE1234F",
  "aadhar_number": "123456789012"
}
```

**Required Fields:**
- `user_id` - Get this from login/registration
- `pan_number` - Format: ABCDE1234F (10 chars)
- `aadhar_number` - Format: 123456789012 (12 digits)

---

## 📥 Response

**Success (200):**
```json
{
  "message": "KYC details saved successfully",
  "user": { /* full user object */ },
  "kyc_status": "submitted"
}
```

**Error (400):**
```json
{
  "error": "PAN number already in use"
}
// OR
{
  "errors": [
    {"msg": "Invalid PAN number format", "param": "pan_number"}
  ]
}
```

---

## 💻 Flutter Code (Copy & Paste)

### 1. Service Method (Already in OnboardingService)

```dart
static Future<Map<String, dynamic>> saveKycDetails({
  required int userId,
  required String panNumber,
  required String aadharNumber,
}) async {
  final response = await ApiService.post(
    '/api/onboarding/kyc-details',
    {
      'user_id': userId,
      'pan_number': panNumber.toUpperCase().trim(),
      'aadhar_number': aadharNumber.trim(),
    },
  );
  return response['user'];
}
```

### 2. Usage in Your Screen

```dart
// In your Continue button onPressed:
final userId = await AuthService.getUserId();
if (userId == null) {
  showError('Please login first');
  return;
}

try {
  await OnboardingService.saveKycDetails(
    userId: userId,
    panNumber: panController.text,
    aadharNumber: aadharController.text,
  );
  
  // Success - navigate to next screen
  Navigator.pushReplacementNamed(context, '/home');
} catch (e) {
  showError('Failed to save: ${e.toString()}');
}
```

---

## ✅ Validation

**PAN Number:**
- ✅ Format: `ABCDE1234F`
- ✅ 5 letters + 4 digits + 1 letter
- ✅ Auto-uppercase in backend
- ✅ Must be unique

**Aadhar Number:**
- ✅ Format: `123456789012`
- ✅ Exactly 12 digits
- ✅ Must be unique

---

## 🧪 Tested & Working!

The API has been tested and is working correctly. You can now integrate it into your Flutter app.

**See full documentation:**
- `KYC_FRONTEND_INTEGRATION.md` - Complete Flutter integration guide
- `API_DOCUMENTATION.md` - Full API reference
- `FLUTTER_INTEGRATION.md` - General Flutter setup

---

## 🚀 Quick Integration Steps

1. ✅ API is ready (already created)
2. ✅ Database fields added (pan_number, aadhar_number)
3. ✅ Copy Flutter code from `KYC_FRONTEND_INTEGRATION.md`
4. ✅ Update base URL in `api_service.dart`
5. ✅ Test with your Flutter app

---

## 📝 Notes

- User must complete personal details first
- PAN and Aadhar must be unique
- KYC status automatically set to "submitted"
- All validation happens on both client and server

