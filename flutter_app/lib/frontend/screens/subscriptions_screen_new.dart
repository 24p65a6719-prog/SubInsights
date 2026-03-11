import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/subscription.dart';
import '../../models/benefit.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_new.dart';

class SubscriptionsScreenNew extends StatefulWidget {
  const SubscriptionsScreenNew({super.key});

  @override
  State<SubscriptionsScreenNew> createState() =>
      _SubscriptionsScreenNewState();
}

class _SubscriptionsScreenNewState extends State<SubscriptionsScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Column(
          children: [
            // Tab bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                tabs: [
                  Tab(
                    text:
                        'My Subs (${appState.userSubscriptions.length})',
                  ),
                  Tab(
                    text:
                        'Browse (${appState.availableSubscriptions.length})',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildSubList(appState.userSubscriptions, appState, true),
                  _buildSubList(
                      appState.availableSubscriptions, appState, false),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubList(
      List<Subscription> subs, AppState appState, bool isUser) {
    if (subs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUser ? Icons.credit_card_off : Icons.search_off,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              isUser
                  ? 'No subscriptions yet'
                  : 'No more subscriptions to add',
              style: const TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: subs.length,
      itemBuilder: (_, i) {
        final sub = subs[i];
        final color = AppColors.fromHex(sub.color);
        final benefits =
            appState.dataService.getBenefitsForSubscription(sub);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showSubDetail(sub, benefits, appState),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                          AppThemeNew.iconFromString(sub.icon),
                          color: color,
                          size: 26),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.provider,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${benefits.length} benefit${benefits.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (sub.isExpiringSoon) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.warning_amber_rounded,
                                    size: 14, color: AppColors.warning),
                                const SizedBox(width: 2),
                                const Text('Expiring soon',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.warning)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Add / Remove button
                    _actionButton(sub, appState, isUser),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(
      Subscription sub, AppState appState, bool isUser) {
    return GestureDetector(
      onTap: () {
        if (isUser) {
          appState.removeSubscription(sub.id);
        } else {
          appState.addSubscription(sub.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isUser ? Icons.remove_rounded : Icons.add_rounded,
          color: isUser ? AppColors.error : AppColors.success,
          size: 22,
        ),
      ),
    );
  }

  void _showSubDetail(
      Subscription sub, List<Benefit> benefits, AppState appState) {
    final color = AppColors.fromHex(sub.color);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (context, scrollCtrl) {
          return SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                          AppThemeNew.iconFromString(sub.icon),
                          color: color,
                          size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text(sub.provider,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(sub.description,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // Benefits
                Text(
                  'Linked Benefits (${benefits.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ...benefits.map((b) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.mintGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.discountLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(b.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(b.validityStatus,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: b.isValid
                                            ? AppColors.success
                                            : AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
