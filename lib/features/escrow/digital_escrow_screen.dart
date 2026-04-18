import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Digital Escrow Screen (MVP) ──────────────────────────────────────────────
// Correct transaction order:
//   1. VERIFY DOCS   — Buyer runs AI check on seller's documents
//   2. INSPECT       — Buyer visits property, field agent confirms
//   3. ADVANCE       — Only after verify + inspect: buyer deposits advance into escrow
//   4. SIGN          — Both parties e-sign sale agreement
//   5. REGISTER      — Full payment + SRO registration within 3 months
//                   ↘ DISPUTE → REFUND (at any point after advance)
//
// MVP: simulated — no real bank API wired yet.
// ──────────────────────────────────────────────────────────────────────────────

// Enum values repurposed to correct sequence:
// init=VerifyDocs, funded=Inspected, docVerified=AdvancePaid, buyerApproved=Signed, released=Registered
enum EscrowState { init, funded, docVerified, buyerApproved, released, dispute, refunded }

class DigitalEscrowScreen extends StatefulWidget {
  final Map<String, dynamic>? dealData;
  const DigitalEscrowScreen({super.key, this.dealData});

  @override
  State<DigitalEscrowScreen> createState() => _DigitalEscrowScreenState();
}

class _DigitalEscrowScreenState extends State<DigitalEscrowScreen> {
  EscrowState _state = EscrowState.init;

