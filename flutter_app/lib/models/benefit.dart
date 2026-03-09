class Benefit {
  final String id;
  final String title;
  final String description;
  final int discountPercent;
  final int maxDiscountInr;
  final List<String> merchantCategories;
  final List<String> eligibleMerchants;
  final List<String> terms;
  final String validFrom;
  final String validUntil;
  final bool isVerified;
  final int usageLimit; // -1 means unlimited
  final int minPurchaseInr;

  Benefit({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercent,
    required this.maxDiscountInr,
    required this.merchantCategories,
    required this.eligibleMerchants,
    required this.terms,
    required this.validFrom,
    required this.validUntil,
    required this.isVerified,
    required this.usageLimit,
    required this.minPurchaseInr,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) {
    return Benefit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discountPercent: json['discount_percent'] as int? ?? 0,
      maxDiscountInr: json['max_discount_inr'] as int? ?? 0,
      merchantCategories: List<String>.from(json['merchant_categories'] ?? []),
      eligibleMerchants: List<String>.from(json['eligible_merchants'] ?? []),
      terms: List<String>.from(json['terms'] ?? []),
      validFrom: json['valid_from'] as String? ?? '',
      validUntil: json['valid_until'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      usageLimit: json['usage_limit'] as int? ?? -1,
      minPurchaseInr: json['min_purchase_inr'] as int? ?? 0,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    final from = DateTime.tryParse(validFrom);
    final until = DateTime.tryParse(validUntil);
    if (from == null || until == null) return false;
    return now.isAfter(from) && now.isBefore(until.add(const Duration(days: 1)));
  }

  bool get isExpiringSoon {
    final until = DateTime.tryParse(validUntil);
    if (until == null) return false;
    return until.difference(DateTime.now()).inDays <= 30;
  }

  String get validityStatus {
    if (!isValid) return 'Expired';
    if (isExpiringSoon) return 'Expiring Soon';
    return 'Active';
  }

  String get discountLabel {
    if (discountPercent > 0) {
      return '$discountPercent% OFF';
    } else if (maxDiscountInr > 0) {
      return '₹$maxDiscountInr OFF';
    }
    return 'Special Offer';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'discount_percent': discountPercent,
        'max_discount_inr': maxDiscountInr,
        'merchant_categories': merchantCategories,
        'eligible_merchants': eligibleMerchants,
        'terms': terms,
        'valid_from': validFrom,
        'valid_until': validUntil,
        'is_verified': isVerified,
        'usage_limit': usageLimit,
        'min_purchase_inr': minPurchaseInr,
      };
}
