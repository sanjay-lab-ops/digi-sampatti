import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class _GovService {
  final IconData icon;
  final Color color;
  final String titleEn;
  final String titleKn;
  final String subtitleEn;
  final String subtitleKn;
  final String whatYouGetEn;
  final String whatYouGetKn;
  final String applyUrl;
  final String department;

  const _GovService({
    required this.icon,
    required this.color,
    required this.titleEn,
    required this.titleKn,
    required this.subtitleEn,
    required this.subtitleKn,
    required this.whatYouGetEn,
    required this.whatYouGetKn,
    required this.applyUrl,
    required this.department,
  });
}

const _services = [
  _GovService(
    icon: Icons.verified_outlined,
    color: Color(0xFF1B5E20),
    titleEn: 'Encumbrance Certificate (EC)',
    titleKn: 'ಭಾರ ಪ್ರಮಾಣಪತ್ರ (EC)',
    subtitleEn: 'Kaveri Online Services',
    subtitleKn: 'ಕಾವೇರಿ ಆನ್‌ಲೈನ್ ಸೇವೆಗಳು',
    whatYouGetEn: 'Proves property has no loans, legal charges, or disputes registered',
    whatYouGetKn: 'ಆಸ್ತಿಯಲ್ಲಿ ಯಾವುದೇ ಸಾಲ ಅಥವಾ ವ್ಯಾಜ್ಯ ಇಲ್ಲ ಎಂದು ದೃಢಪಡಿಸುತ್ತದೆ',
    applyUrl: 'https://kaverionline.karnataka.gov.in',
    department: 'Dept. of Stamps & Registration, Karnataka',
  ),
  _GovService(
    icon: Icons.article_outlined,
    color: Color(0xFF0D47A1),
    titleEn: 'RTC / Pahani (Land Record)',
    titleKn: 'ಆರ್‌ಟಿಸಿ / ಪಹಣಿ',
    subtitleEn: 'Bhoomi Online',
    subtitleKn: 'ಭೂಮಿ ಆನ್‌ಲೈನ್',
    whatYouGetEn: 'Official land ownership record — owner name, survey no., extent, crop details',
    whatYouGetKn: 'ಅಧಿಕೃತ ಭೂಮಿ ದಾಖಲೆ — ಮಾಲೀಕರ ಹೆಸರು, ಸರ್ವೆ ಸಂಖ್ಯೆ, ವಿಸ್ತೀರ್ಣ',
    applyUrl: 'https://bhoomi.karnataka.gov.in/new/bhoomi/',
    department: 'Revenue Dept., Government of Karnataka',
  ),
  _GovService(
    icon: Icons.swap_horiz,
    color: Color(0xFF4A148C),
    titleEn: 'Mutation / Khata Transfer',
    titleKn: 'ಮ್ಯುಟೇಷನ್ / ಖಾತಾ ವರ್ಗಾವಣೆ',
    subtitleEn: 'SAKALA — Guaranteed Time-Bound Services',
    subtitleKn: 'ಸಕಾಲ — ಸಮಯ ಬದ್ಧ ಸೇವೆ',
    whatYouGetEn: 'Transfer property ownership in revenue records after sale/inheritance',
    whatYouGetKn: 'ಮಾರಾಟ/ಉತ್ತರಾಧಿಕಾರದ ನಂತರ ಆದಾಯ ದಾಖಲೆಗಳಲ್ಲಿ ಮಾಲೀಕತ್ವ ವರ್ಗಾಯಿಸಿ',
    applyUrl: 'https://sakala.kar.nic.in',
    department: 'Revenue Dept. via SAKALA, Karnataka',
  ),
  _GovService(
    icon: Icons.how_to_reg,
    color: Color(0xFFB71C1C),
    titleEn: 'Property Registration',
    titleKn: 'ಆಸ್ತಿ ನೋಂದಣಿ',
    subtitleEn: 'Kaveri 2.0 — Slot Booking',
    subtitleKn: 'ಕಾವೇರಿ 2.0 — ಸ್ಲಾಟ್ ಬುಕ್ಕಿಂಗ್',
    whatYouGetEn: 'Book SRO appointment online. Register sale deed, gift deed, or lease deed',
    whatYouGetKn: 'ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ SRO ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಬುಕ್ ಮಾಡಿ',
    applyUrl: 'https://kaverionline.karnataka.gov.in',
    department: 'Dept. of Stamps & Registration, Karnataka',
  ),
  _GovService(
    icon: Icons.domain_verification,
    color: Color(0xFFE65100),
    titleEn: 'RERA Project Verification',
    titleKn: 'RERA ಯೋಜನೆ ಪರಿಶೀಲನೆ',
    subtitleEn: 'Karnataka RERA',
    subtitleKn: 'ಕರ್ನಾಟಕ RERA',
    whatYouGetEn: 'Verify if apartment/plot project is legally registered with RERA. Check builder credentials',
    whatYouGetKn: 'ಅಪಾರ್ಟ್‌ಮೆಂಟ್ ಯೋಜನೆ RERA ನೋಂದಣಿ ಪರಿಶೀಲಿಸಿ',
    applyUrl: 'https://rera.karnataka.gov.in',
    department: 'Karnataka Real Estate Regulatory Authority',
  ),
  _GovService(
    icon: Icons.gavel,
    color: Color(0xFF37474F),
    titleEn: 'Court Case Status',
    titleKn: 'ನ್ಯಾಯಾಲಯ ಪ್ರಕರಣ ಸ್ಥಿತಿ',
    subtitleEn: 'eCourts — National Judicial Data Grid',
    subtitleKn: 'eCourts — ರಾಷ್ಟ್ರೀಯ ನ್ಯಾಯಾಂಗ ದತ್ತಾಂಶ',
    whatYouGetEn: 'Check if property owner or property is involved in any pending court case',
    whatYouGetKn: 'ಆಸ್ತಿ ಮಾಲೀಕರ ವಿರುದ್ಧ ಯಾವುದೇ ನ್ಯಾಯಾಲಯ ಪ್ರಕರಣ ಇದೆಯೇ ಎಂದು ತಿಳಿಯಿರಿ',
    applyUrl: 'https://ecourts.gov.in/ecourts_home/',
    department: 'Ministry of Law & Justice, Govt. of India',
  ),
  _GovService(
    icon: Icons.landscape,
    color: Color(0xFF1A237E),
    titleEn: 'Land Use / Zone Certificate',
    titleKn: 'ಭೂ ಬಳಕೆ / ವಲಯ ಪ್ರಮಾಣಪತ್ರ',
    subtitleEn: 'e-Swathu / BDA / BBMP',
    subtitleKn: 'ಇ-ಸ್ವತ್ಥು / BDA / BBMP',
    whatYouGetEn: 'Confirm if land is agricultural, residential, or commercial — vital before buying',
    whatYouGetKn: 'ಭೂಮಿ ಕೃಷಿ, ವಸತಿ ಅಥವಾ ವಾಣಿಜ್ಯ ಎಂದು ದೃಢಪಡಿಸಿ',
    applyUrl: 'https://eswathu.karnataka.gov.in',
    department: 'Urban Development Dept., Karnataka',
  ),
];

