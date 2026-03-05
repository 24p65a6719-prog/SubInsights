class Membership {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> associatedBenefits;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const Membership({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.associatedBenefits,
    this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      associatedBenefits:
          List<String>.from(json['associated_benefits'] ?? []),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'associated_benefits': associatedBenefits,
        'is_active': isActive,
      };

  bool get isExpired =>
      endDate != null && endDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry =>
      endDate?.difference(DateTime.now()).inDays;
}
