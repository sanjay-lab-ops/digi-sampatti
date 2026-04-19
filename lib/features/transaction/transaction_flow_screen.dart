import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Master transaction dashboard — shows all 8 stages of a property deal.
/// Buyer and Seller both land here after the initial contact is made.
class TransactionFlowScreen extends StatefulWidget {
  final String? propertyTitle;
  final String? sellerName;
  final String? agreedPrice;

  const TransactionFlowScreen({
    super.key,
    this.propertyTitle,
    this.sellerName,
    this.agreedPrice,
  });

  @override
  State<TransactionFlowScreen> createState() => _TransactionFlowScreenState();
}

class _TransactionFlowScreenState extends State<TransactionFlowScreen> {
  // Track which steps are completed
  final Set<int> _completed = {};

  static const _stages = [
    _Stage(
      step: 1,
      icon: Icons.handshake_outlined,
      title: 'Negotiation',
      subtitle: 'Agree on price & terms',
      route: '/negotiation',
      color: Color(0xFF1565C0),
      description: 'Buyer & seller exchange offers via secure chat. Final price agreed and locked.',
    ),
    _Stage(
      step: 2,
      icon: Icons.search_outlined,
      title: 'Due Diligence',
      subtitle: 'Verify property documents',
      route: '/due-diligence',
      color: Color(0xFFE65100),
      description: 'EC check · RTC/Pahani · RERA · Court cases · CERSAI · Khata',
    ),
    _Stage(
      step: 3,
      icon: Icons.receipt_long_outlined,
      title: 'Advance Receipt',
      subtitle: 'Document the token payment',
      route: '/advance-receipt',
      color: Color(0xFF00695C),
      description: 'Generate advance receipt PDF. Both parties sign. Amount recorded.',
    ),
    _Stage(
      step: 4,
      icon: Icons.account_balance_outlined,
      title: 'Digital Escrow',
      subtitle: 'Secure advance in escrow',
      route: '/escrow',
      color: Color(0xFF1B5E20),
      description: 'Advance amount held safely. Released to seller only after registration. 100% protected.',
      isRequired: true,
    ),
    _Stage(
      step: 5,
      icon: Icons.description_outlined,
      title: 'Sale Agreement',
      subtitle: 'Draft & sign agreement',
      route: '/agreement',
      color: Color(0xFF6A1B9A),
      description: 'Standard sale agreement with clauses. Both parties eSign via Aadhaar OTP.',
    ),
    _Stage(
      step: 6,
      icon: Icons.calculate_outlined,
      title: 'Stamp Duty',
      subtitle: 'Calculate & pay stamp duty',
      route: '/transfer/stamp-duty',
      color: Color(0xFF558B2F),
      description: 'Stamp duty + registration fee calculation based on guidance value.',
    ),
    _Stage(
      step: 7,
      icon: Icons.location_city_outlined,
      title: 'SRO Registration',
      subtitle: 'Registration guide & steps',
      route: '/transfer/registration',
      color: Color(0xFF0277BD),
      description: 'Step-by-step guide. Both parties at SRO. Sale deed registered. EC updated.',
    ),
    _Stage(
      step: 8,
      icon: Icons.home_work_outlined,
      title: 'Post Purchase',
      subtitle: 'Khata · Mutation · Tax',
      route: '/post-purchase',
      color: Color(0xFF37474F),
      description: 'Khata transfer · Property tax name change · Annual health check',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Property Transaction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text(widget.propertyTitle ?? 'Active Deal', style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.safe.withOpacity(0.5)),
            ),
            child: Text(
              '${_completed.length}/8 done',
              style: const TextStyle(color: AppColors.safe, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Deal summary banner
          _DealSummaryBanner(
            property: widget.propertyTitle ?? 'Property',
            seller: widget.sellerName ?? 'Seller',
            price: widget.agreedPrice ?? 'TBD',
            completed: _completed.length,
          ),
          // Stages list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _stages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final stage = _stages[i];
                final done = _completed.contains(stage.step);
                final current = !done && (i == 0 || _completed.contains(_stages[i - 1].step));
                return _StageCard(
                  stage: stage,
                  isDone: done,
                  isCurrent: current,
                  onTap: () {
                    context.push(stage.route);
                  },
                  onMarkDone: () => setState(() {
                    if (done) _completed.remove(stage.step);
                    else _completed.add(stage.step);
                  }),
                );
              },
            ),
          ),
        ],
      ),
    ));
  }
}

class _DealSummaryBanner extends StatelessWidget {
  final String property, seller, price;
  final int completed;
  const _DealSummaryBanner({
    required this.property, required this.seller,
    required this.price, required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed / 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed == 8 ? AppColors.safe : const Color(0xFF42A5F5)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SummaryChip(Icons.home_outlined, property)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryChip(Icons.person_outline, seller)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryChip(Icons.currency_rupee, price)),
          ]),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Expanded(child: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _StageCard extends StatelessWidget {
  final _Stage stage;
  final bool isDone, isCurrent;
  final VoidCallback onTap, onMarkDone;
  const _StageCard({
    required this.stage, required this.isDone, required this.isCurrent,
    required this.onTap, required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.safe.withOpacity(0.4)
              : isCurrent ? stage.color.withOpacity(0.5)
              : Colors.grey.shade200,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6, offset: const Offset(0, 2),
        )],
      ),
      child: InkWell(
        onTap: isCurrent || isDone ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Step icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isDone ? AppColors.safe.withOpacity(0.1)
                    : stage.color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.safe.withOpacity(0.4)
                      : stage.color.withOpacity(0.3),
                ),
              ),
              child: Icon(
                isDone ? Icons.check_circle : stage.icon,
                color: isDone ? AppColors.safe : stage.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: stage.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Step ${stage.step}',
                    style: TextStyle(color: stage.color, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                if (isCurrent && !isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('CURRENT',
                      style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.safe.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('DONE',
                      style: TextStyle(color: AppColors.safe, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                if (stage.isRequired && !isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('REQUIRED',
                      style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(stage.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E))),
              Text(stage.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 4),
              Text(stage.description, style: const TextStyle(color: Color(0xFF555577), fontSize: 10)),
            ])),
            const SizedBox(width: 8),
            // Actions
            Column(children: [
              if (isCurrent || isDone)
                Icon(Icons.chevron_right, color: stage.color, size: 20),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onMarkDone,
                child: Icon(
                  isDone ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isDone ? AppColors.safe : Colors.grey.shade300,
                  size: 20,
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Stage {
  final int step;
  final IconData icon;
  final String title, subtitle, route, description;
  final Color color;
  final bool isRequired;
  const _Stage({
    required this.step, required this.icon, required this.title,
    required this.subtitle, required this.route, required this.description,
    required this.color, this.isRequired = false,
  });
}
