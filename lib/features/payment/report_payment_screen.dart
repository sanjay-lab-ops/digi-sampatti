import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/payment_service.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Report Payment Wall ───────────────────────────────────────────────────────
// Shown before the AI analysis runs. User pays ₹149 → analysis unlocks.
// Supports: Razorpay (when KYC done) / UPI direct / WhatsApp manual.
// ──────────────────────────────────────────────────────────────────────────────

class ReportPaymentScreen extends ConsumerStatefulWidget {
  const ReportPaymentScreen({super.key});

  @override
  ConsumerState<ReportPaymentScreen> createState() =>
      _ReportPaymentScreenState();
}

class _ReportPaymentScreenState extends ConsumerState<ReportPaymentScreen> {
  final _payService = PaymentService();
  bool _loading = false;
  String? _error;

  static const int _price = 149;

  @override
  void initState() {
    super.initState();
    _payService.initialize();
    _payService.onSuccess = _onPaymentSuccess;
    _payService.onFailure = (e) => setState(() {
          _loading = false;
          _error = e;
        });
  }

  @override
  void dispose() {
    _payService.dispose();
    super.dispose();
  }

  void _onPaymentSuccess(String paymentId) {
    if (!mounted) return;
    context.pushReplacement('/auto-scan');
  }

  Future<void> _payUpi() async {
    setState(() { _loading = true; _error = null; });
    final launched = await PaymentService.openUpiPayment(
      amountInRupees: _price,
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    if (!mounted) return;
    if (launched) {
      // Show "I've paid" button — UPI doesn't give callback
      setState(() => _loading = false);
      _showUpiConfirmDialog();
    } else {
      setState(() {
        _loading = false;
        _error = 'No UPI app found. Try WhatsApp payment below.';
      });
    }
  }

  void _showUpiConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Sent?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'After completing payment in your UPI app, tap "Confirm" to proceed '
          'to your report.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              context.pushReplacement('/auto-scan');
            },
            child: const Text('Confirm — Run Analysis'),
          ),
        ],
      ),
    );
  }

  Future<void> _payWhatsApp() async {
    await PaymentService.openWhatsAppPayment(
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      amountInRupees: _price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final propType = ref.watch(propertyTypeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unlock Analysis'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── What you get ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Full Property Risk Report',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17)),
                      Text(_propLabel(propType),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  _tick('AI reads all uploaded documents (OCR)'),
                  _tick('30+ fraud checks across 7 government portals'),
                  _tick('Risk Score 0–100 with explanation'),
                  _tick('Red flags: injunctions, loans, B-Khata, disputes'),
                  _tick('Recommended next steps'),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹$_price',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text('one-time · for this property',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.white70, size: 12),
                        SizedBox(width: 5),
                        Text('Powered by Claude AI',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Payment options ─────────────────────────────────────────────
            const Text('Choose Payment Method',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),

            // UPI — works instantly
            _PayOption(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF4CAF50),
              title: 'Pay with UPI',
              subtitle: 'PhonePe · GPay · BHIM · Any UPI app',
              badge: 'INSTANT',
              badgeColor: AppColors.safe,
              onTap: _loading ? null : _payUpi,
            ),
            const SizedBox(height: 10),

            // WhatsApp manual
            _PayOption(
              icon: Icons.chat_outlined,
              iconColor: const Color(0xFF25D366),
              title: 'Pay via WhatsApp',
              subtitle: 'Share payment details on WhatsApp',
              badge: null,
              badgeColor: Colors.transparent,
              onTap: _loading ? null : _payWhatsApp,
            ),
            const SizedBox(height: 10),

            // Skip for testing
            _PayOption(
              icon: Icons.science_outlined,
              iconColor: Colors.grey,
              title: 'Test Mode — Skip Payment',
              subtitle: 'For development only',
              badge: 'DEV',
              badgeColor: Colors.grey,
              onTap: () => context.pushReplacement('/auto-scan'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.red))),
                ]),
              ),
            ],

            if (_loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],

            const SizedBox(height: 32),

            // Trust row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _trustChip(Icons.lock_outline, 'Secure'),
                const SizedBox(width: 12),
                _trustChip(Icons.verified_outlined, 'DPDP Act 2023'),
                const SizedBox(width: 12),
                _trustChip(Icons.receipt_long_outlined, 'Receipt sent'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tick(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.check_circle_outline,
          color: Colors.white70, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, height: 1.4))),
    ]),
  );

  Widget _trustChip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AppColors.textLight),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
    ],
  );

  String _propLabel(String t) => switch (t) {
    'apartment'  => 'Apartment / Flat',
    'bda_layout' => 'BDA Layout Plot',
    'house'      => 'Independent House',
    'farm'       => 'Agricultural Land',
    'commercial' => 'Commercial Property',
    _            => 'Residential Site / Plot',
  };
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _PayOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: onTap == null
                          ? Colors.grey
                          : AppColors.textDark)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight)),
            ],
          )),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(badge!,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor)),
            ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios,
              size: 14,
              color: onTap == null
                  ? Colors.grey.shade300
                  : AppColors.textLight),
        ]),
      ),
    );
  }
}
