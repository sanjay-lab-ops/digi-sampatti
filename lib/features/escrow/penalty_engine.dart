import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Penalty Engine ───────────────────────────────────────────────────────────
// Defines conditions under which buyer or seller forfeits money from escrow.
// All terms are agreed at agreement signing — no surprises.
//
// Seller defaults:
//   • Fails to appear for registration by agreed date
//   • Provides false/forged documents
//   • Has undisclosed prior agreement
//   • Property has undisclosed court case
//
// Buyer defaults:
//   • Fails to pay balance amount by agreed date
//   • Fails to appear for registration
//   • Backs out without valid reason after inspection + legal opinion paid
//
// All penalties are calculated on the ADVANCE amount held in escrow.
// ─────────────────────────────────────────────────────────────────────────────

enum PenaltyParty   { buyer, seller }
enum PenaltyReason  {
  noShowRegistration,
  forgedDocuments,
  undisclosedPriorAgreement,
  undisclosedCourtCase,
  undisclosedLoan,
  failedBalancePayment,
  buyerWithdrawalAfterDueDiligence,
  agreementBreach,
}

class PenaltyRule {
  final PenaltyReason reason;
  final PenaltyParty  defaultingParty;
  final double        penaltyPercent;   // % of advance forfeited
  final String        title;
  final String        description;
  final String        legalBasis;

  const PenaltyRule({
    required this.reason,
    required this.defaultingParty,
    required this.penaltyPercent,
    required this.title,
    required this.description,
    required this.legalBasis,
  });

  double penaltyAmount(double advanceAmount) =>
      advanceAmount * penaltyPercent / 100;
}

// Standard penalty rules (agreed by both parties at signing)
const kPenaltyRules = [
  // ── Seller Defaults ────────────────────────────────────────────────────────
  PenaltyRule(
    reason: PenaltyReason.noShowRegistration,
    defaultingParty: PenaltyParty.seller,
    penaltyPercent: 100,
    title: 'Seller No-Show at Registration',
    description: 'If seller fails to appear at Sub-Registrar on agreed date '
        'without prior notice, seller forfeits 100% of advance AND must '
        'refund the full advance + penalty to buyer.',
    legalBasis: 'Specific Performance Act. Buyer can also file suit for '
        'registration of property.',
  ),
  PenaltyRule(
    reason: PenaltyReason.forgedDocuments,
    defaultingParty: PenaltyParty.seller,
    penaltyPercent: 200,
    title: 'Forged or False Documents',
    description: 'If seller provided forged title documents, forged EC, '
        'or misrepresented ownership, seller forfeits 200% of advance '
        '(double the advance). Criminal complaint also filed.',
    legalBasis: 'IPC Section 420 (cheating), Section 468 (forgery). '
        'Advance forfeited + criminal complaint.',
  ),
  PenaltyRule(
    reason: PenaltyReason.undisclosedPriorAgreement,
    defaultingParty: PenaltyParty.seller,
    penaltyPercent: 150,
    title: 'Undisclosed Prior Sale Agreement',
    description: 'If seller had a prior unregistered agreement with another '
        'buyer that was not disclosed, seller pays 150% of advance as penalty.',
    legalBasis: 'Transfer of Property Act, Section 55. '
        'Seller has duty of disclosure.',
  ),
  PenaltyRule(
    reason: PenaltyReason.undisclosedCourtCase,
    defaultingParty: PenaltyParty.seller,
    penaltyPercent: 100,
    title: 'Undisclosed Court Case or Injunction',
    description: 'If a court injunction, attachment, or pending case was not '
        'disclosed by seller and is discovered after agreement, '
        'seller forfeits 100% of advance.',
    legalBasis: 'Misrepresentation under Indian Contract Act Section 18.',
  ),
  PenaltyRule(
    reason: PenaltyReason.undisclosedLoan,
    defaultingParty: PenaltyParty.seller,
    penaltyPercent: 100,
    title: 'Undisclosed Bank Loan or Mortgage',
    description: 'If an active bank mortgage was not disclosed and prevents '
        'clean transfer, seller forfeits 100% advance AND must repay loan '
        'before any part of the sale proceeds are released.',
    legalBasis: 'Transfer of Property Act. Bank mortgage must be cleared.',
  ),

  // ── Buyer Defaults ──────────────────────────────────────────────────────────
  PenaltyRule(
    reason: PenaltyReason.failedBalancePayment,
    defaultingParty: PenaltyParty.buyer,
    penaltyPercent: 50,
    title: 'Buyer Fails to Pay Balance Amount',
    description: 'If buyer fails to pay the balance amount by the agreed '
        'registration date without valid reason, buyer forfeits 50% of '
        'advance paid. Remaining 50% is refunded.',
    legalBasis: 'Indian Contract Act Section 73 — party in breach '
        'must compensate actual loss.',
  ),
  PenaltyRule(
    reason: PenaltyReason.buyerWithdrawalAfterDueDiligence,
    defaultingParty: PenaltyParty.buyer,
    penaltyPercent: 25,
    title: 'Buyer Withdraws After Inspection + Legal',
    description: 'If buyer withdraws without valid legal reason after '
        'inspection and legal opinion are completed and property is clear, '
        'buyer forfeits 25% of advance. Remaining 75% is refunded.',
    legalBasis: 'Earnest money forfeiture — standard practice in property '
        'transactions. 25% is proportional to seller\'s out-of-pocket costs.',
  ),
  PenaltyRule(
    reason: PenaltyReason.agreementBreach,
    defaultingParty: PenaltyParty.buyer,
    penaltyPercent: 100,
    title: 'General Agreement Breach by Buyer',
    description: 'If buyer breaches any specific agreed term, penalty is '
        'calculated per the specific clause. Maximum: 100% of advance.',
    legalBasis: 'Indian Contract Act Section 73 and 74.',
  ),
];

