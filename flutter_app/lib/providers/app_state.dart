import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../backend/services/admin_settings_service.dart';
import '../models/admin_settings.dart';
import '../models/merchant.dart';
import '../models/benefit.dart';
import '../models/subscription.dart';
import '../services/data_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/offer_validation_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final OfferValidationService _validationService = OfferValidationService();
  final AdminSettingsService _adminSettingsService = AdminSettingsService();

  bool _isLoading = true;
  String? _error;
  List<String> _userSubscriptionIds = [];
  List<NearbyMerchant> _nearbyMerchants = [];
  StreamSubscription? _nearbySubscription;
  String _selectedCity = 'All';
  String _selectedCategory = 'All';
  final Set<String> _notifiedMerchantIds = {};
  bool _locationSimulated = false;
  AdminSettings _adminSettings = AdminSettings.defaults();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  DataService get dataService => _dataService;
  LocationService get locationService => _locationService;
  NotificationService get notificationService => _notificationService;
  OfferValidationService get validationService => _validationService;
  AdminSettings get adminSettings => _adminSettings;
  List<NearbyMerchant> get nearbyMerchants => _nearbyMerchants;
  String get selectedCity => _selectedCity;
  String get selectedCategory => _selectedCategory;
  bool get locationSimulated => _locationSimulated;

  List<Merchant> get merchants => _dataService.merchants;
  List<Benefit> get benefits => _dataService.benefits;
  List<Subscription> get subscriptions => _dataService.subscriptions;

  List<Subscription> get userSubscriptions => _dataService.subscriptions
      .where((s) => _userSubscriptionIds.contains(s.id))
      .toList();

  List<Subscription> get availableSubscriptions => _dataService.subscriptions
      .where((s) => !_userSubscriptionIds.contains(s.id))
      .toList();

  List<Benefit> get userActiveBenefits =>
      _dataService.getActiveBenefitsForUser(_userSubscriptionIds);

  List<String> get cities {
    final citySet =
        _dataService.merchants.map((m) => m.city).toSet().toList()..sort();
    return ['All', ...citySet];
  }

  List<String> get categories {
    final cats =
        _dataService.categories.map((c) => _formatCategory(c)).toList();
    return ['All', ...cats];
  }

  List<Merchant> get filteredMerchants {
    return _dataService.merchants.where((m) {
      final cityMatch = _selectedCity == 'All' || m.city == _selectedCity;
      final catMatch = _selectedCategory == 'All' ||
          _formatCategory(m.category) == _selectedCategory;
      return cityMatch && catMatch;
    }).toList();
  }

  /// Initialize the app
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dataService.loadAll();
      await _notificationService.initialize();
      await _loadAdminSettings();
      await _loadUserSubscriptions();

      // Try to get real location, fallback to simulation
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        // Simulate being in Mumbai for demo
        _locationService.simulatePosition(18.9217, 72.8332);
        _locationSimulated = true;
      }

      // Start monitoring
      _nearbySubscription =
          _locationService.nearbyStream.listen(_onNearbyUpdate);
      await _locationService.startMonitoring(_dataService.merchants);

      // Also do an initial nearby check
      _nearbyMerchants = _locationService.findNearbyMerchants(
        _dataService.merchants,
        radiusMeters: 50000, // 50km for demo
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onNearbyUpdate(List<NearbyMerchant> nearby) {
    _nearbyMerchants = nearby;
    notifyListeners();

    // Send notifications for merchants where the user has dwelled past threshold.
    // hasDwelled is only true after LocationService._dwellThreshold has elapsed,
    // so this is NOT instant — it respects the configured dwell time.
    for (final nm in nearby) {
      if (nm.hasDwelled && !_notifiedMerchantIds.contains(nm.merchant.id)) {
        final benefits = _dataService.getBenefitsAtMerchant(nm.merchant);
        final userBenefits = benefits
            .where((b) => userSubscriptions
                .any((s) => s.associatedBenefits.contains(b.id)))
            .toList();

        if (userBenefits.isNotEmpty) {
          _notificationService.showDwellNotification(
            id: nm.merchant.id.hashCode,
            merchantName: nm.merchant.name,
            offerCount: userBenefits.length,
            dwellTime: '${nm.dwellDuration.inSeconds}s',
          );
          _notifiedMerchantIds.add(nm.merchant.id);
        }
      }
    }
  }

  /// Subscribe to a subscription
  Future<void> addSubscription(String subscriptionId) async {
    if (!_userSubscriptionIds.contains(subscriptionId)) {
      _userSubscriptionIds.add(subscriptionId);
      await _saveUserSubscriptions();
      notifyListeners();
    }
  }

  /// Unsubscribe from a subscription
  Future<void> removeSubscription(String subscriptionId) async {
    _userSubscriptionIds.remove(subscriptionId);
    await _saveUserSubscriptions();
    notifyListeners();
  }

  bool isSubscribed(String subscriptionId) =>
      _userSubscriptionIds.contains(subscriptionId);

  /// Set city filter
  void setCity(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  /// Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> _loadAdminSettings() async {
    try {
      _adminSettings = await _adminSettingsService.loadSettings();
      _locationService.setDwellThreshold(_adminSettings.dwellThreshold);
      _locationService.setNotifyRadius(_adminSettings.dwellRadiusMeters);
    } catch (e) {
      _adminSettings = AdminSettings.defaults();
      _locationService.setDwellThreshold(_adminSettings.dwellThreshold);
      _locationService.setNotifyRadius(_adminSettings.dwellRadiusMeters);
      _error ??= 'Admin settings fallback: $e';
    }
  }

  /// Validate offers at a merchant
  List<ValidationResult> validateOffersAtMerchant(Merchant merchant) {
    return _validationService.validateAllOffersAtMerchant(
      merchant: merchant,
      benefits: _dataService.benefits,
      userSubscriptions: userSubscriptions,
    );
  }

  Future<void> _loadUserSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    _userSubscriptionIds =
        prefs.getStringList('user_subscriptions') ?? [];
    // If no subscriptions saved, add some defaults for demo
    if (_userSubscriptionIds.isEmpty) {
      _userSubscriptionIds = [
        'sub_hdfc_cc',
        'sub_zomato_gold',
        'sub_ieee',
        'sub_amazon_prime',
      ];
      await _saveUserSubscriptions();
    }
  }

  Future<void> _saveUserSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_subscriptions', _userSubscriptionIds);
  }

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  void dispose() {
    _nearbySubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
