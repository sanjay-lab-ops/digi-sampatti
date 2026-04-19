import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Full due diligence checklist covering all legal checks required
/// before a property purchase in India.
class DueDiligenceScreen extends StatefulWidget {
  const DueDiligenceScreen({super.key});

  @override
  State<DueDiligenceScreen> createState() => _DueDiligenceScreenState();
}

class _DueDiligenceScreenState extends State<DueDiligenceScreen> {
  final Map<String, _CheckStatus> _status = {};

  static const _categories = [
    _Category(
      title: 'Title & Ownership',
      icon: Icons.verified_user_outlined,
      color: Color(0xFF1565C0),
      checks: [
        _Check(
          id: 'ec',
          name: 'Encumbrance Certificate (EC)',
          description: 'Confirms no outstanding loans, mortgages, or legal disputes on the property. Get 13-30 years EC.',
          portal: 'Kaveri Online (Karnataka) / State Registration Portal',
          url: 'https://kaverionline.karnataka.gov.in',
          critical: true,
        ),
        _Check(
          id: 'sale_deed',
          name: 'Sale Deed / Title Deed',
          description: 'Original sale deed showing chain of ownership. Verify all previous transfers are registered.',
          portal: 'SRO Office / Kaveri Online',
          url: 'https://kaverionline.karnataka.gov.in',
          critical: true,
        ),
        _Check(
          id: 'khata',
          name: 'Khata Certificate & Extract',
          description: 'BBMP/Gram Panchayat Khata showing property ownership in civic body records.',
          portal: 'BBMP / Gram Panchayat',
          url: 'https://bbmpeaasthi.karnataka.gov.in',
          critical: true,
        ),
        _Check(
          id: 'patta',
          name: 'Patta / Pahani (Rural land)',
          description: 'Land ownership record for agricultural or rural properties. Shows survey number, extent.',
          portal: 'Bhoomi Portal (Karnataka)',
          url: 'https://bhoomi.karnataka.gov.in',
          critical: false,
        ),
      ],
    ),
    _Category(
      title: 'Revenue & Land Records',
      icon: Icons.landscape_outlined,
      color: Color(0xFF2E7D32),
      checks: [
        _Check(
          id: 'rtc',
          name: 'RTC / 7-12 Extract',
          description: 'Record of Rights, Tenancy and Crops. Shows land type, owner, tenant, and crop details.',
          portal: 'Bhoomi Portal / State Land Records',
          url: 'https://bhoomi.karnataka.gov.in',
          critical: true,
        ),
        _Check(
          id: 'mutation',
          name: 'Mutation / Hissa',
          description: 'Verify all previous mutations (ownership changes) are properly recorded in revenue records.',
          portal: 'Bhoomi Portal',
          url: 'https://bhoomi.karnataka.gov.in',
          critical: true,
        ),
        _Check(
          id: 'survey',
          name: 'Survey Map / Sketch',
          description: 'Tippan / FMB sketch showing exact boundaries, area, and adjacent survey numbers.',
          portal: 'Survey Department / Bhoomi',
          url: 'https://bhoomi.karnataka.gov.in',
          critical: false,
        ),
        _Check(
          id: 'land_conversion',
          name: 'DC Conversion Order',
          description: 'For converted agricultural land — Deputy Commissioner conversion order must exist.',
          portal: 'Revenue Department',
          url: null,
          critical: false,
        ),
      ],
    ),
    _Category(
      title: 'Loans & Mortgages',
      icon: Icons.account_balance_outlined,
      color: Color(0xFFE65100),
      checks: [
        _Check(
          id: 'cersai',
          name: 'CERSAI Check',
          description: 'Central Registry of Securitisation Asset Reconstruction and Security Interest — checks for registered mortgages.',
          portal: 'CERSAI Portal',
          url: 'https://cersai.org.in',
          critical: true,
        ),
        _Check(
          id: 'noc_bank',
          name: 'Bank NOC / Loan Closure',
          description: 'If seller had a home loan, get original bank NOC confirming loan is fully repaid.',
          portal: 'Seller\'s bank',
          url: null,
          critical: true,
        ),
      ],
    ),
    _Category(
      title: 'Legal & Court',
      icon: Icons.gavel_outlined,
      color: Color(0xFF6A1B9A),
      checks: [
        _Check(
          id: 'court_cases',
          name: 'Court Case Check',
          description: 'Search District Court, High Court, and Supreme Court for any litigation on the property.',
          portal: 'eCourts Portal',
          url: 'https://ecourts.gov.in',
          critical: true,
        ),
        _Check(
          id: 'attachment',
          name: 'Court Attachment / Stay Order',
          description: 'Verify property is not under court attachment, stay, or receiver order.',
          portal: 'District Court / eCourts',
          url: 'https://ecourts.gov.in',
          critical: true,
        ),
        _Check(
          id: 'will_succession',
          name: 'Will / Succession Certificate',
          description: 'If property was inherited, verify probated will or succession certificate.',
          portal: 'Court / Legal heir',
          url: null,
          critical: false,
        ),
      ],
    ),
    _Category(
      title: 'Building Approvals',
      icon: Icons.apartment_outlined,
      color: Color(0xFF0277BD),
      checks: [
        _Check(
          id: 'building_plan',
          name: 'Building Plan Approval',
          description: 'BDA / BBMP / Panchayat approved building plan. Check for unauthorized floors or deviations.',
          portal: 'BBMP / BDA',
          url: 'https://bbmp.gov.in',
          critical: true,
        ),
        _Check(
          id: 'oc',
          name: 'Occupancy Certificate (OC)',
          description: 'For apartments/flats — OC from BBMP/BDA confirming building is as per approved plan.',
          portal: 'BBMP / BDA',
          url: 'https://bbmp.gov.in',
          critical: true,
        ),
        _Check(
          id: 'rera',
          name: 'RERA Registration',
          description: 'For under-construction properties — must be RERA registered. Check delivery date, completion %.',
          portal: 'RERA Karnataka',
          url: 'https://rera.karnataka.gov.in',
          critical: false,
        ),
        _Check(
          id: 'fire_noc',
          name: 'Fire NOC (High-rise)',
          description: 'Buildings above 15 meters require Fire Department NOC.',
          portal: 'Fire Department',
          url: null,
          critical: false,
        ),
      ],
    ),
    _Category(
      title: 'Tax & Utility',
      icon: Icons.receipt_outlined,
      color: Color(0xFF558B2F),
      checks: [
        _Check(
          id: 'property_tax',
          name: 'Property Tax Paid',
          description: 'Verify all property tax is paid up to date. Get latest paid receipt from BBMP/Panchayat.',
          portal: 'BBMP Property Tax / Panchayat',
          url: 'https://bbmptax.karnataka.gov.in',
          critical: true,
        ),
        _Check(
          id: 'betterment_charges',
          name: 'Betterment / Development Charges',
          description: 'Any pending betterment charges or development charges to the civic body.',
          portal: 'BDA / BBMP',
          url: null,
          critical: false,
        ),
        _Check(
          id: 'eb_dues',
          name: 'EB / Water Dues',
          description: 'Verify electricity board and water board dues are cleared.',
          portal: 'BESCOM / BWSSB',
          url: 'https://bescom.karnataka.gov.in',
          critical: false,
        ),
      ],
    ),
    _Category(
      title: 'Society / Apartment',
      icon: Icons.people_outline,
      color: Color(0xFF37474F),
      checks: [
        _Check(
          id: 'society_noc',
          name: 'Society / Association NOC',
          description: 'For flat purchases — get NOC from residents association confirming no dues.',
          portal: 'Apartment Association',
          url: null,
          critical: false,
        ),
        _Check(
          id: 'maintenance_dues',
          name: 'Maintenance Dues Cleared',
          description: 'Verify all maintenance, parking, and corpus fund dues are paid.',
          portal: 'Society office',
          url: null,
          critical: false,
        ),
        _Check(
          id: 'share_certificate',
          name: 'Share Certificate',
          description: 'Co-operative housing society share certificate in seller\'s name.',
          portal: 'Society office',
          url: null,
          critical: false,
        ),
      ],
    ),
  ];

