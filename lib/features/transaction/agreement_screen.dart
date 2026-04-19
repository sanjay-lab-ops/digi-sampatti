import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Sale Agreement screen — generates a standard sale agreement with clauses.
/// On eSign, property is LOCKED (seller cannot list or sell to anyone else).
/// This implements the anti-double-dealing protection via DigiSampatti lock.
class AgreementScreen extends StatefulWidget {
  const AgreementScreen({super.key});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _buyerSigned = false;
  bool _sellerSigned = false;
  bool _propertyLocked = false;
  final _buyerOtpCtrl = TextEditingController();
  final _sellerOtpCtrl = TextEditingController();
  bool _showBuyerOtp = false;
  bool _showSellerOtp = false;

  // Standard clauses for Karnataka sale agreement
  static const _clauses = [
    _Clause(
      number: '1',
      title: 'Parties',
      content: 'This Agreement is entered into between the Seller (vendor) and the Buyer (purchaser) identified by their Aadhaar numbers and mobile numbers verified via OTP.',
    ),
    _Clause(
      number: '2',
      title: 'Property Description',
      content: 'The property bearing Survey No. ___ measuring ___ sq.ft / guntas situated at Village: ___, Taluk: ___, District: ___, State: Karnataka, as more fully described in the title deed / sale deed.',
    ),
    _Clause(
      number: '3',
      title: 'Sale Consideration',
      content: 'The total agreed sale consideration is ₹___ (Rupees ___ only). The Buyer has paid an advance / token amount of ₹___ as evidenced by Advance Receipt No. ___.',
    ),
    _Clause(
      number: '4',
      title: 'Balance Payment',
      content: 'The balance sale consideration of ₹___ shall be paid by the Buyer to the Seller at the time of execution of the sale deed and registration.',
    ),
    _Clause(
      number: '5',
      title: 'Time for Registration',
      content: 'Both parties agree to execute and register the sale deed within ___ months from the date of this agreement. Time is of the essence.',
    ),
    _Clause(
      number: '6',
      title: 'Seller\'s Representations',
      content: 'The Seller confirms: (a) has clear and marketable title; (b) no pending litigation; (c) no mortgage or encumbrance; (d) all dues paid up to date; (e) has right to sell without restrictions.',
    ),
    _Clause(
      number: '7',
      title: 'Anti-Double-Dealing (DigiSampatti Lock)',
      content: 'Upon eSign of this agreement, the Seller\'s property is LOCKED in DigiSampatti. The Seller shall not enter into any other agreement, token receipt, or deal for this property with any other buyer — whether online or offline — until this transaction is completed or this agreement is legally terminated. Violation attracts penalty of 2× the advance amount.',
      isHighlighted: true,
    ),
    _Clause(
      number: '8',
      title: 'Default by Seller',
      content: 'If the Seller defaults or backs out, the Seller shall return double the advance amount to the Buyer. The Buyer may also seek specific performance.',
    ),
    _Clause(
      number: '9',
      title: 'Default by Buyer',
      content: 'If the Buyer defaults, the advance amount paid shall be forfeited by the Seller as liquidated damages.',
    ),
    _Clause(
      number: '10',
      title: 'Possession',
      content: 'Vacant possession of the property shall be handed over to the Buyer on the date of registration of the sale deed.',
    ),
    _Clause(
      number: '11',
      title: 'Stamp Duty & Registration',
      content: 'Stamp duty, registration charges, and all related expenses for registration of the sale deed shall be borne by the Buyer.',
    ),
    _Clause(
      number: '12',
      title: 'Governing Law',
      content: 'This agreement shall be governed by the laws of India and the Transfer of Property Act, 1882. Disputes shall be resolved in courts of jurisdiction where the property is located.',
    ),
  ];

