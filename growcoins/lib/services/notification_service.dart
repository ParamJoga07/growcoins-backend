import 'api_service.dart' show ApiService, ApiException;
import 'backend_auth_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  // Get all notifications for current user
  static Future<NotificationsResponse> getNotifications({
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      String endpoint = '/api/notifications/user/$userId?limit=$limit&offset=$offset';
      if (isRead != null) {
        endpoint += '&is_read=${isRead ? 'true' : 'false'}';
      }

      final response = await ApiService.get(endpoint);

      return NotificationsResponse.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting notifications: $e');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        return 0;
      }

      final response = await ApiService.get('/api/notifications/user/$userId/unread-count');

      return response['unread_count'] ?? 0;
    } catch (e) {
      // Return 0 on error to prevent UI issues
      return 0;
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.put('/api/notifications/$notificationId/read', {});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await ApiService.put('/api/notifications/user/$userId/read-all', {});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      await ApiService.delete('/api/notifications/$notificationId');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      final userId = await BackendAuthService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      await ApiService.delete('/api/notifications/user/$userId');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Error deleting all notifications: $e');
    }
  }
}

