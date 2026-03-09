import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final Completer<GoogleMapController> _controller = Completer();
  
  Set<Marker> _markers = {};
  Circle? _userLocationCircle;
  Merchant? _selectedMerchant;
  bool _isLoading = true;
  String? _selectedCategory;
  bool _showBottomSheet = false;

  // Default to Mumbai, India
  static const LatLng _defaultLocation = LatLng(19.076, 72.8777);
  LatLng _currentLocation = _defaultLocation;

  late AnimationController _bottomSheetController;
  late Animation<double> _bottomSheetAnimation;

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
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    _loadMarkers();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final appState = context.read<AppState>();
      final position = appState.locationService.currentPosition;
      
      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateUserLocationCircle();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _updateUserLocationCircle() {
    _userLocationCircle = Circle(
      circleId: const CircleId('user_location'),
      center: _currentLocation,
      radius: 100,
      fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      strokeColor: Theme.of(context).colorScheme.primary,
      strokeWidth: 2,
    );
  }

  void _loadMarkers() {
    final appState = context.read<AppState>();
    final merchants = _selectedCategory == null
        ? appState.merchants
        : appState.merchants
            .where((m) => m.category == _selectedCategory)
            .toList();

    final colorScheme = Theme.of(context).colorScheme;
    
    _markers = merchants.map((merchant) {
      final categoryColor = AppTheme.categoryColors[merchant.category] ?? 
          colorScheme.primary;
      
      return Marker(
        markerId: MarkerId(merchant.id),
        position: LatLng(merchant.latitude, merchant.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(categoryColor),
        ),
        infoWindow: InfoWindow(
          title: merchant.name,
          snippet: merchant.category,
        ),
        onTap: () => _onMarkerTapped(merchant),
      );
    }).toSet();

    setState(() {});
  }

  double _getMarkerHue(Color color) {
    HSVColor hsv = HSVColor.fromColor(color);
    return hsv.hue;
  }

  void _onMarkerTapped(Merchant merchant) {
    setState(() {
      _selectedMerchant = merchant;
      _showBottomSheet = true;
    });
    _bottomSheetController.forward();
    
    _animateToLocation(
      LatLng(merchant.latitude, merchant.longitude),
      zoom: 16,
    );
  }

  Future<void> _animateToLocation(LatLng location, {double zoom = 14}) async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(location, zoom),
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
    _loadMarkers();
    _hideBottomSheet();

    if (category != null) {
      final appState = context.read<AppState>();
      final merchantsInCategory = appState.merchants
          .where((m) => m.category == category)
          .toList();
      
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

  Future<void> _fitBounds(LatLng southwest, LatLng northeast) async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        50,
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    await _getCurrentLocation();
    await _animateToLocation(_currentLocation, zoom: 15);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _controller.complete(controller);
              _setMapStyle(controller);
            },
            markers: _markers,
            circles: _userLocationCircle != null ? {_userLocationCircle!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onTap: (_) => _hideBottomSheet(),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: colorScheme.surface.withOpacity(0.8),
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
                    color: Colors.black.withOpacity(0.1),
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
                    '${_markers.length} locations',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search locations...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.5),
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
              color: Colors.black.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.15),
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
              color: colorScheme.outline.withOpacity(0.3),
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
                            categoryColor.withOpacity(0.7),
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
                                  color: categoryColor.withOpacity(0.1),
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
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                merchant.averageReviewRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withOpacity(0.7),
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
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${merchant.address}, ${merchant.city}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
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
    // In production, open Google Maps with directions
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

  Future<void> _setMapStyle(GoogleMapController controller) async {
    // Optional: Apply custom map style for better appearance
    // You can customize this based on your theme
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
                'Map Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildMapTypeOption(
                icon: Icons.map_outlined,
                label: 'Normal',
                type: MapType.normal,
              ),
              _buildMapTypeOption(
                icon: Icons.satellite_alt,
                label: 'Satellite',
                type: MapType.satellite,
              ),
              _buildMapTypeOption(
                icon: Icons.terrain,
                label: 'Terrain',
                type: MapType.terrain,
              ),
              _buildMapTypeOption(
                icon: Icons.layers,
                label: 'Hybrid',
                type: MapType.hybrid,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption({
    required IconData icon,
    required String label,
    required MapType type,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        // Note: MapType can't be changed after creation in google_maps_flutter
        // This would require rebuilding the map
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $label view'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
