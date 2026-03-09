import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_theme.dart';
import '../models/merchant.dart';
import 'merchant_detail_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Column(
          children: [
            // Filters
            _buildFilters(context, state),
            // Merchant list
            Expanded(
              child: state.filteredMerchants.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: state.filteredMerchants.length,
                      itemBuilder: (context, index) {
                        return _buildMerchantCard(
                          context,
                          state,
                          state.filteredMerchants[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, AppState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: state.cities
                  .map((city) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(city, style: const TextStyle(fontSize: 12)),
                          selected: state.selectedCity == city,
                          onSelected: (_) => state.setCity(city),
                          selectedColor:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: state.selectedCity == city
                                ? AppTheme.primaryColor
                                : Colors.grey.shade700,
                            fontWeight: state.selectedCity == city
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Category filter
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: state.categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: state.selectedCategory == cat,
                          onSelected: (_) => state.setCategory(cat),
                          selectedColor:
                              AppTheme.secondaryColor.withValues(alpha: 0.15),
                          avatar: cat != 'All'
                              ? Icon(
                                  AppTheme.getCategoryIcon(
                                      cat.toLowerCase().replaceAll(' ', '_')),
                                  size: 16,
                                )
                              : null,
                          labelStyle: TextStyle(
                            color: state.selectedCategory == cat
                                ? AppTheme.secondaryColor
                                : Colors.grey.shade700,
                            fontWeight: state.selectedCategory == cat
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantCard(
      BuildContext context, AppState state, Merchant merchant) {
    final benefits = state.dataService.getBenefitsAtMerchant(merchant);
    final activeBenefits = benefits.where((b) => b.isValid).toList();
    final color = AppTheme.getCategoryColor(merchant.category);
    final icon = AppTheme.getCategoryIcon(merchant.category);

    // Check if user has any applicable offers
    final userBenefits = benefits
        .where((b) =>
            state.userSubscriptions.any((s) => s.associatedBenefits.contains(b.id)))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantDetailScreen(merchant: merchant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppTheme.formatCategory(merchant.category),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(
                              ' ${merchant.averageReviewRating}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${merchant.city} • ${merchant.address}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (activeBenefits.isNotEmpty) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.local_offer,
                        size: 16, color: AppTheme.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      '${activeBenefits.length} active offer${activeBenefits.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (userBenefits.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${userBenefits.length} for you',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No merchants found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
