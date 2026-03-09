import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/merchant.dart';

class LocationService {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  final _nearbyController = StreamController<List<NearbyMerchant>>.broadcast();

  // Dwell time tracking: merchant_id -> timestamp when user entered radius
  final Map<String, DateTime> _dwellStartTimes = {};
  static const double _notifyRadiusMeters = 500; // 500m radius
  static const Duration _dwellThreshold = Duration(minutes: 2); // 2 min dwell

  Position? get currentPosition => _currentPosition;
  Stream<List<NearbyMerchant>> get nearbyStream => _nearbyController.stream;

  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
        ),
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  /// Simulate a position for testing (since we may not be in India)
  void simulatePosition(double latitude, double longitude) {
    _currentPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Start monitoring location and tracking nearby merchants
  Future<void> startMonitoring(List<Merchant> merchants) async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        // Use simulated position for testing
        debugPrint('Location permission not granted, using simulated position');
        _updateNearbyMerchants(merchants);
        return;
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
        ),
      ).listen((position) {
        _currentPosition = position;
        _updateNearbyMerchants(merchants);
      });
    } catch (e) {
      debugPrint('Error starting monitoring: $e');
    }
  }

  /// Update nearby merchants list based on current position
  void _updateNearbyMerchants(List<Merchant> merchants) {
    if (_currentPosition == null) return;

    final nearby = <NearbyMerchant>[];
    final now = DateTime.now();

    for (final merchant in merchants) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        merchant.latitude,
        merchant.longitude,
      );

      if (distance <= _notifyRadiusMeters * 10) {
        // Extended radius for the list 5km
        final isInDwellZone = distance <= _notifyRadiusMeters;

        if (isInDwellZone) {
          _dwellStartTimes.putIfAbsent(merchant.id, () => now);
        } else {
          _dwellStartTimes.remove(merchant.id);
        }

        final dwellStart = _dwellStartTimes[merchant.id];
        final hasDwelled = dwellStart != null &&
            now.difference(dwellStart) >= _dwellThreshold;

        nearby.add(NearbyMerchant(
          merchant: merchant,
          distanceMeters: distance,
          isInDwellZone: isInDwellZone,
          hasDwelled: hasDwelled,
          dwellDuration:
              dwellStart != null ? now.difference(dwellStart) : Duration.zero,
        ));
      }
    }

    nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    _nearbyController.add(nearby);
  }

  /// Find merchants near a given position
  List<NearbyMerchant> findNearbyMerchants(
    List<Merchant> merchants, {
    double? lat,
    double? lng,
    double radiusMeters = 5000,
  }) {
    final refLat = lat ?? _currentPosition?.latitude;
    final refLng = lng ?? _currentPosition?.longitude;
    if (refLat == null || refLng == null) return [];

    final nearby = <NearbyMerchant>[];
    for (final merchant in merchants) {
      final distance = _calculateDistance(
        refLat,
        refLng,
        merchant.latitude,
        merchant.longitude,
      );
      if (distance <= radiusMeters) {
        nearby.add(NearbyMerchant(
          merchant: merchant,
          distanceMeters: distance,
          isInDwellZone: distance <= _notifyRadiusMeters,
          hasDwelled: false,
          dwellDuration: Duration.zero,
        ));
      }
    }
    nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return nearby;
  }

  /// Haversine formula to calculate distance between two coordinates
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180);

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _dwellStartTimes.clear();
  }

  void dispose() {
    stopMonitoring();
    _nearbyController.close();
  }
}

class NearbyMerchant {
  final Merchant merchant;
  final double distanceMeters;
  final bool isInDwellZone;
  final bool hasDwelled;
  final Duration dwellDuration;

  NearbyMerchant({
    required this.merchant,
    required this.distanceMeters,
    required this.isInDwellZone,
    required this.hasDwelled,
    required this.dwellDuration,
  });

  String get distanceLabel => LocationService.formatDistance(distanceMeters);
}
