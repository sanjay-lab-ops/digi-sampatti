import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Shown when buyer taps "Start Deal" — confirms the ₹99 connection fee
/// and explains exactly what happens next before going to the transaction dashboard.
class DealConnectScreen extends StatefulWidget {
  final String? propertyTitle;
  final String? sellerName;
  final String? price;

  const DealConnectScreen({
    super.key,
    this.propertyTitle,
    this.sellerName,
    this.price,
  });

  @override
  State<DealConnectScreen> createState() => _DealConnectScreenState();
}

class _DealConnectScreenState extends State<DealConnectScreen>
    with SingleTickerProviderStateMixin {
  bool _paid = false;
  bool _paying = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _paying = false; _paid = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Start a Deal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _paid ? _buildSuccess(context) : _buildPayment(context),
    );
  }

  Widget _buildPayment(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Property summary card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.4)),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_outlined, color: Color(0xFF42A5F5), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    widget.propertyTitle ?? 'Selected Property',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Listed by ${widget.sellerName ?? "Seller"}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ])),
              ]),
              if (widget.price != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.currency_rupee, color: Colors.white54, size: 14),
                  Text(widget.price!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ],
            ]),
          ),

          const SizedBox(height: 24),

          // What happens
          const Text('What happens when you connect?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),

          _WhatHappensItem(
            step: 1,
            icon: Icons.lock_outline,
            color: const Color(0xFF42A5F5),
            title: 'Seller is notified instantly',
            body: 'The seller receives your connection request. No phone numbers are shared.',
          ),
          _WhatHappensItem(
            step: 2,
            icon: Icons.handshake_outlined,
            color: const Color(0xFF66BB6A),
            title: 'Shared deal room is created',
            body: 'Both you and the seller land on the same Transaction Dashboard. 8 stages, tracked together.',
          ),
          _WhatHappensItem(
            step: 3,
            icon: Icons.chat_outlined,
            color: const Color(0xFFF59E0B),
            title: 'Negotiation begins immediately',
            body: 'Secure in-app chat + offer exchange. No WhatsApp. No unknown middlemen.',
          ),
          _WhatHappensItem(
            step: 4,
            icon: Icons.verified_outlined,
            color: const Color(0xFFCE93D8),
            title: 'Document verification included',
            body: 'You get access to the seller\'s verified documents and Trust Score report.',
          ),
          _WhatHappensItem(
            step: 5,
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF26C6DA),
            title: 'Digital escrow protects your advance',
            body: 'Advance amount is held safely. Released to seller only after registration.',
            isLast: true,
          ),

          const SizedBox(height: 24),

          // Fee box
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFFF59E0B).withOpacity(0.3),
                    const Color(0xFFF59E0B).withOpacity(0.8),
                    _pulse.value,
                  )!,
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.08),
                    const Color(0xFFF59E0B).withOpacity(0.14),
                  ],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: child,
            ),
            child: Column(children: [
              const Text('One-Time Connection Fee',
                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('₹99', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Includes: Deal room + Secure chat + Doc access + Escrow protection',
                style: TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
            ]),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _paying ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            child: _paying
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Pay ₹99 & Start Deal'),
          ),

          const SizedBox(height: 12),
          const Text(
            '🔒  Payment secured via UPI / Card · No broker fees · No commission on sale',
            style: TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppColors.safe.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.safe.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.safe, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Deal Room Created!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              '${widget.sellerName ?? "The seller"} has been notified. You are now connected.\nNegotiate securely in your shared deal room.',
              style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Connection visual
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Avatar('You', const Color(0xFF1565C0)),
              Expanded(child: Column(children: [
                const Divider(color: Color(0xFF42A5F5), thickness: 2),
                const Text('Connected', style: TextStyle(color: Color(0xFF42A5F5), fontSize: 10, fontWeight: FontWeight.bold)),
              ])),
              _Avatar(widget.sellerName?.split(' ').first ?? 'Seller', const Color(0xFF2E7D32)),
            ]),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/transaction'),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Open Transaction Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatHappensItem extends StatelessWidget {
  final int step;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool isLast;

  const _WhatHappensItem({
    required this.step, required this.icon, required this.color,
    required this.title, required this.body, this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        if (!isLast)
          Container(width: 2, height: 36, color: Colors.white10),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
        ]),
      )),
    ]);
  }
}

class _Avatar extends StatelessWidget {
  final String label;
  final Color color;
  const _Avatar(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: color.withOpacity(0.2),
        child: Text(label[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}
