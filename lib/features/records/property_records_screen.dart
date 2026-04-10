import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/payment_service.dart';
import 'package:digi_sampatti/core/services/instamojo_service.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Property Records Screen ──────────────────────────────────────────────────
// Shows all raw government portal data on-screen for ₹99.
// Owner → Land Type → Extent → Khata → EC Transactions →
// Court Cases → CERSAI → Guidance Value → FMB
// ─────────────────────────────────────────────────────────────────────────────

class PropertyRecordsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? fullResult;
  const PropertyRecordsScreen({super.key, this.fullResult});

  @override
  ConsumerState<PropertyRecordsScreen> createState() =>
      _PropertyRecordsScreenState();
}

class _PropertyRecordsScreenState extends ConsumerState<PropertyRecordsScreen>
    with WidgetsBindingObserver {
  // Records are shown immediately — payment is for PDF export only
  bool _isPaid = true;
  bool _isProcessing = false;
  String? _pendingRequestId;
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? get _data => widget.fullResult;
  Map<String, dynamic>? get _rtc => _data?['rtc'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _ec => _data?['ec'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _courts => _data?['courts'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _cersai => _data?['cersai'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _gv => _data?['guidance_value'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _fmb => _data?['fmb'] as Map<String, dynamic>?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingRequestId != null) {
      _verifyPayment();
    }
  }

  Future<void> _startPayment() async {
    final scan = ref.read(currentScanProvider);
    setState(() => _isProcessing = true);
    try {
      _paymentService.onSuccess = (paymentId) {
        if (mounted) setState(() { _isPaid = true; _isProcessing = false; });
      };
      _paymentService.onFailure = (err) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Payment failed: $err')));
        }
      };
      final requestId = await _paymentService.openReportPayment(
        reportId: 'records-${scan?.surveyNumber ?? "prop"}',
        userPhone: '',
        customAmount: 99,
      );
      if (requestId != null) {
        setState(() { _pendingRequestId = requestId; _isProcessing = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _verifyPayment() async {
    if (_pendingRequestId == null) return;
    setState(() => _isProcessing = true);
    try {
      final status = await InstamojoService().checkPaymentStatus(_pendingRequestId!);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (status.paid) {
            _isPaid = true;
            _pendingRequestId = null;
          }
        });
        if (!status.paid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment not confirmed yet. Try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Property Records'),
        backgroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/report'),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Get PDF'),
          ),
        ],
      ),
      body: _isPaid ? _buildRecords() : _buildPaywall(),
    );
  }

  // ─── Paywall ────────────────────────────────────────────────────────────────
  Widget _buildPaywall() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Preview teaser — blur effect placeholder
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bhoomi RTC — Land Record',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _previewRow('Owner Name', _rtc?['owner_name'] ?? '••••••'),
                _previewRow('Survey Number', _data?['survey_number']?.toString() ?? '••••'),
                _previewRow('District', '••••••••'),
                _previewRow('Land Type', '••••••'),
                _previewRow('Extent', '•••• acres'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Text('Unlock full portal data to see details',
                          style: TextStyle(fontSize: 12, color: Colors.brown)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // What you get
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What you get for ₹99',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                ...[
                  ('Bhoomi RTC', 'Owner name, land type, area, khata, water source'),
                  ('Kaveri EC', 'All transactions in 30 years — mortgages, sales, liens'),
                  ('eCourts', 'Active court cases on this property or owner'),
                  ('CERSAI', 'Bank mortgage registry — any hidden charges'),
                  ('Guidance Value', 'Government minimum price per sqft'),
                  ('FMB Sketch', 'Official land boundary map'),
                  ('RERA', 'Builder registration status'),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.safe, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.$1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(e.$2,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pay button
          ElevatedButton(
            onPressed: _isProcessing ? null : _startPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All Records — ₹99',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text('Pay once · See on screen immediately',
                          style:
                              TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
          ),

          if (_pendingRequestId != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _verifyPayment,
              icon: const Icon(Icons.refresh),
              label: const Text('I completed payment — verify now'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ],

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/report'),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Get PDF Report instead — ₹149'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Full Records View ────────────────────────────────────────────────────────
  Widget _buildRecords() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── What you're looking at — first-time buyer guide ─────────────────
          _buildBuyerGuide(),
          const SizedBox(height: 16),

          // ── CRITICAL alert for injunctions / litigation ─────────────────────
          _buildInjunctionAlert(),

          // ── Bhoomi RTC ──────────────────────────────────────────────────────
          _sectionHeader('Bhoomi RTC — Land Record',
              Icons.article_outlined, const Color(0xFF1B5E20)),
          _buildRtcCard(),
          _verifyBanner(
            'Bhoomi Portal',
            'https://landrecords.karnataka.gov.in',
            'Open Bhoomi → select District/Taluk/Hobli/Village → enter same survey number → compare owner name, land type, area with what DigiSampatti found above.',
          ),
          const SizedBox(height: 16),

          // ── Kaveri EC ───────────────────────────────────────────────────────
          _sectionHeader('Kaveri EC — Encumbrance Certificate',
              Icons.account_balance_outlined, const Color(0xFF0D47A1)),
          _buildEcCard(),
          _verifyBanner(
            'Kaveri EC Portal',
            'https://kaverionline.karnataka.gov.in',
            'Open Kaveri Online → EC Search → enter same survey number & period → compare transaction count and parties with DigiSampatti.',
          ),
          const SizedBox(height: 16),

          // ── eCourts ─────────────────────────────────────────────────────────
          _sectionHeader('eCourts — Court Cases',
              Icons.gavel_outlined, const Color(0xFFBF360C)),
          _buildCourtsCard(),
          _verifyBanner(
            'eCourts India',
            'https://services.ecourts.gov.in/ecourtindia_v6/',
            'Open eCourts → Party Name search → enter owner name, select Karnataka district → verify DigiSampatti shows same number of cases.',
          ),
          const SizedBox(height: 16),

          // ── CERSAI ──────────────────────────────────────────────────────────
          _sectionHeader('CERSAI — Bank Mortgage Registry',
              Icons.lock_outlined, const Color(0xFF880E4F)),
          _buildCersaiCard(),
          _verifyBanner(
            'CERSAI Portal',
            'https://cersai.org.in',
            'Open CERSAI → Property Search → enter survey details → confirm if any bank has a registered charge on this property.',
          ),
          const SizedBox(height: 16),

          // ── Guidance Value ──────────────────────────────────────────────────
          _sectionHeader('Guidance Value — IGR Karnataka',
              Icons.attach_money, const Color(0xFF006064)),
          _buildGvCard(),
          _verifyBanner(
            'IGR Karnataka',
            'https://igr.karnataka.gov.in/english',
            'Open IGR → Guidance Value → select taluk/village → compare ₹/sqft with what DigiSampatti shows above.',
          ),
          const SizedBox(height: 16),

          // ── FMB Sketch ──────────────────────────────────────────────────────
          _sectionHeader('FMB Sketch — Land Boundary Map',
              Icons.map_outlined, const Color(0xFF37474F)),
          _buildFmbCard(),
          _verifyBanner(
            'Bhoomi FMB',
            'https://landrecords.karnataka.gov.in',
            'Open Bhoomi → FMB/Sketch → enter same survey number → compare the land boundary sketch.',
          ),
          const SizedBox(height: 24),

          // ── PDF CTA ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('Get Official PDF Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                const Text(
                    'AI analysis + Risk Score + All data in one shareable PDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Download Full PDF Report',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── "Verify on Government Portal" compare banner ───────────────────────────
  Widget _verifyBanner(String portalName, String url, String instruction) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, size: 16, color: Color(0xFF0D47A1)),
              const SizedBox(width: 6),
              const Text('Verify this data yourself',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0D47A1))),
            ],
          ),
          const SizedBox(height: 4),
          Text(instruction,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 16),
              label: Text('Open $portalName →',
                  style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D47A1),
                side: const BorderSide(color: Color(0xFF0D47A1)),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: child,
    );
  }

  Widget _row(String label, String? value, {Color? valueColor}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOk ? AppColors.safe.withOpacity(0.1) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isOk ? AppColors.safe : Colors.red.shade200),
      ),
      child: Text(text,
          style: TextStyle(
              color: isOk ? AppColors.safe : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }

  // ─── First-time buyer guide ───────────────────────────────────────────────────
  Widget _buildBuyerGuide() {
    const steps = [
      (Icons.article_outlined, '1. Bhoomi RTC',
        'The Revenue/Tenancy Certificate (RTC) is the master record for agricultural land. '
        'It tells you WHO owns the land, HOW MUCH they own, what TYPE of land it is, '
        'and whether there are any government NOTICES against it. '
        'This is the first document any lawyer or bank will ask for.'),
      (Icons.account_balance_outlined, '2. Kaveri EC',
        'The Encumbrance Certificate (EC) lists every TRANSACTION on this property for the last 30 years — '
        'every sale, mortgage, loan, partition, gift deed. '
        'If someone else sold this land before, or took a loan against it, it shows here. '
        'A clean EC means nobody else has a hidden claim on this land.'),
      (Icons.gavel_outlined, '3. eCourts',
        'Checks if the land or the owner is involved in ANY active court case. '
        'If a court has frozen the land (injunction), you cannot register it — '
        'the registrar will reject your sale deed. Always verify this BEFORE paying any advance.'),
      (Icons.lock_outlined, '4. CERSAI',
        'The Central Registry of Securitisation — a national database of bank mortgages. '
        'If the owner took a home loan and gave this land as security, it appears here. '
        'Banks must clear their charge before you can buy.'),
      (Icons.attach_money, '5. Guidance Value',
        'This is the government\'s MINIMUM price per sq.ft for stamp duty calculation. '
        'You cannot register a sale below this value. '
        'If the seller quotes far below guidance value, something is wrong.'),
      (Icons.map_outlined, '6. FMB Sketch',
        'The Field Measurement Book sketch shows the EXACT boundary of the survey number on a map. '
        'Use this to physically verify the land — walk the boundary, check for encroachments, '
        'verify the shape matches what the seller is showing you.'),
    ];
    return ExpansionTile(
      initiallyExpanded: false,
      leading: const Icon(Icons.school_outlined, color: Color(0xFF1B5E20)),
      title: const Text('What do these documents mean?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: const Text('Tap to understand each record — read before buying',
          style: TextStyle(fontSize: 11, color: Colors.grey)),
      backgroundColor: const Color(0xFFF1F8E9),
      collapsedBackgroundColor: const Color(0xFFF1F8E9),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1B5E20), width: 0.5)),
      collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1B5E20), width: 0.5)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: steps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s.$1, color: const Color(0xFF1B5E20), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(s.$3,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Injunction / critical flag detector ─────────────────────────────────────
  Widget _buildInjunctionAlert() {
    final remarks = _rtc?['remarks']?.toString() ?? '';
    final mutations = _rtc?['mutations'] as List? ?? [];
    // Check for court order keywords in remarks or mutation entries
    final allText = [
      remarks,
      ...mutations.map((m) => m.toString()),
    ].join(' ').toLowerCase();

    final hasInjunction = allText.contains('injunction') ||
        allText.contains('temporary stay') ||
        allText.contains('thadeyajne') ||
        allText.contains('ತಡೆಯಾಜ್ಞೆ') ||
        allText.contains('os ') ||
        allText.contains('court order') ||
        allText.contains('trgn');

    if (!hasInjunction) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7B0000).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7B0000), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, color: Color(0xFF7B0000), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CRITICAL: Court Injunction Recorded in RTC',
                  style: TextStyle(
                      color: Color(0xFF7B0000),
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'A Temporary Injunction (ತಡೆಯಾಜ್ಞೆ) means a civil court has issued an ORDER '
            'stopping any transaction on this property until the case is resolved.\n\n'
            'What this means for you:\n'
            '• The Sub-Registrar WILL REJECT your sale deed — you cannot register this property\n'
            '• Even if you pay the seller, you cannot get legal title\n'
            '• The injunction case must be FULLY RESOLVED in court before any sale\n\n'
            'What to do:\n'
            '1. Get the exact OS (Original Suit) case number from the RTC mutation entry\n'
            '2. Search eCourts (services.ecourts.gov.in) to see the current case status\n'
            '3. Consult a property lawyer — DO NOT pay any advance until this is cleared\n'
            '4. Ask the seller for a certified copy of the "Vaad Nispatti" (case disposal order)',
            style: TextStyle(
                fontSize: 12, height: 1.6, color: Color(0xFF4A0000)),
          ),
        ],
      ),
    );
  }

  // ─── RTC Card ────────────────────────────────────────────────────────────────
  Widget _buildRtcCard() {
    if (_rtc == null) {
      return _card(const Text('No data available from Bhoomi portal',
          style: TextStyle(color: AppColors.textLight)));
    }
    final d = _rtc!;
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Owner Name', d['owner_name']?.toString()),
        _row('Owner (Kannada)', d['owner_name_kannada']?.toString()),
        _row('Survey No.', d['survey_number']?.toString()),
        _row('Hissa No.', d['hissa_number']?.toString()),
        _row('Khata Number', d['khata_number']?.toString()),
        _row('Village', d['village']?.toString()),
        _row('Hobli', d['hobli']?.toString()),
        _row('Taluk', d['taluk']?.toString()),
        _row('District', d['district']?.toString()),
        _row('Land Type', d['land_type']?.toString()),
        _row('Nature of Land', d['nature_of_land']?.toString()),
        _row('Area (Acres)', d['extent_acres']?.toString()),
        _row('Area (Guntas)', d['extent_guntas']?.toString()),
        _row('Total Extent', d['extent']?.toString()),
        _row('Water Source', d['water_source']?.toString()),
        _row('Soil Type', d['soil_type']?.toString()),
        _row('Assessment No.', d['assessment_number']?.toString()),
        if (d['land_type'] != null)
          _landTypeWarning(d['land_type'].toString()),
      ],
    ));
  }

  Widget _landTypeWarning(String landType) {
    final dangerous = ['government', 'forest', 'revenue', 'kharab'].any(
        (t) => landType.toLowerCase().contains(t));
    if (!dangerous) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Warning: This land is classified as "$landType". '
              'Do NOT buy without legal advice.',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EC Card ─────────────────────────────────────────────────────────────────
  Widget _buildEcCard() {
    if (_ec == null) {
      return _card(const Text('Kaveri EC portal not available right now.',
          style: TextStyle(color: AppColors.textLight)));
    }
    final d = _ec!;
    final isFree = d['encumbrance_free'] == true;
    final transactions = d['transactions'] as List? ?? [];
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statusBadge(
                isFree ? 'Encumbrance Free ✓' : '${transactions.length} Transaction(s) Found',
                isFree),
          ],
        ),
        const SizedBox(height: 12),
        _row('Period', d['period']?.toString()),
        _row('Total Transactions', transactions.length.toString()),
        if (transactions.isNotEmpty) ...[
          const Divider(),
          const Text('Transaction History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...transactions.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction ${i + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  _row('Doc Type', t['document_type']?.toString()),
                  _row('EC No.', t['ec_number']?.toString()),
                  _row('Date', t['date']?.toString()),
                  _row('Party 1', t['party_1']?.toString()),
                  _row('Party 2', t['party_2']?.toString()),
                  _row('Amount', t['amount']?.toString()),
                  _row('Nature', t['nature']?.toString()),
                ],
              ),
            );
          }),
        ],
      ],
    ));
  }

  // ─── Courts Card ─────────────────────────────────────────────────────────────
  Widget _buildCourtsCard() {
    if (_courts == null) {
      return _card(const Text('eCourts portal check pending.',
          style: TextStyle(color: AppColors.textLight)));
    }
    final d = _courts!;
    final hasCases = d['has_pending_cases'] == true;
    final cases = d['cases'] as List? ?? [];
    final count = d['cases_found'] ?? cases.length;
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusBadge(
            hasCases ? '$count Case(s) Found — Review!' : 'No Cases Found ✓',
            !hasCases),
        const SizedBox(height: 12),
        _row('District', d['district']?.toString()),
        _row('Party Searched', d['party_name']?.toString()),
        if (cases.isNotEmpty) ...[
          const Divider(),
          const Text('Case Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...cases.map((c) {
            final t = c as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Case No.', t['case_number']?.toString()),
                  _row('Court', t['court']?.toString()),
                  _row('Status', t['status']?.toString()),
                  _row('Filed Date', t['filed_date']?.toString()),
                  _row('Next Hearing', t['next_hearing']?.toString()),
                ],
              ),
            );
          }),
        ],
      ],
    ));
  }

  // ─── CERSAI Card ─────────────────────────────────────────────────────────────
  Widget _buildCersaiCard() {
    if (_cersai == null) {
      return _card(const Text('CERSAI check pending.',
          style: TextStyle(color: AppColors.textLight)));
    }
    final d = _cersai!;
    final isMortgaged = d['is_mortgaged'] == true;
    final lenders = (d['lenders'] as List?)?.cast<String>() ?? [];
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusBadge(
            isMortgaged ? 'Mortgage/Charge Found!' : 'No Lien or Charge ✓',
            !isMortgaged),
        const SizedBox(height: 12),
        if (lenders.isNotEmpty)
          _row('Lender(s)', lenders.join(', '),
              valueColor: Colors.red.shade700),
        _row('Total Charges',
            (d['charges'] as List?)?.length.toString() ?? '0'),
        if (isMortgaged)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: const Text(
              'This property has a bank charge. If you buy it, the bank '
              'can still claim it to recover unpaid loans. Do not proceed '
              'without getting a NOC from the lender.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    ));
  }

  // ─── Guidance Value Card ──────────────────────────────────────────────────────
  Widget _buildGvCard() {
    if (_gv == null) {
      return _card(const Text('Guidance value not available.',
          style: TextStyle(color: AppColors.textLight)));
    }
    final d = _gv!;
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₹${d['value_per_sqft'] ?? 'N/A'} per sqft',
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006064)),
        ),
        const SizedBox(height: 8),
        _row('Taluk', d['taluk']?.toString()),
        _row('Area Type', d['area_type']?.toString()),
        _row('Classification', d['classification']?.toString()),
        _row('Last Updated', d['last_updated']?.toString()),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF006064).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'This is the government-set minimum value for this area. '
            'Registration cannot happen below this value. '
            'Bank loans are based on guidance value, not market value.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ),
      ],
    ));
  }

  // ─── FMB Sketch Card ─────────────────────────────────────────────────────────
  Widget _buildFmbCard() {
    if (_fmb == null) {
      return _card(const Text(
          'FMB sketch not available (portal may be offline).',
          style: TextStyle(color: AppColors.textLight)));
    }
    final d = _fmb!;
    final sketchUrl = d['sketch_url'] as String?;
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Area', d['area']?.toString()),
        _row('North', d['north']?.toString()),
        _row('South', d['south']?.toString()),
        _row('East', d['east']?.toString()),
        _row('West', d['west']?.toString()),
        if (sketchUrl != null) ...[
          const SizedBox(height: 12),
          const Text('Land Boundary Sketch',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              sketchUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: Colors.grey.shade100,
                child: const Center(
                  child: Text('Sketch image not loadable',
                      style: TextStyle(color: AppColors.textLight)),
                ),
              ),
            ),
          ),
        ] else
          const Text('Sketch image not available for this survey',
              style: TextStyle(color: AppColors.textLight, fontSize: 12)),
      ],
    ));
  }
}
