import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/merchant.dart';
import '../../models/benefit.dart';
import '../../models/subscription.dart';

/// Abstraction over raw JSON asset loading.
///
/// In a future iteration this can be swapped to a remote API without
/// touching any UI code.
class DataRepository {
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
}
