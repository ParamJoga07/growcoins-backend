import '../models/onboarding_model.dart';
import 'api_service.dart';
import 'backend_auth_service.dart';
import 'user_service.dart';

class OnboardingService {
  // Check if user already has personal details filled (name, email, date of birth)
  static Future<bool> hasPersonalDetails() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return false;
      }

      final user = await UserService.getUser(userId);
      // User data can be in 'user_data' field or directly in user object
      final userData = user['user_data'] ?? user;
      
      // Check if all required personal details are present
      final firstName = userData['first_name'];
      final lastName = userData['last_name'];
      final email = userData['email'];
      final dateOfBirth = userData['date_of_birth'];
      
      final hasName = firstName != null && 
                      firstName.toString().trim().isNotEmpty &&
                      lastName != null && 
                      lastName.toString().trim().isNotEmpty;
      final hasEmail = email != null && 
                       email.toString().trim().isNotEmpty;
      final hasDateOfBirth = dateOfBirth != null && 
                            dateOfBirth.toString().trim().isNotEmpty;
      
      return hasName && hasEmail && hasDateOfBirth;
    } catch (e) {
      print('Error checking personal details: $e');
      return false;
    }
  }
  
  // Get personal details from user profile to pre-fill onboarding
  static Future<OnboardingData?> getPersonalDetailsFromProfile() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final user = await UserService.getUser(userId);
      // User data can be in 'user_data' field or directly in user object
      final userData = user['user_data'] ?? user;
      
      final data = OnboardingData();
      
      // Combine first and last name
      final firstName = userData['first_name'] ?? '';
      final lastName = userData['last_name'] ?? '';
      data.fullName = '$firstName $lastName'.trim();
      
      data.email = userData['email'] ?? '';
      
      // Parse date of birth
      if (userData['date_of_birth'] != null) {
        try {
          final dobStr = userData['date_of_birth'].toString();
          // Handle both ISO format and YYYY-MM-DD format
          if (dobStr.contains('T')) {
            data.dateOfBirth = DateTime.parse(dobStr);
          } else {
            // YYYY-MM-DD format
            final parts = dobStr.split('-');
            if (parts.length == 3) {
              data.dateOfBirth = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            }
          }
        } catch (e) {
          print('Error parsing date of birth: $e');
        }
      }
      
      return data;
    } catch (e) {
      print('Error getting personal details from profile: $e');
      return null;
    }
  }
  // Save onboarding data to backend
  Future<Map<String, dynamic>> saveOnboardingData({
    required OnboardingData data,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Parse fullName into first and last name
      String? firstName;
      String? lastName;
      if (data.fullName != null && data.fullName!.isNotEmpty) {
        final nameParts = data.fullName!.trim().split(' ');
        firstName = nameParts.first;
        lastName = nameParts.length > 1 
            ? nameParts.sublist(1).join(' ') 
            : '';
      }

      // Format date of birth
      String? dateOfBirthStr;
      if (data.dateOfBirth != null) {
        dateOfBirthStr = data.dateOfBirth!.toIso8601String().split('T').first;
      }

      // Update user profile with onboarding data
      await UserService.updateUser(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: data.email,
        dateOfBirth: dateOfBirthStr,
      );

      return {
        'success': true,
        'message': 'Onboarding data saved successfully',
        'user_id': userId,
      };
    } on ApiException catch (e) {
      print('Error saving onboarding data: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error saving onboarding data: $e');
      throw Exception('Failed to save onboarding data: $e');
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return false;
      }

      final user = await UserService.getUser(userId);
      
      // Check if required fields are filled
      return user['first_name'] != null &&
          user['last_name'] != null &&
          user['email'] != null;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  // Get user's onboarding data
  Future<OnboardingData?> getOnboardingData() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final user = await UserService.getUser(userId);
      
      final data = OnboardingData();
      data.fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
      data.email = user['email'];
      
      if (user['date_of_birth'] != null) {
        try {
          data.dateOfBirth = DateTime.parse(user['date_of_birth']);
        } catch (e) {
          print('Error parsing date of birth: $e');
        }
      }
      
      return data;
    } catch (e) {
      print('Error fetching onboarding data: $e');
      return null;
    }
  }

  // Check if user already has KYC details filled (PAN and Aadhar)
  static Future<bool> hasKycDetails() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return false;
      }

      final user = await UserService.getUser(userId);
      // User data can be in 'user_data' field or directly in user object
      final userData = user['user_data'] ?? user;
      
      // Check if both PAN and Aadhar are present
      final panNumber = userData['pan_number'];
      final aadharNumber = userData['aadhar_number'];
      
      final hasPan = panNumber != null && 
                     panNumber.toString().trim().isNotEmpty;
      final hasAadhar = aadharNumber != null && 
                        aadharNumber.toString().trim().isNotEmpty;
      
      return hasPan && hasAadhar;
    } catch (e) {
      print('Error checking KYC details: $e');
      return false;
    }
  }

  // Save KYC Details to backend
  static Future<Map<String, dynamic>> saveKycDetails({
    required String panNumber,
    required String aadharNumber,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.post(
        '/api/onboarding/kyc-details',
        {
          'user_id': userId,
          'pan_number': panNumber.toUpperCase().trim(),
          'aadhar_number': aadharNumber.trim(),
        },
      );

      return response;
    } on ApiException catch (e) {
      print('Error saving KYC details: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error saving KYC details: $e');
      throw Exception('Failed to save KYC details: $e');
    }
  }
}


