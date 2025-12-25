# Backend Integration Guide

## Overview

The app now supports two authentication methods:
1. **Phone OTP Authentication** (Firebase)
2. **Username/Password Authentication** (Backend API)

## Authentication Flow

### Login Selection Screen
- Users are presented with two login options when they first open the app
- They can choose between Phone OTP or Username/Password login

### Phone OTP Flow
- Uses Firebase Authentication
- Same flow as before
- After login, user proceeds to onboarding or home screen

### Username/Password Flow
- Uses your backend API (`/api/auth/login`)
- After successful login, user data is saved locally
- User proceeds to onboarding or home screen based on completion status

## API Configuration

### Base URL Setup

The base URL is configured in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:3001';
```

**Important:** Update this URL based on your environment:

- **Android Emulator**: `http://10.0.2.2:3001`
- **iOS Simulator**: `http://localhost:3001`
- **Physical Device**: `http://YOUR_COMPUTER_IP:3001` (e.g., `http://192.168.1.100:3001`)

### Network Configuration

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Services

### API Service (`lib/services/api_service.dart`)
- Handles all HTTP requests to the backend
- Provides GET, POST, PUT, PATCH methods
- Handles error responses and exceptions

### Backend Auth Service (`lib/services/backend_auth_service.dart`)
- Handles user registration and login
- Manages user session (saves/retrieves user data)
- Tracks authentication type (phone vs backend)

### User Service (`lib/services/user_service.dart`)
- Fetches user profile data
- Updates user information
- Manages account balance

### Onboarding Service (`lib/services/onboarding_service.dart`)
- Saves onboarding data to backend
- Updates user profile with onboarding information
- Checks onboarding completion status

### Risk Assessment Service (`lib/services/risk_assessment_service.dart`)
- Saves risk assessment results to backend
- Fetches risk assessment history
- **Note:** You'll need to create the `/api/risk-assessment` endpoint in your backend

## Screens

### Login Selection Screen (`lib/screens/login_selection_screen.dart`)
- First screen users see
- Two buttons: "Login with Phone OTP" and "Login with Username"
- Link to registration screen

### Backend Login Screen (`lib/screens/backend_login_screen.dart`)
- Username and password input
- Form validation
- Error handling
- Link to registration

### Backend Register Screen (`lib/screens/backend_register_screen.dart`)
- Registration form with all required fields
- Date picker for date of birth
- Password confirmation
- Navigates to onboarding after successful registration

## Data Flow

### Registration Flow
1. User fills registration form
2. Data sent to `/api/auth/register`
3. User ID saved locally
4. User navigated to onboarding

### Login Flow
1. User enters username/password
2. Data sent to `/api/auth/login`
3. User data saved locally
4. Check onboarding status
5. Navigate to onboarding or home screen

### Onboarding Flow
1. User completes onboarding steps
2. Data saved via `OnboardingService.saveOnboardingData()`
3. User profile updated via `/api/users/:id` (PUT)
4. Onboarding marked as completed
5. Navigate to home screen

### Risk Assessment Flow
1. User completes risk assessment
2. Results saved via `RiskAssessmentService.saveRiskAssessment()`
3. **Note:** Requires `/api/risk-assessment` endpoint in backend

## Backend Endpoints Used

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### User Management
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user profile
- `PATCH /api/users/:id/balance` - Update account balance

### Risk Assessment (To be implemented)
- `POST /api/risk-assessment` - Save risk assessment results
- `GET /api/risk-assessment/:userId` - Get risk assessment history

## Error Handling

All API calls use `ApiException` for error handling:
- Validation errors (400) - Shows specific field errors
- Authentication errors (401) - Shows login error message
- Server errors (500) - Shows generic error message

## Testing

### Test Connection
You can test the backend connection using the health check endpoint:
```dart
final response = await ApiService.get('/health');
```

### Test Registration
1. Open app
2. Click "Login with Username"
3. Click "Don't have an account? Register"
4. Fill in registration form
5. Submit

### Test Login
1. Open app
2. Click "Login with Username"
3. Enter username and password
4. Submit

## Next Steps

1. **Update Base URL**: Change the base URL in `api_service.dart` to match your environment
2. **Create Risk Assessment Endpoint**: Implement `/api/risk-assessment` endpoint in your backend
3. **Test on Device**: Test both authentication flows on physical devices
4. **Add Error Handling**: Enhance error messages for better user experience
5. **Add Loading States**: Ensure all API calls show appropriate loading indicators

## Notes

- The app supports both Firebase and backend authentication simultaneously
- User data is stored locally using `SharedPreferences`
- Authentication type is tracked to determine which service to use
- Onboarding completion status is stored locally and checked on app start

