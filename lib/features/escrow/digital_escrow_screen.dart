import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Digital Escrow Screen ────────────────────────────────────────────────────
// Escrow flow (buyer-first model):
//   1. FUND ESCROW    — Buyer deposits advance; funds locked, not released yet
//   2. VERIFY DOCS    — AI + 6-portal document check (Bhoomi / Kaveri / CERSAI…)
//   3. SELLER VERIFY  — Identity + ownership confirmation at government portals
//   4. SIGN AGREEMENT — Both parties e-sign; ownership transfer initiated
//   5. RELEASE FUNDS  — SRO registration complete; funds released to seller
//                    ↘ DISPUTE → mediation → REFUND (at any point)
// ─────────────────────────────────────────────────────────────────────────────

enum EscrowState { fund, docVerify, sellerVerify, sign, released, dispute, refunded }

class DigitalEscrowScreen extends StatefulWidget {
  final Map<String, dynamic>? dealData;
  const DigitalEscrowScreen({super.key, this.dealData});

  @override
  State<DigitalEscrowScreen> createState() => _DigitalEscrowScreenState();
}

class _DigitalEscrowScreenState extends State<DigitalEscrowScreen> {
  EscrowState _state = EscrowState.fund;

  final String _propertyAddress = 'Survey 123, Yelahanka, Bengaluru';
  final double _salePrice       = 4500000;
  final double _advanceAmount   = 450000;
  final String _buyerName       = 'Rahul Sharma';
  final String _sellerName      = 'Suresh Kumar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Secure Escrow'),
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
            _EscrowGuaranteeBanner(
              fundLocked: _state != EscrowState.fund,
              released: _state == EscrowState.released,
              disputed: _state == EscrowState.dispute || _state == EscrowState.refunded,
            ),
            const SizedBox(height: 14),
            _DealSummaryCard(
              address: _propertyAddress,
              salePrice: _salePrice,
              advance: _advanceAmount,
              buyer: _buyerName,
              seller: _sellerName,
            ),
            const SizedBox(height: 14),
            _EscrowFsm(current: _state),
            const SizedBox(height: 14),
            _buildActionCard(),
            const SizedBox(height: 14),
            _PenaltyReminder(advance: _advanceAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return switch (_state) {
      // ── Step 1: Buyer deposits advance into escrow (commitment) ───────────
      EscrowState.fund => _ActionCard(
          icon: Icons.lock_outlined,
          color: AppColors.primary,
          title: 'Step 1 — Lock Advance in Escrow',
          body: 'Deposit ₹${_fmt(_advanceAmount)} (10% advance) into the '
              'DigiSampatti escrow account via IMPS/NEFT.\n\n'
              '🔒 Funds are frozen — not released to seller until all '
              'conditions are met: verified documents, clear title, '
              'signed agreement, and SRO registration.\n\n'
              'This protects both buyer and seller.',
          primaryLabel: 'Show Escrow Account Details',
          onPrimary: _showBankDetails,
          secondaryLabel: 'Advance Locked — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.docVerify),
        ),
      // ── Step 2: AI + portal document verification ─────────────────────────
      EscrowState.docVerify => _ActionCard(
          icon: Icons.psychology_outlined,
          color: AppColors.arthBlue,
          title: 'Step 2 — Verify Property Documents',
          body: 'Run the AI document check on the seller\'s uploaded '
              'documents.\n\n'
              'DigiSampatti checks 6 government portals:\n'
              'Bhoomi · Kaveri EC · eCourts · BBMP Khata · CERSAI · RERA\n\n'
              'You get a Risk Score + plain-language verdict on each document.',
          primaryLabel: 'Run AI Document Check',
          onPrimary: () => context.push('/scan/guide'),
          secondaryLabel: 'Documents Verified — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.sellerVerify),
        ),
      // ── Step 3: Seller identity + ownership verification ──────────────────
      EscrowState.sellerVerify => _ActionCard(
          icon: Icons.verified_user_outlined,
          color: const Color(0xFF6A1B9A),
          title: 'Step 3 — Verify Seller Identity',
          body: 'DigiSampatti confirms the seller\'s identity and '
              'ownership via Aadhaar, PAN, and Bhoomi records.\n\n'
              '✓ Name match across all documents\n'
              '✓ No impersonation or benami ownership flags\n'
              '✓ Seller is the legal title holder\n\n'
              'This step prevents fraud by fake sellers.',
          primaryLabel: 'Check Seller Verification Status',
          onPrimary: () => context.push('/broker'),
          secondaryLabel: 'Seller Verified — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.sign),
        ),
      // ── Step 4: Both parties sign — ownership transfer initiated ─────────
      EscrowState.sign => _ActionCard(
          icon: Icons.draw_outlined,
          color: AppColors.esign,
          title: 'Step 4 — Sign Sale Agreement',
          body: 'Both buyer and seller sign the sale agreement using '
              'Aadhaar e-Sign.\n\n'
              'After signing, ownership transfer is initiated at the '
              'Sub-Registrar Office (SRO).\n\n'
              'Balance payment ₹${_fmt(_salePrice - _advanceAmount)} '
              'is due at SRO within 3 months of signing.',
          primaryLabel: 'e-Sign Agreement (Aadhaar)',
          onPrimary: () => context.push('/esign'),
          secondaryLabel: 'Agreement Signed — Next Step (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.released),
        ),
      // ── Step 5: Registration complete, funds released ─────────────────────
      EscrowState.released => _ActionCard(
          icon: Icons.check_circle_outline,
          color: AppColors.safe,
          title: '✓ Ownership Transferred — Funds Released',
          body: 'SRO registration is complete. Ownership has been '
              'transferred to the buyer.\n\n'
              '✅ Advance ₹${_fmt(_advanceAmount)} released to seller\n'
              '✅ Sale deed registered at SRO\n\n'
              'Next steps:\n'
              '• Bhoomi mutation in buyer\'s name\n'
              '• BBMP Khata transfer\n'
              '• Download registered document copy',
          primaryLabel: 'Find Sub-Registrar Office',
          onPrimary: () => context.push('/transfer/sro'),
          secondaryLabel: null,
          onSecondary: null,
        ),
      EscrowState.dispute => _ActionCard(
          icon: Icons.warning_amber_outlined,
          color: Colors.red,
          title: 'Dispute Raised — Funds Frozen',
          body: 'Escrow funds are frozen immediately.\n\n'
              'DigiSampatti\'s dispute team will review evidence '
              'from both parties within 5 business days.\n\n'
              'Provide screenshots, documents, and communication '
              'records to support your case.',
          primaryLabel: 'Submit Evidence',
          onPrimary: _submitEvidence,
          secondaryLabel: 'Refund Buyer (Simulate)',
          onSecondary: () => setState(() => _state = EscrowState.refunded),
        ),
      EscrowState.refunded => _ActionCard(
          icon: Icons.undo_outlined,
          color: Colors.grey,
          title: 'Advance Refunded',
          body: '₹${_fmt(_advanceAmount)} has been returned to the buyer '
              'after dispute resolution.\n\nApplicable penalties (if any) '
              'have been applied per the agreement terms.',
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
            const SizedBox(height: 4),
            const Text('Transfer your advance to this account',
                style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            const SizedBox(height: 16),
            _BankRow(label: 'Bank', value: 'ICICI Bank — Virtual Account'),
            _BankRow(label: 'Account No.',
                value: 'DIGI${DateTime.now().millisecondsSinceEpoch % 1000000}'),
            _BankRow(label: 'IFSC', value: 'ICIC0000104'),
            _BankRow(label: 'Account Name', value: 'DigiSampatti Escrow'),
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
                '🔒 Funds go to a dedicated escrow account — not directly to seller. '
                'Add your mobile number as payment description so we can link '
                'the transfer automatically.',
                style: TextStyle(fontSize: 11, color: AppColors.warning, height: 1.5),
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
          'This will freeze the escrow funds immediately — no funds move '
          'until resolved.\n\n'
          'Both parties will be notified. DigiSampatti mediates within 5 business days.',
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

// ─── Escrow Guarantee Banner ───────────────────────────────────────────────────
class _EscrowGuaranteeBanner extends StatelessWidget {
  final bool fundLocked;
  final bool released;
  final bool disputed;

  const _EscrowGuaranteeBanner({
    required this.fundLocked,
    required this.released,
    required this.disputed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final IconData icon;
    final String heading;
    final String sub;

    if (disputed) {
      bg = Colors.red.withOpacity(0.06);
      border = Colors.red.withOpacity(0.3);
      icon = Icons.warning_amber_rounded;
      heading = 'Funds Frozen — Dispute Active';
      sub = 'DigiSampatti mediates within 5 business days.';
    } else if (released) {
      bg = AppColors.safe.withOpacity(0.07);
      border = AppColors.safe.withOpacity(0.3);
      icon = Icons.verified_rounded;
      heading = 'Transaction Complete';
      sub = 'Ownership transferred · Funds released · Registered at SRO.';
    } else if (fundLocked) {
      bg = AppColors.primary.withOpacity(0.07);
      border = AppColors.primary.withOpacity(0.3);
      icon = Icons.lock_rounded;
      heading = '₹ Funds Locked in Escrow';
      sub = 'Money is safe · Not released until all steps complete.';
    } else {
      bg = Colors.orange.withOpacity(0.07);
      border = Colors.orange.withOpacity(0.3);
      icon = Icons.lock_open_rounded;
      heading = 'Escrow Not Funded Yet';
      sub = 'Start by locking your advance — it protects both parties.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18,
                color: disputed
                    ? Colors.red
                    : released
                        ? AppColors.safe
                        : fundLocked
                            ? AppColors.primary
                            : Colors.orange),
            const SizedBox(width: 8),
            Text(heading,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: disputed
                        ? Colors.red
                        : released
                            ? AppColors.safe
                            : fundLocked
                                ? AppColors.primary
                                : Colors.orange)),
          ]),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4)),
          if (!fundLocked && !disputed && !released) ...[
            const SizedBox(height: 10),
            const _EscrowHowItWorks(),
          ],
        ],
      ),
    );
  }
}

