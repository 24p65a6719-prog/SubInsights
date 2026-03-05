enum AlertStatus { pending, sent, dismissed, claimed }

class BenefitAlert {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String benefitId;
  final String merchantId;
  final int discountPercent;
  final DateTime createdAt;
  AlertStatus status;
  final String priority;
  String? redemptionCode;

  BenefitAlert({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.benefitId,
    required this.merchantId,
    required this.discountPercent,
    required this.createdAt,
    this.status = AlertStatus.pending,
    required this.priority,
    this.redemptionCode,
  });

  factory BenefitAlert.fromJson(Map<String, dynamic> json) {
    return BenefitAlert(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'user_1',
      title: json['title'] as String,
      message: json['message'] as String,
      benefitId: json['benefit_id'] as String,
      merchantId: json['merchant_id'] as String? ?? '',
      discountPercent: (json['discount'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      status: _parseStatus(json['status'] as String?),
      priority: json['priority'] as String? ?? 'medium',
      redemptionCode: json['redemption_code'] as String?,
    );
  }

  static AlertStatus _parseStatus(String? status) {
    switch (status) {
      case 'sent':
        return AlertStatus.sent;
      case 'dismissed':
        return AlertStatus.dismissed;
      case 'claimed':
        return AlertStatus.claimed;
      default:
        return AlertStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'message': message,
        'benefit_id': benefitId,
        'merchant_id': merchantId,
        'discount': discountPercent,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'priority': priority,
        'redemption_code': redemptionCode,
      };
}
