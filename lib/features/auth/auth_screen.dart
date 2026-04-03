import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ─── Send OTP ──────────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text.trim()}',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) context.go('/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? AppStrings.errorGeneric;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.errorGeneric;
      });
    }
  }

  // ─── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Invalid OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n(ref.watch(languageProvider));
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language toggle top-right
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => ref.read(languageProvider.notifier)
                        .setLanguage(lang == 'kn' ? 'en' : 'kn'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lang == 'kn' ? 'EN' : 'ಕನ್ನಡ',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Logo
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.verified_user, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('DigiSampatti',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
                Center(
                  child: Text(l.platformTagline,
                    style: const TextStyle(color: AppColors.textMedium, fontSize: 14)),
                ),
                const SizedBox(height: 40),

                // Phone Input
                if (!_otpSent) ...[
                  Text(l.enterMobileNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      prefixText: '+91 ',
                      hintText: '9876543210',
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.length != 10) return 'Enter 10-digit mobile number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(l.sendOtp),
                  ),
                ] else ...[
                  Text('${l.otpSentTo}+91 ${_phoneController.text}',
                    style: const TextStyle(color: AppColors.textMedium)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(hintText: l.enterOtpHint, counterText: ''),
                    validator: (v) {
                      if (v == null || v.length != 6) return 'Enter 6-digit OTP';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(l.verifyOtp),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() { _otpSent = false; }),
                      child: Text(l.changeNumber),
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusDangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!,
                      style: const TextStyle(color: AppColors.statusDangerText)),
                  ),
                ],

                const SizedBox(height: 32),
                Center(
                  child: Text(l.agreeTerms,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
