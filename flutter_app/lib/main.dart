import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const SubInsightsApp());
}

class SubInsightsApp extends StatelessWidget {
  const SubInsightsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'SubInsights',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/otp': (_) => const OtpScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

/// Automatically routes to the right screen based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.state) {
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.otpPending:
        return const OtpScreen();
      case AuthState.authenticated:
        return const HomeScreen();
    }
  }
}
