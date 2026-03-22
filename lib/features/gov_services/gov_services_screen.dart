import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';

// ─── Apply Service Data ───────────────────────────────────────────────────────

class _GovService {
  final IconData icon;
  final Color color;
  final String titleEn, titleKn;
  final String subtitleEn, subtitleKn;
  final String whatYouGetEn, whatYouGetKn;
  final String applyUrl;
  final String department;

  const _GovService({
    required this.icon, required this.color,
    required this.titleEn, required this.titleKn,
    required this.subtitleEn, required this.subtitleKn,
    required this.whatYouGetEn, required this.whatYouGetKn,
    required this.applyUrl, required this.department,
  });
}

const _services = [
  _GovService(
    icon: Icons.verified_outlined, color: Color(0xFF1B5E20),
    titleEn: 'Encumbrance Certificate (EC)', titleKn: 'ಭಾರ ಪ್ರಮಾಣಪತ್ರ (EC)',
    subtitleEn: 'Kaveri Online Services', subtitleKn: 'ಕಾವೇರಿ ಆನ್‌ಲೈನ್ ಸೇವೆಗಳು',
    whatYouGetEn: 'Proves property has no loans, legal charges, or disputes registered',
    whatYouGetKn: 'ಆಸ್ತಿಯಲ್ಲಿ ಯಾವುದೇ ಸಾಲ ಅಥವಾ ವ್ಯಾಜ್ಯ ಇಲ್ಲ ಎಂದು ದೃಢಪಡಿಸುತ್ತದೆ',
    applyUrl: 'https://kaverionline.karnataka.gov.in',
    department: 'Dept. of Stamps & Registration, Karnataka',
  ),
  _GovService(
    icon: Icons.article_outlined, color: Color(0xFF0D47A1),
    titleEn: 'RTC / Pahani (Land Record)', titleKn: 'ಆರ್‌ಟಿಸಿ / ಪಹಣಿ',
    subtitleEn: 'Bhoomi Online', subtitleKn: 'ಭೂಮಿ ಆನ್‌ಲೈನ್',
    whatYouGetEn: 'Official land ownership record — owner name, survey no., extent, crop details',
    whatYouGetKn: 'ಅಧಿಕೃತ ಭೂಮಿ ದಾಖಲೆ — ಮಾಲೀಕರ ಹೆಸರು, ಸರ್ವೆ ಸಂಖ್ಯೆ, ವಿಸ್ತೀರ್ಣ',
    applyUrl: 'https://bhoomi.karnataka.gov.in/new/bhoomi/',
    department: 'Revenue Dept., Government of Karnataka',
  ),
  _GovService(
    icon: Icons.swap_horiz, color: Color(0xFF4A148C),
    titleEn: 'Mutation / Khata Transfer', titleKn: 'ಮ್ಯುಟೇಷನ್ / ಖಾತಾ ವರ್ಗಾವಣೆ',
    subtitleEn: 'SAKALA — Guaranteed Time-Bound Services', subtitleKn: 'ಸಕಾಲ — ಸಮಯ ಬದ್ಧ ಸೇವೆ',
    whatYouGetEn: 'Transfer property ownership in revenue records after sale/inheritance',
    whatYouGetKn: 'ಮಾರಾಟ/ಉತ್ತರಾಧಿಕಾರದ ನಂತರ ಆದಾಯ ದಾಖಲೆಗಳಲ್ಲಿ ಮಾಲೀಕತ್ವ ವರ್ಗಾಯಿಸಿ',
    applyUrl: 'https://sakala.kar.nic.in',
    department: 'Revenue Dept. via SAKALA, Karnataka',
  ),
  _GovService(
    icon: Icons.how_to_reg, color: Color(0xFFB71C1C),
    titleEn: 'Property Registration', titleKn: 'ಆಸ್ತಿ ನೋಂದಣಿ',
    subtitleEn: 'Kaveri 2.0 — Slot Booking', subtitleKn: 'ಕಾವೇರಿ 2.0 — ಸ್ಲಾಟ್ ಬುಕ್ಕಿಂಗ್',
    whatYouGetEn: 'Book SRO appointment online. Register sale deed, gift deed, or lease deed',
    whatYouGetKn: 'ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ SRO ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಬುಕ್ ಮಾಡಿ',
    applyUrl: 'https://kaverionline.karnataka.gov.in',
    department: 'Dept. of Stamps & Registration, Karnataka',
  ),
  _GovService(
    icon: Icons.domain_verification, color: Color(0xFFE65100),
    titleEn: 'RERA Project Verification', titleKn: 'RERA ಯೋಜನೆ ಪರಿಶೀಲನೆ',
    subtitleEn: 'Karnataka RERA', subtitleKn: 'ಕರ್ನಾಟಕ RERA',
    whatYouGetEn: 'Verify apartment/plot project RERA registration. Check builder credentials',
    whatYouGetKn: 'ಅಪಾರ್ಟ್‌ಮೆಂಟ್ ಯೋಜನೆ RERA ನೋಂದಣಿ ಪರಿಶೀಲಿಸಿ',
    applyUrl: 'https://rera.karnataka.gov.in',
    department: 'Karnataka Real Estate Regulatory Authority',
  ),
  _GovService(
    icon: Icons.gavel, color: Color(0xFF37474F),
    titleEn: 'Court Case Status', titleKn: 'ನ್ಯಾಯಾಲಯ ಪ್ರಕರಣ ಸ್ಥಿತಿ',
    subtitleEn: 'eCourts — National Judicial Data Grid', subtitleKn: 'eCourts — ರಾಷ್ಟ್ರೀಯ ನ್ಯಾಯಾಂಗ ದತ್ತಾಂಶ',
    whatYouGetEn: 'Check if property or owner has any pending court case in India',
    whatYouGetKn: 'ಆಸ್ತಿ ಮಾಲೀಕರ ವಿರುದ್ಧ ಯಾವುದೇ ನ್ಯಾಯಾಲಯ ಪ್ರಕರಣ ಇದೆಯೇ ಎಂದು ತಿಳಿಯಿರಿ',
    applyUrl: 'https://ecourts.gov.in/ecourts_home/',
    department: 'Ministry of Law & Justice, Govt. of India',
  ),
  _GovService(
    icon: Icons.landscape, color: Color(0xFF1A237E),
    titleEn: 'Land Use / Zone Certificate', titleKn: 'ಭೂ ಬಳಕೆ / ವಲಯ ಪ್ರಮಾಣಪತ್ರ',
    subtitleEn: 'e-Swathu / BDA / BBMP', subtitleKn: 'ಇ-ಸ್ವತ್ಥು / BDA / BBMP',
    whatYouGetEn: 'Confirm if land is agricultural, residential, or commercial — vital before buying',
    whatYouGetKn: 'ಭೂಮಿ ಕೃಷಿ, ವಸತಿ ಅಥವಾ ವಾಣಿಜ್ಯ ಎಂದು ದೃಢಪಡಿಸಿ',
    applyUrl: 'https://eswathu.karnataka.gov.in',
    department: 'Urban Development Dept., Karnataka',
  ),
];

