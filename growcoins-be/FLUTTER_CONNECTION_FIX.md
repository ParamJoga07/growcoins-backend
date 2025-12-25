# Flutter Connection Fix Guide

## ❌ Error You're Seeing

```
Connection refused (OS Error: Connection refused, errno = 111), 
address = localhost, port = 40656, 
uri=http://localhost:3001/api/auth/register
```

## ✅ Solution: Fix Base URL Based on Your Environment

### Step 1: Update `api_service.dart`

Open `lib/services/api_service.dart` and update the `baseUrl`:

```dart
class ApiService {
  // ⚠️ IMPORTANT: Change this based on where you're running the app!
  
  // For Android Emulator - USE THIS:
  static const String baseUrl = 'http://10.0.2.2:3001';
  
  // For iOS Simulator - USE THIS:
  // static const String baseUrl = 'http://localhost:3001';
  
  // For Physical Device - USE YOUR COMPUTER'S IP:
  // static const String baseUrl = 'http://192.168.1.100:3001'; // Replace with your IP
  
  // ... rest of the code
}
```

### Step 2: Find Your Computer's IP Address

**On Mac/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**On Windows:**
```bash
ipconfig
```
Look for IPv4 Address (usually something like `192.168.1.xxx`)

### Step 3: Choose the Correct Base URL

| Environment | Base URL | Notes |
|------------|----------|-------|
| **Android Emulator** | `http://10.0.2.2:3001` | ✅ Use this for Android |
| **iOS Simulator** | `http://localhost:3001` | ✅ Use this for iOS |
| **Physical Device** | `http://[YOUR_IP]:3001` | ✅ Use your computer's IP |
| **Physical Device (Same WiFi)** | `http://192.168.x.x:3001` | Make sure phone and computer are on same WiFi |

### Step 4: Make Base URL Dynamic (Recommended)

Create a better solution that auto-detects:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  // Auto-detect the correct base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001';
    }
    
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine
      return 'http://10.0.2.2:3001';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:3001';
    }
    
    // Default fallback
    return 'http://localhost:3001';
  }
  
  // For physical devices, you'll need to manually set this
  // Or use a config file/environment variable
  static const String physicalDeviceUrl = 'http://192.168.1.100:3001'; // Change this!
  
  // Use this method to get the correct URL
  static String getBaseUrl({bool usePhysicalDevice = false}) {
    if (usePhysicalDevice) {
      return physicalDeviceUrl;
    }
    return baseUrl;
  }
  
  // Update all methods to use getBaseUrl()
  static Future<Map<String, dynamic>> get(String endpoint, {bool usePhysicalDevice = false}) async {
    try {
      final response = await http.get(
        Uri.parse('${getBaseUrl(usePhysicalDevice: usePhysicalDevice)}$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // ... update post, put, patch methods similarly
}
```

## 🔧 Quick Fix for Your Current Issue

**If you're using Android Emulator:**

1. Open `lib/services/api_service.dart`
2. Find this line:
   ```dart
   static const String baseUrl = 'http://localhost:3001';
   ```
3. Change it to:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3001';
   ```
4. Hot restart your Flutter app (not just hot reload)

**If you're using a Physical Device:**

1. Find your computer's IP address (see Step 2 above)
2. Update baseUrl to:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:3001'; // Use your actual IP
   ```
3. Make sure your phone and computer are on the **same WiFi network**
4. Hot restart your Flutter app

## ✅ Verify Server is Running

Test if your server is accessible:

```bash
# From your computer terminal
curl http://localhost:3001/health

# Should return:
# {"status":"OK","message":"Server is running and database is connected",...}
```

## 🧪 Test Connection from Flutter

Add this test method to your `ApiService`:

```dart
static Future<void> testConnection() async {
  try {
    final response = await get('/health');
    print('✅ Connection successful: ${response['message']}');
    return response;
  } catch (e) {
    print('❌ Connection failed: $e');
    print('💡 Make sure:');
    print('   1. Server is running on port 3001');
    print('   2. Base URL is correct for your environment');
    print('   3. For physical device: Use your computer IP, not localhost');
    rethrow;
  }
}
```

Call it in your app:
```dart
// In your initState or button press
await ApiService.testConnection();
```

## 📱 Platform-Specific Notes

### Android Emulator
- ✅ Always use: `http://10.0.2.2:3001`
- `localhost` or `127.0.0.1` will NOT work
- `10.0.2.2` is a special IP that Android emulator uses to access the host machine

### iOS Simulator
- ✅ Can use: `http://localhost:3001`
- ✅ Can also use: `http://127.0.0.1:3001`

### Physical Device (Android/iOS)
- ❌ `localhost` will NOT work
- ❌ `10.0.2.2` will NOT work
- ✅ Must use your computer's actual IP address
- ✅ Must be on same WiFi network
- ✅ Make sure firewall allows connections on port 3001

## 🔥 Common Issues & Solutions

### Issue 1: "Connection refused" on Android Emulator
**Solution:** Change baseUrl to `http://10.0.2.2:3001`

### Issue 2: "Connection refused" on Physical Device
**Solution:** 
1. Use your computer's IP address
2. Ensure same WiFi network
3. Check firewall settings

### Issue 3: "Connection timeout" on Physical Device
**Solution:**
1. Verify server is running: `curl http://localhost:3001/health`
2. Check if IP address is correct
3. Try disabling firewall temporarily to test
4. Ensure phone and computer are on same network

### Issue 4: Works on Emulator but not Physical Device
**Solution:** This is normal! Emulator uses `10.0.2.2`, physical device needs your actual IP.

## 🎯 Recommended Setup

Create a config file `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Development URLs
  static const String androidEmulator = 'http://10.0.2.2:3001';
  static const String iosSimulator = 'http://localhost:3001';
  static const String physicalDevice = 'http://192.168.1.100:3001'; // Change this!
  
  // Production URL (when you deploy)
  static const String production = 'https://api.growcoins.com';
  
  // Get base URL based on environment
  static String getBaseUrl({bool isProduction = false}) {
    if (isProduction) return production;
    
    // You can use environment variables or build flavors
    // For now, manually change this based on where you're testing
    return androidEmulator; // Change to iosSimulator or physicalDevice as needed
  }
}
```

Then in `api_service.dart`:
```dart
import 'config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.getBaseUrl();
  // ... rest of code
}
```

## ✅ Quick Checklist

- [ ] Server is running on port 3001
- [ ] Base URL matches your environment:
  - [ ] Android Emulator: `http://10.0.2.2:3001`
  - [ ] iOS Simulator: `http://localhost:3001`
  - [ ] Physical Device: `http://[YOUR_IP]:3001`
- [ ] Hot restarted app (not just hot reload)
- [ ] For physical device: Same WiFi network
- [ ] Tested with `/health` endpoint first

## 🚀 After Fixing

Once connection works, you should see:
- ✅ Registration successful
- ✅ Login successful
- ✅ API calls working

If you still have issues, check:
1. Server logs for incoming requests
2. Flutter console for detailed error messages
3. Network tab in browser (if testing web)

