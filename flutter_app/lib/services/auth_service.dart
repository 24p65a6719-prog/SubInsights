import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  static const _usersDbKey = 'users_database';
  static const _sessionKey = 'session_token';
  static const _rememberMeKey = 'remember_me';
  static const _otpStorageKey = 'otp_storage';

  // Google Sign-In configuration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  UserModel? _currentUser;
  String? _sessionToken;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _sessionToken != null;

  /// Hash password using SHA-256 with salt
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Generate a unique salt for each user
  String _generateSalt() {
    return DateTime.now().microsecondsSinceEpoch.toString() +
        UniqueKey().toString();
  }

  /// Generate session token
  String _generateSessionToken(String email) {
    final data = email + DateTime.now().toIso8601String() + UniqueKey().toString();
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validate password strength
  PasswordStrength validatePassword(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Get users database
  Future<Map<String, Map<String, dynamic>>> _getUsersDb() async {
    try {
      final data = await _secureStorage.read(key: _usersDbKey);
      if (data == null) return {};
      final decoded = json.decode(data) as Map<String, dynamic>;
      return decoded.map((key, value) => 
          MapEntry(key, Map<String, dynamic>.from(value as Map)));
    } catch (e) {
      debugPrint('Error reading users db: $e');
      return {};
    }
  }

  /// Save users database
  Future<void> _saveUsersDb(Map<String, Map<String, dynamic>> db) async {
    await _secureStorage.write(key: _usersDbKey, value: json.encode(db));
  }

  /// Sign up new user
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Validate inputs
      if (!isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      if (validatePassword(password) == PasswordStrength.weak) {
        return AuthResult.failure(
            'Password must be at least 8 characters with mix of letters, numbers');
      }

      if (name.trim().isEmpty) {
        return AuthResult.failure('Please enter your name');
      }

      final usersDb = await _getUsersDb();
      final emailLower = email.toLowerCase();

      // Check if user exists
      if (usersDb.containsKey(emailLower)) {
        return AuthResult.failure('An account with this email already exists');
      }

      // Create new user
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final user = UserModel(
        id: userId,
        email: emailLower,
        name: name.trim(),
        phone: phone?.trim(),
        subscriptionIds: _getDefaultSubscriptions(),
        createdAt: now,
        lastLogin: now,
        preferences: UserPreferences(),
      );

      // Save to database
      usersDb[emailLower] = {
        'user': user.toJson(),
        'password_hash': hashedPassword,
        'salt': salt,
      };
      await _saveUsersDb(usersDb);

      // Auto login
      _currentUser = user;
      _sessionToken = _generateSessionToken(emailLower);
      await _saveSession();

      return AuthResult.success(user);
    } catch (e) {
      debugPrint('Sign up error: $e');
      return AuthResult.failure('An error occurred. Please try again.');
    }
  }

  /// Sign in existing user
  Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      if (!isValidEmail(email)) {
        return AuthResult.failure('Please enter a valid email address');
      }

      final usersDb = await _getUsersDb();
      final emailLower = email.toLowerCase();

      // Check if user exists
      if (!usersDb.containsKey(emailLower)) {
        return AuthResult.failure('No account found with this email');
      }

      final userData = usersDb[emailLower]!;
      final storedHash = userData['password_hash'] as String;
      final salt = userData['salt'] as String;

      // Verify password
      final inputHash = _hashPassword(password, salt);
      if (inputHash != storedHash) {
        return AuthResult.failure('Incorrect password');
      }

      // Load user
      final user = UserModel.fromJson(
          userData['user'] as Map<String, dynamic>);
      
      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      userData['user'] = updatedUser.toJson();
      await _saveUsersDb(usersDb);

      _currentUser = updatedUser;
      _sessionToken = _generateSessionToken(emailLower);
      
      // Save session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      await _saveSession();

      return AuthResult.success(updatedUser);
    } catch (e) {
      debugPrint('Sign in error: $e');
      return AuthResult.failure('An error occurred. Please try again.');
    }
  }

  /// Check for existing session
  Future<bool> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      
      if (!rememberMe) {
        await signOut();
        return false;
      }

      final sessionData = await _secureStorage.read(key: _sessionKey);
      if (sessionData == null) return false;

      final session = json.decode(sessionData) as Map<String, dynamic>;
      final email = session['email'] as String?;
      final token = session['token'] as String?;
      final expiry = session['expiry'] as String?;

      if (email == null || token == null || expiry == null) return false;

      // Check expiry (30 days)
      final expiryDate = DateTime.parse(expiry);
      if (DateTime.now().isAfter(expiryDate)) {
        await signOut();
        return false;
      }

      // Load user
      final usersDb = await _getUsersDb();
      if (!usersDb.containsKey(email)) return false;

      final userData = usersDb[email]!;
      _currentUser = UserModel.fromJson(
          userData['user'] as Map<String, dynamic>);
      _sessionToken = token;

      return true;
    } catch (e) {
      debugPrint('Check session error: $e');
      return false;
    }
  }

  /// Save current session
  Future<void> _saveSession() async {
    if (_currentUser == null || _sessionToken == null) return;

    final session = {
      'email': _currentUser!.email,
      'token': _sessionToken,
      'expiry': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };
    await _secureStorage.write(key: _sessionKey, value: json.encode(session));
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUser = null;
    _sessionToken = null;
    await _secureStorage.delete(key: _sessionKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
  }

  /// Update user subscriptions
  Future<void> updateSubscriptions(List<String> subscriptionIds) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(subscriptionIds: subscriptionIds);
    
    final usersDb = await _getUsersDb();
    final userData = usersDb[_currentUser!.email];
    if (userData != null) {
      userData['user'] = _currentUser!.toJson();
      await _saveUsersDb(usersDb);
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? name,
    String? phone,
    UserPreferences? preferences,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        preferences: preferences ?? _currentUser!.preferences,
      );

      final usersDb = await _getUsersDb();
      final userData = usersDb[_currentUser!.email];
      if (userData != null) {
        userData['user'] = _currentUser!.toJson();
        await _saveUsersDb(usersDb);
      }

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure('Failed to update profile');
    }
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      final usersDb = await _getUsersDb();
      final userData = usersDb[_currentUser!.email];
      if (userData == null) {
        return AuthResult.failure('User not found');
      }

      // Verify current password
      final storedHash = userData['password_hash'] as String;
      final salt = userData['salt'] as String;
      final inputHash = _hashPassword(currentPassword, salt);

      if (inputHash != storedHash) {
        return AuthResult.failure('Current password is incorrect');
      }

      // Validate new password
      if (validatePassword(newPassword) == PasswordStrength.weak) {
        return AuthResult.failure(
            'New password must be at least 8 characters');
      }

      // Update password
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);
      userData['password_hash'] = newHash;
      userData['salt'] = newSalt;
      await _saveUsersDb(usersDb);

      return AuthResult.success(_currentUser!);
    } catch (e) {
      return AuthResult.failure('Failed to change password');
    }
  }

  /// Delete account
  Future<AuthResult> deleteAccount(String password) async {
    if (_currentUser == null) {
      return AuthResult.failure('Not logged in');
    }

    try {
      final usersDb = await _getUsersDb();
      final userData = usersDb[_currentUser!.email];
      if (userData == null) {
        return AuthResult.failure('User not found');
      }

      // Verify password
      final storedHash = userData['password_hash'] as String;
      final salt = userData['salt'] as String;
      final inputHash = _hashPassword(password, salt);

      if (inputHash != storedHash) {
        return AuthResult.failure('Incorrect password');
      }

      // Remove user
      usersDb.remove(_currentUser!.email);
      await _saveUsersDb(usersDb);
      await signOut();

      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Failed to delete account');
    }
  }

  /// Get default subscriptions for new users
  List<String> _getDefaultSubscriptions() {
    return [
      'sub_hdfc_cc',
      'sub_zomato_gold',
      'sub_ieee',
    ];
  }

  // ==================== Google Sign-In ====================

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in was cancelled');
      }

      final email = googleUser.email.toLowerCase();
      final name = googleUser.displayName ?? email.split('@').first;
      final avatarUrl = googleUser.photoUrl;

      final usersDb = await _getUsersDb();

      if (usersDb.containsKey(email)) {
        // Existing user - sign in
        final userData = usersDb[email]!;
        final user = UserModel.fromJson(
            userData['user'] as Map<String, dynamic>);
        
        // Update with Google info if available
        final updatedUser = user.copyWith(
          lastLogin: DateTime.now(),
          avatarUrl: avatarUrl ?? user.avatarUrl,
        );
        userData['user'] = updatedUser.toJson();
        userData['is_google_user'] = true;
        await _saveUsersDb(usersDb);

        _currentUser = updatedUser;
        _sessionToken = _generateSessionToken(email);
        await _saveSession();

        return AuthResult.success(updatedUser);
      } else {
        // New user - create account
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        final now = DateTime.now();

        final user = UserModel(
          id: userId,
          email: email,
          name: name,
          avatarUrl: avatarUrl,
          subscriptionIds: _getDefaultSubscriptions(),
          createdAt: now,
          lastLogin: now,
          preferences: UserPreferences(),
        );

        usersDb[email] = {
          'user': user.toJson(),
          'is_google_user': true,
        };
        await _saveUsersDb(usersDb);

        _currentUser = user;
        _sessionToken = _generateSessionToken(email);
        await _saveSession();

        return AuthResult.success(user);
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return AuthResult.failure('Failed to sign in with Google. Please try again.');
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign out error: $e');
    }
  }

  /// Check if user is signed in with Google
  bool isGoogleUser() {
    return _googleSignIn.currentUser != null;
  }

  // ==================== OTP Verification ====================

  /// Generate 6-digit OTP
  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP for password reset (simulated - in production use SMS/Email API)
  Future<OtpResult> sendPasswordResetOtp(String email) async {
    try {
      if (!isValidEmail(email)) {
        return OtpResult.failure('Please enter a valid email address');
      }

      final usersDb = await _getUsersDb();
      final emailLower = email.toLowerCase();

      if (!usersDb.containsKey(emailLower)) {
        return OtpResult.failure('No account found with this email');
      }

      // Check if it's a Google-only user
      final userData = usersDb[emailLower]!;
      if (userData['is_google_user'] == true && userData['password_hash'] == null) {
        return OtpResult.failure(
            'This account uses Google Sign-In. Please sign in with Google.');
      }

      // Generate OTP
      final otp = _generateOtp();
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      // Store OTP securely
      final otpData = {
        'email': emailLower,
        'otp': otp,
        'expiry': expiryTime.toIso8601String(),
        'attempts': 0,
      };
      await _secureStorage.write(
        key: _otpStorageKey,
        value: json.encode(otpData),
      );

      // In production, send OTP via SMS/Email service
      // For demo, we'll return the OTP (in real app, never do this!)
      debugPrint('OTP for $emailLower: $otp'); // Remove in production!

      return OtpResult.success(
        message: 'OTP sent to ${maskEmail(emailLower)}',
        // In demo mode, include OTP for testing (remove in production)
        otp: kDebugMode ? otp : null,
      );
    } catch (e) {
      debugPrint('Send OTP error: $e');
      return OtpResult.failure('Failed to send OTP. Please try again.');
    }
  }

  /// Mask email for display (show first 2 chars and domain)
  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name***@$domain';
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
  }

  /// Verify OTP
  Future<OtpResult> verifyOtp(String email, String otp) async {
    try {
      final otpDataStr = await _secureStorage.read(key: _otpStorageKey);
      if (otpDataStr == null) {
        return OtpResult.failure('OTP expired. Please request a new one.');
      }

      final otpData = json.decode(otpDataStr) as Map<String, dynamic>;
      final storedEmail = otpData['email'] as String;
      final storedOtp = otpData['otp'] as String;
      final expiry = DateTime.parse(otpData['expiry'] as String);
      var attempts = otpData['attempts'] as int;

      // Check email match
      if (storedEmail != email.toLowerCase()) {
        return OtpResult.failure('Invalid OTP request');
      }

      // Check expiry
      if (DateTime.now().isAfter(expiry)) {
        await _secureStorage.delete(key: _otpStorageKey);
        return OtpResult.failure('OTP expired. Please request a new one.');
      }

      // Check attempts (max 3)
      if (attempts >= 3) {
        await _secureStorage.delete(key: _otpStorageKey);
        return OtpResult.failure('Too many attempts. Please request a new OTP.');
      }

      // Verify OTP
      if (otp != storedOtp) {
        // Increment attempts
        attempts++;
        otpData['attempts'] = attempts;
        await _secureStorage.write(
          key: _otpStorageKey,
          value: json.encode(otpData),
        );
        return OtpResult.failure(
            'Invalid OTP. ${3 - attempts} attempts remaining.');
      }

      // OTP verified - mark as verified but don't delete yet
      otpData['verified'] = true;
      await _secureStorage.write(
        key: _otpStorageKey,
        value: json.encode(otpData),
      );

      return OtpResult.success(message: 'OTP verified successfully');
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      return OtpResult.failure('Verification failed. Please try again.');
    }
  }

  /// Reset password after OTP verification
  Future<AuthResult> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Check OTP was verified
      final otpDataStr = await _secureStorage.read(key: _otpStorageKey);
      if (otpDataStr == null) {
        return AuthResult.failure('Please verify OTP first');
      }

      final otpData = json.decode(otpDataStr) as Map<String, dynamic>;
      if (otpData['email'] != email.toLowerCase() ||
          otpData['verified'] != true) {
        return AuthResult.failure('Please verify OTP first');
      }

      // Validate new password
      if (validatePassword(newPassword) == PasswordStrength.weak) {
        return AuthResult.failure(
            'Password must be at least 8 characters with mix of letters, numbers');
      }

      final usersDb = await _getUsersDb();
      final emailLower = email.toLowerCase();
      final userData = usersDb[emailLower];

      if (userData == null) {
        return AuthResult.failure('User not found');
      }

      // Update password
      final newSalt = _generateSalt();
      final newHash = _hashPassword(newPassword, newSalt);
      userData['password_hash'] = newHash;
      userData['salt'] = newSalt;
      await _saveUsersDb(usersDb);

      // Clear OTP data
      await _secureStorage.delete(key: _otpStorageKey);

      return AuthResult.success(null);
    } catch (e) {
      debugPrint('Reset password error: $e');
      return AuthResult.failure('Failed to reset password. Please try again.');
    }
  }

  /// Resend OTP
  Future<OtpResult> resendOtp(String email) async {
    // Clear existing OTP and send new one
    await _secureStorage.delete(key: _otpStorageKey);
    return sendPasswordResetOtp(email);
  }
}

class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String? error;

  AuthResult._({required this.isSuccess, this.user, this.error});

  factory AuthResult.success(UserModel? user) =>
      AuthResult._(isSuccess: true, user: user);
  
  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, error: error);
}

class OtpResult {
  final bool isSuccess;
  final String? message;
  final String? error;
  final String? otp; // Only for debug mode

  OtpResult._({required this.isSuccess, this.message, this.error, this.otp});

  factory OtpResult.success({required String message, String? otp}) =>
      OtpResult._(isSuccess: true, message: message, otp: otp);
  
  factory OtpResult.failure(String error) =>
      OtpResult._(isSuccess: false, error: error);
}

enum PasswordStrength { weak, medium, strong }
