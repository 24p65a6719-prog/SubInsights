import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_theme.dart';

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.nearbyMerchants.isEmpty) {
          return _buildEmptyState(context, state);
        }

        return Column(
          children: [
            // Location info bar
            _buildLocationBar(context, state),
            // Nearby merchants list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: state.nearbyMerchants.length,
                itemBuilder: (context, index) {
                  final nm = state.nearbyMerchants[index];
                  final benefits =
                      state.dataService.getBenefitsAtMerchant(nm.merchant);
                  final userBenefits = benefits
                      .where((b) => state.userSubscriptions
                          .any((s) => s.associatedBenefits.contains(b.id)))
                      .toList();
                  final color =
                      AppTheme.getCategoryColor(nm.merchant.category);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/merchant',
                        arguments: nm.merchant,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    AppTheme.getCategoryIcon(
                                        nm.merchant.category),
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nm.merchant.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 12,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            nm.merchant.city,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
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
                                        color: nm.isInDwellZone
                                            ? AppTheme.successColor
                                                .withValues(alpha: 0.1)
                                            : Colors.orange
                                                .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        nm.distanceLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: nm.isInDwellZone
                                              ? AppTheme.successColor
                                              : Colors.orange,
                                        ),
                                      ),
                                    ),
                                    if (nm.isInDwellZone)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          '📍 You\'re here',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.successColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (benefits.isNotEmpty || userBenefits.isNotEmpty) ...[
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 14, color: color),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${benefits.length} offer${benefits.length != 1 ? 's' : ''} available',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (userBenefits.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${userBenefits.length} for you!',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  const Text(
                                    'Tap to validate →',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Show first user benefit preview
                              if (userBenefits.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor
                                          .withValues(alpha: 0.05),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.accentColor
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stars,
                                            size: 16,
                                            color: AppTheme.accentColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            userBenefits.first.title,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            userBenefits.first
                                                .discountLabel,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationBar(BuildContext context, AppState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                state.locationSimulated
                    ? Icons.gps_off
                    : Icons.gps_fixed,
                color: state.locationSimulated
                    ? Colors.orange
                    : AppTheme.successColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                state.locationSimulated
                    ? 'Simulated Location'
                    : 'Live Location Active',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: state.locationSimulated
                      ? Colors.orange
                      : AppTheme.successColor,
                ),
              ),
              const Spacer(),
              Text(
                '${state.nearbyMerchants.length} places nearby',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: state.cities
                  .where((c) => c != 'All')
                  .map((city) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(city,
                              style: const TextStyle(fontSize: 11)),
                          onPressed: () =>
                              state.simulateLocationAtCity(city),
                          avatar: const Icon(Icons.location_on, size: 14),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No nearby places detected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate a location to see nearby offers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: state.cities
                  .where((c) => c != 'All')
                  .map((city) => ElevatedButton.icon(
                        onPressed: () =>
                            state.simulateLocationAtCity(city),
                        icon: const Icon(Icons.location_on, size: 16),
                        label: Text(city),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