// ─── Tracker Service Data ─────────────────────────────────────────────────────

class _TrackerService {
  final String label;
  final String hint;
  final String Function(String ref) trackUrl;
  const _TrackerService(this.label, this.hint, this.trackUrl);
}

final _trackerServices = [
  _TrackerService('SAKALA (Mutation / Khata)', 'e.g. SAKALA123456789',
      (ref) => 'https://sakala.kar.nic.in/sakala/common/trackYourApplication.do'),
  _TrackerService('Kaveri EC / Registration', 'e.g. KAR-2024-12345',
      (ref) => 'https://kaverionline.karnataka.gov.in'),
  _TrackerService('Bhoomi RTC Application', 'e.g. BHM-2024-98765',
      (ref) => 'https://bhoomi.karnataka.gov.in/new/bhoomi/'),
  _TrackerService('RERA Complaint / Project', 'e.g. PRM/KA/RERA/...',
      (ref) => 'https://rera.karnataka.gov.in'),
];

// ─── Grievance Data ───────────────────────────────────────────────────────────

class _GrievanceService {
  final IconData icon;
  final Color color;
  final String titleEn, titleKn;
  final String descEn, descKn;
  final String whenEn, whenKn;
  final String url;

  const _GrievanceService({
    required this.icon, required this.color,
    required this.titleEn, required this.titleKn,
    required this.descEn, required this.descKn,
    required this.whenEn, required this.whenKn,
    required this.url,
  });
}

