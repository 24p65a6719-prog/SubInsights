import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/dwell_timer_widget.dart';
import '../widgets/offer_badge.dart';

class NearbyScreenNew extends StatelessWidget {
  const NearbyScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final nearby = appState.nearbyMerchants;
        final pos = appState.locationService.currentPosition;

        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pos == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_rounded,
                    size: 56, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text('No location set',
                    style: TextStyle(fontSize: 16, color: AppColors.textHint)),
                const SizedBox(height: 8),
                const Text(
                  'Use the simulator on the Home tab\nto set a location',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ],
            ),
          );
        }

        if (nearby.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 56, color: AppColors.textHint),
                const SizedBox(height: 12),
                const Text('No merchants nearby',
                    style: TextStyle(fontSize: 16, color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: nearby.length,
          itemBuilder: (context, i) {
            final nm = nearby[i];
            final benefits =
                appState.dataService.getBenefitsAtMerchant(nm.merchant);
            final userBenefits = benefits
                .where((b) => appState.userSubscriptions
                    .any((s) => s.associatedBenefits.contains(b.id)))
                .toList();
            final catColor =
                AppColors.getCategoryColor(nm.merchant.category);

            return GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/merchant', arguments: nm.merchant),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: nm.isInDwellZone
                      ? Border.all(color: AppColors.success, width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: nm.isInDwellZone
                          ? AppColors.success.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon / dwell timer
                    if (nm.isInDwellZone)
                      DwellTimerWidget(
                        elapsed: nm.dwellDuration,
                        threshold: const Duration(minutes: 2),
                        triggered: nm.hasDwelled,
                        size: 52,
                      )
                    else
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          AppColors.getCategoryIcon(nm.merchant.category),
                          color: catColor,
                          size: 26,
                        ),
                      ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  nm.merchant.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (nm.isInDwellZone) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "You're here!",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              OfferBadge(
                                label: nm.distanceLabel,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                textColor: AppColors.primary,
                                fontSize: 11,
                              ),
                              const SizedBox(width: 8),
                              if (userBenefits.isNotEmpty)
                                OfferBadge(
                                  label:
                                      '${userBenefits.length} offer${userBenefits.length > 1 ? 's' : ''}',
                                  backgroundColor:
                                      AppColors.success.withValues(alpha: 0.1),
                                  textColor: AppColors.success,
                                  fontSize: 11,
                                ),
                            ],
                          ),
                          if (nm.hasDwelled) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.notifications_active,
                                      size: 16, color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Notification sent! ${userBenefits.length} offer${userBenefits.length != 1 ? "s" : ""} available',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
