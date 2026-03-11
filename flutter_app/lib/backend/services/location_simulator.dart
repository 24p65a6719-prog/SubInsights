import 'dart:async';
import 'dart:math';
import '../../models/merchant.dart';
import '../../services/location_service.dart';

/// State emitted by the location simulator on every tick.
class SimulationState {
  final Merchant merchant;
  final double distanceMeters;
  final Duration elapsed;
  final Duration threshold;
  final bool triggered;

  SimulationState({
    required this.merchant,
    required this.distanceMeters,
    required this.elapsed,
    required this.threshold,
    this.triggered = false,
  });

  double get progress =>
      (elapsed.inSeconds / threshold.inSeconds).clamp(0.0, 1.0);
}

/// Simulates the user being at a chosen merchant location and counts dwell
/// time.  Fires a callback when the configurable dwell threshold is crossed.
class LocationSimulator {
  LocationSimulator({
    required this.locationService,
    this.dwellRadiusMeters = 500,
    this.dwellThreshold = const Duration(minutes: 2),
  });

  final LocationService locationService;
  double dwellRadiusMeters;
  Duration dwellThreshold;

  Timer? _timer;
  final _controller = StreamController<SimulationState>.broadcast();
  Stream<SimulationState> get stateStream => _controller.stream;

  Merchant? _activeMerchant;
  DateTime? _startedAt;
  bool _triggered = false;

  Merchant? get activeMerchant => _activeMerchant;
  bool get isRunning => _timer != null;

  /// Teleport the user to [merchant] and start the dwell timer.
  void teleport(Merchant merchant) {
    stop();
    _activeMerchant = merchant;
    _triggered = false;

    // Move the location service cursor
    locationService.simulatePosition(merchant.latitude, merchant.longitude);
    _startedAt = DateTime.now();

    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick(); // emit immediately
  }

  void _tick() {
    if (_activeMerchant == null || _startedAt == null) return;

    final elapsed = DateTime.now().difference(_startedAt!);
    final distance = _haversine(
      locationService.currentPosition!.latitude,
      locationService.currentPosition!.longitude,
      _activeMerchant!.latitude,
      _activeMerchant!.longitude,
    );

    if (elapsed >= dwellThreshold && !_triggered) {
      _triggered = true;
    }

    _controller.add(SimulationState(
      merchant: _activeMerchant!,
      distanceMeters: distance,
      elapsed: elapsed,
      threshold: dwellThreshold,
      triggered: _triggered,
    ));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeMerchant = null;
    _startedAt = null;
    _triggered = false;
  }

  void dispose() {
    stop();
    _controller.close();
  }

  /// Update configurable parameters while running.
  void updateParams({double? radius, Duration? threshold}) {
    if (radius != null) dwellRadiusMeters = radius;
    if (threshold != null) dwellThreshold = threshold;
  }

  // Haversine distance in metres.
  static double _haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * (pi / 180);
}
