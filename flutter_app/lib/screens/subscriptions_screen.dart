import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_theme.dart';
import '../models/subscription.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return CustomScrollView(
          slivers: [
            // My subscriptions
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                '✅ My Subscriptions',
                '${state.userSubscriptions.length} active',
              ),
            ),
            if (state.userSubscriptions.isEmpty)
              SliverToBoxAdapter(child: _buildEmptySubscriptions()),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSubscriptionCard(
                    context, state, state.userSubscriptions[index], true),
                childCount: state.userSubscriptions.length,
              ),
            ),
            // Available subscriptions
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                '➕ Available Subscriptions',
                '${state.availableSubscriptions.length} available',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSubscriptionCard(
                    context, state, state.availableSubscriptions[index], false),
                childCount: state.availableSubscriptions.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, AppState state,
      Subscription subscription, bool isSubscribed) {
    final color = AppTheme.parseColor(subscription.color);
    final benefits = state.dataService.getBenefitsForSubscription(subscription);
    final activeBenefits = benefits.where((b) => b.isValid).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSubscriptionDetail(
            context, state, subscription, isSubscribed),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppTheme.getIconFromString(subscription.icon),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subscription.provider,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.getCategoryColor(
                                    subscription.category)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppTheme.formatCategory(subscription.category),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getCategoryColor(
                                  subscription.category),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.local_offer,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          '${activeBenefits.length} benefit${activeBenefits.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSubscribed)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.errorColor),
                  onPressed: () => _confirmRemove(context, state, subscription),
                  tooltip: 'Remove subscription',
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: AppTheme.successColor, size: 28),
                  onPressed: () => state.addSubscription(subscription.id),
                  tooltip: 'Add subscription',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySubscriptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.card_membership, size: 48, color: Colors.blue.shade300),
          const SizedBox(height: 12),
          const Text(
            'No subscriptions yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Add subscriptions below to see offers near you',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDetail(BuildContext context, AppState state,
      Subscription subscription, bool isSubscribed) {
    final color = AppTheme.parseColor(subscription.color);
    final benefits = state.dataService.getBenefitsForSubscription(subscription);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          AppTheme.getIconFromString(subscription.icon),
                          color: color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscription.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              subscription.provider,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    subscription.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Expires: ${subscription.expiryDate}',
                        style: TextStyle(
                          fontSize: 13,
                          color: subscription.isExpiringSoon
                              ? AppTheme.warningColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Benefits Included:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...benefits.map((benefit) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: benefit.isValid
                              ? AppTheme.successColor.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: benefit.isValid
                                ? AppTheme.successColor.withValues(alpha: 0.2)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              benefit.isValid
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: benefit.isValid
                                  ? AppTheme.successColor
                                  : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    benefit.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    benefit.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (benefit.discountPercent > 0 ||
                                benefit.maxDiscountInr > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: benefit.isValid
                                      ? AppTheme.accentColor
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  benefit.discountLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isSubscribed) {
                          state.removeSubscription(subscription.id);
                        } else {
                          state.addSubscription(subscription.id);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSubscribed ? AppTheme.errorColor : color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSubscribed ? 'Remove Subscription' : 'Add Subscription',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRemove(
      BuildContext context, AppState state, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Subscription?'),
        content:
            Text('Remove "${subscription.name}" from your subscriptions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              state.removeSubscription(subscription.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
