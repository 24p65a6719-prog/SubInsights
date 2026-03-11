import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

/// Configures and starts a background service that monitors the user's
/// GPS position and sends a local notification once the dwell threshold
/// is reached near any merchant from the bundled data.
///
/// On Android this runs as a **foreground service** (persistent notification)
/// so the OS does not kill it.  On iOS it relies on background‑location mode
/// declared in Info.plist.
Future<void> initBackgroundLocationService() async {
  final service = FlutterBackgroundService();

  // Create the persistent notification channel for the foreground service.
  const channelId = 'subinsights_location';
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        'Location Monitoring',
        description: 'Keeps SubInsights tracking your location in the background',
        importance: Importance.low, // silent persistent notification
      ),
    );
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: false, // started explicitly after login
      isForegroundMode: true,
      notificationChannelId: channelId,
      initialNotificationTitle: 'SubInsights',
      initialNotificationContent: 'Monitoring nearby offers…',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );
}

/// Start the background service (call after login / location permission).
Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (!isRunning) {
    await service.startService();
    debugPrint('Background location service started');
  }
}

/// Stop the background service (call on logout).
Future<void> stopBackgroundService() async {
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  if (isRunning) {
    service.invoke('stop');
    debugPrint('Background location service stopped');
  }
}

// ── iOS background entry point ──
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}

// ── Main background entry point (runs in isolate on Android) ──
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // Listen for stop signal from the main isolate.
  service.on('stop').listen((_) {
    service.stopSelf();
  });

  // Load merchant data (from bundled assets — works in isolate).
  final dataService = DataService();
  try {
    await dataService.loadAll();
  } catch (e) {
    debugPrint('Background: failed to load data: $e');
    return;
  }

  // Read user's dwell threshold preference (seconds), default 120.
  final prefs = await SharedPreferences.getInstance();
  final dwellSec = prefs.getInt('dwell_threshold_seconds') ?? 120;
  final dwellThreshold = Duration(seconds: dwellSec);
  const dwellRadius = 500.0; // metres

  final notificationService = NotificationService();
  // On background isolate we only need local-notification init (not FCM).
  await notificationService.initialize();

  // Merchant-id → timestamp when user first entered radius.
  final Map<String, DateTime> dwellStarts = {};
  // Merchants that have already triggered a notification in this session.
  final Set<String> notifiedIds = {};

  // Poll GPS every 10 seconds — good compromise between accuracy & battery.
  Timer.periodic(const Duration(seconds: 10), (_) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final now = DateTime.now();

      for (final merchant in dataService.merchants) {
        final dist = LocationService.haversineDistance(
          position.latitude,
          position.longitude,
          merchant.latitude,
          merchant.longitude,
        );

        if (dist <= dwellRadius) {
          dwellStarts.putIfAbsent(merchant.id, () => now);
          final elapsed = now.difference(dwellStarts[merchant.id]!);

          if (elapsed >= dwellThreshold &&
              !notifiedIds.contains(merchant.id)) {
            final benefits =
                dataService.getBenefitsAtMerchant(merchant);
            if (benefits.isNotEmpty) {
              await notificationService.showDwellNotification(
                id: merchant.id.hashCode,
                merchantName: merchant.name,
                offerCount: benefits.length,
                dwellTime: elapsed.inMinutes >= 1
                    ? '${elapsed.inMinutes} min'
                    : '${elapsed.inSeconds}s',
              );
              notifiedIds.add(merchant.id);
            }
          }
        } else {
          // User left the zone — reset tracking for this merchant.
          dwellStarts.remove(merchant.id);
          notifiedIds.remove(merchant.id);
        }
      }

      // Update the persistent notification content.
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'SubInsights',
          content:
              'Tracking ${dataService.merchants.length} merchants • '
              '${dwellStarts.length} in range',
        );
      }
    } catch (e) {
      debugPrint('Background location tick error: $e');
    }
  });
}
