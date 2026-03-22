import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class EcourtsScreen extends StatefulWidget {
  final String? ownerName;
  final String? surveyNumber;
  const EcourtsScreen({super.key, this.ownerName, this.surveyNumber});

  @override
  State<EcourtsScreen> createState() => _EcourtsScreenState();
}

class _EcourtsScreenState extends State<EcourtsScreen> {
  final _nameController = TextEditingController();
  final _surveyController = TextEditingController();
  bool _isSearching = false;
  _SearchResult? _result;

  static const _districts = [
    'Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Tumakuru', 'Kolar',
    'Mandya', 'Hassan', 'Dakshina Kannada', 'Udupi', 'Shivamogga',
    'Dharwad', 'Belagavi', 'Vijayapura', 'Kalaburagi', 'Raichur',
    'Ballari', 'Chitradurga', 'Davangere', 'Haveri', 'Gadag',
    'Uttara Kannada', 'Chikkamagaluru', 'Kodagu', 'Chamarajanagar',
    'Ramanagara', 'Chikkaballapur',
  ];
  String _selectedDistrict = 'Bengaluru Urban';

  @override
  void initState() {
    super.initState();
    if (widget.ownerName != null) _nameController.text = widget.ownerName!;
    if (widget.surveyNumber != null) _surveyController.text = widget.surveyNumber!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surveyController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_nameController.text.trim().isEmpty && _surveyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter owner name or survey number')));
      return;
    }
    setState(() { _isSearching = true; _result = null; });
    await Future.delayed(const Duration(seconds: 2));

    // Demo: name containing "test" or survey "999" returns mock cases
    final hasCase = _nameController.text.toLowerCase().contains('test') ||
        _surveyController.text.contains('999');

    setState(() {
      _isSearching = false;
      _result = hasCase ? _SearchResult.withCases() : _SearchResult.clean();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Court Case Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 16),
            _buildSearchCard(),
            const SizedBox(height: 16),
            if (_isSearching) _buildSearching(),
            if (_result != null && !_isSearching) _buildResult(_result!),
            if (_result == null && !_isSearching) _buildGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel, color: Color(0xFF1A237E), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('eCourts Property Case Check',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E))),
                SizedBox(height: 3),
                Text('Check if owner or property has pending civil disputes, title claims, or injunctions in any court.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
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
          const Text('Owner Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Ramesh Kumar',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Survey Number (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _surveyController,
            decoration: const InputDecoration(
              hintText: 'e.g. 45/2',
              prefixIcon: Icon(Icons.tag, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
          const SizedBox(height: 14),
          const Text('District Court', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDistrict,
                isExpanded: true,
                items: _districts.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(d, style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedDistrict = v!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Check Court Records'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearching() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking court records...', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          SizedBox(height: 4),
          Text('Searching civil, title, and injunction cases', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildResult(_SearchResult result) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: result.isClean ? AppColors.safe.withOpacity(0.08) : AppColors.danger.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: result.isClean ? AppColors.safe.withOpacity(0.3) : AppColors.danger.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(result.isClean ? Icons.check_circle : Icons.warning_amber_rounded,
                color: result.isClean ? AppColors.safe : AppColors.danger, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.isClean ? 'No Cases Found' : '${result.cases.length} Case(s) Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16,
                        color: result.isClean ? AppColors.safe : AppColors.danger,
                      )),
                    const SizedBox(height: 3),
                    Text(
                      result.isClean
                        ? 'No pending disputes found in $_selectedDistrict courts.'
                        : 'Pending cases found. Do NOT pay advance. Consult a lawyer first.',
                      style: TextStyle(
                        fontSize: 12,
                        color: result.isClean ? AppColors.textLight : AppColors.danger,
                        height: 1.4,
                      )),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!result.isClean) ...[
          const SizedBox(height: 12),
          ...result.cases.map((c) => _CaseCard(courtCase: c)),
        ],
        const SizedBox(height: 12),
        _buildPortalLink(),
      ],
    );
  }

  Widget _buildPortalLink() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verify on Official eCourts Portal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('Always cross-check on the official portal before making any payment.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'https://services.ecourts.gov.in'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied — open in browser'),
                  duration: Duration(seconds: 2),
                ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.link, size: 16, color: Color(0xFF1A237E)),
                  SizedBox(width: 8),
                  Text('services.ecourts.gov.in',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                  Spacer(),
                  Icon(Icons.copy, size: 14, color: AppColors.textLight),
                  SizedBox(width: 4),
                  Text('Copy', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuide() {
    const types = [
      ('Title Dispute', 'Multiple people claiming ownership of same land', Icons.people, AppColors.danger),
      ('Partition Suit', 'Family/joint property division pending in court', Icons.call_split, AppColors.warning),
      ('Injunction', 'Court order stopping sale or construction', Icons.block, AppColors.danger),
      ('Mortgage Recovery', 'Bank filing case to recover unpaid loan on property', Icons.account_balance, AppColors.warning),
      ('Eviction Suit', 'Dispute between landlord and tenant', Icons.home, AppColors.info),
      ('Criminal Case', 'Forgery or fraud related to land documents', Icons.gavel, AppColors.danger),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Why Check Court Cases?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: types.asMap().entries.map((e) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: e.value.$4.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.value.$3, color: e.value.$4, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(e.value.$2,
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.key < types.length - 1) const Divider(height: 1, indent: 64),
              ],
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildPortalLink(),
      ],
    );
  }
}

// ─── Case Card ────────────────────────────────────────────────────────────────
class _CaseCard extends StatelessWidget {
  final _CourtCase courtCase;
  const _CaseCard({required this.courtCase});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(courtCase.type,
                  style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(courtCase.status,
                  style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(courtCase.caseNumber,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(courtCase.parties, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text('Filed: ${courtCase.filingDate}',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              const SizedBox(width: 16),
              const Icon(Icons.event, size: 12, color: AppColors.warning),
              const SizedBox(width: 4),
              Text('Next: ${courtCase.nextHearing}',
                style: const TextStyle(fontSize: 11, color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(courtCase.advice,
              style: const TextStyle(fontSize: 11, color: AppColors.danger, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────
class _CourtCase {
  final String type, caseNumber, parties, filingDate, nextHearing, status, advice;
  const _CourtCase({
    required this.type, required this.caseNumber, required this.parties,
    required this.filingDate, required this.nextHearing,
    required this.status, required this.advice,
  });
}

class _SearchResult {
  final bool isClean;
  final List<_CourtCase> cases;
  const _SearchResult({required this.isClean, required this.cases});

  factory _SearchResult.clean() => const _SearchResult(isClean: true, cases: []);

  factory _SearchResult.withCases() => _SearchResult(isClean: false, cases: [
    _CourtCase(
      type: 'Title Dispute',
      caseNumber: 'O.S. 1452/2021',
      parties: 'Ramesh Kumar vs Suresh Kumar & Others',
      filingDate: '14 Mar 2021',
      nextHearing: '28 Apr 2026',
      status: 'Pending',
      advice: 'Title is disputed. Court has not given final order. Do NOT buy until case is resolved. Consult a property lawyer immediately.',
    ),
    _CourtCase(
      type: 'Injunction',
      caseNumber: 'I.A. 203/2022',
      parties: 'Lakshmi Devi vs Ramesh Kumar',
      filingDate: '02 Jun 2022',
      nextHearing: '15 Apr 2026',
      status: 'Active Injunction',
      advice: 'Court has issued an injunction stopping sale of this property. Any sale during this period is legally void.',
    ),
  ]);
}
