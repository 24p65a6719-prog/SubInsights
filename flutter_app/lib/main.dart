import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/nearby_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/merchant_detail_screen.dart';
import 'utils/app_theme.dart';
import 'models/merchant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SubInsightsApp());
}

class SubInsightsApp extends StatelessWidget {
  const SubInsightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: MaterialApp(
        title: 'SubInsights',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainShell(),
        onGenerateRoute: (settings) {
          if (settings.name == '/merchant') {
            final merchant = settings.arguments as Merchant;
            return MaterialPageRoute(
              builder: (context) =>
                  MerchantDetailScreen(merchant: merchant),
            );
          }
          return null;
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ExploreScreen(),
    NearbyScreen(),
    SubscriptionsScreen(),
  ];

  final _titles = const [
    'SubInsights',
    'Explore',
    'Nearby',
    'Subscriptions',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SubInsights',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your subscription benefits, simplified',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.error != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => state.initialize(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentIndex == 0)
                  const Icon(Icons.insights, size: 24),
                if (_currentIndex == 0) const SizedBox(width: 8),
                Text(_titles[_currentIndex]),
              ],
            ),
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Notifications are active! You\'ll be notified when near an offer.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: state.nearbyMerchants.isNotEmpty,
                  label: Text('${state.nearbyMerchants.length}'),
                  child: const Icon(Icons.near_me_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: state.nearbyMerchants.isNotEmpty,
                  label: Text('${state.nearbyMerchants.length}'),
                  child: const Icon(Icons.near_me),
                ),
                label: 'Nearby',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.card_membership_outlined),
                activeIcon: Icon(Icons.card_membership),
                label: 'Subscriptions',
              ),
            ],
          ),
        );
      },
    );
  }
}
