import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

class BuyerHomeScreen extends ConsumerWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(recentReportsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go('/home'); },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('I\'m a Buyer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
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
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.home_outlined, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text('Find & Verify Property',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Search, verify documents, and buy with confidence',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/marketplace'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Browse Properties', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search by location
            const Text('Search by Location',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            _LocationSearchCard(),
            const SizedBox(height: 16),

            // Verify a property
            const Text('Verify Before You Buy',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ActionCard(
                icon: Icons.upload_file_outlined,
                title: 'Upload Document',
                subtitle: 'RTC, EC, Sale Deed',
                color: AppColors.primary,
                onTap: () => context.push('/upload'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(
                icon: Icons.document_scanner_outlined,
                title: 'Scan Property',
                subtitle: 'Camera scan',
                color: AppColors.safe,
                onTap: () => context.push('/scan'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(
                icon: Icons.search_outlined,
                title: 'Survey No.',
                subtitle: 'Manual search',
                color: AppColors.warning,
                onTap: () => context.push('/manual-search'),
              )),
            ]),
            const SizedBox(height: 16),

            // Tools
            const Text('Buyer Tools',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
            _BuyerToolsList(),
            const SizedBox(height: 16),

            // FinSelf Lite CTA
            _FinSelfCard(),
            const SizedBox(height: 16),

            // Recent verifications
            const Text('My Verifications',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            if (reports.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: const Column(children: [
                  Icon(Icons.folder_open_outlined, size: 40, color: AppColors.textLight),
                  SizedBox(height: 8),
                  Text('No verifications yet', style: TextStyle(color: AppColors.textLight)),
                  SizedBox(height: 4),
                  Text('Upload or scan a property document to start',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12), textAlign: TextAlign.center),
                ]),
              )
            else
              ...reports.take(3).map((r) => _ReportTile(report: r)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ));
  }
}

class _LocationSearchCard extends StatefulWidget {
  @override
  State<_LocationSearchCard> createState() => _LocationSearchCardState();
}

class _LocationSearchCardState extends State<_LocationSearchCard> {
  String? _state = 'Karnataka';
  String? _district;
  String? _type;

  static const _districts = [
    'Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Mangaluru',
    'Belagavi', 'Kalaburagi', 'Ballari', 'Dharwad', 'Shivamogga',
    'Hassan', 'Tumakuru', 'Udupi', 'Haveri', 'Davanagere',
  ];
  static const _types = ['Apartment', 'House / Villa', 'Plot / Land', 'Commercial', 'Agricultural'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.map_outlined, size: 16, color: AppColors.textLight),
          const SizedBox(width: 6),
          const Text('State: ', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
          const Text('Karnataka', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _district,
          hint: const Text('Select District', style: TextStyle(fontSize: 13)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor)),
          ),
          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _district = v),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _type,
          hint: const Text('Property Type', style: TextStyle(fontSize: 13)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor)),
          ),
          items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/marketplace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.search, size: 18, color: Colors.white),
            label: const Text('Search Properties', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
            textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textLight),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _BuyerToolsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(Icons.location_city_outlined, 'SRO Locator', 'Find Sub-Registrar Office', '/sro-locator'),
      _Tool(Icons.gavel_outlined, 'eCourt Check', 'Litigation & court records', '/ecourt'),
      _Tool(Icons.verified_outlined, 'RERA Status', 'Builder/project registration', '/rera'),
      _Tool(Icons.calculate_outlined, 'Stamp Duty', 'Calculate registration cost', '/stamp-duty'),
      _Tool(Icons.people_outline, 'Expert Help', 'Lawyers, banks, surveyors', '/partners'),
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
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(e.value.icon, color: AppColors.primary, size: 18),
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

class _FinSelfCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/arth-id'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0D2137), const Color(0xFF1A3A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFc8922a).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFc8922a), width: 1.5),
            ),
            child: const Icon(Icons.fingerprint, color: Color(0xFFc8922a), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FinSelf Lite', style: TextStyle(color: Color(0xFFc8922a),
                fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 2),
            Text('Check your loan eligibility & CIBIL score before buying',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Color(0xFFc8922a), size: 14),
        ]),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final dynamic report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final score = report.riskAssessment.score as int;
    final color = score >= 70 ? AppColors.safe : score >= 40 ? AppColors.warning : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(child: Text('$score', style: TextStyle(color: color,
              fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(report.propertyAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(report.riskAssessment.level, style: TextStyle(fontSize: 11, color: color)),
        ])),
        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textLight),
      ]),
    );
  }
}
