import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/user_service.dart';

// ─── User Setup Screen ────────────────────────────────────────────────────────
// Shown ONCE on first login.
// User selects their type and enters name → saved to Firestore.
// Brokers see an extra RERA verification form.
// ─────────────────────────────────────────────────────────────────────────────

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  UserType? _selectedType;
  final _nameController = TextEditingController();
  final _reraController = TextEditingController();
  final _officeController = TextEditingController();
  bool _isSaving = false;

  static const _types = [
    (UserType.buyer,  'I am buying property'),
    (UserType.broker, 'I am a Broker / Agent'),
    (UserType.nri,    'I am NRI buying in India'),
    (UserType.seller, 'I am selling property'),
    (UserType.lawyer, 'I am a Lawyer / Advocate'),
    (UserType.bank,   'I am from a Bank / NBFC'),
  ];

  Future<void> _save() async {
    if (_selectedType == null) return;
    setState(() => _isSaving = true);
    try {
      await UserService().saveUserType(
        userType: _selectedType!,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );
      if (_selectedType == UserType.broker &&
          _reraController.text.trim().isNotEmpty) {
        await UserService().submitBrokerVerification(
          reraAgentId: _reraController.text.trim(),
          officeName: _officeController.text.trim(),
          city: 'Karnataka',
        );
      }
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Welcome to DigiSampatti!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 4),
              const Text('Tell us who you are — helps us show the right tools',
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
              const SizedBox(height: 28),

              // ── User type grid ──────────────────────────────────────────
              const Text('I am a...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
                children: _types.map((t) {
                  final type = t.$1;
                  final label = t.$2;
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.borderColor,
                            width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Text(type.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(type.label,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textDark)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Name (optional) ─────────────────────────────────────────
              const Text('Your Name (optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ramesh Kumar',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),

              // ── Broker RERA verification ────────────────────────────────
              if (_selectedType == UserType.broker) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text('Broker Verification',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your RERA Agent ID to get a verified badge. '
                        'Your registration will be checked against RERA Karnataka records.',
                        style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _reraController,
                        decoration: const InputDecoration(
                          labelText: 'RERA Agent Registration ID',
                          hintText: 'e.g. PRM/KA/RERA/1251/309/AG/180919/000001',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _officeController,
                        decoration: const InputDecoration(
                          labelText: 'Office / Agency Name',
                          hintText: 'e.g. Srinivas Properties, Bengaluru',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _VerificationStepsCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Save button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedType == null || _isSaving) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Continue to DigiSampatti',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Skip for now',
                      style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reraController.dispose();
    _officeController.dispose();
    super.dispose();
  }
}

// ── Broker verification steps explained ───────────────────────────────────────
class _VerificationStepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('How broker verification works:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54)),
        SizedBox(height: 6),
        _Step('1', 'You submit RERA Agent ID here'),
        _Step('2', 'DigiSampatti team checks against RERA Karnataka portal'),
        _Step('3', 'Verified badge appears on your profile within 24–48 hrs'),
        _Step('4', 'Clients can see your RERA ID, listings, and reviews'),
        SizedBox(height: 4),
        Text('Without RERA ID you can still use the app — just no verified badge.',
            style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String label;
  const _Step(this.num, this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
            child: Center(child: Text(num, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87))),
        ],
      ),
    );
  }
}
