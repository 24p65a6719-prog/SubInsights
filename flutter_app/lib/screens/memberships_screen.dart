import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your Memberships',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${state.activeMemberships} active memberships',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ...state.memberships.map((membership) {
          final benefits = state.benefits
              .where(
                  (b) => membership.associatedBenefits.contains(b.id))
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _categoryColor(membership.category)
                        .withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _categoryColor(membership.category)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _categoryIcon(membership.category),
                          color: _categoryColor(membership.category),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(membership.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(membership.description,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Active',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                // Benefits
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${membership.associatedBenefits.length} Associated Benefits',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      if (benefits.isEmpty)
                        const Text('No matching benefits found',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12))
                      else
                        ...benefits.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  b.isVerified
                                      ? Icons.verified
                                      : Icons.help_outline,
                                  size: 16,
                                  color: b.isVerified
                                      ? AppColors.success
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(b.title,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _discountColor(
                                            b.discountPercent)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${b.discountPercent}%',
                                    style: TextStyle(
                                      color: _discountColor(
                                          b.discountPercent),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Category: ${membership.category.toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const Spacer(),
                          if (membership.daysUntilExpiry != null)
                            Text(
                              '${membership.daysUntilExpiry} days left',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'professional':
        return AppColors.primary;
      case 'credit_card':
        return AppColors.secondary;
      case 'academic':
        return AppColors.gradientEnd;
      default:
        return Colors.teal;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'professional':
        return Icons.engineering;
      case 'credit_card':
        return Icons.credit_card;
      case 'academic':
        return Icons.school;
      default:
        return Icons.card_membership;
    }
  }

  Color _discountColor(int percent) {
    if (percent >= 30) return const Color(0xFFFFD700);
    if (percent >= 15) return AppColors.secondary;
    return AppColors.success;
  }
}