// ─── Penalty Screen ───────────────────────────────────────────────────────────
class PenaltyEngineScreen extends StatefulWidget {
  final double advanceAmount;
  const PenaltyEngineScreen({super.key, this.advanceAmount = 0});

  @override
  State<PenaltyEngineScreen> createState() => _PenaltyEngineScreenState();
}

class _PenaltyEngineScreenState extends State<PenaltyEngineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sellerRules = kPenaltyRules
        .where((r) => r.defaultingParty == PenaltyParty.seller)
        .toList();
    final buyerRules = kPenaltyRules
        .where((r) => r.defaultingParty == PenaltyParty.buyer)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Default & Penalty Terms'),
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.red,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: 'Seller Defaults'),
            Tab(text: 'Buyer Defaults'),
          ],
        ),
      ),
      body: Column(
        children: [
          _headerInfo(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildRuleList(sellerRules, PenaltyParty.seller),
                _buildRuleList(buyerRules, PenaltyParty.buyer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerInfo() => Container(
    padding: const EdgeInsets.all(14),
    color: Colors.red.shade50,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.policy_outlined, color: Colors.red, size: 18),
          SizedBox(width: 8),
          Text('Penalty Terms — Agreed at Signing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  color: Colors.red)),
        ]),
        const SizedBox(height: 6),
        const Text(
          'These terms are included in every sale agreement generated by DigiSampatti. '
          'Both buyer and seller agree to them when signing. '
          'Penalties are enforced from the escrow amount.',
          style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
        ),
        if (widget.advanceAmount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Advance in escrow: ₹${_fmt(widget.advanceAmount)}',
            style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 13, color: Colors.red),
          ),
        ],
      ],
    ),
  );

  Widget _buildRuleList(List<PenaltyRule> rules, PenaltyParty party) =>
    ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildRuleCard(rules[i]),
    );

  Widget _buildRuleCard(PenaltyRule rule) {
    final isSellerDefault = rule.defaultingParty == PenaltyParty.seller;
    final color = isSellerDefault ? Colors.red.shade800 : Colors.orange.shade800;
    final penaltyAmt = widget.advanceAmount > 0
        ? rule.penaltyAmount(widget.advanceAmount)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(children: [
            Expanded(child: Text(rule.title,
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 13, color: color))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${rule.penaltyPercent.toInt()}% forfeit',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rule.description,
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black54)),
              if (penaltyAmt != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    Text('Penalty amount: ',
                        style: TextStyle(fontSize: 12, color: color)),
                    Text('₹${_fmt(penaltyAmt)}',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.bold, color: color)),
                  ]),
                ),
              ],
              const SizedBox(height: 8),
              Text('Legal basis: ${rule.legalBasis}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ]),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}
