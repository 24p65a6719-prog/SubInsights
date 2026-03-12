import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/admin_settings.dart';

class AdminSettingsService {
  AdminSettingsService({
    FirebaseFirestore? firestore,
    this.collectionPath = 'admin_settings',
    this.documentId = 'live',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String collectionPath;
  final String documentId;
  AdminSettings? _cache;

  Future<AdminSettings> loadSettings({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;

    try {
      final doc = await _firestore.collection(collectionPath).doc(documentId).get();
      if (doc.exists && doc.data() != null) {
        _cache = AdminSettings.fromJson(doc.data()!);
        return _cache!;
      }
    } catch (e) {
      debugPrint('AdminSettingsService Firestore fallback: $e');
    }

    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<void> updateSettings(AdminSettings settings) async {
    await _firestore.collection(collectionPath).doc(documentId).set(
          settings.toJson(),
          SetOptions(merge: true),
        );
    _cache = settings;
  }

  Future<AdminSettings> _loadFromAsset() async {
    final raw = await rootBundle.loadString('assets/data/admin_settings.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    return AdminSettings.fromJson(data);
  }
}
