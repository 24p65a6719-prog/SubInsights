import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/merchant.dart';
import '../utils/app_theme.dart';
import 'merchant_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  Merchant? _selectedMerchant;
  bool _isLoading = true;
  String? _selectedCategory;
  bool _showBottomSheet = false;
  String _currentTileLayer = 'openstreetmap';

  // Default to Mumbai, India
  static final LatLng _defaultLocation = LatLng(19.076, 72.8777);
  LatLng _currentLocation = _defaultLocation;

  late AnimationController _bottomSheetController;
  late Animation<double> _bottomSheetAnimation;

  // Tile layer URLs
  final Map<String, String> _tileLayers = {
    'openstreetmap': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'cartodb_light': 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    'cartodb_dark': 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    'humanitarian': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  };

  @override
  void initState() {
    super.initState();
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bottomSheetAnimation = CurvedAnimation(
      parent: _bottomSheetController,
      curve: Curves.easeOutCubic,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final appState = context.read<AppState>();
      final position = appState.locationService.currentPosition;
      
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  List<Merchant> get _filteredMerchants {
    final appState = context.read<AppState>();
    return _selectedCategory == null
        ? appState.merchants
        : appState.merchants
            .where((m) => m.category == _selectedCategory)
            .toList();
  }

  void _onMarkerTapped(Merchant merchant) {
    setState(() {
      _selectedMerchant = merchant;
      _showBottomSheet = true;
    });
    _bottomSheetController.forward();
    
    _mapController.move(
      LatLng(merchant.latitude, merchant.longitude),
      16,
    );
  }

  void _hideBottomSheet() {
    _bottomSheetController.reverse().then((_) {
      setState(() {
        _showBottomSheet = false;
        _selectedMerchant = null;
      });
    });
  }

  void _onCategorySelected(String? category) {
    setState(() => _selectedCategory = category);
    _hideBottomSheet();

    if (category != null) {
      final merchantsInCategory = _filteredMerchants;
      
      if (merchantsInCategory.isNotEmpty) {
        // Calculate bounds
        double minLat = merchantsInCategory.first.latitude;
        double maxLat = merchantsInCategory.first.latitude;
        double minLng = merchantsInCategory.first.longitude;
        double maxLng = merchantsInCategory.first.longitude;

        for (final m in merchantsInCategory) {
          minLat = minLat < m.latitude ? minLat : m.latitude;
          maxLat = maxLat > m.latitude ? maxLat : m.latitude;
          minLng = minLng < m.longitude ? minLng : m.longitude;
          maxLng = maxLng > m.longitude ? maxLng : m.longitude;
        }

        _fitBounds(
          LatLng(minLat - 0.01, minLng - 0.01),
          LatLng(maxLat + 0.01, maxLng + 0.01),
        );
      }
    }
  }

  void _fitBounds(LatLng southwest, LatLng northeast) {
    final bounds = LatLngBounds(southwest, northeast);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _goToCurrentLocation() {
    _getCurrentLocation().then((_) {
      _mapController.move(_currentLocation, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final merchants = _filteredMerchants;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 12,
              onTap: (_, __) => _hideBottomSheet(),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Tile Layer (OpenStreetMap)
              TileLayer(
                urlTemplate: _tileLayers[_currentTileLayer]!,
                userAgentPackageName: 'com.subinsights.app',
                maxZoom: 19,
              ),
              
              // User location circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentLocation,
                    radius: 80,
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderColor: colorScheme.primary,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  ),
                  CircleMarker(
                    point: _currentLocation,
                    radius: 8,
                    color: colorScheme.primary,
                    borderColor: Colors.white,
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
              
              // Merchant markers
              MarkerLayer(
                markers: merchants.map((merchant) {
                  final categoryColor = AppTheme.categoryColors[merchant.category] ?? 
                      colorScheme.primary;
                  final categoryIcon = AppTheme.categoryIcons[merchant.category] ?? 
                      Icons.place;
                  final isSelected = _selectedMerchant?.id == merchant.id;
                  
                  return Marker(
                    point: LatLng(merchant.latitude, merchant.longitude),
                    width: isSelected ? 56 : 44,
                    height: isSelected ? 56 : 44,
                    child: GestureDetector(
                      onTap: () => _onMarkerTapped(merchant),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 4 : 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.4),
                              blurRadius: isSelected ? 12 : 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          categoryIcon,
                          color: Colors.white,
                          size: isSelected ? 28 : 22,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: colorScheme.surface.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Top bar with search and filters
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _buildSearchBar(colorScheme),
                const SizedBox(height: 12),
                _buildCategoryChips(colorScheme),
              ],
            ),
          ),

          // Floating action buttons
          Positioned(
            right: 16,
            bottom: _showBottomSheet ? 280 : 100,
            child: Column(
              children: [
                _buildFab(
                  icon: Icons.my_location,
                  onPressed: _goToCurrentLocation,
                  heroTag: 'location',
                ),
                const SizedBox(height: 12),
                _buildFab(
                  icon: Icons.layers,
                  onPressed: _showMapTypeDialog,
                  heroTag: 'layers',
                ),
                const SizedBox(height: 12),
                _buildFab(
                  icon: Icons.add,
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                  heroTag: 'zoom_in',
                ),
                const SizedBox(height: 8),
                _buildFab(
                  icon: Icons.remove,
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                  heroTag: 'zoom_out',
                ),
              ],
            ),
          ),

          // Merchant count badge
          Positioned(
            left: 16,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${merchants.length} locations',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Attribution
          Positioned(
            left: 16,
            bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // Bottom sheet for selected merchant
          if (_showBottomSheet && _selectedMerchant != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _bottomSheetAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      (1 - _bottomSheetAnimation.value) * 260,
                    ),
                    child: child,
                  );
                },
                child: _buildMerchantBottomSheet(colorScheme),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search locations...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onSubmitted: _searchMerchants,
      ),
    );
  }

  void _searchMerchants(String query) {
    if (query.isEmpty) {
      _onCategorySelected(null);
      return;
    }

    final appState = context.read<AppState>();
    final results = appState.merchants.where((m) =>
        m.name.toLowerCase().contains(query.toLowerCase()) ||
        m.address.toLowerCase().contains(query.toLowerCase()) ||
        m.city.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isNotEmpty) {
      _onMarkerTapped(results.first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No locations found for "$query"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildCategoryChips(ColorScheme colorScheme) {
    final categories = ['Hotels', 'Restaurants', 'Shops', 'Education'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'All',
            icon: Icons.apps,
            isSelected: _selectedCategory == null,
            color: colorScheme.primary,
            onTap: () => _onCategorySelected(null),
          ),
          ...categories.map((category) {
            final color = AppTheme.categoryColors[category] ?? colorScheme.primary;
            final icon = AppTheme.categoryIcons[category] ?? Icons.place;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildChip(
                label: category,
                icon: icon,
                isSelected: _selectedCategory == category,
                color: color,
                onTap: () => _onCategorySelected(category),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab({
    required IconData icon,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.primary,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget _buildMerchantBottomSheet(ColorScheme colorScheme) {
    final merchant = _selectedMerchant!;
    final categoryColor = AppTheme.categoryColors[merchant.category] ?? 
        colorScheme.primary;
    final categoryIcon = AppTheme.categoryIcons[merchant.category] ?? Icons.place;
    final appState = context.read<AppState>();
    final benefits = appState.dataService.getBenefitsAtMerchant(merchant);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  merchant.category,
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                merchant.averageReviewRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _hideBottomSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${merchant.address}, ${merchant.city}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Benefits count
                if (benefits.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${benefits.length} offers available',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Up to ${_getMaxDiscount(benefits)}% off',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openDirections(merchant),
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewMerchantDetails(merchant),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: categoryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getMaxDiscount(List benefits) {
    int maxDiscount = 0;
    for (final b in benefits) {
      if (b.discountPercentage > maxDiscount) {
        maxDiscount = b.discountPercentage.toInt();
      }
    }
    return maxDiscount;
  }

  void _openDirections(Merchant merchant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${merchant.name}...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewMerchantDetails(Merchant merchant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantDetailScreen(merchant: merchant),
      ),
    );
  }

  void _showMapTypeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Map Style',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildMapStyleOption(
                icon: Icons.map_outlined,
                label: 'Standard',
                styleKey: 'openstreetmap',
              ),
              _buildMapStyleOption(
                icon: Icons.light_mode,
                label: 'Light',
                styleKey: 'cartodb_light',
              ),
              _buildMapStyleOption(
                icon: Icons.dark_mode,
                label: 'Dark',
                styleKey: 'cartodb_dark',
              ),
              _buildMapStyleOption(
                icon: Icons.volunteer_activism,
                label: 'Humanitarian',
                styleKey: 'humanitarian',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapStyleOption({
    required IconData icon,
    required String label,
    required String styleKey,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentTileLayer == styleKey;
    
    return ListTile(
      leading: Icon(
        icon, 
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: () {
        setState(() => _currentTileLayer = styleKey);
        Navigator.pop(context);
      },
    );
  }
}
