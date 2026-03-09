import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/merchant.dart';
import '../models/benefit.dart';
import '../services/offer_validation_service.dart';
import '../utils/app_theme.dart';

class MerchantDetailScreen extends StatelessWidget {
  final Merchant merchant;

  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final benefits = state.dataService.getBenefitsAtMerchant(merchant);
        final subscriptions =
            state.dataService.getSubscriptionsForMerchant(merchant);
        final validations = state.validateOffersAtMerchant(merchant);
        final color = AppTheme.getCategoryColor(merchant.category);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App bar with merchant info
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: color,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    merchant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppTheme.getCategoryIcon(merchant.category),
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppTheme.formatCategory(merchant.category),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Merchant info
              SliverToBoxAdapter(
                child: _buildMerchantInfo(context, state),
              ),

              // Offers section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        '🎁 Available Offers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${benefits.length} offers',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Benefits list with validation
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final validation = validations.length > index
                        ? validations[index]
                        : null;
                    final benefit = validation?.benefit ?? benefits[index];
                    return _buildOfferCard(
                        context, state, benefit, validation);
                  },
                  childCount: validations.isNotEmpty
                      ? validations.length
                      : benefits.length,
                ),
              ),

              // Subscriptions that apply
              if (subscriptions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      '💳 Related Subscriptions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildRelatedSubscription(context, state, subscriptions[index]),
                  childCount: subscriptions.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMerchantInfo(BuildContext context, AppState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating
            Row(
              children: [
                ...List.generate(5, (i) {
                  final filled = i < merchant.averageReviewRating.floor();
                  final half = i == merchant.averageReviewRating.floor() &&
                      merchant.averageReviewRating % 1 >= 0.5;
                  return Icon(
                    half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${merchant.averageReviewRating}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  ' (${merchant.totalReviews} reviews)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Address
            _buildInfoRow(Icons.location_on, merchant.address),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_city, merchant.city),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, merchant.phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.language, merchant.website),
            const SizedBox(height: 12),
            // Distance (if available)
            Consumer<AppState>(
              builder: (context, state, _) {
                final nearby = state.nearbyMerchants
                    .where((nm) => nm.merchant.id == merchant.id)
                    .toList();
                if (nearby.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me,
                            color: AppTheme.secondaryColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Distance: ${nearby.first.distanceLabel}',
                          style: const TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (nearby.first.isInDwellZone) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You\'re here!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, AppState state, Benefit benefit,
      ValidationResult? validation) {
    final isValid = validation?.isValid ?? benefit.isValid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showValidationDetail(context, benefit, validation),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isValid
                          ? AppTheme.successColor.withValues(alpha: 0.1)
                          : AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isValid ? Icons.verified : Icons.warning_amber,
                      color: isValid
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          benefit.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isValid
                              ? AppTheme.accentColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          benefit.discountLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isValid ? '✅ Verified' : '❌ Invalid',
                        style: TextStyle(
                          fontSize: 10,
                          color: isValid
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (validation != null) ...[
                const Divider(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isValid
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isValid ? Icons.check_circle : Icons.info_outline,
                        size: 16,
                        color: isValid
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isValid
                              ? 'This offer is valid for you at this location!'
                              : 'This offer may not apply to you here. Tap for details.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isValid
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showValidationDetail(
      BuildContext context, Benefit benefit, ValidationResult? validation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
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
                  const SizedBox(height: 20),
                  // Offer header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          benefit.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: benefit.isValid
                              ? AppTheme.accentColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          benefit.discountLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    benefit.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Validity info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                            'Status', benefit.validityStatus),
                        _buildDetailRow(
                            'Valid From', benefit.validFrom),
                        _buildDetailRow(
                            'Valid Until', benefit.validUntil),
                        if (benefit.minPurchaseInr > 0)
                          _buildDetailRow('Min. Purchase',
                              '₹${benefit.minPurchaseInr}'),
                        if (benefit.maxDiscountInr > 0)
                          _buildDetailRow('Max Discount',
                              '₹${benefit.maxDiscountInr}'),
                        _buildDetailRow(
                            'Usage Limit',
                            benefit.usageLimit == -1
                                ? 'Unlimited'
                                : '${benefit.usageLimit} times'),
                      ],
                    ),
                  ),

                  // Validation notes
                  if (validation != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '🔍 Verification Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...validation.validationNotes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedSubscription(
      BuildContext context, AppState state, subscription) {
    final color = AppTheme.parseColor(subscription.color);
    final isSubscribed = state.isSubscribed(subscription.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            AppTheme.getIconFromString(subscription.icon),
            color: color,
          ),
        ),
        title: Text(
          subscription.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(subscription.provider,
            style: const TextStyle(fontSize: 12)),
        trailing: isSubscribed
            ? const Chip(
                label: Text('Subscribed',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.successColor)),
                backgroundColor: Color(0xFFE8F5E9),
                side: BorderSide.none,
              )
            : TextButton(
                onPressed: () => state.addSubscription(subscription.id),
                child: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}
