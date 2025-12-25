import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class BackendAuthService {
  static const String _userKey = 'backend_user_data';
  static const String _userIdKey = 'backend_user_id';
  static const String _authTypeKey = 'auth_type'; // 'phone' or 'backend'

  // Register User
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? dateOfBirth,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/register', {
        'username': username,
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      });

      // Save user ID locally
      if (response['user_id'] != null) {
        await _saveUserId(response['user_id']);
        await _setAuthType('backend');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/login', {
        'username': username,
        'password': password,
      });

      // Save user data locally
      if (response['user'] != null) {
        await _saveUserData(response['user']);
        await _saveUserId(response['user']['id']);
        await _setAuthType('backend');
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        return jsonDecode(userJson);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  // Get auth type
  static Future<String?> getAuthType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTypeKey);
    } catch (e) {
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_authTypeKey);
  }

  // Check if user is logged in via backend
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    final authType = await getAuthType();
    return userId != null && authType == 'backend';
  }

  // Save user data
  static Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Save user ID
  static Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  // Set auth type
  static Future<void> _setAuthType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTypeKey, type);
  }

  // Get biometric preference from backend
  // Returns null if preference was never set (404 or other error)
  // Returns bool if preference exists (true or false)
  static Future<bool?> getBiometricPreference(int userId) async {
    try {
      final response = await ApiService.get('/api/auth/biometric/$userId');
      return response['biometric_enabled'] ?? false;
    } on ApiException catch (e) {
      // If 404, user preference was never set
      if (e.statusCode == 404) {
        print('Biometric preference not found for user $userId (never set)');
        return null;
      }
      // For other errors, return null to indicate unknown state
      print('Error getting biometric preference: ${e.message}');
      return null;
    } catch (e) {
      // For other errors, return null
      print('Unexpected error getting biometric preference: $e');
      return null;
    }
  }

  // Set biometric preference in backend
  static Future<void> setBiometricPreference({
    required int userId,
    required bool enabled,
  }) async {
    try {
      await ApiService.put('/api/auth/biometric/$userId', {
        'biometric_enabled': enabled,
      });
    } catch (e) {
      // Log error but don't throw - biometric preference is not critical
      print('Error setting biometric preference: $e');
    }
  }
}

