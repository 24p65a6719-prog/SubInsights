import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../providers/app_state.dart';
import '../theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pending =
        state.alerts.where((a) => a.status == AlertStatus.pending).toList();
    final claimed =
        state.alerts.where((a) => a.status == AlertStatus.claimed).toList();
    final dismissed =
        state.alerts.where((a) => a.status == AlertStatus.dismissed).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary row
        Row(
          children: [
            _StatChip(
              icon: Icons.notifications_active,
              label: '${pending.length} Pending',
              color: AppColors.secondary,
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.check_circle,
              label: '${claimed.length} Claimed',
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.cancel,
              label: '${dismissed.length} Dismissed',
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (pending.isNotEmpty) ...[
          Text('Pending Alerts',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...pending.map((a) => _AlertCard(alert: a)),
          const SizedBox(height: 20),
        ],

        if (claimed.isNotEmpty) ...[
          Text('Claimed Benefits',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...claimed.map((a) => _AlertCard(alert: a)),
          const SizedBox(height: 20),
        ],

        if (dismissed.isNotEmpty) ...[
          Text('Dismissed',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...dismissed.map((a) => _AlertCard(alert: a)),
        ],

        if (state.alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_off,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No alerts yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Update your location to discover nearby benefits',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final BenefitAlert alert;
  const _AlertCard({required this.alert});

  Color get _priorityColor {
    switch (alert.priority) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.secondary;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert.priority.toUpperCase(),
                    style: TextStyle(
                        color: _priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${alert.discountPercent}% OFF',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (alert.status == AlertStatus.claimed)
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                if (alert.status == AlertStatus.dismissed)
                  const Icon(Icons.cancel, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(alert.message,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (alert.redemptionCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${alert.redemptionCode}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
            if (alert.status == AlertStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.claimAlert(alert.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Claimed! Code: ${alert.redemptionCode}'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Claim Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => state.dismissAlert(alert.id),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
