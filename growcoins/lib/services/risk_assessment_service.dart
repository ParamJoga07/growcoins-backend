import '../models/risk_assessment_model.dart';
import 'api_service.dart';
import 'api_service.dart' show ApiException;
import 'backend_auth_service.dart';

class RiskAssessmentService {
  // Save Risk Assessment
  static Future<Map<String, dynamic>> saveRiskAssessment({
    required List<Map<String, dynamic>> answers,
    required int totalScore,
    required String riskProfile,
    String? recommendation,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login first.');
      }

      // Prepare answers in the correct format
      final formattedAnswers = answers.map((answer) => {
        'questionId': answer['questionId'],
        'optionId': answer['optionId'],
        'answerText': answer['answerText'],
        'score': answer['score'],
      }).toList();

      final response = await ApiService.post(
        '/api/risk-assessment',
        {
          'user_id': userId,
          'answers': formattedAnswers,
          'total_score': totalScore,
          'risk_profile': riskProfile,
          'recommendation': recommendation,
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      return response['assessment'] ?? response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to save risk assessment: ${e.toString()}');
    }
  }

  // Get Assessment History
  static Future<List<Map<String, dynamic>>> getAssessmentHistory({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return [];
      }

      final response = await ApiService.get(
        '/api/risk-assessment/$userId?limit=$limit&offset=$offset',
      );

      return List<Map<String, dynamic>>.from(response['assessments'] ?? []);
    } catch (e) {
      print('Error fetching assessment history: $e');
      return [];
    }
  }

  // Get Latest Assessment
  static Future<Map<String, dynamic>?> getLatestAssessment() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await ApiService.get(
        '/api/risk-assessment/$userId/latest',
      );

      return response['assessment'];
    } catch (e) {
      print('Error fetching latest assessment: $e');
      return null;
    }
  }

  // Get Specific Assessment by ID
  static Future<Map<String, dynamic>?> getAssessmentById(int assessmentId) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await ApiService.get(
        '/api/risk-assessment/$userId/$assessmentId',
      );

      return response['assessment'];
    } catch (e) {
      print('Error fetching assessment: $e');
      return null;
    }
  }

  // Check if user has any assessments
  static Future<bool> hasAssessments() async {
    final latest = await getLatestAssessment();
    return latest != null;
  }

  // Legacy method for backward compatibility
  Future<Map<String, dynamic>> saveRiskAssessmentLegacy({
    required RiskAssessmentResult result,
  }) async {
    final answers = result.answers.map((a) => a.toJson()).toList();
    return await saveRiskAssessment(
      answers: answers,
      totalScore: result.totalScore,
      riskProfile: result.riskProfile,
      recommendation: result.recommendation,
    );
  }

  // Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getRiskAssessmentHistory() async {
    return await getAssessmentHistory();
  }

  // Legacy method for backward compatibility
  Future<Map<String, dynamic>?> getLatestRiskAssessment() async {
    return await getLatestAssessment();
  }
}