// ─── Tracker Services ──────────────────────────────────────────────────────────

class _TrackerService {
  final String label;
  final String hint;
  final String Function(String ref) trackUrl;
  const _TrackerService(this.label, this.hint, this.trackUrl);
}

final _trackerServices = [
  _TrackerService(
    'SAKALA (Mutation / Khata)',
    'e.g. SAKALA123456789',
    (ref) => 'https://sakala.kar.nic.in/sakala/common/trackYourApplication.do',
  ),
  _TrackerService(
    'Kaveri EC / Registration',
    'e.g. KAR-2024-12345',
    (ref) => 'https://kaverionline.karnataka.gov.in',
  ),
  _TrackerService(
    'Bhoomi RTC Application',
    'e.g. BHM-2024-98765',
    (ref) => 'https://bhoomi.karnataka.gov.in/new/bhoomi/',
  ),
  _TrackerService(
    'RERA Complaint / Project',
    'e.g. PRM/KA/RERA/...',
    (ref) => 'https://rera.karnataka.gov.in',
  ),
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
  final _refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _refController.dispose();
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
    final url = _trackerServices[_selectedTracker].trackUrl(ref);
    _launch(url);
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
            Tab(text: isKn ? 'ಅರ್ಜಿ ಸಲ್ಲಿಸಿ' : 'Quick Apply'),
            Tab(text: isKn ? 'ಟ್ರ್ಯಾಕ್' : 'Track Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildApplyTab(isKn),
          _buildTrackTab(isKn),
        ],
      ),
    );
  }

  Widget _buildApplyTab(bool isKn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gov banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isKn
                        ? 'DigiSampatti ನಿಮ್ಮನ್ನು ಅಧಿಕೃತ ಸರ್ಕಾರಿ ಪೋರ್ಟಲ್‌ಗಳಿಗೆ ಕರೆದೊಯ್ಯುತ್ತದೆ. ಎಲ್ಲಾ ಅರ್ಜಿಗಳು ಸರ್ಕಾರಿ ಇಲಾಖೆಗಳು ನಿರ್ವಹಿಸುತ್ತವೆ.'
                        : 'DigiSampatti connects you directly to official Government portals. All applications are processed by Government departments.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Prefill chip
          if (widget.prefillData != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isKn
                          ? 'ರಿಪೋರ್ಟ್‌ನಿಂದ: ${widget.prefillData!["surveyNumber"] ?? ""} · ${widget.prefillData!["district"] ?? ""}'
                          : 'From your report: ${widget.prefillData!["surveyNumber"] ?? ""} · ${widget.prefillData!["district"] ?? ""}',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            isKn ? '7 ಅಧಿಕೃತ ಸರ್ಕಾರಿ ಸೇವೆಗಳು' : '7 Official Government Services',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          ...List.generate(_services.length, (i) => _ServiceCard(
            service: _services[i],
            isKn: isKn,
            onTap: () => _launch(_services[i].applyUrl),
          )),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isKn ? '© ಸರ್ಕಾರಿ ಪೋರ್ಟಲ್‌ಗಳು. DigiSampatti ಸ್ವತಂತ್ರ ಮಾರ್ಗದರ್ಶಿ ಅಪ್ಲಿಕೇಶನ್.'
                  : '© Official Government portals. DigiSampatti is an independent guide app.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTrackTab(bool isKn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCE93D8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.track_changes, color: Color(0xFF6A1B9A), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isKn
                        ? 'ನಿಮ್ಮ ಅರ್ಜಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ. ಅಧಿಕೃತ ಪೋರ್ಟಲ್‌ನಲ್ಲಿ ಸ್ಥಿತಿ ತಿಳಿಯಿರಿ.'
                        : 'Enter your application reference number to check status on the official portal.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6A1B9A), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            isKn ? 'ಸೇವೆ ಆಯ್ಕೆ ಮಾಡಿ' : 'Select Service',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),

          // Service selector
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: selected ? AppColors.primary : AppColors.borderColor, width: 2),
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
          const SizedBox(height: 20),

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
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _trackApplication,
              icon: const Icon(Icons.search),
              label: Text(isKn ? 'ಅಧಿಕೃತ ಪೋರ್ಟಲ್‌ನಲ್ಲಿ ಟ್ರ್ಯಾಕ್ ಮಾಡಿ' : 'Track on Official Portal'),
            ),
          ),
          const SizedBox(height: 24),

          // Status guide
          Text(
            isKn ? 'ಅರ್ಜಿ ಸ್ಥಿತಿ ಅರ್ಥ' : 'What Application Statuses Mean',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          _StatusGuideCard(isKn: isKn),
          const SizedBox(height: 24),

          // Help section
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
                  const Icon(Icons.help_outline, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isKn ? 'ಸಹಾಯ ಬೇಕೇ?' : 'Need Help?',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  isKn
                      ? 'SAKALA Helpline: 080-22230281\nBhoomi Helpline: 080-22113355\nKaveri Helpdesk: kaveri.helpdesk@gmail.com'
                      : 'SAKALA Helpline: 080-22230281\nBhoomi Helpline: 080-22113355\nKaveri Helpdesk: kaveri.helpdesk@gmail.com',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _GovService service;
  final bool isKn;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.isKn, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
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
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: service.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(service.icon, color: service.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKn ? service.titleKn : service.titleEn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        Text(
                          isKn ? service.subtitleKn : service.subtitleEn,
                          style: TextStyle(fontSize: 11, color: service.color, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: service.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isKn ? 'ತೆರೆಯಿರಿ' : 'Apply',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 13, color: service.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isKn ? service.whatYouGetKn : service.whatYouGetEn,
                        style: TextStyle(fontSize: 11, color: service.color, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                service.department,
                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
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
      ('Submitted / ಸಲ್ಲಿಸಲಾಗಿದೆ', isKn ? 'ಅರ್ಜಿ ಸ್ವೀಕರಿಸಲಾಗಿದೆ' : 'Application received by department', Colors.blue),
      ('Under Process / ಪರಿಶೀಲನೆ', isKn ? 'ಅಧಿಕಾರಿ ಪರಿಶೀಲಿಸುತ್ತಿದ್ದಾರೆ' : 'Officer is reviewing your documents', Colors.orange),
      ('Approved / ಅನುಮೋದಿಸಲಾಗಿದೆ', isKn ? 'ಅರ್ಜಿ ಅನುಮೋದಿಸಲಾಗಿದೆ' : 'Application approved — collect document', Colors.green),
      ('Rejected / ತಿರಸ್ಕರಿಸಲಾಗಿದೆ', isKn ? 'ಅರ್ಜಿ ತಿರಸ್ಕರಿಸಲಾಗಿದೆ — ಕಾರಣ ನೋಡಿ' : 'Application rejected — check reason and reapply', Colors.red),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
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
