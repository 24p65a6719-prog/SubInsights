import 'package:flutter/material.dart';
import '../models/benefit.dart';
import '../models/merchant.dart';
import '../theme.dart';

class BenefitCard extends StatelessWidget {
  final Benefit benefit;
  final Merchant? merchant;
  final double? distance;
  final VoidCallback? onClaim;

  const BenefitCard({
    super.key,
    required this.benefit,
    this.merchant,
    this.distance,
    this.onClaim,
  });

  Color get _borderColor {
    if (benefit.discountPercent >= 30) return const Color(0xFFFFD700);
    if (benefit.discountPercent >= 15) return AppColors.secondary;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: _borderColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Discount badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${benefit.discountPercent}% OFF',
                      style: TextStyle(
                        color: _borderColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Verification badge
                  if (benefit.isVerified) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '${(benefit.verificationScore * 100).toInt()}%',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline,
                              size: 14, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text('Unverified',
                              style: TextStyle(
                                  color: AppColors.warning, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (distance != null)
                    Text(
                      '${distance!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: distance! < 2
                            ? AppColors.success
                            : distance! < 5
                                ? AppColors.secondary
                                : AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(benefit.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(benefit.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              if (merchant != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(_categoryIcon(merchant!.category),
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(merchant!.name,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      merchant!.averageReviewRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onClaim,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Claim Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Benefit saved!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_border, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'hotel':
        return Icons.hotel;
      case 'airline':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      case 'retail':
        return Icons.shopping_bag;
      default:
        return Icons.store;
    }
  }
}