  // Demo deal values — in production these come from dealData
  final String _propertyAddress = 'Survey 123, Yelahanka, Bengaluru';
  final double _salePrice       = 4500000;
  final double _advanceAmount   = 450000; // 10% advance
  final String _buyerName       = 'Rahul Sharma';
  final String _sellerName      = 'Suresh Kumar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Escrow'),
        backgroundColor: Colors.white,
        actions: [
          if (_state != EscrowState.released && _state != EscrowState.refunded)
            TextButton.icon(
              icon: const Icon(Icons.gavel, size: 16, color: Colors.red),
              label: const Text('Dispute',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
              onPressed: _raiseDispute,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DealSummaryCard(
              address: _propertyAddress,
              salePrice: _salePrice,
              advance: _advanceAmount,
              buyer: _buyerName,
              seller: _sellerName,
            ),
            const SizedBox(height: 20),
            _EscrowFsm(current: _state),
            const SizedBox(height: 20),
            _buildActionCard(),
            const SizedBox(height: 16),
            _PenaltyReminder(advance: _advanceAmount),
          ],
        ),
      ),
    );
  }

  // ─── Action card changes based on current FSM state ────────────────────────
  Widget _buildActionCard() {
    return switch (_state) {
      // ── Step 1: Verify documents BEFORE anything else ─────────────────────
      EscrowState.init => _ActionCard(
          icon: Icons.psychology_outlined,
          color: AppColors.arthBlue,
          title: 'Step 1 — Verify the Property Documents',
          body: 'Before paying anything, run the AI check on the seller\'s '
              'documents.\n\nArth ID checks 8 government portals: '
              'Bhoomi · Kaveri EC · eCourts · BBMP Khata · CERSAI · RERA.\n\n'
              'Get the Risk Score and AI verdict first.',
          primaryLabel: 'Run AI Document Check',
          onPrimary: () => context.push('/scan/guide'),
          secondaryLabel: 'Docs Verified — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.funded),
        ),
      // ── Step 2: Physically inspect the property ───────────────────────────
      EscrowState.funded => _ActionCard(
          icon: Icons.location_on_outlined,
          color: AppColors.warning,
          title: 'Step 2 — Inspect the Property',
          body: 'Visit the property in person — check physical boundaries, '
              'construction quality, neighbours, road access.\n\n'
              'Or book a Arth ID field agent for a GPS-verified '
              '48-hour inspection report.',
          primaryLabel: 'Book Field Inspection',
          onPrimary: () => context.push('/field-inspection'),
          secondaryLabel: 'Inspection Done — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.docVerified),
        ),
      // ── Step 3: Advance payment into escrow (AFTER verify + inspect) ──────
      EscrowState.docVerified => _ActionCard(
          icon: Icons.account_balance_outlined,
          color: AppColors.primary,
          title: 'Step 3 — Deposit Advance into Escrow',
          body: 'You have verified the documents and inspected the property.\n\n'
              'Now deposit ₹${_fmt(_advanceAmount)} (10% advance) into the '
              'Arth ID escrow account via IMPS/NEFT.\n\n'
              'Funds are held safely — not released to seller until you sign '
              'the agreement.',
          primaryLabel: 'Show Escrow Account Details',
          onPrimary: _showBankDetails,
          secondaryLabel: 'Advance Paid — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.buyerApproved),
        ),
      // ── Step 4: Both parties e-sign the sale agreement ────────────────────
      EscrowState.buyerApproved => _ActionCard(
          icon: Icons.draw_outlined,
          color: AppColors.esign,
          title: 'Step 4 — Sign Sale Agreement',
          body: 'Both buyer and seller sign the sale agreement using '
              'Aadhaar e-Sign.\n\n'
              'After signing, advance is released to seller. Balance payment '
              '(₹${_fmt(_salePrice - _advanceAmount)}) to be made at SRO '
              'registration within 3 months.',
          primaryLabel: 'e-Sign Agreement (Aadhaar)',
          onPrimary: () => context.push('/esign'),
          secondaryLabel: 'Agreement Signed — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.released),
        ),
      // ── Step 5: Full payment + SRO registration ───────────────────────────
      EscrowState.released => _ActionCard(
          icon: Icons.check_circle_outline,
          color: AppColors.safe,
          title: '✓ Agreement Signed — Registration Pending',
          body: 'Advance ₹${_fmt(_advanceAmount)} has been released to seller.\n\n'
              'Complete the transaction:\n'
              '• Pay balance ₹${_fmt(_salePrice - _advanceAmount)} at SRO\n'
              '• Register the sale deed within 3 months\n'
              '• Get Bhoomi mutation + BBMP Khata transfer in your name',
          primaryLabel: 'Find Sub-Registrar Office',
          onPrimary: () => context.push('/transfer/sro'),
          secondaryLabel: null,
          onSecondary: null,
        ),
      EscrowState.dispute => _ActionCard(
          icon: Icons.warning_amber_outlined,
          color: Colors.red,
          title: 'Dispute Raised',
          body: 'Funds are frozen. Arth ID\'s dispute team will review '
              'evidence from both parties within 5 business days.\n\n'
              'Provide screenshots, documents, and communication records.',
          primaryLabel: 'Submit Evidence',
          onPrimary: _submitEvidence,
          secondaryLabel: 'Refund Buyer (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.refunded),
        ),
      EscrowState.refunded => _ActionCard(
          icon: Icons.undo_outlined,
          color: Colors.grey,
          title: 'Advance Refunded',
          body: '₹${_fmt(_advanceAmount)} has been refunded to the buyer after '
              'dispute resolution.\n\nApplicable penalties (if any) have been '
              'applied per the agreement terms.',
          primaryLabel: 'View Penalty Terms',
          onPrimary: () => context.push('/advance-receipt'),
          secondaryLabel: null,
          onSecondary: null,
        ),
    };
  }

  void _showBankDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escrow Account Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _BankRow(label: 'Bank', value: 'ICICI Bank — Virtual Account'),
            _BankRow(label: 'Account No.',
                value: 'DIGI${DateTime.now().millisecondsSinceEpoch % 1000000}'),
            _BankRow(label: 'IFSC', value: 'ICIC0000104'),
            _BankRow(label: 'Account Name', value: 'Arth ID Escrow'),
            _BankRow(
                label: 'Amount to Transfer',
                value: '₹${_fmt(_advanceAmount)}',
                highlight: true),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Use IMPS or NEFT. Add your mobile number as payment description '
                'so we can link the transfer automatically.',
                style: TextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _raiseDispute() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Raise a Dispute?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will freeze the escrow funds immediately.\n\n'
          'Both parties will be notified and asked to submit evidence. '
          'Arth ID will mediate within 5 business days.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _state = EscrowState.dispute);
            },
            child: const Text('Raise Dispute'),
          ),
        ],
      ),
    );
  }

  void _submitEvidence() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence submission — coming soon'),
        backgroundColor: AppColors.slate,
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}

// ─── Deal Summary ──────────────────────────────────────────────────────────────
class _DealSummaryCard extends StatelessWidget {
  final String address, buyer, seller;
  final double salePrice, advance;

