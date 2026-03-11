import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/merchant.dart';
import '../theme/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/offer_badge.dart';

class MapScreenNew extends StatefulWidget {
  const MapScreenNew({super.key});

  @override
  State<MapScreenNew> createState() => _MapScreenNewState();
}

class _MapScreenNewState extends State<MapScreenNew> {
  final _mapCtrl = MapController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCat = 'All';
  Merchant? _selectedMerchant;
  int _tileModeIdx = 0;

  static const _tileModes = [
    ('OSM', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
    ('Light',
        'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png'),
    ('Dark',
        'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final pos = appState.locationService.currentPosition;
        final center = pos != null
            ? LatLng(pos.latitude, pos.longitude)
            : const LatLng(19.076, 72.8777); // Mumbai fallback

        // Filter merchants
        var merchants = appState.merchants;
        if (_selectedCat != 'All') {
          final catLower = _selectedCat.toLowerCase();
          merchants = merchants
              .where((m) => m.category.toLowerCase() == catLower)
              .toList();
        }
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          merchants = merchants
              .where((m) =>
                  m.name.toLowerCase().contains(q) ||
                  m.city.toLowerCase().contains(q))
              .toList();
        }

        return Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                onTap: (_, __) => setState(() => _selectedMerchant = null),
              ),
              children: [
                TileLayer(urlTemplate: _tileModes[_tileModeIdx].$2),
                // User position
                if (pos != null)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: center,
                      radius: 8,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      borderColor: Colors.white,
                      borderStrokeWidth: 3,
                    ),
                    CircleMarker(
                      point: center,
                      radius: 40,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderColor: AppColors.primary.withValues(alpha: 0.15),
                      borderStrokeWidth: 1,
                    ),
                  ]),
                // Merchant markers
                MarkerLayer(
                  markers: merchants.map((m) {
                    final catColor =
                        AppColors.getCategoryColor(m.category);
                    final selected = _selectedMerchant?.id == m.id;
                    return Marker(
                      point: LatLng(m.latitude, m.longitude),
                      width: selected ? 48 : 40,
                      height: selected ? 48 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedMerchant = m);
                          _mapCtrl.move(
                            LatLng(m.latitude, m.longitude),
                            _mapCtrl.camera.zoom,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: selected ? catColor : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: catColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: catColor.withValues(alpha: 0.3),
                                blurRadius: selected ? 12 : 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            AppColors.getCategoryIcon(m.category),
                            color: selected ? Colors.white : catColor,
                            size: selected ? 22 : 18,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Search / controls overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search on map...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CategoryChip(
                          label: 'All',
                          selected: _selectedCat == 'All',
                          onTap: () =>
                              setState(() => _selectedCat = 'All'),
                        ),
                        ...AppColors.category.keys.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: CategoryChip(
                              label: _fmt(cat),
                              selected: _selectedCat == cat,
                              onTap: () =>
                                  setState(() => _selectedCat = cat),
                              color: AppColors.getCategoryColor(cat),
                              icon: AppColors.getCategoryIcon(cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tile mode toggle
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              right: 12,
              child: Column(
                children: [
                  _mapBtn(Icons.layers_rounded, () {
                    setState(() =>
                        _tileModeIdx = (_tileModeIdx + 1) % _tileModes.length);
                  }),
                  const SizedBox(height: 8),
                  _mapBtn(Icons.my_location_rounded, () {
                    if (pos != null) {
                      _mapCtrl.move(center, 14);
                    }
                  }),
                ],
              ),
            ),

            // Selected merchant bottom sheet
            if (_selectedMerchant != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _merchantSheet(appState),
              ),
          ],
        );
      },
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  Widget _merchantSheet(AppState appState) {
    final m = _selectedMerchant!;
    final catColor = AppColors.getCategoryColor(m.category);
    final benefits = appState.dataService.getBenefitsAtMerchant(m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text('${_fmt(m.category)} • ${m.city}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 16, color: Color(0xFFFFB300)),
                  const SizedBox(width: 2),
                  Text(m.averageReviewRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (benefits.isNotEmpty)
                OfferBadge(
                    label:
                        '${benefits.length} offer${benefits.length > 1 ? 's' : ''}'),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/merchant', arguments: m);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
