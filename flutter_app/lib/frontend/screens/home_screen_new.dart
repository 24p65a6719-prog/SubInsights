import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/offer_badge.dart';

class HomeScreenNew extends StatelessWidget {
  const HomeScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final userBenefits = appState.userActiveBenefits;
        final nearby = appState.nearbyMerchants;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroHeader(appState, nearby.length, userBenefits.length),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Nearby Offers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            if (nearby.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Text(
                    'No nearby offers found.',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _buildNearbyCarousel(context, appState),
                ),
              ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Top Deals For You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildDealTile(context, appState, index),
                childCount: userBenefits.length > 8 ? 8 : userBenefits.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildHeroHeader(AppState state, int nearbyCount, int benefitCount) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.insights_rounded, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'SubInsights',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: '$nearbyCount',
                    label: 'Nearby',
                    icon: Icons.location_on_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    value: '$benefitCount',
                    label: 'Offers',
                    icon: Icons.local_offer_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    value: '${state.userSubscriptions.length}',
                    label: 'Subs',
                    icon: Icons.card_membership_rounded,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyCarousel(BuildContext context, AppState state) {
    final nearby = state.nearbyMerchants.take(10).toList();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (_, index) {
        final nm = nearby[index];
        final benefits = state.dataService.getBenefitsAtMerchant(nm.merchant);
        final catColor = AppColors.getCategoryColor(nm.merchant.category);
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/merchant', arguments: nm.merchant),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        AppColors.getCategoryIcon(nm.merchant.category),
                        color: catColor,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    OfferBadge(
                      label: nm.distanceLabel,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      textColor: AppColors.primary,
                      fontSize: 11,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  nm.merchant.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  '${benefits.length} offer${benefits.length == 1 ? '' : 's'} available',
                  style: TextStyle(
                    fontSize: 12,
                    color: benefits.isNotEmpty ? AppColors.success : AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemCount: nearby.length,
    );
  }

  Widget _buildDealTile(BuildContext context, AppState state, int index) {
    if (index >= state.userActiveBenefits.length) return const SizedBox.shrink();
    final benefit = state.userActiveBenefits[index];
    final merchants = state.dataService.getMerchantsForBenefit(benefit);
    final merchantName = merchants.isNotEmpty ? merchants.first.name : '—';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.mintGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                benefit.discountLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'at $merchantName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            benefit.validityStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: benefit.isValid ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
