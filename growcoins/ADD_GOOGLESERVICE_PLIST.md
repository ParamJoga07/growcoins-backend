# Quick Fix: Add GoogleService-Info.plist to Xcode

## The Problem
Firebase can't find `GoogleService-Info.plist` because it's not added to the Xcode project.

## Solution (2 minutes)

### Step 1: Xcode is now open
The workspace should be open. If not, run:
```bash
open ios/Runner.xcworkspace
```

### Step 2: Add the file to Xcode
1. In the **Project Navigator** (left sidebar), find the **Runner** folder (blue icon)
2. **Right-click** on the **Runner** folder
3. Select **"Add Files to Runner..."**
4. Navigate to: `ios/Runner/GoogleService-Info.plist`
5. **IMPORTANT:** In the dialog that appears:
   - ✅ **UNCHECK** "Copy items if needed" (file is already in the right place)
   - ✅ **CHECK** "Add to targets: Runner"
6. Click **"Add"**

### Step 3: Verify
- The file should now appear in the Project Navigator under `Runner`
- Select the file and check the **File Inspector** (right sidebar)
- Under **Target Membership**, make sure **Runner** is checked ✅

### Step 4: Rebuild
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Alternative: If you can't add it via Xcode

If for some reason you can't add it via Xcode, you can manually edit the project file, but this is more complex and error-prone. The Xcode method above is recommended.

## After Adding
Once the file is added, Firebase should initialize correctly and you'll see the phone login screen!

