import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<PaintOpsNotification> _notificationController = 
      StreamController<PaintOpsNotification>.broadcast();

  Stream<PaintOpsNotification> get notificationStream => _notificationController.stream;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kIsWeb) {
        // Web-specific notification setup
        await _initializeWebNotifications();
      } else {
        // Mobile-specific notification setup
        await _initializeMobileNotifications();
      }
      
      _isInitialized = true;
      if (kDebugMode) {
        print('Notification service initialized successfully for ${kIsWeb ? 'web' : 'mobile'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
    }
  }

  Future<void> _initializeWebNotifications() async {
    // Web notification setup using browser APIs
    if (kDebugMode) {
      print('Initializing web notifications...');
    }
    
    try {
      // In a real implementation, this would use the browser's Notification API
      // For now, we'll just set up a basic structure
      if (kDebugMode) {
        print('Web notifications ready (placeholder implementation)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Web notification initialization error: $e');
      }
    }
  }

  Future<void> _initializeMobileNotifications() async {
    // Mobile notification setup
    // This would use Firebase Cloud Messaging in production
    if (kDebugMode) {
      print('Initializing mobile notifications...');
    }
    
    try {
      // In a real implementation, this would initialize FCM
      if (kDebugMode) {
        print('Mobile notifications ready (placeholder implementation)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Mobile notification initialization error: $e');
      }
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) {
        // Request web notification permissions
        return await _requestWebNotificationPermissions();
      } else {
        // Request mobile notification permissions
        return await _requestMobileNotificationPermissions();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting notification permissions: $e');
      }
      return false;
    }
  }

  Future<bool> _requestWebNotificationPermissions() async {
    // Web permission request
    try {
      if (kDebugMode) {
        print('Requesting web notification permissions...');
      }
      
      // In a real implementation, this would use:
      // final permission = await html.Notification.requestPermission();
      // return permission == 'granted';
      
      return true; // Placeholder
    } catch (e) {
      if (kDebugMode) {
        print('Web permission request error: $e');
      }
      return false;
    }
  }

  Future<bool> _requestMobileNotificationPermissions() async {
    // Mobile permission request
    try {
      if (kDebugMode) {
        print('Requesting mobile notification permissions...');
      }
      
      // In a real implementation, this would use FCM permission request
      return true; // Placeholder
    } catch (e) {
      if (kDebugMode) {
        print('Mobile permission request error: $e');
      }
      return false;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = PaintOpsNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        timestamp: DateTime.now(),
        type: NotificationType.local,
      );

      _notificationController.add(notification);

      if (kIsWeb) {
        await _showWebNotification(notification);
      } else {
        await _showMobileNotification(notification);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
    }
  }

  Future<void> _showWebNotification(PaintOpsNotification notification) async {
    try {
      if (kDebugMode) {
        print('Web notification: ${notification.title} - ${notification.body}');
      }
      
      // In a real web implementation, this would create a browser notification:
      // html.Notification(notification.title, body: notification.body);
      
      // For now, we'll simulate the notification being shown
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (kDebugMode) {
        print('Error showing web notification: $e');
      }
    }
  }

  Future<void> _showMobileNotification(PaintOpsNotification notification) async {
    try {
      if (kDebugMode) {
        print('Mobile notification: ${notification.title} - ${notification.body}');
      }
      
      // In a real mobile implementation, this would use local notifications
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (kDebugMode) {
        print('Error showing mobile notification: $e');
      }
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = PaintOpsNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        timestamp: scheduledTime,
        type: NotificationType.scheduled,
      );

      // Calculate delay
      final delay = scheduledTime.difference(DateTime.now());
      
      if (delay.isNegative) {
        // Show immediately if scheduled time is in the past
        await showLocalNotification(
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
        );
      } else {
        // Schedule for future
        if (kDebugMode) {
          print('Scheduling notification for ${scheduledTime.toIso8601String()}');
        }
        
        Timer(delay, () async {
          await showLocalNotification(
            title: title,
            body: body,
            imageUrl: imageUrl,
            data: data,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  Future<void> notifyNewLead(String leadName, String projectType) async {
    final title = kIsWeb ? 'New Lead Received!' : 'New Lead 📧';
    final body = kIsWeb 
        ? '$leadName submitted a quote request for $projectType'
        : '$leadName - $projectType request';
    
    await showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'new_lead',
        'leadName': leadName,
        'projectType': projectType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> notifyTimesheetApprovalNeeded(String workerName, String projectName) async {
    final title = kIsWeb ? 'Timesheet Approval Required' : 'Approval Needed ⏰';
    final body = kIsWeb
        ? '$workerName submitted timesheet for $projectName'
        : '$workerName - $projectName timesheet';
    
    await showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'timesheet_approval',
        'workerName': workerName,
        'projectName': projectName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> notifyExpenseApprovalNeeded(String submitterName, double amount) async {
    final title = kIsWeb ? 'Expense Approval Required' : 'Expense Approval 💰';
    final body = kIsWeb
        ? '$submitterName submitted expense for \$${amount.toStringAsFixed(2)}'
        : '$submitterName - \$${amount.toStringAsFixed(2)}';
    
    await showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'expense_approval',
        'submitterName': submitterName,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> notifyProjectDeadline(String projectName, int daysRemaining) async {
    String title;
    String body;
    
    if (kIsWeb) {
      title = 'Project Deadline Alert';
      if (daysRemaining <= 0) {
        body = '$projectName deadline has passed';
      } else if (daysRemaining == 1) {
        body = '$projectName is due tomorrow';
      } else {
        body = '$projectName is due in $daysRemaining days';
      }
    } else {
      title = daysRemaining <= 0 ? 'Overdue! ⚠️' : 'Deadline Alert 📅';
      if (daysRemaining <= 0) {
        body = '$projectName is overdue';
      } else if (daysRemaining == 1) {
        body = '$projectName due tomorrow';
      } else {
        body = '$projectName due in $daysRemaining days';
      }
    }

    await showLocalNotification(
      title: title,
      body: body,
      data: {
        'type': 'project_deadline',
        'projectName': projectName,
        'daysRemaining': daysRemaining,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Platform-specific notification management
  Future<void> clearAllNotifications() async {
    try {
      if (kIsWeb) {
        await _clearWebNotifications();
      } else {
        await _clearMobileNotifications();
      }
      
      if (kDebugMode) {
        print('All notifications cleared for ${kIsWeb ? 'web' : 'mobile'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
    }
  }

  Future<void> _clearWebNotifications() async {
    // Clear web notifications
    // In a real implementation, this would clear browser notifications
    if (kDebugMode) {
      print('Clearing web notifications...');
    }
  }

  Future<void> _clearMobileNotifications() async {
    // Clear mobile notifications
    // In a real implementation, this would clear system tray notifications
    if (kDebugMode) {
      print('Clearing mobile notifications...');
    }
  }

  // Enhanced notification features for different platforms
  Future<void> showRichNotification({
    required String title,
    required String body,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kIsWeb) {
        // Web rich notifications with actions
        await _showWebRichNotification(title, body, imageUrl, actions, data);
      } else {
        // Mobile rich notifications
        await _showMobileRichNotification(title, body, imageUrl, actions, data);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing rich notification: $e');
      }
    }
  }

  Future<void> _showWebRichNotification(
    String title,
    String body,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
  ) async {
    if (kDebugMode) {
      print('Web rich notification: $title');
      if (actions != null) {
        print('Actions: ${actions.map((a) => a.title).join(', ')}');
      }
    }
  }

  Future<void> _showMobileRichNotification(
    String title,
    String body,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
  ) async {
    if (kDebugMode) {
      print('Mobile rich notification: $title');
      if (actions != null) {
        print('Actions: ${actions.map((a) => a.title).join(', ')}');
      }
    }
  }

  void dispose() {
    _notificationController.close();
  }
}

class PaintOpsNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final NotificationType type;

  PaintOpsNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'platform': kIsWeb ? 'web' : 'mobile',
    };
  }

  factory PaintOpsNotification.fromJson(Map<String, dynamic> json) {
    return PaintOpsNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.local,
      ),
    );
  }
}

class NotificationAction {
  final String id;
  final String title;
  final String? icon;

  NotificationAction({
    required this.id,
    required this.title,
    this.icon,
  });
}

enum NotificationType {
  local,
  push,
  scheduled,
  system,
}
