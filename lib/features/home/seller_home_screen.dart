import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class SellerHomeScreen extends ConsumerWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('I\'m a Seller'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), AppColors.safe],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sell_outlined, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text('List & Sell Your Property',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Get AI-verified badge • Reach serious buyers • Sell faster',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => context.push('/seller-kyc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_home_outlined, size: 18),
                      label: const Text('List Property', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => context.push('/seller-listing'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.list_alt_outlined, size: 18),
                      label: const Text('My Listings', style: TextStyle(fontSize: 13)),
                    )),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seller journey steps
            const Text('Seller Journey',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            _SellerJourneyCard(),
            const SizedBox(height: 16),

            // Pricing tiers
            const Text('Listing Plans',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            _PricingCard(),
            const SizedBox(height: 16),

            // Seller tools
            const Text('Seller Tools',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            _SellerToolsList(),
            const SizedBox(height: 16),

            // Document vault
            _DocumentVaultCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller-kyc'),
        backgroundColor: AppColors.safe,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SellerJourneyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(1, 'Verify Your Identity', 'KYC with Aadhaar/PAN', Icons.verified_user_outlined, true),
      _Step(2, 'Upload Documents', 'RTC, EC, Title Deed, etc.', Icons.upload_file_outlined, false),
      _Step(3, 'AI Verification', 'Get 0–100 document score', Icons.psychology_outlined, false),
      _Step(4, 'List Property', 'Set price, add photos', Icons.add_home_outlined, false),
      _Step(5, 'Connect Buyers', 'Secure chat, no direct contact', Icons.chat_outlined, false),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: steps.asMap().entries.map((e) => _StepRow(
          step: e.value,
          isLast: e.key == steps.length - 1,
        )).toList(),
      ),
    );
  }
}

class _Step {
  final int num;
  final String title, subtitle;
  final IconData icon;
  final bool done;
  const _Step(this.num, this.title, this.subtitle, this.icon, this.done);
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isLast;
  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: step.done ? AppColors.safe : AppColors.borderColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: step.done
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text('${step.num}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMedium))),
        ),
        if (!isLast) Container(width: 2, height: 30, color: AppColors.borderColor),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Icon(step.icon, size: 16, color: step.done ? AppColors.safe : AppColors.textLight),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: step.done ? AppColors.textDark : AppColors.textMedium)),
            Text(step.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
        ]),
      )),
    ]);
  }
}

class _PricingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _PriceTile('Basic', '₹99', 'Verify Docs\nBasic listing', AppColors.textMedium, false)),
      const SizedBox(width: 8),
      Expanded(child: _PriceTile('Standard', '₹199', 'Verified badge\nBuyer leads', AppColors.primary, true)),
      const SizedBox(width: 8),
      Expanded(child: _PriceTile('Premium', '₹499', 'Full report\nPriority listing', AppColors.safe, false)),
    ]);
  }
}

class _PriceTile extends StatelessWidget {
  final String plan, price, features;
  final Color color;
  final bool highlighted;
  const _PriceTile(this.plan, this.price, this.features, this.color, this.highlighted);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlighted ? color : AppColors.borderColor, width: highlighted ? 2 : 1),
      ),
      child: Column(children: [
        if (highlighted) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: const Text('Popular', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        Text(plan, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(features, style: const TextStyle(fontSize: 10, color: AppColors.textLight), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _SellerToolsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(Icons.psychology_outlined, 'AI Document Score', 'Upload & get 0–100 score', '/upload'),
      _Tool(Icons.lock_outlined, 'Document Vault', 'Secure storage with OTP lock', '/escrow'),
      _Tool(Icons.calculate_outlined, 'Property Valuation', 'Market price estimate', '/stamp-duty'),
      _Tool(Icons.people_outline, 'Expert Services', 'Legal, survey, insurance', '/partners'),
      _Tool(Icons.assignment_outlined, 'e-Sign Agreement', 'Digital sale agreement', '/esign'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: tools.asMap().entries.map((e) => Column(children: [
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.safe.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(e.value.icon, color: AppColors.safe, size: 18),
            ),
            title: Text(e.value.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(e.value.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLight),
            onTap: () => context.push(e.value.route),
            dense: true,
          ),
          if (e.key < tools.length - 1) const Divider(height: 1, indent: 60),
        ])).toList(),
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String title, subtitle, route;
  const _Tool(this.icon, this.title, this.subtitle, this.route);
}

class _DocumentVaultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/escrow'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2137),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: const Icon(Icons.lock_outlined, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Secure Document Vault', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 2),
            Text('Your docs are OTP-locked. Buyer can only view after escrow starts.',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 14),
        ]),
      ),
    );
  }
}
