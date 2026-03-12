import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class ForgotPasswordScreenNew extends StatefulWidget {
  const ForgotPasswordScreenNew({super.key});

  @override
  State<ForgotPasswordScreenNew> createState() =>
      _ForgotPasswordScreenNewState();
}

class _ForgotPasswordScreenNewState extends State<ForgotPasswordScreenNew> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _step = 0; // 0=email, 1=otp, 2=new password
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _auth.sendPasswordResetOtp(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.isSuccess) {
      setState(() {
        _step = 1;
        _success = result.message;
      });
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Please enter the 6-digit OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await _auth.verifyOtp(_emailCtrl.text.trim(), _otpCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.isSuccess) {
      setState(() {
        _step = 2;
        _success = result.message;
      });
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _resetPassword() async {
    if (_passCtrl.text.isEmpty ||
        _auth.validatePassword(_passCtrl.text) == PasswordStrength.weak) {
      setState(() => _error = 'Please enter a strong password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _auth.resetPassword(
        email: _emailCtrl.text.trim(), newPassword: _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.lock_reset_rounded,
                      size: 56, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text('Reset Password',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 28),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Steps indicator
                        Row(
                          children: List.generate(3, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? AppColors.primary
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_success != null && _error == null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_success!,
                                style: const TextStyle(
                                    color: AppColors.success, fontSize: 13)),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (_step == 0) ...[
                          const Text('Enter Email',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            label: 'Send OTP',
                            isLoading: _loading,
                            onPressed: _sendOtp,
                          ),
                        ],

                        if (_step == 1) ...[
                          const Text('Verify OTP',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: '6-digit OTP',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'Verify',
                            isLoading: _loading,
                            onPressed: _verifyOtp,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              final r = await _auth.resendOtp(
                                  _emailCtrl.text.trim());
                              if (mounted) {
                                setState(() {
                                  _success = r.isSuccess ? r.message : null;
                                  _error = r.isSuccess ? null : r.error;
                                });
                              }
                            },
                            child: const Text('Resend OTP'),
                          ),
                        ],

                        if (_step == 2) ...[
                          const Text('New Password',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            label: 'Reset Password',
                            isLoading: _loading,
                            onPressed: _resetPassword,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
