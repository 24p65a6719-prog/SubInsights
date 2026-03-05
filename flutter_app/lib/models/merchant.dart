import 'dart:math';

class Location {
  final double latitude;
  final double longitude;

  const Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Haversine distance in kilometers
  double distanceTo(Location other) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(other.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

class Merchant {
  final String id;
  final String name;
  final String category;
  final Location location;
  final String address;
  final String phone;
  final String website;
  final List<String> benefitsOffered;
  final double averageReviewRating;
  final int totalReviews;
  final bool isActive;

  const Merchant({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.address,
    required this.phone,
    required this.website,
    required this.benefitsOffered,
    required this.averageReviewRating,
    required this.totalReviews,
    this.isActive = true,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      location: Location(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      address: json['address'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      benefitsOffered: List<String>.from(json['benefits_offered'] ?? []),
      averageReviewRating:
          (json['average_review_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': address,
        'phone': phone,
        'website': website,
        'benefits_offered': benefitsOffered,
        'average_review_rating': averageReviewRating,
        'total_reviews': totalReviews,
        'is_active': isActive,
      };

  double distanceTo(Location userLocation) =>
      location.distanceTo(userLocation);
}
