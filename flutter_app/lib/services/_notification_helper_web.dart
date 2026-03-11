// Web-specific notification implementation using the browser Notification API.
// Only compiled on web via conditional import in notification_service.dart.
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Requests browser notification permission on first load.
Future<void> initializeWebNotifications() async {
  try {
    if (web.Notification.permission == 'default') {
      final jsResult = await web.Notification.requestPermission().toDart;
      final permission = jsResult.toDart;
      debugPrint('Web notification permission: $permission');
    } else {
      debugPrint('Web notification permission: ${web.Notification.permission}');
    }
  } catch (e) {
    debugPrint('Web notifications not supported by this browser: $e');
  }
}

/// Shows an OS-level browser notification (requires permission granted).
void showWebNotification(String title, String body) {
  try {
    if (web.Notification.permission == 'granted') {
      web.Notification(
        title,
        web.NotificationOptions(body: body),
      );
    } else {
      // Permission not granted – silently skip (no crash)
      debugPrint('Web notification skipped (permission: ${web.Notification.permission}): $title');
    }
  } catch (e) {
    debugPrint('Web notification show error: $e');
  }
}