  int get _totalChecks => _categories.fold(0, (s, c) => s + c.checks.length);
  int get _criticalChecks => _categories.fold(0, (s, c) => s + c.checks.where((ch) => ch.critical).length);
  int get _doneCount => _status.values.where((s) => s == _CheckStatus.clear).length;
  int get _issueCount => _status.values.where((s) => s == _CheckStatus.issue).length;
  int get _criticalDone => _categories
    .expand((c) => c.checks.where((ch) => ch.critical))
    .where((ch) => _status[ch.id] == _CheckStatus.clear)
    .length;

  bool get _allCriticalDone => _criticalDone == _criticalChecks;

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
            Text('Due Diligence', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Full property verification checklist', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ]),
        ),
        body: Column(children: [
          // Score header
          _DiligenceHeader(
            total: _totalChecks,
            done: _doneCount,
            issues: _issueCount,
            criticalDone: _criticalDone,
            criticalTotal: _criticalChecks,
          ),
          // Categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _categories.length + 1,
              itemBuilder: (context, i) {
                if (i == _categories.length) {
                  return _ProceedButton(
                    allCriticalDone: _allCriticalDone,
                    onProceed: () => context.go('/advance-receipt'),
                  );
                }
                final cat = _categories[i];
                return _CategorySection(
                  category: cat,
                  statuses: _status,
                  onStatusChanged: (id, status) => setState(() => _status[id] = status),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _DiligenceHeader extends StatelessWidget {
  final int total, done, issues, criticalDone, criticalTotal;
  const _DiligenceHeader({
    required this.total, required this.done, required this.issues,
    required this.criticalDone, required this.criticalTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [
        Row(children: [
          Expanded(child: _ScorePill('$done/$total', 'Verified', AppColors.safe)),
          const SizedBox(width: 8),
          Expanded(child: _ScorePill('$criticalDone/$criticalTotal', 'Critical', Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _ScorePill('$issues', 'Issues', issues > 0 ? AppColors.danger : Colors.grey)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? done / total : 0,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.safe),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('Red = Critical check', style: TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(width: 16),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade600, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('Grey = Optional check', style: TextStyle(color: Colors.white54, fontSize: 10)),
        ]),
      ]),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String value, label;
  final Color color;
  const _ScorePill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final _Category category;
  final Map<String, _CheckStatus> statuses;
  final void Function(String id, _CheckStatus status) onStatusChanged;
  const _CategorySection({
    required this.category, required this.statuses, required this.onStatusChanged,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Category header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cat.color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(cat.icon, color: cat.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(cat.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E)))),
              Text('${cat.checks.where((c) => widget.statuses[c.id] == _CheckStatus.clear).length}/${cat.checks.length}',
                style: TextStyle(color: cat.color, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey, size: 18),
            ]),
          ),
        ),
        // Checks
        if (_expanded) ...[
          const Divider(height: 1),
          ...cat.checks.map((check) => _CheckItem(
            check: check,
            status: widget.statuses[check.id] ?? _CheckStatus.pending,
            onStatusChanged: (s) => widget.onStatusChanged(check.id, s),
          )),
        ],
      ]),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final _Check check;
  final _CheckStatus status;
  final void Function(_CheckStatus) onStatusChanged;
  const _CheckItem({required this.check, required this.status, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        color: status == _CheckStatus.issue ? Colors.red.withOpacity(0.03) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (check.critical)
            Container(
              width: 6, height: 6, margin: const EdgeInsets.only(right: 6, top: 1),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          Expanded(child: Text(check.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A1A2E)))),
          // Status buttons
          _StatusButton(status: status, onChanged: onStatusChanged),
        ]),
        const SizedBox(height: 4),
        Text(check.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.language, size: 10, color: Colors.blueGrey),
          const SizedBox(width: 4),
          Expanded(child: Text(check.portal,
            style: const TextStyle(fontSize: 10, color: Colors.blueGrey))),
          if (check.url != null)
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(check.url!);
                if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Open Portal →',
                style: TextStyle(fontSize: 10, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
            ),
        ]),
      ]),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final _CheckStatus status;
  final void Function(_CheckStatus) onChanged;
  const _StatusButton({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CheckStatus>(
      onSelected: onChanged,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status == _CheckStatus.clear ? AppColors.safe.withOpacity(0.1)
              : status == _CheckStatus.issue ? Colors.red.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: status == _CheckStatus.clear ? AppColors.safe.withOpacity(0.4)
                : status == _CheckStatus.issue ? Colors.red.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            status == _CheckStatus.clear ? Icons.check_circle
                : status == _CheckStatus.issue ? Icons.cancel
                : Icons.radio_button_unchecked,
            size: 12,
            color: status == _CheckStatus.clear ? AppColors.safe
                : status == _CheckStatus.issue ? Colors.red
                : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            status == _CheckStatus.clear ? 'Clear'
                : status == _CheckStatus.issue ? 'Issue'
                : 'Pending',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: status == _CheckStatus.clear ? AppColors.safe
                  : status == _CheckStatus.issue ? Colors.red
                  : Colors.grey,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
        ]),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: _CheckStatus.pending, child: Text('Pending')),
        const PopupMenuItem(value: _CheckStatus.clear, child: Text('✅ Clear')),
        const PopupMenuItem(value: _CheckStatus.issue, child: Text('❌ Issue Found')),
      ],
    );
  }
}

class _ProceedButton extends StatelessWidget {
  final bool allCriticalDone;
  final VoidCallback onProceed;
  const _ProceedButton({required this.allCriticalDone, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      child: Column(children: [
        if (!allCriticalDone)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                'Complete all critical (red dot) checks before proceeding.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              )),
            ]),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: allCriticalDone ? onProceed : null,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Proceed to Advance Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safe,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

enum _CheckStatus { pending, clear, issue }

class _Check {
  final String id, name, description, portal;
  final String? url;
  final bool critical;
  const _Check({
    required this.id, required this.name, required this.description,
    required this.portal, this.url, required this.critical,
  });
}

class _Category {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Check> checks;
  const _Category({required this.title, required this.icon, required this.color, required this.checks});
}
