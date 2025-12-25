class Notification {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  // Helper methods for notification types
  bool get isGoalCreated => type == 'goal_created';
  bool get isGoalProgress => type == 'goal_progress';
  bool get isGoalCompleted => type == 'goal_completed';
  bool get isSavingsUpdate => type == 'savings_update';
  bool get isSystemNotification => type == 'system';

  // Get icon based on type
  String get iconName {
    switch (type) {
      case 'goal_created':
        return 'target';
      case 'goal_progress':
        return 'trending_up';
      case 'goal_completed':
        return 'celebration';
      case 'savings_update':
        return 'savings';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  // Get color based on type
  String get colorHex {
    switch (type) {
      case 'goal_created':
        return '#3B82F6'; // Blue
      case 'goal_progress':
        return '#10B981'; // Green
      case 'goal_completed':
        return '#F59E0B'; // Amber/Gold
      case 'savings_update':
        return '#10B981'; // Green
      case 'system':
        return '#6B7280'; // Gray
      default:
        return '#1E40AF'; // Primary blue
    }
  }
}

class NotificationsResponse {
  final List<Notification> notifications;
  final int total;
  final int unreadCount;
  final int limit;
  final int offset;

  NotificationsResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.limit,
    required this.offset,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      notifications: (json['notifications'] as List? ?? [])
          .map((n) => Notification.fromJson(n))
          .toList(),
      total: json['total'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
    );
  }
}