class _EscrowHowItWorks extends StatelessWidget {
  const _EscrowHowItWorks();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EscrowFlowChip(Icons.lock_outlined, 'Lock\nFunds'),
        _EscrowFlowArrow(),
        _EscrowFlowChip(Icons.psychology_outlined, 'Verify\nDocs'),
        _EscrowFlowArrow(),
        _EscrowFlowChip(Icons.verified_user_outlined, 'Verify\nSeller'),
        _EscrowFlowArrow(),
        _EscrowFlowChip(Icons.draw_outlined, 'Sign &\nTransfer'),
        _EscrowFlowArrow(),
        _EscrowFlowChip(Icons.check_circle_outline, 'Release\nFunds'),
      ],
    );
  }
}

class _EscrowFlowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EscrowFlowChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
      const SizedBox(height: 3),
      Text(label,
          style: const TextStyle(fontSize: 8, color: AppColors.textLight),
          textAlign: TextAlign.center),
    ],
  );
}

class _EscrowFlowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 1,
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.borderColor,
    ),
  );
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
            const Icon(Icons.home_outlined, color: AppColors.primary, size: 18),
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
            Expanded(child: _DealStat('In Escrow',
                '₹${_fmt(advance)}', AppColors.primary)),
            Expanded(child: _DealStat('Balance Due',
                '₹${_fmt(salePrice - advance)}', AppColors.slate)),
          ]),
          const Divider(height: 20),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('Buyer: $buyer',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            const SizedBox(width: 16),
            const Icon(Icons.sell_outlined, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('Seller: $seller',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
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
          const Text('Progress',
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
    (EscrowState.fund,         'Lock\nFunds',       Icons.lock_outlined),
    (EscrowState.docVerify,    'Verify\nDocs',      Icons.psychology_outlined),
    (EscrowState.sellerVerify, 'Verify\nSeller',    Icons.verified_user_outlined),
    (EscrowState.sign,         'Sign &\nTransfer',  Icons.draw_outlined),
    (EscrowState.released,     'Release\nFunds',    Icons.check_circle_outline),
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
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
            ),
            Text(
              refunded
                  ? 'Advance has been returned to buyer after dispute resolution.'
                  : 'Mediation in progress. No funds will move until resolved.',
              style: const TextStyle(fontSize: 11, color: Colors.red, height: 1.4),
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
                      fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(body,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textLight, height: 1.65)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              child: Text(secondaryLabel!, style: const TextStyle(fontSize: 12)),
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
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          Text(value,
              style: TextStyle(
                  fontSize: highlight ? 15 : 12,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                  color: highlight ? AppColors.primary : AppColors.textDark)),
        ],
      ),
    );
  }
}
