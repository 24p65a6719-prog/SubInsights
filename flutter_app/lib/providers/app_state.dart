import 'dart:math';
import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/benefit.dart';
import '../models/membership.dart';
import '../models/merchant.dart';
import '../services/data_service.dart';

class AppState extends ChangeNotifier {
  final DataService _dataService = DataService();
  bool _initialized = false;
  bool _loading = true;

  // Current user location (SF downtown default)
  Location _userLocation =
      const Location(latitude: 37.7749, longitude: -122.4194);

  // Alerts
  final List<BenefitAlert> _alerts = [];
  int _claimedCount = 0;

  // Getters
  bool get initialized => _initialized;
  bool get loading => _loading;
  Location get userLocation => _userLocation;
  List<Benefit> get benefits => _dataService.benefits;
  List<Membership> get memberships => _dataService.memberships;
  List<Merchant> get merchants => _dataService.merchants;
  List<BenefitAlert> get alerts => _alerts;
  List<BenefitAlert> get pendingAlerts =>
      _alerts.where((a) => a.status == AlertStatus.pending).toList();
  int get claimedCount => _claimedCount;
  DataService get dataService => _dataService;

  // Stats
  int get activeMemberships =>
      _dataService.memberships.where((m) => !m.isExpired).length;
  int get verifiedBenefits =>
      _dataService.benefits.where((b) => b.isVerified).length;
  int get nearbyMerchantCount =>
      _dataService.nearbyMerchants(_userLocation).length;
  double get estimatedAnnualSavings {
    double total = 0;
    for (final b in _dataService.benefits.where((b) => b.isVerified)) {
      total += b.discountPercent * 50.0; // rough estimate
    }
    return total;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();

    await _dataService.loadAll();
    _initialized = true;
    _loading = false;

    // Generate initial demo alerts
    _generateDemoAlerts();

    notifyListeners();
  }

  // ─── Location ───
  void updateLocation(double lat, double lon) {
    _userLocation = Location(latitude: lat, longitude: lon);
    _generateDemoAlerts();
    notifyListeners();
  }

  List<Merchant> get nearbyMerchants =>
      _dataService.nearbyMerchants(_userLocation);

  // ─── Alerts ───
  void _generateDemoAlerts() {
    _alerts.clear();
    final nearby = _dataService.nearbyMerchants(_userLocation, radiusKm: 5.0);
    for (final merchant in nearby.take(3)) {
      final merchantBenefits = _dataService.benefitsForMerchant(merchant.id);
      for (final benefit in merchantBenefits) {
        _alerts.add(BenefitAlert(
          id: 'alert_${benefit.id}_${merchant.id}',
          userId: 'user_1',
          title: '🎉 ${benefit.title} at ${merchant.name}',
          message:
              '${merchant.name} is honoring your ${benefit.title}! Get ${benefit.discountPercent}% off. Valid today.',
          benefitId: benefit.id,
          merchantId: merchant.id,
          discountPercent: benefit.discountPercent,
          createdAt: DateTime.now(),
          priority: benefit.priority,
        ));
      }
    }
  }

  void claimAlert(String alertId) {
    final alert = _alerts.firstWhere((a) => a.id == alertId);
    alert.status = AlertStatus.claimed;
    alert.redemptionCode = _dataService.generateRedemptionCode();
    _claimedCount++;
    notifyListeners();
  }

  void dismissAlert(String alertId) {
    final alert = _alerts.firstWhere((a) => a.id == alertId);
    alert.status = AlertStatus.dismissed;
    notifyListeners();
  }

  // ─── BERT Verification ───
  Future<void> verifyBenefit(String benefitId) async {
    final benefit = _dataService.benefitById(benefitId);
    if (benefit == null) return;

    // Simulate BERT verification delay
    await Future.delayed(const Duration(seconds: 1));

    final rng = Random();
    benefit.isVerified = true;
    benefit.verificationScore = 0.7 + rng.nextDouble() * 0.25;
    benefit.lastVerification = DateTime.now();
    notifyListeners();
  }

  Future<void> verifyAllBenefits() async {
    for (final b in _dataService.benefits) {
      await verifyBenefit(b.id);
    }
  }
}
