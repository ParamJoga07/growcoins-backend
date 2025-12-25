import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL Configuration
  // For physical devices, replace with your computer's IP address
  // Find your IP: Mac/Linux: ifconfig | grep "inet " | grep -v 127.0.0.1
  //              Windows: ipconfig (look for IPv4 Address)
  // 
  // Your detected IP: 192.168.0.4
  // For physical device, uncomment and update the line below:
  // static const String _customBaseUrl = 'http://192.168.0.4:3001';
  static const String _customBaseUrl = ''; // Set this for physical devices
  
  // Get base URL based on platform
  static String get baseUrl {
    // If custom URL is set, use it (for physical devices)
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    
    // Auto-detect based on platform
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:3001';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:3001';
    } else {
      // Default fallback
      return 'http://localhost:3001';
    }
  }
  
  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Helper method for GET requests
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: _getConnectionErrorMessage(),
        statusCode: 0,
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for POST requests
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: _getConnectionErrorMessage(),
        statusCode: 0,
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PUT requests
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: _getConnectionErrorMessage(),
        statusCode: 0,
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PATCH requests
  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: _getConnectionErrorMessage(),
        statusCode: 0,
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for DELETE requests
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: _getConnectionErrorMessage(),
        statusCode: 0,
      );
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get helpful error message for connection issues
  static String _getConnectionErrorMessage() {
    return '''Cannot connect to backend server.

Current URL: $baseUrl

Troubleshooting:
1. Make sure your backend server is running on port 3001
2. If using a physical device, update _customBaseUrl in api_service.dart with your computer's IP address
   Example: static const String _customBaseUrl = 'http://192.168.0.4:3001';
3. Ensure your device and computer are on the same WiFi network
4. Check firewall settings on your computer

To find your IP address:
- Mac/Linux: ifconfig | grep "inet " | grep -v 127.0.0.1
- Windows: ipconfig (look for IPv4 Address)''';
  }

  // Handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    // Handle empty responses
    if (response.body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        return {};
      } else {
        throw ApiException(
          message: 'Empty response from server',
          statusCode: statusCode,
        );
      }
    }
    
    try {
      final responseBody = jsonDecode(response.body);
      
      if (statusCode >= 200 && statusCode < 300) {
        return responseBody;
      } else {
        throw ApiException(
          message: responseBody['error'] ?? 'An error occurred',
          statusCode: statusCode,
          errors: responseBody['errors'],
        );
      }
    } catch (e) {
      // If JSON decode fails, provide helpful error
      if (e is FormatException) {
        throw ApiException(
          message: 'Invalid JSON response from server. Status: $statusCode',
          statusCode: statusCode,
        );
      }
      rethrow;
    }
  }
}

// Custom Exception class
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

