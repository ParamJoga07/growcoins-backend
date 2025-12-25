# iOS Firebase Configuration Fix

## Issue
Firebase is not initializing correctly on iOS. The error indicates that `GoogleService-Info.plist` is not being found by the Xcode project.

## Solution

The `GoogleService-Info.plist` file exists in `ios/Runner/` but needs to be properly added to the Xcode project target.

### Steps to Fix:

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   (Note: Open `.xcworkspace`, not `.xcodeproj`)

2. **Add GoogleService-Info.plist to Xcode:**
   - In Xcode, right-click on the `Runner` folder in the Project Navigator
   - Select "Add Files to Runner..."
   - Navigate to `ios/Runner/GoogleService-Info.plist`
   - **IMPORTANT:** Check "Copy items if needed" (uncheck if already checked)
   - Make sure "Add to targets: Runner" is checked
   - Click "Add"

3. **Verify the file is added:**
   - The file should appear in the Project Navigator under `Runner`
   - Select the file and check the "Target Membership" in the File Inspector
   - Make sure "Runner" is checked

4. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

## Alternative: Manual Configuration

If the above doesn't work, you can manually configure Firebase options in code. However, the Xcode method above is the recommended approach.

## Verification

After adding the file to Xcode, Firebase should initialize correctly and you should see the phone login screen instead of the error.

