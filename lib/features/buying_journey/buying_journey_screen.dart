import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/language_provider.dart';
import 'package:digi_sampatti/core/services/property_data_service.dart';

class BuyingJourneyScreen extends ConsumerStatefulWidget {
  const BuyingJourneyScreen({super.key});

  @override
  ConsumerState<BuyingJourneyScreen> createState() => _BuyingJourneyScreenState();
}

class _BuyingJourneyScreenState extends ConsumerState<BuyingJourneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // checklist state — stage 1
  final Map<int, bool> _preAdvance = {};
  // checklist state — stage 2
  final Map<int, bool> _agreement = {};
  // Firestore journey ID — default 'default_journey'
  final String _journeyId = 'default_journey';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    final data = await PropertyDataService().loadJourneyChecks(_journeyId);
    if (mounted) {
      setState(() {
        if (data['preAdvance'] != null) _preAdvance.addAll(data['preAdvance']!);
        if (data['agreement'] != null) _agreement.addAll(data['agreement']!);
      });
    }
  }

  Future<void> _saveCheck(String stage, int index, bool value) async {
    await PropertyDataService().saveJourneyCheckItem(
      journeyId: _journeyId,
      stage: stage,
      itemIndex: index,
      checked: value,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isKn = lang == 'kn';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isKn ? 'ಖರೀದಿ ಪ್ರಯಾಣ' : 'Buying Journey'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMedium,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: isKn ? 'ಪರಿಶೀಲನೆ' : 'Stage 1'),
            Tab(text: isKn ? 'ಒಪ್ಪಂದ' : 'Stage 2'),
            Tab(text: isKn ? 'ನೋಂದಣಿ' : 'Stage 3'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildStage1(isKn),
          _buildStage2(isKn),
          _buildStage3(isKn),
        ],
      ),
    );
  }

  // ── Stage 1: Before Paying Advance ──────────────────────────────────────────

  Widget _buildStage1(bool isKn) {
    final checks = isKn
        ? [
            'RTC (ಭೂ ದಾಖಲೆ) — ಮಾರಾಟಗಾರರ ಹೆಸರು ಸರ್ಕಾರಿ ದಾಖಲೆಯಲ್ಲಿ ಇದೆಯೇ?',
            'EC (ಭಾರ ಪ್ರಮಾಣಪತ್ರ) — ಈ ಆಸ್ತಿ ಮೇಲೆ ಯಾವ ಬ್ಯಾಂಕ್ ಸಾಲ ಇಲ್ಲ ತಾನೇ?',
            'ನ್ಯಾಯಾಲಯ ಪ್ರಕರಣ — ಈ ಆಸ್ತಿ ಕೋರ್ಟ್‌ನಲ್ಲಿ ತಗಾದೆ ಇಲ್ಲ ತಾನೇ?',
            'ಅಪಾರ್ಟ್‌ಮೆಂಟ್ ಆಗಿದ್ದರೆ — RERA ನೋಂದಣಿ ಇದೆಯೇ? (ನೋಂದಣಿ ಇಲ್ಲದ ಬಿಲ್ಡರ್ ಕಾನೂನುಬಾಹಿರ)',
            'ಭೂಮಿ ಬಳಕೆ — ಕೃಷಿ ಭೂಮಿ ಅಲ್ಲ ತಾನೇ? ಕೃಷಿ ಭೂಮಿ ಖರೀದಿಗೆ ವಿಶೇಷ ಅನುಮತಿ ಬೇಕು',
            'ಬೆಲೆ ಸರಿ ಇದೆಯೇ? ಸರ್ಕಾರಿ ನಿಗದಿ ಬೆಲೆಗಿಂತ ತುಂಬಾ ಹೆಚ್ಚು ಕೇಳುತ್ತಿದ್ದಾರೆಯೇ?',
            'DigiSampatti ರಿಪೋರ್ಟ್ ಮಾಡಿ — ಮೇಲಿನ ಎಲ್ಲ ಒಂದೇ ಕ್ಲಿಕ್‌ನಲ್ಲಿ ತಿಳಿಯಿರಿ',
          ]
        : [
            'RTC (land ownership record) — is the seller\'s name on the government record?',
            'EC (no-loan certificate) — does this property have any bank loan on it?',
            'Court cases — is this property involved in any legal dispute?',
            'If apartment — is the project RERA registered? (Unregistered builder = illegal)',
            'Land type — is it agricultural land? Buying farm land has special restrictions',
            'Is the price fair? Is it way above government guidance value?',
            'Run DigiSampatti report — checks all of the above in one go',
          ];

    final done = _preAdvance.values.where((v) => v).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeader(
            stage: 1,
            titleEn: 'Before Paying Advance',
            titleKn: 'ಮುಂಗಡ ಹಣ ನೀಡುವ ಮೊದಲು',
            subtitleEn: 'Never pay a rupee before completing all checks below',
            subtitleKn: 'ಕೆಳಗಿನ ಎಲ್ಲ ಪರಿಶೀಲನೆ ಮಾಡದೆ ಒಂದು ರೂಪಾಯಿ ನೀಡಬೇಡಿ',
            color: AppColors.primary,
            isKn: isKn,
          ),
          const SizedBox(height: 14),

          // Progress
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: checks.isEmpty ? 0 : done / checks.length,
                  backgroundColor: AppColors.borderColor,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text('$done/${checks.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),

          // Checklist
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: List.generate(checks.length, (i) {
                final checked = _preAdvance[i] ?? false;
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        final newVal = !checked;
                        setState(() => _preAdvance[i] = newVal);
                        _saveCheck('preAdvance', i, newVal);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: checked ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                    color: checked ? AppColors.primary : AppColors.borderColor,
                                    width: 2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: checked
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                checks[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: checked ? AppColors.textMedium : AppColors.textDark,
                                  decoration: checked ? TextDecoration.lineThrough : null,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < checks.length - 1) const Divider(height: 1, indent: 48),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Valuation card
          _ValuationCard(isKn: isKn, onLaunch: _launch),
          const SizedBox(height: 14),

          // Advance receipt CTA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.safe],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isKn ? 'ಮುಂಗಡ ರಸೀದಿ ಸಿದ್ಧಪಡಿಸಿ' : 'Generate Advance Receipt',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  isKn
                      ? 'ಹಣ ನೀಡಿದ ನಂತರ PDF ರಸೀದಿ ಮಾಡಿ — ಎರಡೂ ಕಡೆ ಸಹಿ ಮಾಡಿ'
                      : 'After paying, generate a PDF receipt — both parties sign it',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/advance-receipt'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(isKn ? 'ರಸೀದಿ ಮಾಡಿ' : 'Create Advance Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment guidance
          _PaymentGuidanceCard(isKn: isKn),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Stage 2: Agreement for Sale ──────────────────────────────────────────────

  Widget _buildStage2(bool isKn) {
    final mustHave = isKn
        ? [
            'ಸರ್ವೆ ಸಂಖ್ಯೆ ಮತ್ತು ಜಿಲ್ಲೆ ಸ್ಪಷ್ಟವಾಗಿ ಇದೆಯೇ?',
            'ಒಟ್ಟು ಮೊತ್ತ ಮತ್ತು ಯಾವಾಗ ಎಷ್ಟು ಕೊಡಬೇಕು — ಸ್ಪಷ್ಟವಾಗಿ ಇದೆಯೇ?',
            'ಕೀ ಕೊಡುವ ದಿನಾಂಕ — "ಆದಷ್ಟು ಬೇಗ" ಅಲ್ಲ, ನಿಖರ ದಿನಾಂಕ ಇದೆಯೇ?',
            'ತಡ ಆದರೆ ದಂಡ — ಮಾರಾಟಗಾರ ತಡ ಮಾಡಿದರೂ ದಂಡ ಇದೆಯೇ?',
            'ಡೀಲ್ ಮುರಿದರೆ — ಮುಂಗಡ ವಾಪಸ್ ಸಿಗುತ್ತದೆ ಎಂದು ಬರೆದಿದೆಯೇ?',
            'ಹಳೆ ಬಾಕಿ ತೆರಿಗೆ / ಬಿಲ್ — ಮಾರಾಟಗಾರ ಮೊದಲು ತೀರಿಸುತ್ತಾರೆ ಎಂದು ಇದೆಯೇ?',
            'ಎರಡೂ ಕಡೆ ಸಹಿ + ಸಾಕ್ಷಿ ಸಹಿ ಎಲ್ಲ ಪುಟಗಳ ಮೇಲೆ ಇದೆಯೇ?',
          ]
        : [
            'Survey number and district clearly mentioned?',
            'Total price + when each payment is due — clearly written?',
            'Handover date — exact date, not "as soon as possible"?',
            'Penalty if seller delays — not just buyer, seller too?',
            'If deal breaks — advance refund clearly stated?',
            'Old pending taxes/bills — seller pays before registration?',
            'Both signatures + witness signature on every page?',
          ];

    final redFlags = isKn
        ? [
            'ಸ್ವಾಧೀನ ದಿನಾಂಕ "ಅನುಕೂಲ ಸಮಯ" ಎಂದು ಇದ್ದರೆ — ಸ್ಪಷ್ಟ ದಿನಾಂಕ ಕೇಳಿ',
            'ಮುಂಗಡ ವಾಪಸ್ ನೀಡಲ್ಲ ಎಂದಿದ್ದರೆ — ಒಪ್ಪಬೇಡಿ',
            'ಒಪ್ಪಂದ ನೋಂದಣಿ ಮಾಡದಿದ್ದರೆ — ನ್ಯಾಯಾಲಯದಲ್ಲಿ ದುರ್ಬಲ',
            'ಬಿಲ್ಡರ್ ದಂಡ ಷರತ್ತು ಇಲ್ಲ ಎಂದಿದ್ದರೆ — ವಿಳಂಬ ಆದರೆ ಕೇಸ್ ಮಾಡಲು ಆಗಲ್ಲ',
          ]
        : [
            'Possession date says "mutually convenient time" — demand exact date',
            'Advance is non-refundable under any condition — do not agree',
            'Agreement is not registered — weak in court if dispute arises',
            'No penalty clause on builder for delay — you cannot sue for compensation',
          ];

    final done = _agreement.values.where((v) => v).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeader(
            stage: 2,
            titleEn: 'Agreement for Sale',
            titleKn: 'ಮಾರಾಟ ಒಪ್ಪಂದ',
            subtitleEn: 'Before signing — verify these clauses are in the agreement',
            subtitleKn: 'ಸಹಿ ಮಾಡುವ ಮೊದಲು — ಈ ಷರತ್ತುಗಳು ಇವೆಯೇ ಎಂದು ಪರಿಶೀಲಿಸಿ',
            color: AppColors.arthBlue,
            isKn: isKn,
          ),
          const SizedBox(height: 14),

          Text(isKn ? 'ಒಪ್ಪಂದದಲ್ಲಿ ಇರಲೇಬೇಕು' : 'Must-have clauses in the agreement',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          const SizedBox(height: 8),

          // Progress
          Row(children: [
            Expanded(
              child: LinearProgressIndicator(
                value: mustHave.isEmpty ? 0 : done / mustHave.length,
                backgroundColor: AppColors.borderColor,
                color: AppColors.arthBlue,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Text('$done/${mustHave.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.arthBlue)),
          ]),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: List.generate(mustHave.length, (i) {
                final checked = _agreement[i] ?? false;
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        final newVal = !checked;
                        setState(() => _agreement[i] = newVal);
                        _saveCheck('agreement', i, newVal);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: checked ? AppColors.arthBlue : Colors.transparent,
                                border: Border.all(
                                    color: checked ? AppColors.arthBlue : AppColors.borderColor,
                                    width: 2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: checked
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(mustHave[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: checked ? AppColors.textMedium : AppColors.textDark,
                                    decoration: checked ? TextDecoration.lineThrough : null,
                                    height: 1.4,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < mustHave.length - 1) const Divider(height: 1, indent: 48),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Red flags
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.warning_amber, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text(isKn ? 'ಒಪ್ಪಂದದಲ್ಲಿ ಈ ಷರತ್ತು ಇದ್ದರೆ ಒಪ್ಪಬೇಡಿ' : 'Red Flags — refuse to sign if you see these',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                ]),
                const SizedBox(height: 10),
                ...redFlags.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Register agreement tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9FA8DA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF303F9F), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isKn
                        ? 'ಒಪ್ಪಂದವನ್ನು SRO ನಲ್ಲಿ ನೋಂದಣಿ ಮಾಡಿ. ₹500 ಸ್ಟಾಂಪ್ ಪೇಪರ್ ಮೇಲೆ ಮಾಡಿದ ಒಪ್ಪಂದ ನ್ಯಾಯಾಲಯದಲ್ಲಿ ದುರ್ಬಲ.'
                        : 'Get the agreement registered at SRO. An agreement only on ₹500 stamp paper is weak in court — register it for ₹1,000 stamp duty.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF303F9F), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Stage 3: Registration ────────────────────────────────────────────────────

  Widget _buildStage3(bool isKn) {
    final steps = isKn
        ? [
            ('ಸ್ಟಾಂಪ್ ಡ್ಯೂಟಿ ಲೆಕ್ಕ ಹಾಕಿ', 'ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ ಅಥವಾ ಮಾರಾಟ ಬೆಲೆ — ಯಾವುದು ಹೆಚ್ಚೋ ಅದರ ಮೇಲೆ', Icons.calculate, AppColors.primary),
            ('Kaveri 2.0 ನಲ್ಲಿ SRO ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಬುಕ್ ಮಾಡಿ', 'ಆನ್‌ಲೈನ್‌ನಲ್ಲಿ ಮುಂಚಿತವಾಗಿ ಬುಕ್ ಮಾಡಿ — ಕ್ಯೂ ಇಲ್ಲ', Icons.calendar_today, const Color(0xFFB71C1C)),
            ('ಎಲ್ಲ ದಾಖಲೆ ತಯಾರಿ', 'ಆಧಾರ್, PAN, ಸೇಲ್ ಡೀಡ್ ಡ್ರಾಫ್ಟ್, EC, RTC, ಖಾತಾ, NOC', Icons.folder_open, AppColors.esign),
            ('ಸ್ಟಾಂಪ್ ಡ್ಯೂಟಿ ಆನ್‌ಲೈನ್ ಪಾವತಿ', 'Kaveri ಪೋರ್ಟಲ್ ಮೂಲಕ ಚಲಾನ್ ಮಾಡಿ', Icons.payment, AppColors.primary),
            ('SRO ಭೇಟಿ ಮತ್ತು ನೋಂದಣಿ', 'ಎರಡೂ ಕಡೆ ಆಧಾರ್ + ಬಯೋಮೆಟ್ರಿಕ್ ಅಗತ್ಯ', Icons.how_to_reg, AppColors.arthBlue),
            ('ನೋಂದಾಯಿತ ದಾಖಲೆ ಪಡೆಯಿರಿ', 'SRO ಸ್ಕ್ಯಾನ್ ಕಾಪಿ ನಂತರ ನಿಮ್ಮ ಫೋನ್‌ಗೆ ಬರುತ್ತದೆ', Icons.download_done, AppColors.primary),
          ]
        : [
            ('Calculate Stamp Duty', 'Higher of guidance value or sale price × stamp duty rate', Icons.calculate, AppColors.primary),
            ('Book SRO Appointment on Kaveri 2.0', 'Book online in advance — no queue at office', Icons.calendar_today, const Color(0xFFB71C1C)),
            ('Prepare all documents', 'Aadhaar, PAN, sale deed draft, EC, RTC, Khata, NOC if needed', Icons.folder_open, AppColors.esign),
            ('Pay Stamp Duty online', 'Generate challan on Kaveri portal before visiting SRO', Icons.payment, AppColors.primary),
            ('Visit SRO for registration', 'Both buyer and seller must be present — Aadhaar + biometric', Icons.how_to_reg, AppColors.arthBlue),
            ('Collect registered document', 'Scanned copy delivered digitally after registration', Icons.download_done, AppColors.primary),
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageHeader(
            stage: 3,
            titleEn: 'Property Registration',
            titleKn: 'ಆಸ್ತಿ ನೋಂದಣಿ',
            subtitleEn: 'Final step — legal ownership transfer at SRO',
            subtitleKn: 'ಅಂತಿಮ ಹಂತ — SRO ನಲ್ಲಿ ಕಾನೂನು ಮಾಲೀಕತ್ವ ವರ್ಗಾವಣೆ',
            color: const Color(0xFFB71C1C),
            isKn: isKn,
          ),
          const SizedBox(height: 14),

          ...List.generate(steps.length, (i) {
            final (title, desc, icon, color) = steps[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text(desc,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
                        ],
                      ),
                    ),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Quick links
          Text(isKn ? 'ತ್ವರಿತ ಲಿಂಕ್‌ಗಳು' : 'Quick Links',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _QuickLinkBtn(
                  label: isKn ? 'ಸ್ಟಾಂಪ್ ಡ್ಯೂಟಿ ಲೆಕ್ಕ' : 'Stamp Duty',
                  icon: Icons.calculate,
                  color: AppColors.primary,
                  onTap: () => context.push('/transfer/stamp-duty'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickLinkBtn(
                  label: isKn ? 'SRO ಬುಕ್ಕಿಂಗ್' : 'SRO Booking',
                  icon: Icons.calendar_today,
                  color: const Color(0xFFB71C1C),
                  onTap: () => _launch('https://kaverionline.karnataka.gov.in'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickLinkBtn(
                  label: isKn ? 'ದಾಖಲೆ ಪಟ್ಟಿ' : 'Doc Checklist',
                  icon: Icons.folder_open,
                  color: AppColors.esign,
                  onTap: () => context.push('/transfer/documents'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickLinkBtn(
                  label: isKn ? 'ಮ್ಯುಟೇಷನ್ ಮಾರ್ಗದರ್ಶಿ' : 'After Registration',
                  icon: Icons.swap_horiz,
                  color: AppColors.primary,
                  onTap: () => context.push('/transfer/mutation'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Valuation Card ───────────────────────────────────────────────────────────

class _ValuationCard extends StatefulWidget {
  final bool isKn;
  final Future<void> Function(String) onLaunch;
  const _ValuationCard({required this.isKn, required this.onLaunch});

  @override
  State<_ValuationCard> createState() => _ValuationCardState();
}

class _ValuationCardState extends State<_ValuationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isKn = widget.isKn;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECB3),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.price_check, color: Color(0xFFE65100), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKn ? 'ಬೆಲೆ ಸರಿ ಇದೆಯೇ? ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ ಪರಿಶೀಲಿಸಿ' : 'Is the price fair? Check Guidance Value',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        Text(
                          isKn ? 'ಸರ್ಕಾರಿ ನಿಗದಿ ಬೆಲೆ vs ಮಾರಾಟಗಾರ ಕೇಳುವ ಬೆಲೆ' : 'Government guidance value vs asking price',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textMedium),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ValuationRow(
                    isKn: isKn,
                    titleEn: 'What is Guidance Value?',
                    titleKn: 'ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ ಎಂದರೇನು?',
                    descEn: 'The minimum property value set by Karnataka government for stamp duty calculation. If a builder quotes ₹3 Cr but guidance value is ₹1.5 Cr, stamp duty is still on ₹3 Cr (higher value).',
                    descKn: 'ಸ್ಟಾಂಪ್ ಡ್ಯೂಟಿ ಲೆಕ್ಕಕ್ಕೆ ಕರ್ನಾಟಕ ಸರ್ಕಾರ ನಿಗದಿ ಮಾಡಿದ ಕನಿಷ್ಠ ಮೌಲ್ಯ.',
                    color: const Color(0xFFE65100),
                  ),
                  const SizedBox(height: 10),
                  _ValuationRow(
                    isKn: isKn,
                    titleEn: 'Builder quotes ₹3 Cr — how to verify?',
                    titleKn: 'ಬಿಲ್ಡರ್ ₹3 Cr ಕೇಳಿದರೆ — ಹೇಗೆ ಪರಿಶೀಲಿಸಬೇಕು?',
                    descEn: '1. Check guidance value on Kaveri portal for that area\n2. Compare with similar properties on MagicBricks / 99acres\n3. If asking price is 2× guidance value — negotiate or walk away\n4. For apartments: demand builder\'s cost sheet (land + construction + profit)',
                    descKn: '1. Kaveri ಪೋರ್ಟಲ್‌ನಲ್ಲಿ ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ ನೋಡಿ\n2. MagicBricks / 99acres ನಲ್ಲಿ ಹೋಲಿಸಿ\n3. ಬೆಲೆ ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯದ 2 ಪಟ್ಟು ಇದ್ದರೆ — ಚೌಕಾಸಿ ಮಾಡಿ',
                    color: AppColors.arthBlue,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onLaunch('https://kaverionline.karnataka.gov.in/GuidanceValue'),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(isKn ? 'Kaveri ನಲ್ಲಿ ಮಾರ್ಗದರ್ಶಿ ಮೌಲ್ಯ ನೋಡಿ' : 'Check Guidance Value on Kaveri'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFFFB74D)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValuationRow extends StatelessWidget {
  final bool isKn;
  final String titleEn, titleKn, descEn, descKn;
  final Color color;

  const _ValuationRow({
    required this.isKn, required this.titleEn, required this.titleKn,
    required this.descEn, required this.descKn, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isKn ? titleKn : titleEn,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
        const SizedBox(height: 4),
        Text(isKn ? descKn : descEn,
            style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.5)),
      ],
    );
  }
}

// ─── Payment Guidance Card ────────────────────────────────────────────────────

class _PaymentGuidanceCard extends StatelessWidget {
  final bool isKn;
  const _PaymentGuidanceCard({required this.isKn});

  @override
  Widget build(BuildContext context) {
    final dos = isKn
        ? ['ಚೆಕ್ ಅಥವಾ RTGS/NEFT ಮೂಲಕ ಪಾವತಿ ಮಾಡಿ', 'ಚೆಕ್ ಹಿಂಭಾಗದಲ್ಲಿ ಆಸ್ತಿ ವಿವರ ಬರೆಯಿರಿ', 'ರಸೀದಿ / ಒಪ್ಪಂದ ಸಹಿ ಮಾಡಿ ಇಟ್ಟುಕೊಳ್ಳಿ']
        : ['Pay by cheque or RTGS/NEFT only', 'Write property details on back of cheque', 'Keep signed receipt / agreement copy'];

    final donts = isKn
        ? ['ನಗದು ನೀಡಬೇಡಿ — ಯಾವುದೇ ಪುರಾವೆ ಇಲ್ಲ', 'ಮೊದಲ ಭೇಟಿಯಲ್ಲೇ ಮೊತ್ತ ನೀಡಬೇಡಿ', 'UPI ಬಳಸಬೇಡಿ — ₹1L ಮಿತಿ, ನ್ಯಾಯಾಲಯದಲ್ಲಿ ದುರ್ಬಲ']
        : ['Never pay in cash — no proof', 'Never pay on first meeting without verification', 'Avoid UPI — ₹1L limit, weak proof in court'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.payments_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(isKn ? 'ಮುಂಗಡ ಪಾವತಿ ಮಾರ್ಗದರ್ಶಿ' : 'Advance Payment Guide',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isKn ? '✓ ಮಾಡಿ' : '✓ Do',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.safe)),
                    const SizedBox(height: 6),
                    ...dos.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.safe)),
                          Expanded(child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isKn ? '✗ ಮಾಡಬೇಡಿ' : '✗ Don\'t',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.danger)),
                    const SizedBox(height: 6),
                    ...donts.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.danger)),
                          Expanded(child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final int stage;
  final String titleEn, titleKn, subtitleEn, subtitleKn;
  final Color color;
  final bool isKn;

  const _StageHeader({
    required this.stage, required this.titleEn, required this.titleKn,
    required this.subtitleEn, required this.subtitleKn,
    required this.color, required this.isKn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text('$stage',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isKn ? titleKn : titleEn,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                Text(isKn ? subtitleKn : subtitleEn,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLinkBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(child: Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
          ],
        ),
      ),
    );
  }
}
