import '../models/goal_models.dart';
import 'api_service.dart' show ApiService, ApiException;
import 'backend_auth_service.dart';

class GoalService {
  // Get Setup Status
  static Future<SetupStatus> getSetupStatus() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.get('/api/goals/setup-status/$userId');

      return SetupStatus.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting setup status: $e');
    }
  }

  // Get Goal Categories
  static Future<List<GoalCategory>> getCategories() async {
    try {
      final response = await ApiService.get('/api/goals/categories');

      if (response['categories'] != null) {
        return (response['categories'] as List)
            .map((c) => GoalCategory.fromJson(c))
            .toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting categories: $e');
    }
  }

  // Get User Goals
  static Future<GoalsResponse> getUserGoals({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      String endpoint = '/api/goals/user/$userId?limit=$limit&offset=$offset';
      if (status != null) {
        endpoint += '&status=$status';
      }

      final response = await ApiService.get(endpoint);

      // Check if response has goals array
      if (response['goals'] == null) {
        // Return empty goals if no goals found (not an error)
        return GoalsResponse(
          goals: [],
          total: 0,
          limit: limit,
          offset: offset,
        );
      }

      return GoalsResponse.fromJson(response);
    } on ApiException catch (e) {
      // Provide more detailed error message
      if (e.statusCode == 404) {
        throw Exception('User not found. Please log in again.');
      } else if (e.statusCode == 500) {
        throw Exception('Server error: ${e.message}. Please check backend logs.');
      } else {
        throw Exception('Failed to get user goals: ${e.message}');
      }
    } catch (e) {
      String errorMessage = e.toString();
      
      // Provide helpful error messages
      if (errorMessage.contains('Route not found') || errorMessage.contains('404')) {
        throw Exception('Goals endpoint not found. Please ensure:\n1. Backend server is running on port 3001\n2. Route /api/goals/user/:user_id is registered\n3. Server has been restarted');
      }
      
      if (errorMessage.contains('Connection refused') || errorMessage.contains('Failed host lookup')) {
        throw Exception('Cannot connect to backend server. Please check:\n1. Server is running\n2. Correct base URL in api_service.dart\n3. Network connection');
      }
      
      throw Exception('Error getting user goals: $e');
    }
  }

  // Create Goal
  static Future<Goal> createGoal(CreateGoalRequest request) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final requestData = request.toJson();
      requestData['user_id'] = userId;

      final response = await ApiService.post('/api/goals', requestData);

      if (response['goal'] != null) {
        return Goal.fromJson(response['goal']);
      }
      throw Exception('Invalid response from server');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error creating goal: $e');
    }
  }

  // Update Goal
  static Future<Goal> updateGoal({
    required int goalId,
    String? goalName,
    double? targetAmount,
    DateTime? targetDate,
    String? status,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (goalName != null) requestData['goal_name'] = goalName;
      if (targetAmount != null) requestData['target_amount'] = targetAmount;
      if (targetDate != null) {
        requestData['target_date'] = targetDate.toIso8601String().split('T')[0];
      }
      if (status != null) requestData['status'] = status;

      final response = await ApiService.put('/api/goals/$goalId', requestData);

      if (response['goal'] != null) {
        return Goal.fromJson(response['goal']);
      }
      throw Exception('Invalid response from server');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error updating goal: $e');
    }
  }

  // Delete Goal
  static Future<void> deleteGoal(int goalId) async {
    try {
      await ApiService.delete('/api/goals/$goalId');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error deleting goal: $e');
    }
  }

  // Get Goal Details
  static Future<Goal> getGoalDetails(int goalId) async {
    try {
      final response = await ApiService.get('/api/goals/$goalId');

      if (response['goal'] != null) {
        return Goal.fromJson(response['goal']);
      }
      throw Exception('Goal not found');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting goal details: $e');
    }
  }
}

