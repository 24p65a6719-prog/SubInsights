import 'package:flutter/material.dart';

/// SubInsights colour palette — modern dark-gradient-friendly colours.
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF3F3D99);
  static const Color primaryLight = Color(0xFFA29BFE);

  // ── Secondary / Accent ──
  static const Color secondary = Color(0xFF00D9A6);
  static const Color secondaryDark = Color(0xFF00A87D);

  // ── Surfaces ──
  static const Color surface = Color(0xFFF8F9FE);
  static const Color card = Colors.white;
  static const Color scaffoldBg = Color(0xFFF2F3FA);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A1D3B);
  static const Color textSecondary = Color(0xFF6B7080);
  static const Color textHint = Color(0xFFA0A4B8);

  // ── Feedback ──
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF448AFF);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF3F3D99), Color(0xFF2D2B70)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [secondary, Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF8F9FE), Color(0xFFEEF0FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Category colours ──
  static const Map<String, Color> category = {
    'hotel': Color(0xFF7B1FA2),
    'restaurant': Color(0xFFC62828),
    'cafe': Color(0xFF6D4C41),
    'shopping': Color(0xFFE65100),
    'banking': Color(0xFF1565C0),
    'pharmacy': Color(0xFF2E7D32),
    'health': Color(0xFF00897B),
    'entertainment': Color(0xFFFF6F00),
    'cinema': Color(0xFFAD1457),
    'fitness': Color(0xFFFF5252),
    'spa': Color(0xFF8E24AA),
    'coworking': Color(0xFF0277BD),
    'electronics': Color(0xFF37474F),
    'professional': Color(0xFF455A64),
    'dining': Color(0xFFD84315),
  };

  static const Map<String, IconData> categoryIcons = {
    'hotel': Icons.hotel,
    'restaurant': Icons.restaurant,
    'cafe': Icons.local_cafe,
    'shopping': Icons.shopping_bag,
    'banking': Icons.account_balance,
    'pharmacy': Icons.local_pharmacy,
    'health': Icons.health_and_safety,
    'entertainment': Icons.movie,
    'cinema': Icons.theaters,
    'fitness': Icons.fitness_center,
    'spa': Icons.spa,
    'coworking': Icons.work_outline,
    'electronics': Icons.devices,
    'professional': Icons.business_center,
    'dining': Icons.dinner_dining,
  };

  static Color getCategoryColor(String cat) =>
      category[cat.toLowerCase()] ?? const Color(0xFF78909C);

  static IconData getCategoryIcon(String cat) =>
      categoryIcons[cat.toLowerCase()] ?? Icons.store;

  /// Parse hex string like "#FF6C63FF" to Color
  static Color fromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF78909C);
    }
  }
}
