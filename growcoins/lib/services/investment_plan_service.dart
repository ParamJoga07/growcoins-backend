import '../models/investment_plan_model.dart';
import 'api_service.dart';
import 'api_service.dart' show ApiException;
import 'backend_auth_service.dart';

class InvestmentPlanService {
  /// Generate or get investment plan for user based on risk profile
  static Future<InvestmentPlan> generatePlan({
    int? goalId,
    String? frequency,
    double? monthlyAmount,
    int? durationMonths,
  }) async {
    try {
      final userId = await _getUserId();

      final body = <String, dynamic>{'user_id': userId};

      if (goalId != null) body['goal_id'] = goalId;
      if (frequency != null) body['frequency'] = frequency;
      if (monthlyAmount != null) body['monthly_amount'] = monthlyAmount;
      if (durationMonths != null) body['duration_months'] = durationMonths;

      final response = await ApiService.post(
        '/api/investment-plan/generate',
        body,
      );

      if (response['success'] == true) {
        return InvestmentPlan.fromJson(response['plan']);
      } else {
        throw ApiException(
          message: response['error'] ?? 'Failed to generate investment plan',
          statusCode: 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error generating plan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Get existing investment plan for user
  static Future<InvestmentPlan?> getPlan({int? goalId}) async {
    try {
      final userId = await _getUserId();
      final endpoint = goalId != null
          ? '/api/investment-plan/user/$userId?goal_id=$goalId'
          : '/api/investment-plan/user/$userId';

      final response = await ApiService.get(endpoint);

      if (response['success'] == true && response['plan'] != null) {
        return InvestmentPlan.fromJson(response['plan']);
      }
      return null;
    } on ApiException catch (e) {
      if (e.message.contains('not found') || e.message.contains('404')) {
        return null;
      }
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error fetching plan: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Update auto-save configuration
  static Future<InvestmentPlan> updateAutoSave({
    required String frequency,
    double? monthlyAmount,
    int? durationMonths,
    int? goalId,
  }) async {
    try {
      final userId = await _getUserId();

      final body = <String, dynamic>{'user_id': userId, 'frequency': frequency};

      if (monthlyAmount != null) body['monthly_amount'] = monthlyAmount;
      if (durationMonths != null) body['duration_months'] = durationMonths;
      if (goalId != null) body['goal_id'] = goalId;

      final response = await ApiService.put(
        '/api/investment-plan/auto-save',
        body,
      );

      if (response['success'] == true) {
        return InvestmentPlan.fromJson(response['plan']);
      } else {
        throw ApiException(
          message: response['error'] ?? 'Failed to update auto-save',
          statusCode: 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error updating auto-save: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Create payment mandate
  static Future<Map<String, dynamic>> createPaymentMandate({
    required String bankAccountNumber,
    required String ifscCode,
    required String accountHolderName,
    int? goalId,
  }) async {
    try {
      final userId = await _getUserId();

      // Ensure IFSC code is uppercase and properly formatted
      final formattedIfscCode = ifscCode.trim().toUpperCase();

      final response =
          await ApiService.post('/api/investment-plan/payment-mandate', {
            'user_id': userId,
            'bank_account_number': bankAccountNumber.trim(),
            'ifsc_code': formattedIfscCode,
            'account_holder_name': accountHolderName.trim(),
            if (goalId != null) 'goal_id': goalId,
          });

      if (response['success'] == true) {
        return response['mandate'];
      } else {
        throw ApiException(
          message: response['error'] ?? 'Failed to create payment mandate',
          statusCode: 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error creating payment mandate: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Complete investment setup
  static Future<Map<String, dynamic>> completeSetup({
    required int mandateId,
    int? goalId,
  }) async {
    try {
      final userId = await _getUserId();

      final response =
          await ApiService.post('/api/investment-plan/complete-setup', {
            'user_id': userId,
            'mandate_id': mandateId,
            if (goalId != null) 'goal_id': goalId,
          });

      if (response['success'] == true) {
        return response;
      } else {
        throw ApiException(
          message: response['error'] ?? 'Failed to complete setup',
          statusCode: 500,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Error completing setup: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  /// Helper to get user ID
  static Future<int> _getUserId() async {
    final userId = await BackendAuthService.getUserId();
    if (userId == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }
    return userId;
  }
}
