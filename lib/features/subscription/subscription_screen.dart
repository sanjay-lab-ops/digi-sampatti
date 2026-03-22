import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _paymentService = PaymentService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
    _paymentService.onSuccess = _onSuccess;
    _paymentService.onFailure = _onFailure;
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _pay(int amount, String desc) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    _paymentService.openPaymentAmount(
      amount: amount,
      userPhone: phone,
      description: desc,
    );
  }

  void _onSuccess(PaymentSuccessResponse r) {
    setState(() => _isProcessing = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.safe, size: 60),
            const SizedBox(height: 16),
            const Text('Payment Successful!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Your subscription is now active. Enjoy unlimited reports!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Start Using'),
            ),
          ],
        ),
      ),
    );
  }

  void _onFailure(PaymentFailureResponse r) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.message ?? 'Payment failed. Try again.'),
        backgroundColor: AppColors.danger));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Plans & Pricing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPlanCard(
              title: 'Single Report',
              price: '₹99',
              period: 'per report',
              color: AppColors.info,
              features: const [
                'Full legal report for 1 property',
                'AI risk analysis + safety score',
                'PDF download & WhatsApp share',
                'Valid for 30 days',
              ],
              buttonText: 'Buy Single Report — ₹99',
              onTap: () => _pay(99, 'DigiSampatti — Single Property Report'),
              isPopular: false,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              title: 'Monthly Unlimited',
              price: '₹999',
              period: 'per month',
              color: AppColors.primary,
              features: const [
                'Unlimited property reports',
                'Priority AI analysis',
                'PDF download & share — unlimited',
                'Court case check — unlimited',
                'Cancel anytime',
                'Best for brokers & investors',
              ],
              buttonText: 'Subscribe — ₹999/month',
              onTap: () => _pay(999, 'DigiSampatti — Monthly Unlimited Plan'),
              isPopular: true,
            ),
            const SizedBox(height: 12),
            _buildBrokerPlan(),
            const SizedBox(height: 20),
            _buildFaq(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.verified_user, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text('Simple, Honest Pricing',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('No hidden charges. No subscription traps.\nPay only when you verify.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required Color color,
    required List<String> features,
    required String buttonText,
    required VoidCallback onTap,
    required bool isPopular,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isPopular ? color : AppColors.borderColor, width: isPopular ? 2 : 1),
            boxShadow: isPopular ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) const SizedBox(height: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(period, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: AppColors.textMedium))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isProcessing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: const Text('MOST POPULAR',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
      ],
    );
  }

  Widget _buildBrokerPlan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people, color: Color(0xFF1A237E), size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Broker / Agency Plan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E))),
                SizedBox(height: 3),
                Text('Custom pricing for teams with 5+ users. Volume discounts available.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact: support@digisampatti.com'))),
            child: const Text('Contact Us'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaq() {
    const faqs = [
      ('Can I cancel anytime?', 'Yes. Monthly plan can be cancelled anytime. No questions asked.'),
      ('Is payment secure?', 'Yes. All payments via Razorpay — India\'s most trusted payment gateway. UPI, Card, Net Banking accepted.'),
      ('What if I\'m not satisfied?', 'Contact support@digisampatti.com within 24 hours of purchase for a refund.'),
      ('Does the report work for all of Karnataka?', 'Yes — all 31 Karnataka districts. Bhoomi data covers the entire state.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Common Questions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
        const SizedBox(height: 12),
        ...faqs.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(f.$2, style: const TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
            ],
          ),
        )),
      ],
    );
  }
}