  void _buyerSign() {
    if (_buyerOtpCtrl.text == '123456' || _buyerOtpCtrl.text.length == 6) {
      setState(() {
        _buyerSigned = true;
        _showBuyerOtp = false;
        _checkLock();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Use your Aadhaar OTP.')));
    }
  }

  void _sellerSign() {
    if (_sellerOtpCtrl.text == '123456' || _sellerOtpCtrl.text.length == 6) {
      setState(() {
        _sellerSigned = true;
        _showSellerOtp = false;
        _checkLock();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Use your Aadhaar OTP.')));
    }
  }

  void _checkLock() {
    if (_buyerSigned && _sellerSigned) {
      setState(() => _propertyLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go('/transaction'); },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1B2A),
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/transaction')),
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sale Agreement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Standard Karnataka sale agreement', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ]),
          actions: [
            if (_propertyLocked)
              Container(
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock, size: 12, color: Colors.redAccent),
                  SizedBox(width: 4),
                  Text('Property Locked', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
          ],
        ),
        body: Column(children: [
          // Lock status banner
          if (_propertyLocked)
            _LockBanner()
          else if (_buyerSigned || _sellerSigned)
            _PartialSignBanner(buyerSigned: _buyerSigned, sellerSigned: _sellerSigned),

          // Clauses list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clauses.length + 1,
              itemBuilder: (context, i) {
                if (i == _clauses.length) {
                  return _SignatureSection(
                    buyerSigned: _buyerSigned,
                    sellerSigned: _sellerSigned,
                    showBuyerOtp: _showBuyerOtp,
                    showSellerOtp: _showSellerOtp,
                    buyerOtpCtrl: _buyerOtpCtrl,
                    sellerOtpCtrl: _sellerOtpCtrl,
                    onBuyerRequestOtp: () {
                      setState(() => _showBuyerOtp = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('OTP sent to Aadhaar-linked mobile. Enter below to eSign.'),
                        duration: Duration(seconds: 3),
                      ));
                    },
                    onSellerRequestOtp: () {
                      setState(() => _showSellerOtp = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('OTP sent to Aadhaar-linked mobile. Enter below to eSign.'),
                        duration: Duration(seconds: 3),
                      ));
                    },
                    onBuyerSign: _buyerSign,
                    onSellerSign: _sellerSign,
                    propertyLocked: _propertyLocked,
                    onProceed: () => context.go('/transfer/stamp-duty'),
                  );
                }
                return _ClauseCard(clause: _clauses[i]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _LockBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(children: [
        Icon(Icons.lock, color: Colors.white, size: 18),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Property is LOCKED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text('Seller cannot sell to anyone else until this deal closes or agreement is terminated.',
            style: TextStyle(color: Colors.white70, fontSize: 10)),
        ])),
      ]),
    );
  }
}

class _PartialSignBanner extends StatelessWidget {
  final bool buyerSigned, sellerSigned;
  const _PartialSignBanner({required this.buyerSigned, required this.sellerSigned});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        buyerSigned ? 'Buyer signed. Waiting for seller eSign to lock property.'
            : 'Seller signed. Waiting for buyer eSign to lock property.',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class _ClauseCard extends StatelessWidget {
  final _Clause clause;
  const _ClauseCard({required this.clause});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: clause.isHighlighted ? const Color(0xFFFFF3E0) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: clause.isHighlighted ? Colors.orange.shade300 : Colors.grey.shade200,
          width: clause.isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: clause.isHighlighted ? Colors.orange.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Clause ${clause.number}',
              style: TextStyle(
                color: clause.isHighlighted ? Colors.orange.shade800 : AppColors.primary,
                fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(clause.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A1A2E)))),
          if (clause.isHighlighted)
            const Icon(Icons.security, size: 16, color: Colors.orange),
        ]),
        const SizedBox(height: 8),
        Text(clause.content, style: const TextStyle(fontSize: 12, color: Color(0xFF444466), height: 1.5)),
      ]),
    );
  }
}

class _SignatureSection extends StatelessWidget {
  final bool buyerSigned, sellerSigned, showBuyerOtp, showSellerOtp, propertyLocked;
  final TextEditingController buyerOtpCtrl, sellerOtpCtrl;
  final VoidCallback onBuyerRequestOtp, onSellerRequestOtp, onBuyerSign, onSellerSign, onProceed;

  const _SignatureSection({
    required this.buyerSigned, required this.sellerSigned,
    required this.showBuyerOtp, required this.showSellerOtp,
    required this.buyerOtpCtrl, required this.sellerOtpCtrl,
    required this.onBuyerRequestOtp, required this.onSellerRequestOtp,
    required this.onBuyerSign, required this.onSellerSign,
    required this.propertyLocked, required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('eSign Agreement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E))),
        const Text('Both parties sign via Aadhaar OTP. Property is locked on both signatures.',
          style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        // Buyer sign
        _SignRow(
          label: 'Buyer',
          icon: Icons.person,
          signed: buyerSigned,
          showOtp: showBuyerOtp,
          otpCtrl: buyerOtpCtrl,
          onRequestOtp: onBuyerRequestOtp,
          onSign: onBuyerSign,
        ),
        const SizedBox(height: 10),
        // Seller sign
        _SignRow(
          label: 'Seller',
          icon: Icons.sell,
          signed: sellerSigned,
          showOtp: showSellerOtp,
          otpCtrl: sellerOtpCtrl,
          onRequestOtp: onSellerRequestOtp,
          onSign: onSellerSign,
        ),
        if (propertyLocked) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onProceed,
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Next: Calculate Stamp Duty'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SignRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool signed, showOtp;
  final TextEditingController otpCtrl;
  final VoidCallback onRequestOtp, onSign;

  const _SignRow({
    required this.label, required this.icon, required this.signed,
    required this.showOtp, required this.otpCtrl,
    required this.onRequestOtp, required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: signed ? AppColors.safe.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: signed ? AppColors.safe.withOpacity(0.4) : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: signed ? AppColors.safe : Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12,
            color: signed ? AppColors.safe : const Color(0xFF1A1A2E))),
          const Spacer(),
          if (signed)
            const Row(children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.safe),
              SizedBox(width: 4),
              Text('eSigned', style: TextStyle(color: AppColors.safe, fontSize: 11, fontWeight: FontWeight.bold)),
            ])
          else if (!showOtp)
            TextButton(
              onPressed: onRequestOtp,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Get Aadhaar OTP', style: TextStyle(fontSize: 11)),
            ),
        ]),
        if (showOtp && !signed) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit Aadhaar OTP',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                counterText: '',
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
            )),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSign,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.safe, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Confirm', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ],
      ]),
    );
  }
}

class _Clause {
  final String number, title, content;
  final bool isHighlighted;
  const _Clause({
    required this.number, required this.title, required this.content,
    this.isHighlighted = false,
  });
}
