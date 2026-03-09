import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/merchant.dart';
import '../models/benefit.dart';
import '../models/subscription.dart';

class DataService {
  List<Merchant> _merchants = [];
  List<Benefit> _benefits = [];
  List<Subscription> _subscriptions = [];

  List<Merchant> get merchants => _merchants;
  List<Benefit> get benefits => _benefits;
  List<Subscription> get subscriptions => _subscriptions;

  Future<void> loadAll() async {
    await Future.wait([
      _loadMerchants(),
      _loadBenefits(),
      _loadSubscriptions(),
    ]);
  }

  Future<void> _loadMerchants() async {
    final jsonStr = await rootBundle.loadString('assets/data/merchants.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _merchants = (data['merchants'] as List)
        .map((m) => Merchant.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadBenefits() async {
    final jsonStr = await rootBundle.loadString('assets/data/benefits.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _benefits = (data['benefits'] as List)
        .map((b) => Benefit.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadSubscriptions() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/subscriptions.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    _subscriptions = (data['subscriptions'] as List)
        .map((s) => Subscription.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Get benefits for a specific subscription
  List<Benefit> getBenefitsForSubscription(Subscription subscription) {
    return _benefits
        .where((b) => subscription.associatedBenefits.contains(b.id))
        .toList();
  }

  /// Get merchants that offer a specific benefit
  List<Merchant> getMerchantsForBenefit(Benefit benefit) {
    return _merchants
        .where((m) => benefit.eligibleMerchants.contains(m.id))
        .toList();
  }

  /// Get all benefits available at a specific merchant
  List<Benefit> getBenefitsAtMerchant(Merchant merchant) {
    return _benefits
        .where((b) => b.eligibleMerchants.contains(merchant.id))
        .toList();
  }

  /// Get all subscriptions that provide benefits at a merchant
  List<Subscription> getSubscriptionsForMerchant(Merchant merchant) {
    final merchantBenefitIds = merchant.benefitsOffered.toSet();
    return _subscriptions.where((s) {
      return s.associatedBenefits.any((b) => merchantBenefitIds.contains(b));
    }).toList();
  }

  /// Get merchants by category
  List<Merchant> getMerchantsByCategory(String category) {
    return _merchants.where((m) => m.category == category).toList();
  }

  /// Get all unique categories
  List<String> get categories {
    return _merchants.map((m) => m.category).toSet().toList()..sort();
  }

  /// Get all active benefits from user subscriptions
  List<Benefit> getActiveBenefitsForUser(List<String> userSubscriptionIds) {
    final userSubs = _subscriptions
        .where((s) => userSubscriptionIds.contains(s.id) && s.isActive)
        .toList();
    final benefitIds = <String>{};
    for (final sub in userSubs) {
      benefitIds.addAll(sub.associatedBenefits);
    }
    return _benefits
        .where((b) => benefitIds.contains(b.id) && b.isValid)
        .toList();
  }
}