  const _DealSummaryCard({
    required this.address,
    required this.salePrice,
    required this.advance,
    required this.buyer,
    required this.seller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.home_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(address,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark)),
            ),
          ]),
          const Divider(height: 20),
          Row(children: [
            Expanded(child: _DealStat('Sale Price',
                '₹${_fmt(salePrice)}', AppColors.textDark)),
            Expanded(child: _DealStat('Advance (Escrow)',
                '₹${_fmt(advance)}', AppColors.primary)),
            Expanded(child: _DealStat('Balance',
                '₹${_fmt(salePrice - advance)}', AppColors.slate)),
          ]),
          const Divider(height: 20),
          Row(children: [
            const Icon(Icons.person_outline,
                size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('Buyer: $buyer',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
            const SizedBox(width: 16),
            const Icon(Icons.sell_outlined,
                size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('Seller: $seller',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
          ]),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(2)} L';
    return v.toStringAsFixed(0);
  }
}

class _DealStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DealStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 14, color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
    ],
  );
}

// ─── FSM Progress Bar ──────────────────────────────────────────────────────────
class _EscrowFsm extends StatelessWidget {
  final EscrowState current;
  const _EscrowFsm({required this.current});

  @override
  Widget build(BuildContext context) {
    final isDispute  = current == EscrowState.dispute;
    final isRefunded = current == EscrowState.refunded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDispute || isRefunded
                ? Colors.red.withOpacity(0.3)
                : AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Escrow Status',
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 13, color: AppColors.textDark)),
          const SizedBox(height: 14),
          if (isDispute || isRefunded)
            _DisputeBanner(refunded: isRefunded)
          else
            _NormalFsm(current: current),
        ],
      ),
    );
  }
}

class _NormalFsm extends StatelessWidget {
  final EscrowState current;
  const _NormalFsm({required this.current});

  static const _steps = [
    (EscrowState.init,          'Verify\nDocs',   Icons.psychology_outlined),
    (EscrowState.funded,        'Inspect\nPlace', Icons.location_on_outlined),
    (EscrowState.docVerified,   'Deposit\nAdvance', Icons.account_balance_outlined),
    (EscrowState.buyerApproved, 'Sign\nAgreement', Icons.draw_outlined),
    (EscrowState.released,      'Register\n(SRO)', Icons.home_outlined),
  ];

  int get _currentIndex =>
      _steps.indexWhere((s) => s.$1 == current).clamp(0, _steps.length - 1);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length, (i) {
        final done   = i < _currentIndex;
        final active = i == _currentIndex;
        final step   = _steps[i];

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.safe
                            : active
                                ? AppColors.primary
                                : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: done || active
                                ? Colors.transparent
                                : AppColors.borderColor,
                            width: 1.5),
                      ),
                      child: Icon(
                        done ? Icons.check : step.$3,
                        size: 16,
                        color: done || active ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(step.$2,
                        style: TextStyle(
                            fontSize: 9,
                            color: active
                                ? AppColors.primary
                                : done
                                    ? AppColors.safe
                                    : AppColors.textLight,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.normal),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (i < _steps.length - 1)
                Container(
                  width: 16, height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: i < _currentIndex ? AppColors.safe : AppColors.borderColor,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _DisputeBanner extends StatelessWidget {
  final bool refunded;
  const _DisputeBanner({required this.refunded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(
          refunded ? Icons.undo_outlined : Icons.warning_amber_outlined,
          color: Colors.red, size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              refunded ? 'Escrow Refunded' : 'Funds Frozen — Dispute Active',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13, color: Colors.red),
            ),
            Text(
              refunded
                  ? 'Advance has been returned to buyer after dispute resolution.'
                  : 'Mediation in progress. No funds will move until resolved.',
              style: const TextStyle(
                  fontSize: 11, color: Colors.red, height: 1.4),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(body,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  height: 1.6)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(primaryLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onSecondary,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.4)),
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(secondaryLabel!,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Penalty Reminder ─────────────────────────────────────────────────────────
class _PenaltyReminder extends StatelessWidget {
  final double advance;
  const _PenaltyReminder({required this.advance});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/advance-receipt'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.policy_outlined, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Penalty terms apply to both buyer and seller. '
              'Tap to review default conditions.',
              style: TextStyle(fontSize: 11, color: Colors.red, height: 1.4),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.red),
        ]),
      ),
    );
  }
}

// ─── Bank detail row ──────────────────────────────────────────────────────────
class _BankRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _BankRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textLight)),
          Text(value,
              style: TextStyle(
                  fontSize: highlight ? 15 : 12,
                  fontWeight: highlight
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: highlight ? AppColors.primary : AppColors.textDark)),
        ],
      ),
    );
  }
}
