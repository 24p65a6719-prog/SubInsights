import 'dart:math';

/// Configuration flags that are managed by admins via Firebase/console.
class AdminSettings {
  const AdminSettings({
    required this.dwellThreshold,
    required this.dwellRadiusMeters,
    required this.locationSimulationEnabled,
    required this.dwellControlVisible,
  });

  final Duration dwellThreshold;
  final double dwellRadiusMeters;
  final bool locationSimulationEnabled;
  final bool dwellControlVisible;

  factory AdminSettings.defaults() => const AdminSettings(
        dwellThreshold: Duration(minutes: 2),
        dwellRadiusMeters: 500,
        locationSimulationEnabled: false,
        dwellControlVisible: false,
      );

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    final thresholdSeconds = (json['dwellThresholdSeconds'] as num?)?.toInt() ??
        AdminSettings.defaults().dwellThreshold.inSeconds;
    final radius = (json['dwellRadiusMeters'] as num?)?.toDouble() ??
        AdminSettings.defaults().dwellRadiusMeters;
    return AdminSettings(
      dwellThreshold: Duration(seconds: max(5, thresholdSeconds)),
      dwellRadiusMeters: radius.clamp(100, 5000),
      locationSimulationEnabled: json['locationSimulationEnabled'] as bool? ??
          AdminSettings.defaults().locationSimulationEnabled,
      dwellControlVisible: json['dwellControlVisible'] as bool? ??
          AdminSettings.defaults().dwellControlVisible,
    );
  }

  Map<String, dynamic> toJson() => {
        'dwellThresholdSeconds': dwellThreshold.inSeconds,
        'dwellRadiusMeters': dwellRadiusMeters,
        'locationSimulationEnabled': locationSimulationEnabled,
        'dwellControlVisible': dwellControlVisible,
      };

  AdminSettings copyWith({
    Duration? dwellThreshold,
    double? dwellRadiusMeters,
    bool? locationSimulationEnabled,
    bool? dwellControlVisible,
  }) {
    return AdminSettings(
      dwellThreshold: dwellThreshold ?? this.dwellThreshold,
      dwellRadiusMeters: dwellRadiusMeters ?? this.dwellRadiusMeters,
      locationSimulationEnabled:
          locationSimulationEnabled ?? this.locationSimulationEnabled,
      dwellControlVisible: dwellControlVisible ?? this.dwellControlVisible,
    );
  }
}
