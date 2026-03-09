import '../models/benefit.dart';
import '../models/merchant.dart';
import '../models/subscription.dart';

/// Result of offer validation at a specific merchant location.
class ValidationResult {
  final Benefit benefit;
  final Merchant merchant;
  final bool isValid;
  final List<String> validationNotes;
  final String status; // 'valid', 'expired', 'not_applicable', 'conditions_not_met'

  ValidationResult({
    required this.benefit,
    required this.merchant,
    required this.isValid,
    required this.validationNotes,
    required this.status,
  });
}

/// Validates offers/benefits at specific merchant locations,
/// checking T&C, validity period, merchant eligibility, etc.
class OfferValidationService {
  /// Validate a benefit at a specific merchant
  ValidationResult validateOffer({
    required Benefit benefit,
    required Merchant merchant,
    required List<Subscription> userSubscriptions,
  }) {
    final notes = <String>[];
    var status = 'valid';
    var isValid = true;

    // 1. Check if benefit is still within valid dates
    if (!benefit.isValid) {
      notes.add('❌ This offer has expired (valid until ${benefit.validUntil})');
      status = 'expired';
      isValid = false;
    } else if (benefit.isExpiringSoon) {
      notes.add(
          '⚠️ This offer is expiring soon (valid until ${benefit.validUntil})');
    } else {
      notes.add('✅ Offer is within validity period');
    }

    // 2. Check if merchant is eligible for this benefit
    if (benefit.eligibleMerchants.contains(merchant.id)) {
      notes.add('✅ ${merchant.name} is an eligible merchant for this offer');
    } else {
      notes.add(
          '❌ ${merchant.name} is not listed as eligible for this offer');
      status = 'not_applicable';
      isValid = false;
    }

    // 3. Check if merchant category matches
    if (benefit.merchantCategories.contains(merchant.category)) {
      notes.add('✅ Merchant category "${_formatCategory(merchant.category)}" is applicable');
    } else {
      notes.add(
          '⚠️ Merchant category "${_formatCategory(merchant.category)}" may not be applicable');
    }

    // 4. Check if user has a subscription that provides this benefit
    final matchingSubs = userSubscriptions.where(
        (s) => s.isActive && s.associatedBenefits.contains(benefit.id));
    if (matchingSubs.isNotEmpty) {
      for (final sub in matchingSubs) {
        notes.add('✅ Available through your "${sub.name}" subscription');
      }
    } else {
      notes.add(
          '❌ You don\'t have a subscription that includes this benefit');
      status = 'conditions_not_met';
      isValid = false;
    }

    // 5. Check minimum purchase requirement
    if (benefit.minPurchaseInr > 0) {
      notes.add(
          'ℹ️ Minimum purchase: ₹${benefit.minPurchaseInr} required');
    }

    // 6. Check usage limit
    if (benefit.usageLimit > 0) {
      notes.add(
          'ℹ️ Usage limit: ${benefit.usageLimit} time${benefit.usageLimit > 1 ? 's' : ''}');
    } else if (benefit.usageLimit == -1) {
      notes.add('✅ Unlimited usage');
    }

    // 7. Add T&C summary
    if (benefit.terms.isNotEmpty) {
      notes.add('');
      notes.add('📋 Terms & Conditions:');
      for (final term in benefit.terms) {
        notes.add('  • $term');
      }
    }

    // 8. Verification status
    if (benefit.isVerified) {
      notes.add('');
      notes.add('🔒 This offer has been verified by SubInsights');
    }

    return ValidationResult(
      benefit: benefit,
      merchant: merchant,
      isValid: isValid,
      validationNotes: notes,
      status: status,
    );
  }

  /// Validate all benefits at a merchant for a user
  List<ValidationResult> validateAllOffersAtMerchant({
    required Merchant merchant,
    required List<Benefit> benefits,
    required List<Subscription> userSubscriptions,
  }) {
    final merchantBenefits =
        benefits.where((b) => b.eligibleMerchants.contains(merchant.id));

    return merchantBenefits
        .map((b) => validateOffer(
              benefit: b,
              merchant: merchant,
              userSubscriptions: userSubscriptions,
            ))
        .toList()
      ..sort((a, b) {
        // Valid offers first
        if (a.isValid && !b.isValid) return -1;
        if (!a.isValid && b.isValid) return 1;
        return 0;
      });
  }

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
