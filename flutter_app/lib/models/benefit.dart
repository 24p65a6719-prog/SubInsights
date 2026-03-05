class Benefit {
  final String id;
  final String title;
  final String description;
  final int discountPercent;
  final List<String> merchantCategories;
  final List<String> eligibleMerchants;
  bool isVerified;
  double verificationScore;
  DateTime? lastVerification;
  String? membershipId;

  Benefit({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercent,
    required this.merchantCategories,
    required this.eligibleMerchants,
    this.isVerified = false,
    this.verificationScore = 0.0,
    this.lastVerification,
    this.membershipId,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) {
    return Benefit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discountPercent: (json['discount_percent'] as num).toInt(),
      merchantCategories:
          List<String>.from(json['merchant_categories'] ?? []),
      eligibleMerchants:
          List<String>.from(json['eligible_merchants'] ?? []),
      isVerified: json['is_verified'] as bool? ?? false,
      verificationScore:
          (json['verification_score'] as num?)?.toDouble() ?? 0.0,
      membershipId: json['membership_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'discount_percent': discountPercent,
        'merchant_categories': merchantCategories,
        'eligible_merchants': eligibleMerchants,
        'is_verified': isVerified,
        'verification_score': verificationScore,
        'membership_id': membershipId,
      };

  String get verificationStatus {
    if (!isVerified) return 'Not Verified';
    if (verificationScore >= 0.6) return 'Highly Verified';
    return 'Moderately Verified';
  }

  String get priority {
    if (discountPercent >= 30) return 'high';
    if (discountPercent >= 15) return 'medium';
    return 'low';
  }
}
