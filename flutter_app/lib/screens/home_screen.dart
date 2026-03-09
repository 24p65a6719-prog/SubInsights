import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_theme.dart';
import '../models/merchant.dart';
import 'merchant_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return CustomScrollView(
          slivers: [
            // Header with location simulator
            SliverToBoxAdapter(child: _buildLocationHeader(context, state)),
            // Quick stats
            SliverToBoxAdapter(child: _buildQuickStats(context, state)),
            // Nearby offers section
            if (state.nearbyMerchants.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSectionTitle(context, '📍 Nearby Offers'),
              ),
            if (state.nearbyMerchants.isNotEmpty)
              SliverToBoxAdapter(child: _buildNearbyCarousel(context, state)),
            // Active benefits count by category
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, '🎯 Explore by Category'),
            ),
            SliverToBoxAdapter(child: _buildCategoryGrid(context, state)),
            // Recent offers
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, '🔥 Your Active Offers'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final benefit = state.userActiveBenefits[index];
                  final merchants =
                      state.dataService.getMerchantsForBenefit(benefit);
                  return _buildOfferCard(context, state, benefit, merchants);
                },
                childCount: state.userActiveBenefits.length.clamp(0, 5),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  Widget _buildLocationHeader(BuildContext context, AppState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                state.locationSimulated
                    ? 'Simulated Location'
                    : 'Live Location',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.nearbyMerchants.length} nearby',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Simulate your location:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: state.cities
                  .where((c) => c != 'All')
                  .map((city) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(city,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white)),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          side: BorderSide.none,
                          onPressed: () =>
                              state.simulateLocationAtCity(city),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            context,
            icon: Icons.card_membership,
            label: 'Subscriptions',
            value: '${state.userSubscriptions.length}',
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            icon: Icons.local_offer,
            label: 'Active Offers',
            value: '${state.userActiveBenefits.length}',
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            icon: Icons.location_on,
            label: 'Nearby',
            value: '${state.nearbyMerchants.length}',
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildNearbyCarousel(BuildContext context, AppState state) {
    final nearby = state.nearbyMerchants.take(8).toList();
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: nearby.length,
        itemBuilder: (context, index) {
          final nm = nearby[index];
          final benefits =
              state.dataService.getBenefitsAtMerchant(nm.merchant);
          final catColor =
              AppTheme.getCategoryColor(nm.merchant.category);

          return GestureDetector(
            onTap: () => _openMerchantDetail(context, nm.merchant),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          AppTheme.getCategoryIcon(nm.merchant.category),
                          color: catColor,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: nm.isInDwellZone
                              ? AppTheme.successColor.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          nm.distanceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: nm.isInDwellZone
                                ? AppTheme.successColor
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nm.merchant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nm.merchant.city,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.local_offer,
                          size: 14, color: catColor),
                      const SizedBox(width: 4),
                      Text(
                        '${benefits.length} offer${benefits.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, AppState state) {
    final categoryData = <String, int>{};
    for (final m in state.merchants) {
      categoryData[m.category] = (categoryData[m.category] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: categoryData.entries.map((entry) {
          final cat = entry.key;
          final count = entry.value;
          final color = AppTheme.getCategoryColor(cat);
          final icon = AppTheme.getCategoryIcon(cat);

          return GestureDetector(
            onTap: () {
              state.setCategory(AppTheme.formatCategory(cat));
              // Switch to explore tab
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null) {
                // Navigate by triggering the parent
              }
            },
            child: Container(
              width: (MediaQuery.of(context).size.width - 52) / 3,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    AppTheme.formatCategory(cat),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count places',
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, AppState state, benefit,
      List<Merchant> merchants) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: merchants.isNotEmpty
            ? () => _openMerchantDetail(context, merchants.first)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: benefit.isValid
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  benefit.isValid ? Icons.local_offer : Icons.timer_off,
                  color: benefit.isValid
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
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
                        fontSize: 14,
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
                    if (merchants.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'at ${merchants.map((m) => m.name).join(', ')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: benefit.isValid
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
            ],
          ),
        ),
      ),
    );
  }

  void _openMerchantDetail(BuildContext context, Merchant merchant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantDetailScreen(merchant: merchant),
      ),
    );
  }
}
