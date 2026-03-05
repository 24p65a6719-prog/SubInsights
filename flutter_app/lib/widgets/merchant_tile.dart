import 'package:flutter/material.dart';
import '../models/merchant.dart';
import '../theme.dart';

class MerchantTile extends StatelessWidget {
  final Merchant merchant;
  final double distance;

  const MerchantTile({
    super.key,
    required this.merchant,
    required this.distance,
  });

  Color get _distanceColor {
    if (distance < 2) return AppColors.success;
    if (distance < 5) return AppColors.secondary;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(_categoryIcon, color: _categoryColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchant.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(merchant.address,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          '${merchant.averageReviewRating} (${merchant.totalReviews})',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.card_giftcard,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Text(
                          '${merchant.benefitsOffered.length} benefits',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _distanceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: _distanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    merchant.category.toUpperCase(),
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _categoryColor {
    switch (merchant.category) {
      case 'hotel':
        return AppColors.primary;
      case 'airline':
        return const Color(0xFF00BCD4);
      case 'restaurant':
        return AppColors.secondary;
      default:
        return Colors.teal;
    }
  }

  IconData get _categoryIcon {
    switch (merchant.category) {
      case 'hotel':
        return Icons.hotel;
      case 'airline':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      case 'retail':
        return Icons.shopping_bag;
      default:
        return Icons.storefront;
    }
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(_categoryIcon, color: _categoryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(merchant.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(Icons.location_on, merchant.address),
            _DetailRow(Icons.phone, merchant.phone),
            _DetailRow(
                Icons.star, '${merchant.averageReviewRating} / 5.0 (${merchant.totalReviews} reviews)'),
            _DetailRow(Icons.card_giftcard,
                '${merchant.benefitsOffered.length} benefits available'),
            _DetailRow(Icons.near_me, '${distance.toStringAsFixed(2)} km away'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
