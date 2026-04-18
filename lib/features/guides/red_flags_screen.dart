import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class RedFlagsScreen extends StatelessWidget {
  const RedFlagsScreen({super.key});

  static const _flags = [
    _Flag('Price Far Below Market Rate', 'If a property is 20–30% cheaper than similar properties nearby — something is wrong. Usually: disputed title, no DC conversion, revenue site, or court case pending.',
      Icons.money_off, AppColors.danger, 'Run Arth ID check immediately'),
    _Flag('Seller in a Hurry to Close', '"Sign today — I have 3 other buyers." This pressure tactic is used when seller knows of a legal problem. A genuine seller will give you time to verify.',
      Icons.timer, AppColors.danger, 'Take your time — always verify'),
    _Flag('No Original Documents', 'Seller can only show photocopies. Original title deed, original EC, original RTC — all should be available. Originals withheld often means property is mortgaged.',
      Icons.description, AppColors.danger, 'Demand originals before paying'),
    _Flag('EC Shows Loan Not Closed', 'Encumbrance Certificate shows a bank mortgage registered but no discharge entry. Bank\'s claim on property still exists. Your money goes — bank keeps the property.',
      Icons.account_balance, AppColors.danger, 'Get Bank NOC + discharge document'),
    _Flag('B Khata or No Khata', 'B Khata means the property has legal irregularities. No Khata means it\'s completely unrecorded. Banks won\'t give loans and future resale is very difficult.',
      Icons.warning_amber, AppColors.danger, 'Verify Khata type at ward office'),
    _Flag('No DC Conversion for Agricultural Land', 'Selling agricultural land as "residential plot" without official DC conversion order. Building on such land is illegal. BBMP will not give plan approval.',
      Icons.agriculture, AppColors.warning, 'Demand DC Conversion Order copy'),
    _Flag('RERA Not Registered (New Apartment)', 'Builder says "RERA applied" but has no RERA number. You cannot pay more than 10% without RERA registration. No RERA = no protection if builder delays.',
      Icons.apartment, AppColors.warning, 'Verify on rera.karnataka.gov.in'),
    _Flag('JDA Not Registered', 'Builder and landowner have an unregistered Joint Development Agreement. If dispute happens, court can freeze project. Your flat delivery stops.',
      Icons.handshake, AppColors.warning, 'Ask for registered JDA copy'),
    _Flag('Survey Number Mismatch', 'Documents show Survey No. 123/A but actual plot is 123/B. Or street address doesn\'t match survey number in RTC. Common in fraudulent deals.',
      Icons.map, AppColors.warning, 'Match survey number in RTC, deed, and physical location'),
    _Flag('Multiple Owners, Only One Selling', 'Property has 5 legal heirs but only 1 is selling. Other heirs can challenge the sale in court. You lose the property even after paying full amount.',
      Icons.people, AppColors.warning, 'Get NOC from ALL legal heirs'),
    _Flag('No Property Tax Paid for Years', 'Seller cannot show recent property tax receipts. Large pending dues mean BBMP can attach the property. You inherit the dues after buying.',
      Icons.receipt, AppColors.warning, 'Ask for last 5 years tax receipts'),
    _Flag('Power of Attorney from Abroad (Unverified)', 'NRI seller gives POA to a local person. If POA is fake or not registered, the entire sale is invalid. Very common fraud.',
      Icons.public, AppColors.info, 'Verify POA is registered at SRO'),
    _Flag('Verbal Promises Not in Writing', 'Builder promises parking, extra storage, gym, club house verbally. Not mentioned in sale agreement. After possession — none of these exist.',
      Icons.chat, AppColors.info, 'Everything must be in the sale agreement'),
    _Flag('Old Will Not Probated', 'Property transferred based on an unregistered will. Unregistered wills can be challenged. Other family members can claim property years later.',
      Icons.gavel, AppColors.info, 'Get succession certificate or probated will'),
    _Flag('Layout Not BDA/BBMP Approved', 'Plot in a layout that doesn\'t have BDA/BBMP approval. No legal roads, no sewage, no water connection officially. Very common in Bengaluru outskirts.',
      Icons.grid_on, AppColors.info, 'Check LP number on BDA/BBMP portal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Red Flags Guide')),
      body: Column(
        children: [
          Container(
            color: AppColors.danger.withOpacity(0.08),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('15 Warning Signs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 14)),
                      Text('${_flags.where((f) => f.severity == AppColors.danger).length} critical  •  ${_flags.where((f) => f.severity == AppColors.warning).length} serious  •  ${_flags.where((f) => f.severity == AppColors.info).length} caution',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _flags.length,
              itemBuilder: (context, i) {
                final f = _flags[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: f.severity.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(f.icon, color: f.severity, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(f.title, style: TextStyle(fontWeight: FontWeight.bold, color: f.severity, fontSize: 13))),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: f.severity, shape: BoxShape.circle),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(f.description, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_forward, size: 14, color: AppColors.safe),
                            const SizedBox(width: 4),
                            Expanded(child: Text(f.action, style: const TextStyle(fontSize: 12, color: AppColors.safe, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Flag {
  final String title;
  final String description;
  final IconData icon;
  final Color severity;
  final String action;
  const _Flag(this.title, this.description, this.icon, this.severity, this.action);
}
