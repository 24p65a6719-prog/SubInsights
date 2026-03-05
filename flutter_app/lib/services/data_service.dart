import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/benefit.dart';
import '../models/membership.dart';
import '../models/merchant.dart';

/// Loads demo data from bundled JSON assets and generates
/// simulated real-time data when the backend is unavailable.
class DataService {
  List<Benefit> _benefits = [];
  List<Membership> _memberships = [];
  List<Merchant> _merchants = [];

  List<Benefit> get benefits => _benefits;
  List<Membership> get memberships => _memberships;
  List<Merchant> get merchants => _merchants;

  Future<void> loadAll() async {
    await Future.wait([
      _loadBenefits(),
      _loadMemberships(),
      _loadMerchants(),
    ]);
    _assignVerificationScores();
  }

  Future<void> _loadBenefits() async {
    final raw = await rootBundle.loadString('assets/data/benefits.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _benefits = (data['benefits'] as List)
        .map((e) => Benefit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadMemberships() async {
    final raw = await rootBundle.loadString('assets/data/memberships.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _memberships = (data['memberships'] as List)
        .map((e) => Membership.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadMerchants() async {
    final raw = await rootBundle.loadString('assets/data/merchants.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _merchants = (data['merchants'] as List)
        .map((e) => Merchant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _assignVerificationScores() {
    final rng = Random(42);
    for (final b in _benefits) {
      b.isVerified = true;
      b.verificationScore = 0.65 + rng.nextDouble() * 0.3; // 0.65 – 0.95
      b.lastVerification = DateTime.now().subtract(
        Duration(hours: rng.nextInt(24)),
      );
    }
  }

  List<Merchant> nearbyMerchants(Location userLocation,
      {double radiusKm = 5.0}) {
    return _merchants
        .where((m) => m.distanceTo(userLocation) <= radiusKm)
        .toList()
      ..sort((a, b) =>
          a.distanceTo(userLocation).compareTo(b.distanceTo(userLocation)));
  }

  List<Benefit> benefitsForMerchant(String merchantId) {
    return _benefits
        .where((b) => b.eligibleMerchants.contains(merchantId))
        .toList();
  }

  Merchant? merchantById(String id) {
    try {
      return _merchants.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Benefit? benefitById(String id) {
    try {
      return _benefits.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Generate a simulated redemption code
  String generateRedemptionCode() {
    final rng = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
