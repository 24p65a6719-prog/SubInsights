import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/benefit_card.dart';

class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen> {
  String _filter = 'all'; // all, verified, high

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    var filtered = state.benefits;
    if (_filter == 'verified') {
      filtered = filtered.where((b) => b.isVerified).toList();
    } else if (_filter == 'high') {
      filtered = filtered.where((b) => b.discountPercent >= 15).toList();
    }

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _chip('All', 'all'),
              const SizedBox(width: 8),
              _chip('Verified', 'verified'),
              const SizedBox(width: 8),
              _chip('High Value', 'high'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.verified, color: AppColors.primary),
                tooltip: 'Verify All Benefits',
                onPressed: () => state.verifyAllBenefits(),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No benefits found',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final b = filtered[index];
                    final merchant = state.dataService.merchants
                        .where((m) => b.eligibleMerchants.contains(m.id))
                        .toList();
                    final first =
                        merchant.isNotEmpty ? merchant.first : null;
                    return BenefitCard(
                      benefit: b,
                      merchant: first,
                      distance:
                          first?.distanceTo(state.userLocation),
                      onClaim: () {
                        final code =
                            state.dataService.generateRedemptionCode();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Claimed! Redemption Code: $code'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
    );
  }
}
