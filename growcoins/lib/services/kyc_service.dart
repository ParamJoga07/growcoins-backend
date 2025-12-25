import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart' show ApiService, ApiException;
import 'backend_auth_service.dart';

class KycService {
  /// Upload Video KYC
  static Future<Map<String, dynamic>> uploadVideoKyc({
    required String videoPath,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Create multipart request
      final uri = Uri.parse('${ApiService.baseUrl}/api/kyc/video-kyc/upload');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(ApiService.headers);

      // Add user_id field
      request.fields['user_id'] = userId.toString();

      // Add video file
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        throw Exception('Video file does not exist');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoPath,
          filename: 'video_kyc_${DateTime.now().millisecondsSinceEpoch}.mp4',
          contentType: http.MediaType('video', 'mp4'),
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        // Parse error response
        Map<String, dynamic> error;
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to upload video: ${response.body}');
        }

        final errorMessage =
            error['error'] ?? error['message'] ?? 'Failed to upload video';

        throw ApiException(
          message: errorMessage.toString(),
          statusCode: response.statusCode,
          errors: error['errors'],
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw Exception('Error uploading video KYC: $e');
    }
  }

  /// Get Video KYC Status
  static Future<Map<String, dynamic>> getVideoKycStatus(int kycId) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response =
          await ApiService.get('/api/kyc/video-kyc/status/$kycId?user_id=$userId');

      return response;
    } catch (e) {
      throw Exception('Error getting video KYC status: $e');
    }
  }

  /// Get Video KYC Details
  static Future<Map<String, dynamic>> getVideoKycDetails(int kycId) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response =
          await ApiService.get('/api/kyc/video-kyc/$kycId?user_id=$userId');

      return response;
    } catch (e) {
      throw Exception('Error getting video KYC details: $e');
    }
  }

  /// Retry Video KYC (delete previous and allow new upload)
  static Future<void> retryVideoKyc(int kycId) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await ApiService.delete('/api/kyc/video-kyc/$kycId?user_id=$userId');
    } catch (e) {
      throw Exception('Error retrying video KYC: $e');
    }
  }
}

