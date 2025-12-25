import 'api_service.dart' show ApiService, ApiException;
import 'backend_auth_service.dart';

class ProfileService {
  // Get User Profile
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final response = await ApiService.get('/api/users/profile/$userId');

      if (response['success'] == true) {
        return {
          'success': true,
          'profile': response['profile'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to fetch profile',
        };
      }
    } on ApiException catch (e) {
      // Handle 404 specifically
      if (e.statusCode == 404) {
        return {
          'success': false,
          'error': 'Profile not found. Please ensure the backend server is running and the route is registered.',
        };
      }
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      String errorMessage = e.toString();
      
      // Provide helpful error messages
      if (errorMessage.contains('Route not found') || errorMessage.contains('404')) {
        return {
          'success': false,
          'error': 'Profile endpoint not found. Please ensure:\n1. Backend server is running on port 3001\n2. Route /api/users/profile/:id is registered\n3. Server has been restarted after adding the route',
        };
      }
      
      if (errorMessage.contains('Connection refused') || errorMessage.contains('Failed host lookup')) {
        return {
          'success': false,
          'error': 'Cannot connect to backend server. Please check:\n1. Server is running\n2. Correct base URL in api_service.dart\n3. Network connection',
        };
      }
      
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get Current User Profile
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      return await getProfile(userId);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting user ID: ${e.toString()}',
      };
    }
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      // Remove null values from the update data
      profileData.removeWhere((key, value) => value == null || value == '');

      final response = await ApiService.put(
        '/api/users/profile/$userId',
        profileData,
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['message'] ?? 'Profile updated successfully',
          'profile': response['profile'],
        };
      } else {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to update profile',
          'errors': response['errors'],
        };
      }
    } on ApiException catch (e) {
      return {
        'success': false,
        'error': e.message,
        'errors': e.errors,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update Current User Profile
  static Future<Map<String, dynamic>> updateCurrentUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not logged in',
        };
      }

      return await updateProfile(userId, profileData);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error getting user ID: ${e.toString()}',
      };
    }
  }
}

