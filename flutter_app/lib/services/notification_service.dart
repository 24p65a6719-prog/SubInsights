import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Conditionally import web notification helpers.
// On web (dart.library.html is available) the real browser Notification API is
// used; on mobile/desktop the stub no-ops are imported.
import '_notification_helper_stub.dart'
    if (dart.library.html) '_notification_helper_web.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _fcmToken;

  /// The FCM device token (null until initialize() completes).
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // 1. Request browser Notification API permission.
      await initializeWebNotifications();

      // 2. Firebase Cloud Messaging — handles server-sent push notifications.
      //    Background messages (tab closed / inactive) are handled automatically
      //    by web/firebase-messaging-sw.js.
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCM permission: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          final token = await messaging.getToken(vapidKey: 'BH0KB0A7a2IuoVpJDXlbrP-bkhkEv6CQCMOwLB6qkhrIHCpkijSYcN7AfGOkIzQmPnKoIWQ4JoJW-XLM5h0wkRI');
          _fcmToken = token;
          debugPrint('FCM Web Token: $token');

          // Foreground messages (tab is open): show via browser Notification API.
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            final notification = message.notification;
            if (notification != null) {
              showWebNotification(
                notification.title ?? 'SubInsights',
                notification.body ?? '',
              );
            }
          });
        }
      } catch (e) {
        debugPrint('FCM initialization error (non-fatal): $e');
      }
    } else {
      // ── Mobile: Local Notifications ──
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

      // Create notification channels for Android (required for Android 8+).
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'dwell_offers',
            'Dwell Offers',
            description:
                'Notifications triggered when you spend time near a location',
            importance: Importance.max,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'nearby_offers',
            'Nearby Offers',
            description: 'Notifications for offers near your location',
            importance: Importance.high,
          ),
        );
      }

      // ── Mobile: Firebase Cloud Messaging (FCM) ──
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('FCM mobile permission: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          _fcmToken = await messaging.getToken();
          debugPrint('FCM Mobile Token: $_fcmToken');

          // Token refresh listener — update backend if you have one.
          messaging.onTokenRefresh.listen((newToken) {
            _fcmToken = newToken;
            debugPrint('FCM Token refreshed: $newToken');
          });

          // Foreground FCM messages → show as local notification.
          FirebaseMessaging.onMessage.listen(_showFcmAsLocal);

          // When user taps a background FCM notification → app opens.
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
            debugPrint('FCM notification opened: ${message.data}');
          });
        }
      } catch (e) {
        debugPrint('FCM mobile initialization error (non-fatal): $e');
      }
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Convert an incoming FCM message to a local notification on mobile.
  Future<void> _showFcmAsLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'dwell_offers',
      'Dwell Offers',
      channelDescription:
          'Notifications triggered when you spend time near a location',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      notification.hashCode,
      notification.title ?? 'SubInsights',
      notification.body ?? '',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show a nearby offer notification.
  Future<void> showNearbyOfferNotification({
    required int id,
    required String merchantName,
    required String offerTitle,
    required String distance,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    if (kIsWeb) {
      showWebNotification(
        '🎯 Offer Nearby! ($distance away)',
        '$offerTitle at $merchantName',
      );
      return;
    }

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
    await _plugin.show(
      id,
      '🎯 Offer Nearby! ($distance away)',
      '$offerTitle at $merchantName',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Show a dwell-time triggered notification.
  Future<void> showDwellNotification({
    required int id,
    required String merchantName,
    required int offerCount,
    required String dwellTime,
  }) async {
    if (!_isInitialized) await initialize();

    if (kIsWeb) {
      showWebNotification(
        '📍 Don\'t miss your offers!',
        'You\'ve been near $merchantName for $dwellTime. '
        'You have $offerCount offer${offerCount > 1 ? 's' : ''} available here!',
      );
      return;
    }

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
    await _plugin.show(
      id,
      '📍 Don\'t miss your offers!',
      'You have $offerCount offer${offerCount > 1 ? 's' : ''} at $merchantName',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'merchant:$merchantName',
    );
  }

  /// Show an offer expiry warning notification.
  Future<void> showExpiryWarning({
    required int id,
    required String offerTitle,
    required int daysLeft,
  }) async {
    if (!_isInitialized) await initialize();

    if (kIsWeb) {
      showWebNotification(
        '⏰ Offer Expiring Soon!',
        '$offerTitle expires in $daysLeft day${daysLeft > 1 ? 's' : ''}',
      );
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'expiry_warnings',
      'Expiry Warnings',
      channelDescription: 'Notifications for offers about to expire',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      id,
      '⏰ Offer Expiring Soon!',
      '$offerTitle expires in $daysLeft day${daysLeft > 1 ? 's' : ''}',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelAll() async {
    if (!kIsWeb) await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    if (!kIsWeb) await _plugin.cancel(id);
  }
}
