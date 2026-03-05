import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthState { unauthenticated, otpPending, authenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AuthState _state = AuthState.unauthenticated;
  User? _user;
  String? _pendingUserId;
  String? _demoOtp;
  String? _error;
  bool _loading = false;

  AuthState get state => _state;
  User? get user => _user;
  String? get demoOtp => _demoOtp;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Register a new account. On success moves to OTP pending.
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (res['status'] == 'success' || res['user_id'] != null) {
        _pendingUserId = res['user_id'] as String?;
        _demoOtp = res['demo_otp']?.toString();
        _state = AuthState.otpPending;
      } else {
        _error = res['message'] as String? ?? 'Registration failed';
      }
    } catch (e) {
      // Demo/offline mode – skip to authenticated
      _user = User(id: 'user_1', email: email, fullName: fullName);
      _state = AuthState.authenticated;
    }

    _loading = false;
    notifyListeners();
  }

  /// Verify OTP code.
  Future<void> verifyOtp(String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.verifyOtp(
        userId: _pendingUserId ?? '',
        otp: otp,
      );

      if (res['status'] == 'success') {
        _user = User(
          id: _pendingUserId ?? 'user_1',
          email: res['email'] as String? ?? '',
          fullName: res['full_name'] as String? ?? '',
          isVerified: true,
          token: res['token'] as String?,
        );
        if (_user!.token != null) _api.setToken(_user!.token!);
        _state = AuthState.authenticated;
      } else {
        _error = res['message'] as String? ?? 'Invalid OTP';
      }
    } catch (e) {
      // Demo mode: accept any 6-digit code
      if (otp.length == 6) {
        _user = User(
          id: _pendingUserId ?? 'user_1',
          email: '',
          fullName: '',
          isVerified: true,
        );
        _state = AuthState.authenticated;
      } else {
        _error = 'Enter a 6-digit OTP';
      }
    }

    _loading = false;
    notifyListeners();
  }

  /// Login with email / password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(email: email, password: password);

      if (res['status'] == 'success' || res['token'] != null) {
        _user = User(
          id: res['user_id'] as String? ?? 'user_1',
          email: email,
          fullName: res['full_name'] as String? ?? '',
          isVerified: true,
          token: res['token'] as String?,
        );
        if (_user!.token != null) _api.setToken(_user!.token!);
        _state = AuthState.authenticated;
      } else {
        _error = res['message'] as String? ?? 'Login failed';
      }
    } catch (e) {
      // Demo/offline mode
      _user = User(id: 'user_1', email: email, fullName: 'Demo User');
      _state = AuthState.authenticated;
    }

    _loading = false;
    notifyListeners();
  }

  /// Skip auth for demo mode.
  void loginAsDemo() {
    _user = User(
      id: 'user_1',
      email: 'demo@subinsights.com',
      fullName: 'Demo User',
      isVerified: true,
    );
    _state = AuthState.authenticated;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _state = AuthState.unauthenticated;
    _error = null;
    notifyListeners();
  }
}
