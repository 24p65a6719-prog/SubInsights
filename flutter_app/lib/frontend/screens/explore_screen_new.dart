import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/merchant.dart';
import '../theme/app_colors.dart';
import '../widgets/merchant_card.dart';
import '../widgets/category_chip.dart';

class ExploreScreenNew extends StatefulWidget {
  const ExploreScreenNew({super.key});

  @override
  State<ExploreScreenNew> createState() => _ExploreScreenNewState();
}

class _ExploreScreenNewState extends State<ExploreScreenNew> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _gridView = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final cities = appState.cities;
        final categories = appState.categories;

        // Filter
        List<Merchant> merchants = appState.filteredMerchants;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          merchants = merchants
              .where((m) =>
                  m.name.toLowerCase().contains(q) ||
                  m.category.toLowerCase().contains(q) ||
                  m.city.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search merchants...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textHint),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _gridView
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                        onPressed: () =>
                            setState(() => _gridView = !_gridView),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // City filter
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final city = cities[i];
                  return CategoryChip(
                    label: city,
                    selected: appState.selectedCity == city,
                    onTap: () => appState.setCity(city),
                    icon: Icons.location_city,
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Category filter
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return CategoryChip(
                    label: cat,
                    selected: appState.selectedCategory == cat,
                    onTap: () => appState.setCategory(cat),
                    color: cat == 'All'
                        ? null
                        : AppColors.getCategoryColor(cat.toLowerCase()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${merchants.length} merchant${merchants.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // List / Grid
            Expanded(
              child: merchants.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('No merchants found',
                              style: TextStyle(color: AppColors.textHint)),
                        ],
                      ),
                    )
                  : _gridView
                      ? GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: merchants.length,
                          itemBuilder: (_, i) =>
                              _gridCard(merchants[i], appState),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: merchants.length,
                          itemBuilder: (_, i) {
                            final m = merchants[i];
                            final offers = appState.dataService
                                .getBenefitsAtMerchant(m);
                            return MerchantCard(
                              name: m.name,
                              category: m.category,
                              city: m.city,
                              rating: m.averageReviewRating,
                              offerCount: offers.length,
                              onTap: () => Navigator.pushNamed(
                                  context, '/merchant',
                                  arguments: m),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _gridCard(Merchant m, AppState appState) {
    final catColor = AppColors.getCategoryColor(m.category);
    final offers = appState.dataService.getBenefitsAtMerchant(m);
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/merchant', arguments: m),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(AppColors.getCategoryIcon(m.category),
                  color: catColor, size: 24),
            ),
            const Spacer(),
            Text(
              m.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: Color(0xFFFFB300)),
                const SizedBox(width: 2),
                Text(m.averageReviewRating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (offers.isNotEmpty)
                  Text('${offers.length} offer${offers.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 2),
            Text(m.city,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