const _grievances = [
  _GrievanceService(
    icon: Icons.report_problem_outlined, color: Color(0xFFB71C1C),
    titleEn: 'Land / Property Fraud Complaint',
    titleKn: 'ಭೂಮಿ / ಆಸ್ತಿ ವಂಚನೆ ದೂರು',
    descEn: 'Karnataka Revenue Dept. Grievance Portal',
    descKn: 'ಕರ್ನಾಟಕ ಕಂದಾಯ ಇಲಾಖೆ ದೂರು ಪೋರ್ಟಲ್',
    whenEn: 'Fake RTC, forged sale deed, identity fraud, wrong mutation',
    whenKn: 'ನಕಲಿ RTC, ಕ್ಷಮಾ ಮಾರಾಟ ಪತ್ರ, ತಪ್ಪಾದ ಮ್ಯುಟೇಷನ್',
    url: 'https://sakala.kar.nic.in',
  ),
  _GrievanceService(
    icon: Icons.fence, color: Color(0xFFE65100),
    titleEn: 'Land Encroachment Complaint',
    titleKn: 'ಭೂಮಿ ಒತ್ತುವರಿ ದೂರು',
    descEn: 'Revenue Department / Tahsildar Office Online',
    descKn: 'ಕಂದಾಯ ಇಲಾಖೆ / ತಹಸೀಲ್ದಾರ್ ಕಚೇರಿ',
    whenEn: 'Someone has illegally occupied or fenced your land',
    whenKn: 'ಯಾರಾದರೂ ನಿಮ್ಮ ಭೂಮಿ ಅಕ್ರಮವಾಗಿ ಆಕ್ರಮಿಸಿಕೊಂಡಿದ್ದರೆ',
    url: 'https://sakala.kar.nic.in',
  ),
  _GrievanceService(
    icon: Icons.apartment, color: Color(0xFF4A148C),
    titleEn: 'Builder / RERA Violation Complaint',
    titleKn: 'ಬಿಲ್ಡರ್ / RERA ಉಲ್ಲಂಘನೆ ದೂರು',
    descEn: 'Karnataka RERA Complaint Portal',
    descKn: 'ಕರ್ನಾಟಕ RERA ದೂರು ಪೋರ್ಟಲ್',
    whenEn: 'Builder delay, unregistered project, false promises, possession issues',
    whenKn: 'ಬಿಲ್ಡರ್ ವಿಳಂಬ, ನೋಂದಣಿಯಾಗದ ಯೋಜನೆ, ಸ್ವಾಧೀನ ಸಮಸ್ಯೆ',
    url: 'https://rera.karnataka.gov.in/viewComplaint',
  ),
  _GrievanceService(
    icon: Icons.privacy_tip_outlined, color: Color(0xFF1B5E20),
    titleEn: 'File RTI — Right to Information',
    titleKn: 'RTI ಸಲ್ಲಿಸಿ — ಮಾಹಿತಿ ಹಕ್ಕು',
    descEn: 'RTI Online — Central / State',
    descKn: 'RTI ಆನ್‌ಲೈನ್ — ಕೇಂದ್ರ / ರಾಜ್ಯ',
    whenEn: 'Ask government to share official land records, approvals, decisions on your property',
    whenKn: 'ಸರ್ಕಾರದಿಂದ ಅಧಿಕೃತ ಭೂ ದಾಖಲೆ, ಅನುಮೋದನೆ ಕೇಳಿ',
    url: 'https://rtionline.gov.in',
  ),
  _GrievanceService(
    icon: Icons.record_voice_over_outlined, color: Color(0xFF37474F),
    titleEn: 'CM Helpline / Jan Spandana',
    titleKn: 'ಸಿಎಂ ಹೆಲ್ಪ್‌ಲೈನ್ / ಜನ ಸ್ಪಂದನ',
    descEn: 'Karnataka CM Helpline 1902 — escalate unresolved issues',
    descKn: 'ಕರ್ನಾಟಕ ಸಿಎಂ ಹೆಲ್ಪ್‌ಲೈನ್ 1902',
    whenEn: 'If government department is not responding or rejecting your valid application',
    whenKn: 'ಸರ್ಕಾರಿ ಇಲಾಖೆ ಸ್ಪಂದಿಸದಿದ್ದರೆ ಅಥವಾ ಸರಿಯಾದ ಅರ್ಜಿ ತಿರಸ್ಕರಿಸಿದರೆ',
    url: 'https://janaspandana.karnataka.gov.in',
  ),
];

