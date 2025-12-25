# Phone Number Format Guide

## 📱 Format Required

Your phone number **MUST** include the country code with a `+` sign.

### Format:
```
+[Country Code][Phone Number]
```

## ✅ Examples of Valid Phone Numbers

### United States:
```
+1234567890
+15551234567
```

### India:
```
+919876543210
+911234567890
```

### United Kingdom:
```
+447911123456
+442071234567
```

### Canada:
```
+14161234567
+15141234567
```

## 🧪 Using Test Phone Numbers (Recommended for Development)

Instead of using real phone numbers (which cost SMS credits), you can set up **test phone numbers** in Firebase Console:

### Steps to Add Test Numbers:

1. Go to **Firebase Console** → **Authentication** → **Sign-in method**
2. Click on **Phone** provider
3. Scroll down to **"Phone numbers for testing"** section
4. Click **"Add phone number"**
5. Enter:
   - **Phone number**: `+1234567890` (any number you want)
   - **Verification code**: `123456` (the code you'll enter)
6. Click **Save**

### Using Test Numbers:

- Enter the test phone number exactly as you added it (e.g., `+1234567890`)
- When prompted for OTP, enter the test code you set (e.g., `123456`)
- **No SMS will be sent** - it's instant!

## 📝 Important Notes

### For Real Phone Numbers:
- ✅ Must start with `+` and country code
- ✅ No spaces or dashes (e.g., `+1234567890`, NOT `+1 234-567-8900`)
- ✅ Must be a valid, active phone number
- ⚠️ Will send a real SMS (costs Firebase credits)
- ⚠️ You'll receive a real verification code via SMS

### For Testing:
- ✅ Use test phone numbers (free, instant)
- ✅ No SMS charges
- ✅ Works immediately

## 🎯 Recommended: Start with Test Numbers

1. **Add a test number in Firebase Console:**
   - Phone: `+1234567890`
   - Code: `123456`

2. **In the app, enter:** `+1234567890`

3. **When OTP screen appears, enter:** `123456`

4. **You'll be logged in instantly!**

## ❌ Common Mistakes

- ❌ `1234567890` (missing `+` and country code)
- ❌ `+1 234-567-8900` (has spaces/dashes)
- ❌ `1234-567-8900` (wrong format)
- ✅ `+1234567890` (correct!)

## 🔍 How to Find Your Country Code

- **US/Canada**: `+1`
- **UK**: `+44`
- **India**: `+91`
- **Australia**: `+61`
- **Germany**: `+49`
- **France**: `+33`

Or search: "country code for [your country]"

## 💡 Quick Test Setup

**Fastest way to test:**

1. Firebase Console → Authentication → Sign-in method → Phone
2. Add test number: `+1234567890` with code `123456`
3. In app: Enter `+1234567890`
4. Enter OTP: `123456`
5. Done! ✅

