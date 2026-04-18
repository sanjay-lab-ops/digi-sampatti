import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ── Complete offline demo — no API, no login needed ──────────────────────────

class DemoReportScreen extends StatefulWidget {
  const DemoReportScreen({super.key});
  @override
  State<DemoReportScreen> createState() => _DemoReportScreenState();
}

class _DemoReportScreenState extends State<DemoReportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _scoreAnim;
  int _tab = 0;

  static const _score = 87;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _scoreAnim = IntTween(begin: 0, end: _score)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Sample Property Report'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(
            children: [
              _Tab('Report', 0, _tab, (i) => setState(() => _tab = i)),
              _Tab('Documents', 1, _tab, (i) => setState(() => _tab = i)),
              _Tab('Sign & QR', 2, _tab, (i) => setState(() => _tab = i)),
              _Tab('Grievance', 3, _tab, (i) => setState(() => _tab = i)),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _ReportTab(scoreAnim: _scoreAnim, ctrl: _ctrl),
          const _DocumentsTab(),
          const _SignQrTab(),
          const _GrievanceTab(),
        ],
      ),
    );
  }
}

// ── TAB 1 — Report ───────────────────────────────────────────────────────────
class _ReportTab extends StatelessWidget {
  final Animation<int> scoreAnim;
  final AnimationController ctrl;
  const _ReportTab({required this.scoreAnim, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is how your real report looks. '
                  'Data fetched directly from Bhoomi, Kaveri, eCourts & RERA Karnataka.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Property info card
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Survey No. 45/2',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      SizedBox(height: 2),
                      Text('Yelahanka, Bengaluru Urban',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('Karnataka • 26 March 2026',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  // Animated score
                  AnimatedBuilder(
                    animation: scoreAnim,
                    builder: (_, __) => _ScoreCircle(score: scoreAnim.value),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.primary, size: 16),
                  SizedBox(width: 6),
                  Text('Data from Bhoomi, Kaveri, eCourts, RERA Karnataka',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Checks
        _CheckCard(
          icon: Icons.person,
          title: 'Land Ownership (RTC)',
          status: 'clear',
          detail: 'Owner: Ramesh Kumar S/O Krishnappa\n'
              'Survey: 45/2 • Area: 12 Guntas\n'
              'Type: Residential (DC Converted)\n'
              'Verified from Bhoomi, Karnataka Revenue Dept',
        ),
        const SizedBox(height: 8),
        _CheckCard(
          icon: Icons.account_balance,
          title: 'Encumbrance (EC)',
          status: 'clear',
          detail: 'No active loans or mortgages found\n'
              'EC period: 2001–2026 (25 years clean)\n'
              'Verified from Kaveri Online, IGR Karnataka',
        ),
        const SizedBox(height: 8),
        _CheckCard(
          icon: Icons.sync_alt,
          title: 'Mutation / Khata',
          status: 'warning',
          detail: 'Khata transfer pending at BBMP\n'
              'Seller applied: 12 Jan 2026 — Status: Processing\n'
              'Action: Confirm Khata is transferred before registration',
        ),
        const SizedBox(height: 8),
        _CheckCard(
          icon: Icons.gavel,
          title: 'Court Cases (eCourts)',
          status: 'clear',
          detail: 'No active or historical court cases found\n'
              'Checked: Karnataka High Court, District Court\n'
              'Verified from eCourts, Ministry of Law, GoI',
        ),
        const SizedBox(height: 8),
        _CheckCard(
          icon: Icons.business,
          title: 'RERA Registration',
          status: 'clear',
          detail: 'Not applicable — individual resale property\n'
              'RERA applies to builder projects only',
        ),
        const SizedBox(height: 8),
        _CheckCard(
          icon: Icons.currency_rupee,
          title: 'Guidance Value',
          status: 'clear',
          detail: 'Govt Guidance Value: ₹4,800/sq ft\n'
              'Quoted price: ₹5,200/sq ft — within acceptable range\n'
              'Stamp duty basis: Guidance Value (whichever is higher)',
        ),
        const SizedBox(height: 16),

        // Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceGreen,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arth ID Recommendation',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary)),
              SizedBox(height: 8),
              Text(
                'This property is GENERALLY SAFE to proceed with. '
                'One pending item: confirm Khata transfer is complete '
                'before paying registration charges. '
                'All other checks — ownership, encumbrance, court cases — are clear.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Govt data chain
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Government Data Chain',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              _ChainRow('Village Accountant (VA)', 'Yelahanka Hobli', true),
              _ChainRow('Revenue Inspector (RI)', 'Bengaluru North Taluk', true),
              _ChainRow('Tahsildar', 'Bengaluru Urban', true),
              _ChainRow('Sub-Registrar (SRO)', 'Yelahanka SRO', true),
              _ChainRow('IGR Karnataka', 'Kaveri Online', true),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── TAB 2 — Documents ────────────────────────────────────────────────────────
class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Government Documents Found'),
        _DocTile(Icons.description, 'RTC (Record of Rights)',
            'Bhoomi Karnataka', 'Available', Colors.green),
        _DocTile(Icons.receipt_long, 'Encumbrance Certificate (EC)',
            'Kaveri Online, IGR', 'Available', Colors.green),
        _DocTile(Icons.home_work, 'Khata Certificate',
            'BBMP Bengaluru', 'Transfer Pending', Colors.orange),
        _DocTile(Icons.map, 'Village Map / Tippan',
            'KSRSAC Karnataka', 'Available', Colors.green),
        _DocTile(Icons.gavel, 'Court Case Search',
            'eCourts Karnataka', 'No Cases Found', Colors.green),
        const SizedBox(height: 16),
        const _SectionHeader('What to Collect from Seller'),
        _DocTile(Icons.person_outline, 'Sale Deed (Original)',
            'From Seller', 'Request before advance', Colors.blue),
        _DocTile(Icons.receipt, 'Tax Paid Receipts',
            'BBMP / Gram Panchayat', 'Last 3 years', Colors.blue),
        _DocTile(Icons.link_off, 'No Objection Certificate',
            'Society / Apartment', 'If applicable', Colors.blue),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'All RTC, EC and mutation documents are verified directly '
            'from Karnataka government portals — Bhoomi, Kaveri Online, '
            'eCourts, RERA — inside the Arth ID app.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ── TAB 3 — Sign & QR ────────────────────────────────────────────────────────
class _SignQrTab extends StatelessWidget {
  const _SignQrTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Blockchain QR
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('Blockchain Verification QR',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 4),
              const Text('Scan to verify this report is authentic and unmodified',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // QR mockup
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 10),
                            itemCount: 100,
                            itemBuilder: (_, i) => Container(
                              margin: const EdgeInsets.all(1),
                              color: [2, 5, 8, 11, 15, 22, 31, 44, 53, 67, 71, 88, 93]
                                      .contains(i % 17)
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            color: Colors.white,
                            child: const Icon(Icons.verified_user,
                                color: AppColors.primary, size: 28),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Report ID: DS-20260326-87421',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const Text('Hash: 3a7f...9c2d (Hyperledger Fabric)',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  const Text(
                    'Tamper-proof • Immutable • Court-admissible',
                    style: TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Digital Signatures
        const _SectionHeader('Official Digital Signatures'),
        _SignatureCard(
          role: 'Village Accountant (VA)',
          name: 'Pending — Awaiting Aadhaar e-Sign',
          taluk: 'Yelahanka Hobli',
          signed: false,
        ),
        const SizedBox(height: 8),
        _SignatureCard(
          role: 'Revenue Inspector',
          name: 'Pending — Digital Signature Required',
          taluk: 'Bengaluru North Taluk',
          signed: false,
        ),
        const SizedBox(height: 8),
        _SignatureCard(
          role: 'Arth ID Platform',
          name: 'Sanjay R, Founder',
          taluk: 'Startup India: IN-0326-9427JD',
          signed: true,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Text(
            'Arth ID directly accesses all government databases (Bhoomi, Kaveri, eCourts, BBMP, CERSAI, BDA/BMRDA, FMB) as a public citizen right — '
            'no MOU or government approval needed. VA and Tahsildar can co-sign reports '
            'using Aadhaar e-Sign directly from their phone.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Owner key
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.key, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Your Report Key (Owner Permission)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DS-KEY-9X7K-2M4P-8Q1R',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share this key with buyer or bank to allow them to view '
                'your verified report. Without this key, the report '
                'cannot be accessed by anyone else.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── TAB 4 — Grievance ────────────────────────────────────────────────────────
class _GrievanceTab extends StatefulWidget {
  const _GrievanceTab();
  @override
  State<_GrievanceTab> createState() => _GrievanceTabState();
}

class _GrievanceTabState extends State<_GrievanceTab> {
  bool _filed = false;
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_filed) return _TicketView();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Raise a Grievance'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Issue Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Wrong ownership record',
                  'EC mismatch',
                  'Mutation not updated',
                  'Encroachment',
                  'Fraud alert',
                  'Other',
                ].map((t) => ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      selected: false,
                      onSelected: (_) {},
                    )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Describe your issue',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() => _filed = true),
                icon: const Icon(Icons.send),
                label: const Text('Submit Grievance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionHeader('Escalation Timeline'),
        _EscalationRow('Day 1–7', 'Complaint sent to Village Accountant',
            Icons.send, Colors.blue, true),
        _EscalationRow('Day 8–15', 'Auto-escalate to Revenue Inspector',
            Icons.arrow_upward, Colors.orange, false),
        _EscalationRow('Day 16–30', 'Escalate to Tahsildar + RTI option',
            Icons.warning, Colors.deepOrange, false),
        _EscalationRow('Day 31+', 'Lokayukta + Legal Aid route',
            Icons.gavel, Colors.red, false),
      ],
    );
  }
}

class _TicketView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Grievance Filed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Ticket: DS-GRV-2026-4821',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          const Text(
            'Your complaint has been sent to Village Accountant, '
            'Yelahanka Hobli. Expected response: 7 working days. '
            'You will receive a notification when they respond.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Timeline
          _EscalationRow('Now', 'Sent to Village Accountant',
              Icons.send, Colors.green, true),
          _EscalationRow('Day 8', 'Auto-escalate if no response',
              Icons.arrow_upward, Colors.orange, false),
          _EscalationRow('Day 16', 'RTI option unlocked',
              Icons.description, Colors.deepOrange, false),
          _EscalationRow('Day 31', 'Lokayukta route available',
              Icons.gavel, Colors.red, false),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _Tab(this.label, this.index, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: sel ? Colors.amber : Colors.transparent, width: 2.5),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: sel ? Colors.amber : Colors.white60,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final int score;
  const _ScoreCircle({required this.score});
  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? AppColors.primary
        : score >= 50
            ? Colors.orange
            : Colors.red;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$score',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text('/100',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );
}

class _CheckCard extends StatefulWidget {
  final IconData icon;
  final String title, status, detail;
  const _CheckCard(
      {required this.icon,
      required this.title,
      required this.status,
      required this.detail});
  @override
  State<_CheckCard> createState() => _CheckCardState();
}

class _CheckCardState extends State<_CheckCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.status == 'clear'
        ? AppColors.primary
        : widget.status == 'warning'
            ? Colors.orange
            : Colors.red;
    final icon = widget.status == 'clear'
        ? Icons.check_circle
        : widget.status == 'warning'
            ? Icons.warning_amber
            : Icons.cancel;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(widget.icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(widget.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 4),
                Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                    size: 18),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.detail,
                    style: const TextStyle(fontSize: 12, height: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  final String role, office;
  final bool verified;
  const _ChainRow(this.role, this.office, this.verified);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
                verified ? Icons.check_circle : Icons.radio_button_unchecked,
                color: verified ? AppColors.primary : Colors.grey,
                size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(role,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500))),
            Text(office,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary)),
      );
}

class _DocTile extends StatelessWidget {
  final IconData icon;
  final String title, source, status;
  final Color statusColor;
  const _DocTile(this.icon, this.title, this.source, this.status,
      this.statusColor);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(source,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

class _SignatureCard extends StatelessWidget {
  final String role, name, taluk;
  final bool signed;
  const _SignatureCard(
      {required this.role,
      required this.name,
      required this.taluk,
      required this.signed});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: signed
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: signed
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                  signed ? Icons.verified : Icons.pending,
                  color: signed ? AppColors.primary : Colors.grey,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(name,
                      style: TextStyle(
                          fontSize: 12,
                          color: signed ? Colors.black87 : Colors.grey)),
                  Text(taluk,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: signed
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                signed ? 'SIGNED' : 'PENDING',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: signed ? AppColors.primary : Colors.grey),
              ),
            ),
          ],
        ),
      );
}

class _EscalationRow extends StatelessWidget {
  final String day, label;
  final IconData icon;
  final Color color;
  final bool active;
  const _EscalationRow(this.day, this.label, this.icon, this.color,
      this.active);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: active ? color : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.white : Colors.grey)),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: active ? color : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.black87 : Colors.grey))),
          ],
        ),
      );
}
