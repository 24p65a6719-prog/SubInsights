import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription.dart';
import '../../providers/app_state.dart';
import '../../services/auth_service.dart';
import '../theme/app_colors.dart';

class ProfileScreenNew extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onLogout;

  const ProfileScreenNew({
    super.key,
    required this.authService,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return CustomScrollView(
            slivers: [
              // ── Hero header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          // Avatar
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2),
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          if (user?.phone != null &&
                              user!.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // The back arrow & title shown when collapsed
                title: const Text('Profile'),
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
              ),

              // ── Stats row ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      _StatCell(
                        label: 'Subscriptions',
                        value:
                            '${appState.userSubscriptions.length}',
                        icon: Icons.card_membership,
                      ),
                      _Divider(),
                      _StatCell(
                        label: 'Active Benefits',
                        value: '${appState.userActiveBenefits.length}',
                        icon: Icons.local_offer_outlined,
                      ),
                      _Divider(),
                      _StatCell(
                        label: 'Nearby Offers',
                        value: '${appState.nearbyMerchants.length}',
                        icon: Icons.near_me_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              // ── My Subscriptions heading ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 24, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'My Subscriptions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${appState.userSubscriptions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Add more button
                      if (appState.availableSubscriptions.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.add,
                              size: 16, color: AppColors.primary),
                          label: const Text(
                            'Add More',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Subscription list ─────────────────────────────────────
              appState.userSubscriptions.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptySubs(context),
                    )
                  : SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final sub = appState.userSubscriptions[i];
                            return _SubscriptionTile(
                              subscription: sub,
                              onRemove: () =>
                                  _confirmRemove(context, sub, appState),
                            );
                          },
                          childCount: appState.userSubscriptions.length,
                        ),
                      ),
                    ),

              // ── Account section ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: const Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    children: [
                      _AccountTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notification Preferences',
                        onTap: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Coming soon!'),
                                behavior: SnackBarBehavior.floating)),
                      ),
                      const Divider(height: 1, indent: 56),
                      _AccountTile(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text('Coming soon!'),
                                behavior: SnackBarBehavior.floating)),
                      ),
                      const Divider(height: 1, indent: 56),
                      _AccountTile(
                        icon: Icons.logout,
                        label: 'Sign Out',
                        color: AppColors.error,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptySubs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.card_membership_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'No subscriptions yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Go to the Subscriptions tab to browse\nand add services you use.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Browse Subscriptions'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, Subscription sub, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Subscription'),
        content: Text(
            'Remove ${sub.name} from your subscriptions? You can always add it back later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              appState.removeSubscription(sub.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${sub.name} removed'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => appState.addSubscription(sub.id),
                ),
              ));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close profile screen
              onLogout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCell(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.surface);
  }
}

class _SubscriptionTile extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onRemove;

  const _SubscriptionTile(
      {required this.subscription, required this.onRemove});

  Color _parseColor() {
    try {
      final hex =
          subscription.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  IconData _iconFromName(String name) {
    const map = {
      'card_membership': Icons.card_membership,
      'local_grocery_store': Icons.local_grocery_store,
      'movie': Icons.movie,
      'music_note': Icons.music_note,
      'fitness_center': Icons.fitness_center,
      'flight': Icons.flight,
      'local_cafe': Icons.local_cafe,
      'shopping_bag': Icons.shopping_bag,
      'hotel': Icons.hotel,
      'local_shipping': Icons.local_shipping,
    };
    return map[name] ?? Icons.card_membership;
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconFromName(subscription.icon), color: color, size: 22),
        ),
        title: Text(
          subscription.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subscription.provider,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: AppColors.error, size: 22),
          tooltip: 'Remove',
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color)),
      trailing: Icon(Icons.chevron_right,
          color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }
}
