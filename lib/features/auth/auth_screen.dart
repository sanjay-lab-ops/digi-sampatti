import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';
import 'package:digi_sampatti/core/services/user_service.dart';
import 'package:digi_sampatti/core/widgets/ds_logo.dart';

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

  // ─── After login: save to Firestore, route to setup if first time ──────────
  Future<void> _afterLogin() async {
    if (!mounted) return;
    try {
      final user = await UserService().getOrCreateProfile();
      if (!mounted) return;
      if (user.isFirstLogin) {
        context.go('/setup');   // new user → choose type + name
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
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
          await _afterLogin();
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
      await _afterLogin();
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
                const Center(child: DSLogo(size: 72)),
                const SizedBox(height: 24),
                const Center(
                  child: Text('DigiSampatti',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
                Center(
                  child: Text(l.platformTagline,
                    style: const TextStyle(color: AppColors.textMedium, fontSize: 14)),
                ),
                const SizedBox(height: 20),

                // Feature chips
                _FeatureChips(),

                const SizedBox(height: 28),

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

// ─── Feature Chips ────────────────────────────────────────────────────────────
class _FeatureChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Legal Score — highlighted chip
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.psychology_outlined, color: Color(0xFF1B5E20)),
                SizedBox(width: 8),
                Text('AI Legal Score', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              content: const Text(
                'Our AI analyses RTC ownership, EC transaction history, RERA registration, '
                'eCourt cases, and CERSAI mortgage data to give a 0–100 property safety score.\n\n'
                '🟢 80–100 : Safe to buy\n'
                '🟡 50–79  : Verify before buying\n'
                '🔴 0–49   : High risk — consult advocate',
                style: TextStyle(height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Legal Score',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('0–100 property safety score from government portals',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.info_outline, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
        // Small feature chips row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _Chip(icon: Icons.account_balance_outlined, label: '7 Govt Portals'),
            _Chip(icon: Icons.shield_outlined,           label: '8 Fraud Types'),
            _Chip(icon: Icons.timer_outlined,            label: '90 Seconds'),
            _Chip(icon: Icons.location_off_outlined,     label: 'Zero Office Visits'),
            _Chip(icon: Icons.gavel_outlined,            label: 'DPDP Act 2023'),
            _Chip(icon: Icons.workspace_premium_outlined, label: 'Patent Pending'),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8D8B8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
