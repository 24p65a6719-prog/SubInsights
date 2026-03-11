# SubInsights — Real Mobile Deployment Plan
## A Complete Gap Analysis & Implementation Guide for Live GPS-Based Push Notifications

---

## 1. Does the Current App Work on a Real Phone?

**Short answer: Partially — but not fully as intended.**

Here is an honest breakdown of what works today versus what needs to be added for the GPS + dwell-time notification flow to work in production on a real Android or iOS device.

---

## 2. What Works Right Now

| Feature | Status | Notes |
|---|---|---|
| Email Sign-Up / Login | ✅ Works | Stored locally via `flutter_secure_storage` |
| Google Sign-In | ✅ Works on Web | Mobile needs `google-services.json` / `GoogleService-Info.plist` |
| Subscription management | ✅ Works | Persisted via `SharedPreferences` |
| Merchant browsing & explore | ✅ Works | Loaded from bundled JSON assets |
| Map view | ✅ Works | Uses `flutter_map` (OpenStreetMap, no API key needed) |
| Location permission request | ✅ Works | `geolocator` handles this correctly |
| Real GPS positioning | ✅ Works (foreground) | `Geolocator.getPositionStream()` fires when **moving** |
| Local notifications (foreground) | ✅ Works | `flutter_local_notifications` set up correctly for Android/iOS |
| Dwell timer in simulator | ✅ Works | `LocationSimulator` correctly counts dwell via `Timer.periodic` |
| Haversine distance calculation | ✅ Works | Accurate within meters |

---

## 3. What Does NOT Work Yet for Real-World Deployment

### 3.1 Critical Gap — Dwell Timer Does Not Tick When Stationary

**This is the biggest issue.**

The current `LocationService` calculates dwell time inside `_updateNearbyMerchants`, which is only called when `Geolocator.getPositionStream` fires a new GPS event. But `getPositionStream` is configured with:

```dart
LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 50,  // ← only fires after moving 50 metres
)
```

**If the user stands still near a merchant, the stream never fires again.** The dwell timer never advances. No notification is ever sent.

**Fix Required:** The `LocationService` needs its own `Timer.periodic` that periodically calls `_updateNearbyMerchants` using the last-known position, even when the user is stationary.

---

### 3.2 Critical Gap — No Background Location Service

The app runs location tracking only while it is **open and in the foreground**. The moment the user switches apps or locks their screen:

- `getPositionStream` is paused by the OS
- The dwell timer stops counting
- No notifications are sent

**Fix Required:**

#### Android
Needs a **Foreground Service** declared in `AndroidManifest.xml` with a persistent notification. On Android 12+, `FOREGROUND_SERVICE_LOCATION` permission is also required.

Use the `flutter_background_service` or `workmanager` package.

#### iOS
iOS does not allow continuous background GPS unless you declare the `location` background mode in `Info.plist`. Uses `CLLocationManager.startUpdatingLocation()` with `allowsBackgroundLocationUpdates = true`.

---

### 3.3 Critical Gap — Firebase Not Initialized on Mobile

Firebase is currently guarded behind `kIsWeb`:

```dart
// main.dart
if (kIsWeb) {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
}
```

This means:
- FCM does not work on Android or iOS
- Google Sign-In through Firebase does not work on mobile
- Push notifications through FCM cannot be received when the app is in the background

**Fix Required:**
1. Download `google-services.json` from Firebase Console → place in `android/app/`
2. Download `GoogleService-Info.plist` from Firebase Console → place in `ios/Runner/`
3. Remove the `kIsWeb` guard and always call `Firebase.initializeApp()`

---

### 3.4 Missing — FCM-Based Background Push Notifications

`flutter_local_notifications` can show notifications when the **app is open**. But when the app is **closed or killed**, you need FCM to deliver the notification from a server.

The current flow:

```
User near merchant → app detects dwell → app calls showDwellNotification()
```

This only works in the foreground. The real flow for background notifications needs:

```
Background service detects dwell 
  → triggers local notification (works on Android foreground service)
  → OR sends FCM message to own server → server sends push via FCM → device receives it even when app is killed
```

---

### 3.5 Missing — `google-services.json` and `GoogleService-Info.plist`

Google Sign-In on mobile requires the `SHA-1` fingerprint of your app registered in Firebase Console, and the downloaded config files. Without these:

- `GoogleSignIn().signIn()` throws an error on Android
- Firebase Auth OAuth redirect does not work on iOS

---

## 4. The Architecture That Must Be Built

### 4.1 Full Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│                  DEVICE                             │
│                                                     │
│  ┌──────────────┐     every 1s    ┌──────────────┐  │
│  │ GPS Stream   │ ──────────────► │ Dwell Timer  │  │
│  │ (geolocator) │                 │ (periodic)   │  │
│  └──────────────┘                 └──────┬───────┘  │
│                                          │           │
│                              threshold   │           │
│                              reached     ▼           │
│                         ┌────────────────────────┐  │
│                         │  NotificationService   │  │
│                         │  showDwellNotification │  │
│                         └────────┬───────────────┘  │
│                                  │                   │
│              ┌───────────────────┴──────────────┐   │
│       App    │                           App    │   │
│    Foreground│                        Background│   │
│              ▼                                  ▼   │
│   flutter_local_notifications          FCM Push     │
│   (shows immediately)             (from your server)│
└─────────────────────────────────────────────────────┘
```

---

### 4.2 Step-by-Step Fix Implementation

---

#### STEP 1 — Fix the Stationary Dwell Timer (Most Important)

**File:** `lib/services/location_service.dart`

Add a `Timer.periodic` that runs the dwell check every second using the last known GPS position. This is separate from `getPositionStream` (which only fires on movement).

```dart
Timer? _dwellTimer;

