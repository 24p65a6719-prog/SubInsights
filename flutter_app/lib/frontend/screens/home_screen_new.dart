import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../backend/services/location_simulator.dart';
import '../../models/merchant.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/offer_badge.dart';
import '../widgets/dwell_timer_widget.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  late LocationSimulator _simulator;
  StreamSubscription<SimulationState>? _simSub;
  SimulationState? _simState;
  String _selectedCity = 'Mumbai';
  Merchant? _selectedMerchant;

  // Configurable params
  double _dwellRadius = 500;
  int _dwellSeconds = 120;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _simulator = LocationSimulator(
      locationService: appState.locationService,
      dwellRadiusMeters: _dwellRadius,
      dwellThreshold: Duration(seconds: _dwellSeconds),
    );
    _simSub = _simulator.stateStream.listen((state) {
      setState(() => _simState = state);
      if (state.triggered) {
        _onDwellTriggered(state, appState);
      }
    });
  }

  bool _notifiedCurrent = false;

  void _onDwellTriggered(SimulationState state, AppState appState) {
    if (_notifiedCurrent) return;
    _notifiedCurrent = true;
    final benefits =
        appState.dataService.getBenefitsAtMerchant(state.merchant);
    if (benefits.isNotEmpty) {
      appState.notificationService.showDwellNotification(
        id: state.merchant.id.hashCode,
        merchantName: state.merchant.name,
        offerCount: benefits.length,
        dwellTime: '${state.elapsed.inSeconds}s',
      );
    }
  }

  void _teleport(Merchant merchant) {
    _notifiedCurrent = false;
    _selectedMerchant = merchant;
    _simulator.teleport(merchant);

    final appState = context.read<AppState>();
    appState.simulateLocationAtCity(merchant.city);
  }

  @override
  void dispose() {
    _simSub?.cancel();
    _simulator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cities = appState.cities.where((c) => c != 'All').toList();
        final cityMerchants = appState.merchants
            .where((m) => m.city == _selectedCity)
            .toList();
        final userBenefits = appState.userActiveBenefits;
        final nearby = appState.nearbyMerchants;

        return CustomScrollView(
          slivers: [
            // ── Hero header ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insights_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            'SubInsights',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (appState.locationSimulated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.gps_fixed,
                                      size: 14, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedCity,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quick stats row
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              value: '${nearby.length}',
                              label: 'Nearby',
                              icon: Icons.location_on_rounded,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              value: '${userBenefits.length}',
                              label: 'Offers',
                              icon: Icons.local_offer_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              value: '${appState.userSubscriptions.length}',
                              label: 'Subs',
                              icon: Icons.card_membership_rounded,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Location Simulator Panel ──
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.explore_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Location Simulator',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (_simulator.isRunning)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // City picker
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final city = cities[i];
                          final sel = city == _selectedCity;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedCity = city;
                              _selectedMerchant = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      sel ? FontWeight.w600 : FontWeight.w500,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Merchant picker
                    if (cityMerchants.isEmpty)
                      const Center(
                        child: Text('No merchants in this city',
                            style: TextStyle(color: AppColors.textHint)),
                      )
                    else
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cityMerchants.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final m = cityMerchants[i];
                            final sel = _selectedMerchant?.id == m.id;
                            final catColor =
                                AppColors.getCategoryColor(m.category);
                            return GestureDetector(
                              onTap: () => _teleport(m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? catColor.withValues(alpha: 0.15)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        sel ? catColor : Colors.grey.shade200,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        AppColors.getCategoryIcon(m.category),
                                        size: 18,
                                        color: catColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      m.name.length > 20
                                          ? '${m.name.substring(0, 18)}...'
                                          : m.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: sel
                                            ? catColor
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Dwell parameters
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dwell Radius',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint)),
                              Slider(
                                value: _dwellRadius,
                                min: 100,
                                max: 2000,
                                divisions: 19,
                                label: '${_dwellRadius.round()}m',
                                activeColor: AppColors.primary,
                                onChanged: (v) {
                                  setState(() => _dwellRadius = v);
                                  _simulator.updateParams(radius: v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dwell Time',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textHint)),
                              Slider(
                                value: _dwellSeconds.toDouble(),
                                min: 30,
                                max: 600,
                                divisions: 19,
                                label: _dwellSeconds >= 60
                                    ? '${(_dwellSeconds / 60).toStringAsFixed(1)}min'
                                    : '${_dwellSeconds}s',
                                activeColor: AppColors.secondary,
                                onChanged: (v) {
                                  setState(
                                      () => _dwellSeconds = v.round());
                                  _simulator.updateParams(
                                      threshold:
                                          Duration(seconds: v.round()));
                                  // Keep LocationService dwell threshold in sync
                                  context.read<AppState>().locationService
                                      .setDwellThreshold(Duration(seconds: v.round()));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Sim state (if running)
                    if (_simState != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          DwellTimerWidget(
                            elapsed: _simState!.elapsed,
                            threshold: _simState!.threshold,
                            triggered: _simState!.triggered,
                            size: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _simState!.merchant.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_simState!.distanceMeters.round()}m away  •  ${_simState!.elapsed.inSeconds}s elapsed',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                if (_simState!.triggered) ...[
                                  const SizedBox(height: 4),
                                  const OfferBadge(
                                    label: 'NOTIFICATION SENT',
                                    backgroundColor: AppColors.success,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle_outlined,
                                color: AppColors.error),
                            onPressed: () {
                              _simulator.stop();
                              setState(() {
                                _simState = null;
                                _selectedMerchant = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Section: Nearby Offers ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Nearby Offers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            if (nearby.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: Text(
                      'Teleport to a location to see nearby offers',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: nearby.take(10).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final nm = nearby[i];
                      final benefits = appState.dataService
                          .getBenefitsAtMerchant(nm.merchant);
                      final catColor =
                          AppColors.getCategoryColor(nm.merchant.category);
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/merchant',
                              arguments: nm.merchant);
                        },
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      AppColors.getCategoryIcon(
                                          nm.merchant.category),
                                      color: catColor,
                                      size: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  OfferBadge(
                                    label: nm.distanceLabel,
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.1),
                                    textColor: AppColors.primary,
                                    fontSize: 11,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                nm.merchant.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                '${benefits.length} offer${benefits.length != 1 ? 's' : ''} available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: benefits.isNotEmpty
                                      ? AppColors.success
                                      : AppColors.textHint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── Top Deals ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Top Deals For You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i >= userBenefits.length || i >= 8) return null;
                  final benefit = userBenefits[i];
                  final merchants =
                      appState.dataService.getMerchantsForBenefit(benefit);
                  final merchantName =
                      merchants.isNotEmpty ? merchants.first.name : '—';
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.mintGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              benefit.discountLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                benefit.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'at $merchantName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          benefit.validityStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: benefit.isValid
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount:
                    userBenefits.length > 8 ? 8 : userBenefits.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}
