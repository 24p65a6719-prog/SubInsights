import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation can be handled via a callback or global key
  }

  /// Show a nearby offer notification
  Future<void> showNearbyOfferNotification({
    required int id,
    required String merchantName,
    required String offerTitle,
    required String distance,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'nearby_offers',
      'Nearby Offers',
      channelDescription: 'Notifications for offers near your location',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '$offerTitle at $merchantName',
        contentTitle: '🎯 Offer Nearby! ($distance away)',
        summaryText: merchantName,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      '🎯 Offer Nearby! ($distance away)',
      '$offerTitle at $merchantName',
      details,
      payload: payload,
    );
  }

  /// Show a dwell-time triggered notification
  Future<void> showDwellNotification({
    required int id,
    required String merchantName,
    required int offerCount,
    required String dwellTime,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'dwell_offers',
      'Dwell Offers',
      channelDescription:
          'Notifications triggered when you spend time near a location',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'You\'ve been near $merchantName for $dwellTime. '
        'You have $offerCount offer${offerCount > 1 ? 's' : ''} available here!',
        contentTitle: '📍 Don\'t miss your offers!',
        summaryText: '$offerCount offers at $merchantName',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      '📍 Don\'t miss your offers!',
      'You have $offerCount offer${offerCount > 1 ? 's' : ''} at $merchantName',
      details,
      payload: 'merchant:$merchantName',
    );
  }

  /// Show offer expiry warning
  Future<void> showExpiryWarning({
    required int id,
    required String offerTitle,
    required int daysLeft,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'expiry_warnings',
      'Expiry Warnings',
      channelDescription: 'Notifications for offers about to expire',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id,
      '⏰ Offer Expiring Soon!',
      '$offerTitle expires in $daysLeft day${daysLeft > 1 ? 's' : ''}',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
