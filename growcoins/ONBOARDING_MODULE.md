# Onboarding Module Documentation

## 📋 Overview

The Onboarding module guides new users through a series of screens to collect personal details, KYC information, and financial preferences. This data is saved to the backend database.

## 🔄 Complete Flow

After successful login, users are automatically taken through:

1. **Personal Details Screen** → Full Name, Email, Date of Birth
2. **KYC Screen** → PAN Number, Aadhar Number
3. **Financial Info Screen 1** → Monthly Income Range, Savings Management
4. **Financial Info Screen 2** → Monthly Savings Percentage, Spending Category
5. **Setup Profile Screen** → Upload Bank Statement (optional) → Complete
6. **Home Screen** → User lands here after completing onboarding

## 📱 Screens Created

### 1. OnboardingPersonalDetailsScreen
- **Fields:**
  - Full Legal Name (required)
  - Email ID (required, validated)
  - Date of Birth (required, date picker)
- **Design:** Dark blue gradient background
- **Navigation:** Next → KYC Screen

### 2. OnboardingKYCScreen
- **Fields:**
  - PAN Number (required, 10 characters, uppercase)
  - Aadhar Number (required, 12 digits)
- **Design:** Medium blue background
- **Navigation:** Continue → Financial Info Screen 1

### 3. OnboardingFinancialInfoScreen (2 sets)
- **Question Set 1:**
  - What is your current monthly income range?
    - Below ₹25,000
    - ₹25,001 - ₹50,000
    - ₹50,001 - ₹75,000
    - Above ₹75,001
  - How do you manage your savings currently?
    - Regular Savings Account
    - Fixed Deposit
    - Investment In Mutual Funds
    - Not Actively Saving
- **Question Set 2:**
  - How much of your monthly income do you save?
    - Less than 10%
    - 10% - 20%
    - 21% - 30%
    - More than 30%
  - Which categories do you spend the most on each month?
    - Essential Expenses Only
    - Essential Expenses & Some Discretionary Spending
    - Balanced Spending Of Essentials & Discretionary Items
    - Heavy Discretionary Spending With Minimal Savings
- **Design:** White background with progress indicators
- **Navigation:** Next → Next Screen / Submit → Setup Profile

### 4. OnboardingSetupProfileScreen
- **Features:**
  - Welcome banner
  - Upload Bank Statement (PDF, JPG, PNG) - Optional
  - Skip or Continue buttons
- **Design:** White background with curved blue bottom section
- **Navigation:** Skip/Continue → Home Screen (saves data)

## 📊 Data Structure

### OnboardingData Model

```dart
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "dateOfBirth": "1990-01-01T00:00:00Z",
  "panNumber": "ABCDE1234F",
  "aadharNumber": "123456789012",
  "monthlyIncomeRange": "₹25,001 - ₹50,000",
  "savingsManagement": "Regular Savings Account",
  "monthlySavingsPercentage": "10% - 20%",
  "spendingCategory": "Essential Expenses Only",
  "bankStatementPath": "/path/to/file.pdf",
  "completedAt": "2024-12-22T10:30:00Z"
}
```

## 🔌 Backend API Integration

### Save Onboarding Data

**Endpoint:** `POST /api/onboarding`

**Request Body:**
```json
{
  "userId": "user_id_here",
  "fullName": "John Doe",
  "email": "john@example.com",
  "dateOfBirth": "1990-01-01T00:00:00Z",
  "panNumber": "ABCDE1234F",
  "aadharNumber": "123456789012",
  "monthlyIncomeRange": "₹25,001 - ₹50,000",
  "savingsManagement": "Regular Savings Account",
  "monthlySavingsPercentage": "10% - 20%",
  "spendingCategory": "Essential Expenses Only",
  "bankStatementPath": "/path/to/file.pdf",
  "completedAt": "2024-12-22T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Onboarding data saved successfully"
}
```

## ⚙️ Configuration

### Update Backend URL

Edit `lib/services/onboarding_service.dart`:

```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

### Add Authentication Token

If your API requires authentication:

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $yourToken',
},
```

## 🔐 Onboarding Completion Tracking

- Onboarding completion status is stored locally using `SharedPreferences`
- Key: `onboarding_completed`
- Set to `true` after successful completion
- Checked automatically after login to determine if onboarding should be shown

## 🎯 Features

✅ Automatic flow after login  
✅ Form validation on all screens  
✅ Date picker for DOB  
✅ PAN/Aadhar number validation  
✅ Radio button selection for financial questions  
✅ File picker for bank statement upload  
✅ Progress indicators  
✅ Skip option for bank statement  
✅ Data persistence across navigation  
✅ Backend API integration  
✅ Completion tracking  

## 📝 Validation Rules

- **Full Name:** Required, non-empty
- **Email:** Required, must contain '@'
- **Date of Birth:** Required, must be selected
- **PAN Number:** Required, exactly 10 characters
- **Aadhar Number:** Required, exactly 12 digits
- **Financial Questions:** All must be answered before proceeding
- **Bank Statement:** Optional (can skip)

## 🚀 How It Works

1. **User logs in** → Firebase authentication successful
2. **AuthWrapper checks** → Is onboarding completed?
3. **If NO** → Show `OnboardingPersonalDetailsScreen`
4. **User completes all screens** → Data saved to backend
5. **Onboarding marked complete** → `setOnboardingCompleted(true)`
6. **Navigate to Home Screen** → User can now use the app

## 🔄 Re-running Onboarding

To allow users to re-run onboarding (for testing or updates):

```dart
// Reset onboarding status
await _authStateService.setOnboardingCompleted(false);
```

## 📦 Dependencies Added

- `http: ^1.2.2` - For API calls
- `file_picker: ^8.1.4` - For bank statement upload
- `intl: ^0.19.0` - For date formatting

## 🎨 UI Design

- **Personal Details & KYC:** Blue gradient backgrounds with white input fields
- **Financial Info:** Clean white background with radio button options
- **Setup Profile:** White background with curved blue bottom section
- **Consistent:** All screens have blue app bar and consistent styling

## ✅ Testing Checklist

- [ ] Login with phone number
- [ ] Complete personal details screen
- [ ] Complete KYC screen
- [ ] Answer financial questions (both sets)
- [ ] Upload bank statement (or skip)
- [ ] Verify data is saved to backend
- [ ] Verify onboarding completion status
- [ ] Logout and login again → Should go directly to Home Screen

## 🐛 Troubleshooting

### Onboarding shows every time
- Check if `setOnboardingCompleted(true)` is being called
- Verify SharedPreferences is working

### Data not saving
- Check backend URL in `onboarding_service.dart`
- Verify API endpoint is correct
- Check authentication tokens if required

### File upload not working
- Ensure file_picker permissions are granted
- Check file size limits
- Verify file types are supported

## 📍 Entry Point

**Automatic:** After successful login, if onboarding is not completed, users are automatically taken to the onboarding flow.

**Manual:** You can also start onboarding from anywhere:

```dart
import 'screens/onboarding/onboarding_personal_details_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const OnboardingPersonalDetailsScreen(),
  ),
);
```

