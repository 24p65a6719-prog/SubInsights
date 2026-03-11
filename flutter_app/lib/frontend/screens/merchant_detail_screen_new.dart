import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/merchant.dart';
import '../../services/offer_validation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/offer_badge.dart';

class MerchantDetailScreenNew extends StatelessWidget {
  final Merchant merchant;
  const MerchantDetailScreenNew({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.getCategoryColor(merchant.category);

    return Consumer<AppState>(
      builder: (context, appState, _) {
        final validations = appState.validateOffersAtMerchant(merchant);
        final subs =
            appState.dataService.getSubscriptionsForMerchant(merchant);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Collapsing header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                stretch: true,
                backgroundColor: catColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [catColor, catColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              AppColors.getCategoryIcon(merchant.category),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            merchant.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmt(merchant.category)} • ${merchant.city}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Info section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating row
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final fill = merchant.averageReviewRating - i;
                            return Icon(
                              fill >= 1
                                  ? Icons.star_rounded
                                  : fill >= 0.5
                                      ? Icons.star_half_rounded
                                      : Icons.star_border_rounded,
                              size: 22,
                              color: const Color(0xFFFFB300),
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${merchant.averageReviewRating.toStringAsFixed(1)} (${merchant.totalReviews} reviews)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Address
                      _infoRow(Icons.location_on_outlined, merchant.address),
                      const SizedBox(height: 8),
                      _infoRow(Icons.phone_outlined, merchant.phone),
                      const SizedBox(height: 8),
                      _infoRow(Icons.language_outlined, merchant.website),
                      const SizedBox(height: 20),

                      // Offers
                      Row(
                        children: [
                          const Text(
                            'Available Offers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OfferBadge(label: '${validations.length}'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (validations.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No offers at this merchant',
                              style:
                                  TextStyle(color: AppColors.textHint),
                            ),
                          ),
                        )
                      else
                        ...validations.map((v) => _offerCard(v)),

                      const SizedBox(height: 24),

                      // Related subscriptions
                      if (subs.isNotEmpty) ...[
                        const Text(
                          'Related Subscriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...subs.map((s) {
                          final subColor = AppColors.fromHex(s.color);
                          final isOwned = appState.isSubscribed(s.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isOwned
                                  ? Border.all(
                                      color: AppColors.success, width: 1.5)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: subColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    AppColors.getCategoryIcon(s.category),
                                    color: subColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      Text(s.provider,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textHint)),
                                    ],
                                  ),
                                ),
                                if (isOwned)
                                  const OfferBadge(
                                    label: 'OWNED',
                                    backgroundColor: AppColors.success,
                                  )
                                else
                                  TextButton(
                                    onPressed: () =>
                                        appState.addSubscription(s.id),
                                    child: const Text('Add',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _offerCard(ValidationResult v) {
    final statusIcon = switch (v.status) {
      'valid' => Icons.check_circle_rounded,
      'expired' => Icons.cancel_rounded,
      _ => Icons.warning_amber_rounded,
    };
    final statusColor = switch (v.status) {
      'valid' => AppColors.success,
      'expired' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(statusIcon, color: statusColor, size: 24),
        title: Text(
          v.benefit.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            OfferBadge(
              label: v.benefit.discountLabel,
              backgroundColor: statusColor.withValues(alpha: 0.1),
              textColor: statusColor,
              fontSize: 11,
            ),
            const SizedBox(width: 8),
            Text(
              v.status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
        shape: const Border(),
        children: v.validationNotes
            .map((note) => Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _fmt(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) =>
          w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
