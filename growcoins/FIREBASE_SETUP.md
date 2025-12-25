# Firebase Setup Guide

## Step 1: Install Dependencies

Run the following command in your terminal:

```bash
cd growcoins
flutter pub get
```

## Step 2: Firebase Configuration

### For iOS:

1. Download `GoogleService-Info.plist` from your Firebase Console
2. Place it in: `ios/Runner/GoogleService-Info.plist`
3. Open Xcode and add the file to your project (if not automatically added)

### For Android:

1. Download `google-services.json` from your Firebase Console
2. Place it in: `android/app/google-services.json`

## Step 3: Enable Firebase Phone Authentication

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Phone" as a sign-in provider
3. Add your app's SHA-1 fingerprint (for Android) in Firebase Console

## Step 4: Uncomment Firebase Initialization

In `lib/main.dart`, uncomment the line:

```dart
await Firebase.initializeApp();
```

## Step 5: iOS Configuration

The Face ID permission has already been added to `Info.plist`. Make sure your app's bundle identifier matches the one in Firebase Console.

## Step 6: Run the App

```bash
flutter run
```

## Testing

- Use a real device or simulator with phone number capability for testing OTP
- For iOS, test Face ID/Touch ID on a real device (simulators don't support biometrics)

