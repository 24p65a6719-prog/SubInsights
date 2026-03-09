class Subscription {
  final String id;
  final String name;
  final String provider;
  final String category;
  final String icon;
  final String color;
  final String description;
  final List<String> associatedBenefits;
  final bool isActive;
  final String expiryDate;

  Subscription({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    required this.icon,
    required this.color,
    required this.description,
    required this.associatedBenefits,
    required this.isActive,
    required this.expiryDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: json['provider'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String? ?? 'card_membership',
      color: json['color'] as String? ?? '#607D8B',
      description: json['description'] as String? ?? '',
      associatedBenefits: List<String>.from(json['associated_benefits'] ?? []),
      isActive: json['is_active'] as bool? ?? true,
      expiryDate: json['expiry_date'] as String? ?? '',
    );
  }

  bool get isExpired {
    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  bool get isExpiringSoon {
    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return false;
    return expiry.difference(DateTime.now()).inDays <= 30;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        'category': category,
        'icon': icon,
        'color': color,
        'description': description,
        'associated_benefits': associatedBenefits,
        'is_active': isActive,
        'expiry_date': expiryDate,
      };
}
