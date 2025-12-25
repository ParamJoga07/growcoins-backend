import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/savings_models.dart';
import 'api_service.dart' show ApiService, ApiException;
import 'backend_auth_service.dart';

class SavingsService {
  // Set Roundoff Amount
  static Future<Map<String, dynamic>> setRoundoffAmount({
    required int roundoffAmount,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.post(
        '/api/savings/roundoff',
        {
          'user_id': userId,
          'roundoff_amount': roundoffAmount,
        },
      );

      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error setting roundoff amount: $e');
    }
  }

  // Upload Bank Statement PDF
  static Future<SavingsUploadResponse> uploadBankStatement({
    required File pdfFile,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Validate file exists
      if (!await pdfFile.exists()) {
        throw Exception('PDF file does not exist');
      }

      // No need to validate file type - file picker is already configured for PDF only
      // Trust the file picker and let the backend validate if needed

      // Create multipart request
      final uri = Uri.parse('${ApiService.baseUrl}/api/savings/upload');
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(ApiService.headers);

      // Add user_id field
      request.fields['user_id'] = userId.toString();

      // Add file with proper content type and filename
      final filePathParts = pdfFile.path.split('/');
      final originalFileName = filePathParts.last;
      // Ensure filename has .pdf extension
      final uploadFileName = originalFileName.toLowerCase().endsWith('.pdf') 
          ? originalFileName 
          : '$originalFileName.pdf';
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'statement',
          pdfFile.path,
          filename: uploadFileName,
          contentType: http.MediaType('application', 'pdf'),
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug: Log upload response
        print('=== Bank Statement Upload Response ===');
        print('Response: $data');
        print('Summary: ${data['summary']}');
        if (data['summary'] != null) {
          print('total_savings in upload response: ${data['summary']['total_savings']} (type: ${data['summary']['total_savings']?.runtimeType})');
        }
        print('=====================================');
        
        final uploadResponse = SavingsUploadResponse.fromJson(data);
        
        // Debug: Log parsed response
        print('=== Parsed Upload Response ===');
        print('Total Savings: ${uploadResponse.summary.totalSavings}');
        print('Transactions Processed: ${uploadResponse.transactionsProcessed}');
        print('==============================');
        
        return uploadResponse;
      } else {
        // Parse error response
        Map<String, dynamic> error;
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to upload statement: ${response.body}');
        }
        
        final errorMessage = error['error'] ?? error['message'] ?? 'Failed to upload statement';
        
        // Pass through the actual backend error message without modification
        throw Exception(errorMessage.toString());
      }
    } catch (e) {
      // Re-throw if it's already an Exception with our custom message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error uploading statement: $e');
    }
  }

  // Get Savings Summary
  static Future<SavingsSummary> getSavingsSummary() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.get('/api/savings/summary/$userId');
      
      // Debug: Log raw response
      print('=== Savings Summary Raw Response ===');
      print('Response type: ${response.runtimeType}');
      print('Response: $response');
      print('total_savings: ${response['total_savings']} (type: ${response['total_savings']?.runtimeType})');
      print('projections: ${response['projections']}');
      if (response['projections'] != null) {
        print('monthly.savings: ${response['projections']['monthly']?['savings']}');
        print('yearly.savings: ${response['projections']['yearly']?['savings']}');
        print('daily.savings: ${response['projections']['daily']?['savings']}');
      }
      print('====================================');

      final summary = SavingsSummary.fromJson(response);
      
      // Debug: Log parsed summary
      print('=== Parsed Savings Summary ===');
      print('Total Savings: ${summary.totalSavings}');
      print('Monthly Projection: ${summary.projections?.monthly.savings}');
      print('Yearly Projection: ${summary.projections?.yearly.savings}');
      print('Daily Projection: ${summary.projections?.daily.savings}');
      print('==============================');

      return summary;
    } catch (e) {
      print('Error getting savings summary: $e');
      rethrow;
    }
  }

  // Get Transactions
  static Future<TransactionsResponse> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.get(
        '/api/savings/transactions/$userId?limit=$limit&offset=$offset',
      );

      return TransactionsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Error getting transactions: $e');
    }
  }

  // Get Insights
  static Future<SavingsInsights> getInsights() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.get('/api/savings/insights/$userId');

      return SavingsInsights.fromJson(response);
    } catch (e) {
      throw Exception('Error getting insights: $e');
    }
  }

  // Get Roundoff Setting
  static Future<RoundoffSetting> getRoundoffSetting() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await ApiService.get('/api/savings/roundoff/$userId');

      if (response['setting'] != null) {
        return RoundoffSetting.fromJson(response['setting']);
      } else {
        // Return default setting
        return RoundoffSetting(
          userId: userId,
          roundoffAmount: 10,
          isActive: true,
        );
      }
    } catch (e) {
      throw Exception('Error getting roundoff setting: $e');
    }
  }

  // Pick PDF File
  static Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        // Validate file exists
        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }
        
        // Since file picker is configured with allowedExtensions: ['pdf'],
        // we trust that the selected file is a PDF
        // No need for additional validation here - validation happens at upload time
        
        return file;
      }
      return null;
    } catch (e) {
      // Check if it's a MissingPluginException
      final errorString = e.toString();
      if (errorString.contains('MissingPluginException')) {
        throw Exception(
          'File picker plugin not initialized. Please stop the app completely and rebuild it (flutter run). Hot reload does not work for native plugins.',
        );
      }
      // Re-throw if it's already an Exception with our custom message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error picking PDF file: $e');
    }
  }
}

