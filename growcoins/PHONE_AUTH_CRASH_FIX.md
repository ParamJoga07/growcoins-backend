# Fix: Phone Auth Crash on iOS

## The Problem
The app crashes with:
```
FirebaseAuth/PhoneAuthProvider.swift:109: Fatal error: Unexpectedly found nil while implicitly unwrapping an Optional value
```

This happens because Firebase Phone Authentication is not properly configured.

## Required Steps

### 1. Verify GoogleService-Info.plist is Added to Xcode
- Open `ios/Runner.xcworkspace` in Xcode
- Check if `GoogleService-Info.plist` appears in the Project Navigator under `Runner`
- If not, add it (see `ADD_GOOGLESERVICE_PLIST.md`)

### 2. Enable Phone Authentication in Firebase Console
**CRITICAL:** Phone authentication must be enabled in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `growcoin-c21b1`
3. Go to **Authentication** → **Sign-in method**
4. Find **Phone** in the list
5. Click on it and **Enable** it
6. Save the changes

### 3. Verify Bundle Identifier Matches
- In Xcode, check your Bundle Identifier (should be `com.example.growcoins`)
- In Firebase Console → Project Settings → Your apps, verify the iOS app has the same Bundle ID

### 4. Rebuild the App
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Common Issues

### Issue: "Phone provider not enabled"
**Solution:** Enable Phone authentication in Firebase Console (Step 2 above)

### Issue: "Bundle ID mismatch"
**Solution:** Ensure the Bundle ID in Xcode matches the one in Firebase Console

### Issue: "GoogleService-Info.plist not found"
**Solution:** Add the file to Xcode project (Step 1 above)

## Testing
After completing these steps:
1. The app should not crash when clicking "Send OTP"
2. You should receive an SMS with the verification code
3. Enter the code to complete authentication

## Note
- Phone authentication requires a real phone number
- Test numbers can be configured in Firebase Console for development
- Make sure you have SMS credits/quota in Firebase Console

