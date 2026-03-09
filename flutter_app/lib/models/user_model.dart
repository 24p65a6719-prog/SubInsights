class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final List<String> subscriptionIds;
  final DateTime createdAt;
  final DateTime lastLogin;
  final UserPreferences preferences;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    required this.subscriptionIds,
    required this.createdAt,
    required this.lastLogin,
    required this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionIds: List<String>.from(json['subscription_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: DateTime.parse(json['last_login'] as String),
      preferences: UserPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'subscription_ids': subscriptionIds,
        'created_at': createdAt.toIso8601String(),
        'last_login': lastLogin.toIso8601String(),
        'preferences': preferences.toJson(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    List<String>? subscriptionIds,
    DateTime? createdAt,
    DateTime? lastLogin,
    UserPreferences? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionIds: subscriptionIds ?? this.subscriptionIds,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class UserPreferences {
  final bool notificationsEnabled;
  final bool locationTrackingEnabled;
  final double notificationRadius; // in meters
  final int dwellTimeMinutes;
  final List<String> favoriteCategories;
  final List<String> favoriteCities;
  final String theme; // 'light', 'dark', 'system'

  UserPreferences({
    this.notificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.notificationRadius = 500,
    this.dwellTimeMinutes = 2,
    this.favoriteCategories = const [],
    this.favoriteCities = const [],
    this.theme = 'light',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      locationTrackingEnabled:
          json['location_tracking_enabled'] as bool? ?? true,
      notificationRadius: (json['notification_radius'] as num?)?.toDouble() ?? 500,
      dwellTimeMinutes: json['dwell_time_minutes'] as int? ?? 2,
      favoriteCategories:
          List<String>.from(json['favorite_categories'] ?? []),
      favoriteCities: List<String>.from(json['favorite_cities'] ?? []),
      theme: json['theme'] as String? ?? 'light',
    );
  }

  Map<String, dynamic> toJson() => {
        'notifications_enabled': notificationsEnabled,
        'location_tracking_enabled': locationTrackingEnabled,
        'notification_radius': notificationRadius,
        'dwell_time_minutes': dwellTimeMinutes,
        'favorite_categories': favoriteCategories,
        'favorite_cities': favoriteCities,
        'theme': theme,
      };

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? locationTrackingEnabled,
    double? notificationRadius,
    int? dwellTimeMinutes,
    List<String>? favoriteCategories,
    List<String>? favoriteCities,
    String? theme,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      notificationRadius: notificationRadius ?? this.notificationRadius,
      dwellTimeMinutes: dwellTimeMinutes ?? this.dwellTimeMinutes,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      favoriteCities: favoriteCities ?? this.favoriteCities,
      theme: theme ?? this.theme,
    );
  }
}
