import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color secondaryColor = Color(0xFF00897B);
  static const Color accentColor = Color(0xFFFF6F00);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  /// Get icon for a category
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hotel':
        return Icons.hotel;
      case 'banking':
        return Icons.account_balance;
      case 'shop':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'education':
        return Icons.school;
      case 'conference':
        return Icons.event;
      case 'book_fair':
        return Icons.menu_book;
      default:
        return Icons.store;
    }
  }

  /// Get color for a category
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hotel':
        return const Color(0xFF7B1FA2);
      case 'banking':
        return const Color(0xFF1565C0);
      case 'shop':
        return const Color(0xFFE65100);
      case 'restaurant':
        return const Color(0xFFC62828);
      case 'education':
        return const Color(0xFF2E7D32);
      case 'conference':
        return const Color(0xFF00838F);
      case 'book_fair':
        return const Color(0xFF4E342E);
      default:
        return Colors.grey;
    }
  }

  /// Get icon from string name
  static IconData getIconFromString(String iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'restaurant':
        return Icons.restaurant;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'school':
        return Icons.school;
      case 'computer':
        return Icons.computer;
      case 'local_library':
        return Icons.local_library;
      case 'confirmation_number':
        return Icons.confirmation_number;
      case 'hotel':
        return Icons.hotel;
      case 'account_balance':
        return Icons.account_balance;
      case 'event':
        return Icons.event;
      case 'menu_book':
        return Icons.menu_book;
      case 'card_membership':
        return Icons.card_membership;
      default:
        return Icons.star;
    }
  }

  /// Parse hex color string
  static Color parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Format category string for display
  static String formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
