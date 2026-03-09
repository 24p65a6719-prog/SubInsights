class Merchant {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String address;
  final String phone;
  final String website;
  final List<String> benefitsOffered;
  final double averageReviewRating;
  final int totalReviews;
  final String city;
  final String imageIcon;

  Merchant({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.website,
    required this.benefitsOffered,
    required this.averageReviewRating,
    required this.totalReviews,
    required this.city,
    required this.imageIcon,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      benefitsOffered: List<String>.from(json['benefits_offered'] ?? []),
      averageReviewRating: (json['average_review_rating'] as num).toDouble(),
      totalReviews: json['total_reviews'] as int,
      city: json['city'] as String? ?? '',
      imageIcon: json['image_icon'] as String? ?? 'store',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'phone': phone,
        'website': website,
        'benefits_offered': benefitsOffered,
        'average_review_rating': averageReviewRating,
        'total_reviews': totalReviews,
        'city': city,
        'image_icon': imageIcon,
      };
}