Future<void> startMonitoring(List<Merchant> merchants) async {
  // ... existing GPS stream setup ...

  // NEW: tick the dwell tracker every second, even when stationary
  _dwellTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (_currentPosition != null) {
      _updateNearbyMerchants(merchants);
    }
  });
}

void stopMonitoring() {
  _positionSubscription?.cancel();
  _dwellTimer?.cancel();     // ← cancel the new timer too
  _dwellStartTimes.clear();
}
```

**Why this works:** `getPositionStream` with `distanceFilter: 50` only fires after the user moves 50 metres. Standing still means no updates. The periodic timer solves this by re-evaluating the last known position every second, which allows `_dwellStartTimes` to accumulate time correctly.

---

#### STEP 2 — Wire `_onNearbyUpdate` to Send Notifications After Dwell

After removing the instant notification from the last session, the `_onNearbyUpdate` in `AppState` no longer sends any notification at all. But the `LocationService` dwell-tracking path still correctly sets `hasDwelled = true` once the threshold passes.

**File:** `lib/providers/app_state.dart`

Restore a guarded notification call here, but now it is safe because `hasDwelled` only becomes true after the real dwell threshold:

```dart
void _onNearbyUpdate(List<NearbyMerchant> nearby) {
  _nearbyMerchants = nearby;
  notifyListeners();

  // Only fires when hasDwelled = true (i.e. after the threshold duration)
  for (final nm in nearby) {
    if (nm.hasDwelled && !_notifiedMerchantIds.contains(nm.merchant.id)) {
      final benefits = _dataService.getBenefitsAtMerchant(nm.merchant);
      final userBenefits = benefits
          .where((b) => userSubscriptions
              .any((s) => s.associatedBenefits.contains(b.id)))
          .toList();
      if (userBenefits.isNotEmpty) {
        _notificationService.showDwellNotification(
          id: nm.merchant.id.hashCode,
          merchantName: nm.merchant.name,
          offerCount: userBenefits.length,
          dwellTime: '${nm.dwellDuration.inSeconds}s',
        );
        _notifiedMerchantIds.add(nm.merchant.id);
      }
    }
  }
}
```

---

#### STEP 3 — Add Background Location Service (Android)

**Add dependency to `pubspec.yaml`:**

```yaml
dependencies:
  flutter_background_service: ^5.0.5
```

**Declare in `android/app/src/main/AndroidManifest.xml`:**

```xml
<!-- Inside <manifest> -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Inside <application> -->
<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    android:foregroundServiceType="location"
    android:exported="false" />
```

**Create `lib/services/background_location_service.dart`:**

```dart
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_service.dart';
import 'data_service.dart';
import 'location_service.dart';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'subinsights_location',
      initialNotificationTitle: 'SubInsights',
      initialNotificationContent: 'Monitoring nearby offers...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final notificationService = NotificationService();
  await notificationService.initialize();
  final dataService = DataService();
  await dataService.loadAll();
  final locationService = LocationService();

  final Map<String, DateTime> dwellStartTimes = {};
  const dwellThreshold = Duration(minutes: 2); // load from prefs in production

  Timer.periodic(const Duration(seconds: 10), (_) async {
    final position = await Geolocator.getCurrentPosition();
    for (final merchant in dataService.merchants) {
      final dist = LocationService.staticHaversine(
        position.latitude, position.longitude,
        merchant.latitude, merchant.longitude,
      );
      if (dist <= 500) {
        dwellStartTimes.putIfAbsent(merchant.id, () => DateTime.now());
        final elapsed = DateTime.now().difference(dwellStartTimes[merchant.id]!);
        if (elapsed >= dwellThreshold) {
          final benefits = dataService.getBenefitsAtMerchant(merchant);
          if (benefits.isNotEmpty) {
            await notificationService.showDwellNotification(
              id: merchant.id.hashCode,
              merchantName: merchant.name,
              offerCount: benefits.length,
              dwellTime: '${elapsed.inMinutes} min',
            );
          }
          dwellStartTimes.remove(merchant.id); // reset so it doesn't repeat
        }
      } else {
        dwellStartTimes.remove(merchant.id);
      }
    }
  });
}
```

---

#### STEP 4 — Enable Firebase on Android & iOS

**`main.dart`** — Remove the `kIsWeb` guard:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // works for all platforms
  );
  runApp(const SubInsightsApp());
}
```

This requires:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Add Android app → download `google-services.json` → place in `android/app/`
3. Add iOS app → download `GoogleService-Info.plist` → place in `ios/Runner/` (add via Xcode)
4. Run `flutterfire configure` to regenerate `firebase_options.dart`

