import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/merchant_tile.dart';

class MerchantsScreen extends StatelessWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nearby = state.nearbyMerchants;
    final allMerchants = state.merchants;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Map-like header card
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
            ),
          ),
          child: Stack(
            children: [
              // Grid lines
              ...List.generate(5, (i) {
                final y = 40.0 * i;
                return Positioned(
                  top: y,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                );
              }),
              // User location marker
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_pin_circle,
                        color: AppColors.primary, size: 40),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${state.userLocation.latitude.toStringAsFixed(4)}, '
                        '${state.userLocation.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              // Merchant markers
              ...nearby.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                final dist = m.distanceTo(state.userLocation);
                final color = dist < 2
                    ? AppColors.success
                    : dist < 5
                        ? AppColors.secondary
                        : AppColors.danger;
                // Spread markers around center
                final offsets = [
                  const Offset(60, -50),
                  const Offset(-70, -40),
                  const Offset(50, 50),
                  const Offset(-60, 60),
                ];
                final offset = offsets[i % offsets.length];
                return Positioned(
                  left: 100 + offset.dx,
                  top: 100 + offset.dy,
                  child: Tooltip(
                    message: '${m.name} (${dist.toStringAsFixed(1)}km)',
                    child: Icon(Icons.location_on, color: color, size: 28),
                  ),
                );
              }),
              // Legend
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendItem(color: AppColors.success, label: '< 2km'),
                      _LegendItem(color: AppColors.secondary, label: '2-5km'),
                      _LegendItem(color: AppColors.danger, label: '> 5km'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text('Nearby Merchants (${nearby.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (nearby.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No merchants within range',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...nearby.map(
            (m) => MerchantTile(
              merchant: m,
              distance: m.distanceTo(state.userLocation),
            ),
          ),

        const SizedBox(height: 24),
        Text('All Merchants (${allMerchants.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...allMerchants.map(
          (m) => MerchantTile(
            merchant: m,
            distance: m.distanceTo(state.userLocation),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
