import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/benefit_card.dart';
import '../widgets/merchant_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return RefreshIndicator(
      onRefresh: () async {
        state.updateLocation(
          state.userLocation.latitude,
          state.userLocation.longitude,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Location Input ───
          _LocationBar(state: state),
          const SizedBox(height: 16),

          // ─── Stats Grid ───
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active Memberships',
                  value: '${state.activeMemberships}',
                  icon: Icons.card_membership,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Verified Benefits',
                  value: '${state.verifiedBenefits}',
                  icon: Icons.verified,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Nearby Merchants',
                  value: '${state.nearbyMerchantCount}',
                  icon: Icons.storefront,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Est. Annual Savings',
                  value: '\$${state.estimatedAnnualSavings.toStringAsFixed(0)}',
                  icon: Icons.savings,
                  color: AppColors.gradientEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Nearby Merchants ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nearby Merchants',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.nearbyMerchants.take(3).map(
                (m) => MerchantTile(
                  merchant: m,
                  distance: m.distanceTo(state.userLocation),
                ),
              ),

          const SizedBox(height: 24),

          // ─── Benefits ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available Benefits',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => state.verifyAllBenefits(),
                icon: const Icon(Icons.verified, size: 18),
                label: const Text('Verify All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.benefits.map(
            (b) {
              final merchant = state.dataService.merchants
                  .where((m) => b.eligibleMerchants.contains(m.id))
                  .toList();
              final firstMerchant =
                  merchant.isNotEmpty ? merchant.first : null;
              return BenefitCard(
                benefit: b,
                merchant: firstMerchant,
                distance: firstMerchant?.distanceTo(state.userLocation),
                onClaim: () {
                  final code = state.dataService.generateRedemptionCode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Claimed! Redemption Code: $code'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final AppState state;
  const _LocationBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final latCtl = TextEditingController(
        text: state.userLocation.latitude.toStringAsFixed(4));
    final lonCtl = TextEditingController(
        text: state.userLocation.longitude.toStringAsFixed(4));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.my_location, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: latCtl,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: lonCtl,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latCtl.text);
                final lon = double.tryParse(lonCtl.text);
                if (lat != null && lon != null) {
                  state.updateLocation(lat, lon);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
