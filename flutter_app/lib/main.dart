import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'services/auth_service.dart';
import 'frontend/screens/home_screen_new.dart';
import 'frontend/screens/explore_screen_new.dart';
import 'frontend/screens/nearby_screen_new.dart';
import 'frontend/screens/subscriptions_screen_new.dart';
import 'frontend/screens/map_screen_new.dart';
import 'frontend/screens/merchant_detail_screen_new.dart';
import 'frontend/screens/login_screen_new.dart';
import 'frontend/screens/profile_screen_new.dart';
import 'frontend/theme/app_colors.dart';
import 'frontend/theme/app_theme_new.dart';
import 'models/merchant.dart';
import 'services/background_location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase on all platforms.
  // Web uses the web config; Android/iOS use their respective configs
  // from firebase_options.dart (populated by `flutterfire configure`).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background message handler (must be a top-level function).
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configure the background location service (does not start it yet).
  if (!kIsWeb) {
    await initBackgroundLocationService();
  }

  runApp(const SubInsightsApp());
}

/// Top-level handler for FCM messages received when the app is killed.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('FCM background message: ${message.messageId}');
}

class SubInsightsApp extends StatelessWidget {
  const SubInsightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: MaterialApp(
        title: 'SubInsights',
        theme: AppThemeNew.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          if (settings.name == '/merchant') {
            final merchant = settings.arguments as Merchant;
            return MaterialPageRoute(
              builder: (context) =>
                  MerchantDetailScreenNew(merchant: merchant),
            );
          }
          return null;
        },
      ),
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final isLoggedIn = await _authService.checkSession();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isCheckingAuth = false;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() => _isLoggedIn = true);
    // Start background location monitoring after successful login.
    if (!kIsWeb) {
      _requestPermissionsAndStartBackground();
    }
  }

  Future<void> _requestPermissionsAndStartBackground() async {
    // Request notification permission (Android 13+ / iOS).
    final notifStatus = await Permission.notification.request();
    debugPrint('Notification permission: $notifStatus');

    // Request location-always permission for background tracking.
    final locStatus = await Permission.locationAlways.request();
    debugPrint('Location-always permission: $locStatus');

    await startBackgroundService();
  }

  void _onLogout() {
    _authService.signOut();
    if (!kIsWeb) {
      stopBackgroundService();
    }
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights,
                size: 64,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreenNew(onLoginSuccess: _onLoginSuccess, authService: _authService);
    }

    return MainShell(onLogout: _onLogout, authService: _authService);
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  final AuthService authService;

  const MainShell({
    super.key,
    required this.onLogout,
    required this.authService,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreenNew(),
      const ExploreScreenNew(),
      const MapScreenNew(),
      const NearbyScreenNew(),
      const SubscriptionsScreenNew(),
    ];
  }

  final _titles = const [
    'SubInsights',
    'Explore',
    'Map',
    'Nearby',
    'Subscriptions',
  ];

  void _showProfileMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreenNew(
          authService: widget.authService,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SubInsights',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                      color: AppColors.primary,
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
                        size: 64, color: AppColors.error),
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
              IconButton(
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    widget.authService.currentUser?.initials ?? '?',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                onPressed: _showProfileMenu,
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: state.nearbyMerchants.isNotEmpty,
                  label: Text('${state.nearbyMerchants.length}'),
                  child: const Icon(Icons.near_me_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: state.nearbyMerchants.isNotEmpty,
                  label: Text('${state.nearbyMerchants.length}'),
                  child: const Icon(Icons.near_me),
                ),
                label: 'Nearby',
              ),
              const NavigationDestination(
                icon: Icon(Icons.card_membership_outlined),
                selectedIcon: Icon(Icons.card_membership),
                label: 'Subscriptions',
              ),
            ],
          ),
        );
      },
    );
  }
}