---

#### STEP 5 — FCM Token Registration (Background Notifications When App Killed)

In `NotificationService.initialize()`, add mobile FCM token retrieval:

```dart
// For Android / iOS (non-web)
final messaging = FirebaseMessaging.instance;
await messaging.requestPermission(alert: true, badge: true, sound: true);

final token = await messaging.getToken();
debugPrint('FCM Mobile Token: $token');
// Send this token to your backend server so it can push to this device

// Handle FCM notification when app is in background but not killed
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Navigate to the relevant merchant screen
});

// Handle FCM notification when app is completely killed
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

Add at top level (not inside a class):

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Show local notification from FCM data
}
```

---

#### STEP 6 — iOS Background Location Mode

**`ios/Runner/Info.plist`** — Add background modes:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>SubInsights needs location access to detect when you are near a merchant and alert you about your subscription offers.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>SubInsights uses your location in the background to notify you about offers near you.</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

---

#### STEP 7 — Android Notification Permission (Android 13+)

**`android/app/src/main/AndroidManifest.xml`:**

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

In code, request it at runtime:

```dart
import 'package:permission_handler/permission_handler.dart';

if (await Permission.notification.isDenied) {
  await Permission.notification.request();
}
```

Add `permission_handler: ^11.3.1` to `pubspec.yaml`.

---

## 5. Recommended Package Additions

```yaml
dependencies:
  flutter_background_service: ^5.0.5  # Background GPS + dwell tracking
  permission_handler: ^11.3.1          # Runtime notification permission (Android 13+)
  workmanager: ^0.5.2                  # Alternative to background_service for periodic checks
```

---

## 6. Battery & Performance Considerations

| Strategy | Battery Impact | Accuracy | Recommended For |
|---|---|---|---|
| `getPositionStream` + `distanceFilter: 50` | Medium | High | Foreground movement detection |
| `Timer.periodic(1s)` on last known position | Low | High (uses cached GPS) | Dwell time counting ✅ |
| Geofencing (`geolocator` `GeofenceService`) | Very Low | Medium | Large-radius triggers |
| Foreground Service (Android) | Medium | High | Always-on tracking |
| `WorkManager` 15-min interval (Android) | Very Low | Low (delayed) | Battery-friendly periodic checks |
| Significant Location Change (iOS) | Very Low | Low | iOS background wake-ups |

**Recommended production strategy:**
- Use **geofencing** to enter/exit a 500m zone (battery efficient)
- When inside a geofence, start a **foreground service** that counts dwell time with a 1-second timer
- When dwell threshold is reached, fire a **local notification**
- Stop the foreground service when the user leaves the geofence

---

## 7. Complete Feature Gap Summary

| Requirement | Current State | What's Needed |
|---|---|---|
| GPS location (foreground) | ✅ Complete | — |
| Dwell time while moving | ✅ Works | — |
| **Dwell time while stationary** | ❌ Broken | `Timer.periodic` in `LocationService` |
| Notifications when app is open | ✅ Complete | — |
| **Notifications when app is minimized** | ❌ Missing | Background service / foreground service |
| **Notifications when app is killed** | ❌ Missing | FCM + backend server |
| Firebase on Android/iOS | ❌ Missing | `google-services.json`, remove `kIsWeb` guard |
| Google Sign-In on mobile | ❌ Missing | `google-services.json` + SHA-1 fingerprint |
| Background location (Android) | ❌ Missing | Foreground service declaration |
| Background location (iOS) | ❌ Missing | `UIBackgroundModes: location` in `Info.plist` |
| Notification permission (Android 13+) | ❌ Missing | `POST_NOTIFICATIONS` + runtime request |

---

## 8. Priority Order for Making It Fully Work

1. **[Critical]** Fix stationary dwell timer — `Timer.periodic` in `LocationService` (30 min work)
2. **[Critical]** Add Firebase config files and enable on mobile — `google-services.json` + remove `kIsWeb` guard (1 hour)
3. **[Critical]** Background service for Android — `flutter_background_service` (2-3 hours)
4. **[High]** iOS background location mode — `Info.plist` changes (30 min)
5. **[High]** Android 13+ notification permission — `permission_handler` (30 min)
6. **[Medium]** FCM background message handler — for when app is killed (1-2 hours)
7. **[Low]** Replace continuous GPS with geofencing for better battery life (3-4 hours)

---

## 9. Quick Test on a Real Phone (Without All the Above)

You can already test the core dwell-notification logic on a real phone with these steps:

1. Build and install the debug APK: `flutter run --debug` (with phone plugged in via USB)
2. Keep the app **in the foreground**
3. Go to the **Home** tab → Location Simulator
4. Set Dwell Time to **30 seconds** (minimum slider value)
5. Select any merchant → tap it to start the dwell timer
6. After 30 seconds the dwell triggers and a local notification appears (app must be open)

This confirms the notification logic works. What it won't test is background/killed-app behaviour, which needs the Steps 2–6 above.

---

*Generated: March 2026 | SubInsights v1.0.0*