// ─── Rejection Step Data ──────────────────────────────────────────────────────

const _rejectionStepsEn = [
  ('1. Read the rejection reason', 'Log in to the portal and open your application. The exact reason is listed — missing document, wrong format, mismatch in name/survey number, etc.'),
  ('2. Correct the document or detail', 'Fix the specific issue. Example: if the RTC name doesn\'t match the sale deed name, get an affidavit. If a document is missing, get a certified copy.'),
  ('3. Re-apply with corrections', 'Submit a fresh application on the same portal. Attach all corrected documents. Keep the old application number for reference.'),
  ('4. Escalate via SAKALA if delayed', 'If the department doesn\'t process within the SAKALA time limit, file a SAKALA Second Appeal — it goes to a senior officer automatically.'),
  ('5. File CM Helpline if still stuck', 'Call 1902 or file on Jan Spandana online. Mention your application number and rejection date. Usually resolved in 7–15 days.'),
];

const _rejectionStepsKn = [
  ('1. ತಿರಸ್ಕಾರ ಕಾರಣ ಓದಿ', 'ಪೋರ್ಟಲ್‌ನಲ್ಲಿ ಲಾಗಿನ್ ಮಾಡಿ. ನಿಖರ ಕಾರಣ ತಿಳಿಯಿರಿ — ದಾಖಲೆ ಕಾಣೆ, ತಪ್ಪಾದ ಹೆಸರು, ಇತ್ಯಾದಿ.'),
  ('2. ತಪ್ಪನ್ನು ಸರಿಪಡಿಸಿ', 'ಸಮಸ್ಯೆ ಸರಿಪಡಿಸಿ. ಹೆಸರು ತಪ್ಪಿದ್ದರೆ ಅಫಿಡವಿಟ್ ಪಡೆಯಿರಿ. ದಾಖಲೆ ಇಲ್ಲದಿದ್ದರೆ ಸರ್ಟಿಫೈಡ್ ಕಾಪಿ ತೆಗೆಯಿರಿ.'),
  ('3. ಮತ್ತೆ ಅರ್ಜಿ ಸಲ್ಲಿಸಿ', 'ಅದೇ ಪೋರ್ಟಲ್‌ನಲ್ಲಿ ಸರಿಪಡಿಸಿದ ದಾಖಲೆಗಳೊಂದಿಗೆ ಹೊಸ ಅರ್ಜಿ ಸಲ್ಲಿಸಿ.'),
  ('4. SAKALA ಮೂಲಕ ಎಸ್ಕಲೇಟ್ ಮಾಡಿ', 'SAKALA ಸಮಯ ಮಿತಿ ಮೀರಿದರೆ ಎರಡನೇ ಮೇಲ್ಮನವಿ ಸಲ್ಲಿಸಿ. ಹಿರಿಯ ಅಧಿಕಾರಿಗೆ ತಲುಪುತ್ತದೆ.'),
  ('5. ಇನ್ನೂ ಸಮಸ್ಯೆ ಇದ್ದರೆ CM Helpline 1902', 'ಅರ್ಜಿ ಸಂಖ್ಯೆ ಮತ್ತು ತಿರಸ್ಕಾರ ದಿನಾಂಕ ನಮೂದಿಸಿ. ಸಾಮಾನ್ಯವಾಗಿ 7–15 ದಿನಗಳಲ್ಲಿ ಪರಿಹಾರ.'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class GovServicesScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefillData;
  const GovServicesScreen({super.key, this.prefillData});

  @override
  ConsumerState<GovServicesScreen> createState() => _GovServicesScreenState();
}

class _GovServicesScreenState extends ConsumerState<GovServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedTracker = 0;
  bool _showRejectionHelp = false;
  final _refController = TextEditingController();
  late TextEditingController _surveyController;
  late TextEditingController _districtController;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _surveyController = TextEditingController(
        text: widget.prefillData?['surveyNumber'] as String? ?? '');
    _districtController = TextEditingController(
        text: widget.prefillData?['district'] as String? ?? '');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _refController.dispose();
    _surveyController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser. Please visit the website manually.')),
        );
      }
    }
  }

  void _trackApplication() {
    final ref = _refController.text.trim();
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your application reference number')),
      );
      return;
    }
    _launch(_trackerServices[_selectedTracker].trackUrl(ref));
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isKn = lang == 'kn';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isKn ? 'ಅರ್ಜಿ & ಟ್ರ್ಯಾಕ್' : 'Apply & Track'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: isKn ? 'ಅರ್ಜಿ' : 'Apply'),
            Tab(text: isKn ? 'ಟ್ರ್ಯಾಕ್' : 'Track'),
            Tab(text: isKn ? 'ದೂರು' : 'Grievance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildApplyTab(isKn),
          _buildTrackTab(isKn),
          _buildGrievanceTab(isKn),
        ],
      ),
    );
  }

  // ── Apply Tab ────────────────────────────────────────────────────────────────

  Widget _buildApplyTab(bool isKn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isKn
                        ? 'ಅಧಿಕೃತ ಸರ್ಕಾರಿ ಪೋರ್ಟಲ್‌ಗಳು. ಎಲ್ಲಾ ಅರ್ಜಿಗಳು ಸರ್ಕಾರಿ ಇಲಾಖೆಗಳು ನಿರ್ವಹಿಸುತ್ತವೆ.'
                        : 'Official Government portals only. All applications processed by Government departments.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Editable prefill fields
          Text(
            isKn ? 'ಆಸ್ತಿ ವಿವರ (ಸಂಪಾದಿಸಬಹುದು)' : 'Property Details — Edit if needed',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _surveyController,
                  decoration: InputDecoration(
                    labelText: isKn ? 'ಸರ್ವೆ ಸಂಖ್ಯೆ' : 'Survey No.',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    labelText: isKn ? 'ಜಿಲ್ಲೆ' : 'District',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            isKn ? '7 ಅಧಿಕೃತ ಸರ್ಕಾರಿ ಸೇವೆಗಳು' : '7 Official Government Services',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          ...List.generate(_services.length, (i) => _ServiceCard(
            service: _services[i],
            isKn: isKn,
            surveyNo: _surveyController.text,
            district: _districtController.text,
            onTap: () => _launch(_services[i].applyUrl),
          )),
          const SizedBox(height: 4),
          Center(
            child: Text(
              isKn ? '© DigiSampatti ಸ್ವತಂತ್ರ ಮಾರ್ಗದರ್ಶಿ. ಸರ್ಕಾರಿ ಪೋರ್ಟಲ್‌ಗಳಿಗೆ ಮಾತ್ರ ಲಿಂಕ್.'
                  : '© DigiSampatti is an independent guide. Links go only to official .gov.in portals.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Track Tab ────────────────────────────────────────────────────────────────

  Widget _buildTrackTab(bool isKn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service selector
          Text(
            isKn ? 'ಸೇವೆ ಆಯ್ಕೆ ಮಾಡಿ' : 'Select Service',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: List.generate(_trackerServices.length, (i) {
                final selected = _selectedTracker == i;
                return InkWell(
                  onTap: () => setState(() => _selectedTracker = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: selected ? AppColors.primary : AppColors.borderColor, width: 2),
                            color: selected ? AppColors.primary : Colors.transparent,
                          ),
                          child: selected
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _trackerServices[i].label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              color: selected ? AppColors.primary : AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isKn ? 'ಅರ್ಜಿ ಸಂಖ್ಯೆ' : 'Application Reference Number',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _refController,
            decoration: InputDecoration(
              hintText: _trackerServices[_selectedTracker].hint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_outlined, size: 18),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) _refController.text = data!.text!;
                },
                tooltip: 'Paste',
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _trackApplication,
              icon: const Icon(Icons.search),
              label: Text(isKn ? 'ಅಧಿಕೃತ ಪೋರ್ಟಲ್‌ನಲ್ಲಿ ಟ್ರ್ಯಾಕ್ ಮಾಡಿ' : 'Track on Official Portal'),
            ),
          ),
          const SizedBox(height: 22),

          // Status guide
          Text(
            isKn ? 'ಅರ್ಜಿ ಸ್ಥಿತಿ ಅರ್ಥ' : 'What Application Statuses Mean',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          _StatusGuideCard(isKn: isKn),
          const SizedBox(height: 16),

          // Rejected help — expandable
          InkWell(
            onTap: () => setState(() => _showRejectionHelp = !_showRejectionHelp),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isKn
                          ? 'ಅರ್ಜಿ ತಿರಸ್ಕರಿಸಲಾಗಿದೆಯೇ? ಮುಂದೇನು ಮಾಡಬೇಕು?'
                          : 'Application Rejected? What to do next',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFE65100)),
                    ),
                  ),
                  Icon(
                    _showRejectionHelp ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFE65100),
                  ),
                ],
              ),
            ),
          ),
          if (_showRejectionHelp) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  isKn ? _rejectionStepsKn.length : _rejectionStepsEn.length,
                  (i) {
                    final (title, desc) = isKn ? _rejectionStepsKn[i] : _rejectionStepsEn[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22, height: 22,
                            margin: const EdgeInsets.only(top: 1, right: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE65100),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(desc,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textMedium, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Helpline
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.phone, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Text(isKn ? 'ಸಹಾಯ ಬೇಕೇ?' : 'Need Help?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'SAKALA Helpline: 080-22230281\nBhoomi Helpline: 080-22113355\nCM Helpline: 1902',
                  style: TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Grievance Tab ─────────────────────────────────────────────────────────────

  Widget _buildGrievanceTab(bool isKn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, color: Color(0xFFC62828), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isKn
                        ? 'ಅಕ್ರಮ ಕಂಡರೆ ಅಧಿಕೃತ ಸರ್ಕಾರಿ ಪೋರ್ಟಲ್‌ಗಳ ಮೂಲಕ ದೂರು ಸಲ್ಲಿಸಿ.'
                        : 'If you find wrongdoing, file a complaint on official Government portals. Your rights are protected by law.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFC62828), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isKn ? 'ದೂರು ಪ್ರಕಾರ ಆಯ್ಕೆ ಮಾಡಿ' : 'Select Complaint Type',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),

          ...List.generate(_grievances.length, (i) => _GrievanceCard(
            g: _grievances[i],
            isKn: isKn,
            onTap: () => _launch(_grievances[i].url),
          )),

          const SizedBox(height: 14),

          // Wrongdoing documentation tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF6A1B9A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isKn ? 'ದೂರು ಸಲ್ಲಿಸುವ ಮೊದಲು' : 'Before Filing a Complaint',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6A1B9A)),
                  ),
                ]),
                const SizedBox(height: 10),
                ..._buildTip(
                  isKn
                      ? [
                          'ಎಲ್ಲ ದಾಖಲೆಗಳ ಫೋಟೋ ತೆಗೆಯಿರಿ (RTC, ಸೇಲ್ ಡೀಡ್, ಮ್ಯಾಪ್)',
                          'ಅರ್ಜಿ ಸಂಖ್ಯೆ ಮತ್ತು ದಿನಾಂಕಗಳನ್ನು ಬರೆದಿಡಿ',
                          'ಸ್ಥಳ / ಸರ್ವೆ ಸಂಖ್ಯೆ ಸ್ಪಷ್ಟವಾಗಿ ನಮೂದಿಸಿ',
                          'ಸಾಕ್ಷಿಗಳ ಹೆಸರು ಮತ್ತು ದೂರವಾಣಿ ಸಂಖ್ಯೆ ಇಟ್ಟುಕೊಳ್ಳಿ',
                        ]
                      : [
                          'Photograph all documents (RTC, sale deed, map, approvals)',
                          'Note all application numbers and dates',
                          'State the exact survey number and location clearly',
                          'Keep names and contacts of witnesses ready',
                        ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _buildTip(List<String> tips) => tips
      .map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold)),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4))),
              ],
            ),
          ))
      .toList();
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _GovService service;
  final bool isKn;
  final String surveyNo;
  final String district;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service, required this.isKn,
    required this.surveyNo, required this.district,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: service.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(service.icon, color: service.color, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isKn ? service.titleKn : service.titleEn,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        Text(isKn ? service.subtitleKn : service.subtitleEn,
                            style: TextStyle(fontSize: 11, color: service.color, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: service.color, borderRadius: BorderRadius.circular(8)),
                    child: Text(isKn ? 'ತೆರೆಯಿರಿ' : 'Apply',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: service.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(isKn ? service.whatYouGetKn : service.whatYouGetEn,
                          style: TextStyle(fontSize: 11, color: service.color, height: 1.4)),
                    ),
                  ],
                ),
              ),
              if (surveyNo.isNotEmpty || district.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.edit_note, size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    [if (surveyNo.isNotEmpty) 'Survey: $surveyNo', if (district.isNotEmpty) district]
                        .join(' · '),
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ]),
              ],
              const SizedBox(height: 4),
              Text(service.department,
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grievance Card ───────────────────────────────────────────────────────────

class _GrievanceCard extends StatelessWidget {
  final _GrievanceService g;
  final bool isKn;
  final VoidCallback onTap;

  const _GrievanceCard({required this.g, required this.isKn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: g.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(g.icon, color: g.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isKn ? g.titleKn : g.titleEn,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    Text(isKn ? g.descKn : g.descEn,
                        style: TextStyle(fontSize: 11, color: g.color, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: g.color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isKn ? g.whenKn : g.whenEn,
                          style: TextStyle(fontSize: 11, color: g.color, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, size: 16, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Guide ─────────────────────────────────────────────────────────────

class _StatusGuideCard extends StatelessWidget {
  final bool isKn;
  const _StatusGuideCard({required this.isKn});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('Submitted', isKn ? 'ಅರ್ಜಿ ಸ್ವೀಕರಿಸಲಾಗಿದೆ' : 'Application received by department', Colors.blue),
      ('Under Process', isKn ? 'ಅಧಿಕಾರಿ ಪರಿಶೀಲಿಸುತ್ತಿದ್ದಾರೆ' : 'Officer reviewing your documents', Colors.orange),
      ('Approved', isKn ? 'ಅನುಮೋದಿಸಲಾಗಿದೆ — ದಾಖಲೆ ಸಂಗ್ರಹಿಸಿ' : 'Approved — collect your document', Colors.green),
      ('Rejected', isKn ? 'ತಿರಸ್ಕರಿಸಲಾಗಿದೆ — ಕಾರಣ ನೋಡಿ ಮತ್ತೆ ಅರ್ಜಿ ಸಲ್ಲಿಸಿ' : 'Rejected — read reason, correct & reapply', Colors.red),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: statuses.asMap().entries.map((e) {
          final (label, desc, color) = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (e.key < statuses.length - 1) const Divider(height: 1, indent: 34),
            ],
          );
        }).toList(),
      ),
    );
  }
}
