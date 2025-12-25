import 'api_service.dart';

class UserService {
  // Get user by ID
  static Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final response = await ApiService.get('/api/users/$userId');
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }

  // Get all users
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await ApiService.get('/api/users');
      return response['users'];
    } catch (e) {
      rethrow;
    }
  }

  // Update user
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (zipCode != null) body['zip_code'] = zipCode;
      if (country != null) body['country'] = country;

      final response = await ApiService.put('/api/users/$userId', body);
      return response['user'];
    } catch (e) {
      rethrow;
    }
  }

  // Update account balance
  static Future<Map<String, dynamic>> updateBalance({
    required int userId,
    required double amount,
    required String operation, // 'add', 'subtract', or 'set'
  }) async {
    try {
      final response = await ApiService.patch(
        '/api/users/$userId/balance',
        {
          'amount': amount,
          'operation': operation,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

