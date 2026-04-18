import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

// ─── Hidden Legal Issues Screen ───────────────────────────────────────────────
// Issues that WILL NOT appear in the RTC or standard portal checks.
// These require additional investigation — seller questions, physical checks,
// or cross-referencing other government databases.
//
// The three categories:
//   🔴 Cannot be detected from documents alone — must ask seller / investigate
//   🟠 May be detectable with additional documents
//   🟡 Can be checked via alternative sources
// ──────────────────────────────────────────────────────────────────────────────

class HiddenIssue {
  final String id;
  final String title;
  final String why;              // why it won't show in RTC
  final String howToDetect;      // practical detection method
  final String consequence;      // what happens if missed
  final HiddenIssueLevel level;
  final String? checkUrl;
  final List<String> questions;  // questions to ask seller
  bool? answered;                // null = not asked, true = no issue, false = issue found

  HiddenIssue({
    required this.id,
    required this.title,
    required this.why,
    required this.howToDetect,
    required this.consequence,
    required this.level,
    required this.questions,
    this.checkUrl,
    this.answered,
  });
}

enum HiddenIssueLevel { critical, high, medium }

class HiddenIssuesScreen extends ConsumerStatefulWidget {
  const HiddenIssuesScreen({super.key});
  @override
  ConsumerState<HiddenIssuesScreen> createState() => _HiddenIssuesScreenState();
}

class _HiddenIssuesScreenState extends ConsumerState<HiddenIssuesScreen> {
  late final List<HiddenIssue> _issues;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    final propType = ref.read(propertyTypeProvider);
    _issues = _buildIssueList(propType);
  }

  List<HiddenIssue> _buildIssueList(String propType) {
    final all = [

      // ── UNREGISTERED AGREEMENTS ──────────────────────────────────────────
      HiddenIssue(
        id: 'unregistered_agreement',
        title: 'Unregistered Sale Agreement with a Prior Buyer',
        why: 'An Agreement of Sale (ಮಾರಾಟ ಒಪ್ಪಂದ) can be written on stamp paper '
            'and signed between seller and a previous buyer WITHOUT registering '
            'at the Sub-Registrar. It does NOT appear in EC or RTC.',
        howToDetect:
            '1. Ask seller directly: "Have you signed any agreement with anyone for this property?"\n'
            '2. Ask for original title documents — if seller is hesitant to show them, suspect a prior agreement\n'
            '3. Check if property was advertised/listed with another buyer\n'
            '4. A prior buyer may have filed a lis pendens (notice of suit) in eCourts — search seller name',
        consequence:
            'If a prior unregistered agreement exists and the prior buyer goes to court, '
            'they can claim the property under Section 53A of Transfer of Property Act (part performance). '
            'Your registered sale deed may be challenged.',
        level: HiddenIssueLevel.critical,
        questions: [
          'Have you signed any agreement of sale, MOU, or any document with any other person for this property?',
          'Has any person paid you any advance or token money for this property?',
          'Has any broker shown this property to other buyers?',
          'Is this property currently listed with any other agent or platform?',
        ],
        checkUrl: 'https://services.ecourts.gov.in/ecourtindia_v6/',
      ),

      // ── FAMILY / PARTITION DISPUTES ──────────────────────────────────────
      HiddenIssue(
        id: 'family_dispute',
        title: 'Undisclosed Family Dispute or Co-heir Claim',
        why: 'Family disputes, oral partition agreements, and co-heir claims '
            'are NOT recorded in RTC until a court order is passed and a mutation is done. '
            'A sibling or spouse may have an unrecorded claim.',
        howToDetect:
            '1. Check how seller acquired the property — if by inheritance, all legal heirs must consent\n'
            '2. Ask for the original will or heirship certificate\n'
            '3. Check the mutation history in RTC — look for multiple names\n'
            '4. If joint ownership, ALL owners must sign the sale deed\n'
            '5. Search seller and property in eCourts for any partition suits',
        consequence:
            'A co-heir who did not consent to the sale can file a partition suit '
            'and get a court order to cancel your sale deed even after registration.',
        level: HiddenIssueLevel.critical,
        questions: [
          'Did you inherit this property? If yes, are there other legal heirs?',
          'Have all co-owners/legal heirs agreed to this sale?',
          'Is there any dispute within the family about this property?',
          'Was this property in your parents\' name? How was it transferred to you?',
        ],
      ),

      // ── ORAL AGREEMENTS ──────────────────────────────────────────────────
      HiddenIssue(
        id: 'oral_agreement',
        title: 'Oral Agreement / Part Performance (Section 53A TPA)',
        why: 'Under Section 53A of Transfer of Property Act, if a buyer has paid '
            'part of the price AND taken possession of the property under an oral or '
            'unregistered agreement, they have a RIGHT to defend possession. '
            'This does NOT appear anywhere in official records.',
        howToDetect:
            '1. Physically visit the property — is anyone living on it or farming it?\n'
            '2. Ask neighbours: has anyone else been using or claiming this land?\n'
            '3. Ask seller: has anyone else paid any money for this property in the past?',
        consequence:
            'If you buy and someone already has possession under an oral agreement, '
            'they cannot be easily evicted. You may own the title but not the possession.',
        level: HiddenIssueLevel.critical,
        questions: [
          'Is anyone currently living on or farming this land?',
          'Has any person been in possession of this property with your knowledge?',
          'Has anyone else paid you money for this property in any form?',
        ],
      ),

      // ── ADVERSE POSSESSION ────────────────────────────────────────────────
      HiddenIssue(
        id: 'adverse_possession',
        title: 'Adverse Possession — 12-Year Occupant\'s Claim',
        why: 'Under Section 65 of Limitation Act, if a person has occupied land '
            'openly, continuously, and without objection for 12+ years, '
            'they can file for adverse possession. This does NOT appear in RTC.',
        howToDetect:
            '1. Physically visit — is anyone living on or using the land?\n'
            '2. Check how long any occupant has been there\n'
            '3. Ask neighbours — who has been using this land in the last 15 years?\n'
            '4. Check if occupant has any electricity bills, water connections, or government records in this land\'s address',
        consequence:
            'A 12-year occupant can go to court and claim ownership. '
            'Your title deed does not automatically override adverse possession.',
        level: HiddenIssueLevel.critical,
        questions: [
          'Is there any person currently living on or occupying this property?',
          'How long has that person been there?',
          'Do they have any bills or government documents showing this address?',
          'Has any court case been filed by or against this occupant?',
        ],
      ),

      // ── POWER OF ATTORNEY FRAUD ──────────────────────────────────────────
      HiddenIssue(
        id: 'poa_fraud',
        title: 'Fraudulent or Revoked Power of Attorney',
        why: 'A General Power of Attorney (GPA) may appear in EC or mutations, '
            'but a PoA holder can forge documents or sell even after the PoA is revoked '
            'or the principal is deceased. Revocation may not be in official records.',
        howToDetect:
            '1. If seller is selling via PoA — verify the PoA is still valid and registered\n'
            '2. Check PoA registration date vs. principal\'s death date (if applicable)\n'
            '3. Contact the original principal (if alive) and confirm they are aware of the sale\n'
            '4. Check EC for any PoA entries — if GPA was cancelled, it should show\n'
            '5. A PoA cannot be used by the PoA holder to sell to themselves',
        consequence:
            'A forged or revoked PoA makes the sale void. You lose the property '
            'and must go to court to recover your money.',
        level: HiddenIssueLevel.critical,
        questions: [
          'Are you selling this property directly or through a Power of Attorney?',
          'If through PoA — is the original owner alive and aware of this sale?',
          'When was the PoA given? Has it been registered?',
          'Has the PoA been used for any other transactions?',
        ],
      ),

      // ── BENAMI PROPERTY ──────────────────────────────────────────────────
      HiddenIssue(
        id: 'benami',
        title: 'Benami Property — Actual Owner is Someone Else',
        why: 'A benami property is held by one person (benamidar) on behalf of another '
            'who is the actual owner (beneficial owner). RTC shows the benamidar\'s name. '
            'If the beneficial owner is under IT/ED investigation, the property can be '
            'attached — even after you buy it.',
        howToDetect:
            '1. Check if seller has corresponding income for this property value\n'
            '2. Check if IT/ED has any attachment orders — these may show in eCourts\n'
            '3. Ask seller for source of funds when they bought the property\n'
            '4. Check for previous sale deed — does the consideration amount match market value?',
        consequence:
            'Under Benami Transactions (Prohibition) Act 2016, the government can '
            'confiscate benami property without compensation to the buyer.',
        level: HiddenIssueLevel.high,
        questions: [
          'Did you buy this property yourself or is anyone else the actual owner?',
          'What was your source of funds when you purchased this property?',
          'Is this property under any IT or ED investigation to your knowledge?',
        ],
        checkUrl: 'https://www.incometax.gov.in/iec/foportal/',
      ),

      // ── GOVERNMENT ACQUISITION ────────────────────────────────────────────
      HiddenIssue(
        id: 'acquisition',
        title: 'Pending Government Acquisition / LA Notice',
        why: 'Under Land Acquisition Act, the government can issue a notice for '
            'acquisition. The notice is in gazette and government records, but may NOT '
            'be immediately reflected in RTC — especially early-stage notifications.',
        howToDetect:
            '1. Check Karnataka Gazette for acquisition notices in this area\n'
            '2. Ask at the local Sub-Registrar office if any acquisition is pending\n'
            '3. Check NHAI/BDA/BMRDA plans for road widening in this area\n'
            '4. Ask neighbours and local village accountant (patwari)',
        consequence:
            'If government acquires the land after you buy, you get compensation '
            'at guidance value — not market value. You lose the property.',
        level: HiddenIssueLevel.high,
        questions: [
          'Have you received any notice from government (NHAI, BDA, BBMP, State) for this property?',
          'Is there any road widening or infrastructure project planned near this property?',
          'Have you seen any government surveyors measuring this area recently?',
        ],
        checkUrl: 'https://bdabangalore.org',
      ),

      // ── WAQF BOARD CLAIM ─────────────────────────────────────────────────
      HiddenIssue(
        id: 'waqf',
        title: 'Waqf Board Claim',
        why: 'The Waqf Board can claim property as waqf (Islamic religious endowment) '
            'even if RTC shows a private owner. Waqf claims may not appear in RTC '
            'unless the Waqf Board has filed for mutation.',
        howToDetect:
            '1. Check the Waqf Board property lists (state-specific)\n'
            '2. Ask at Sub-Registrar if property is near any mosque/dargah\n'
            '3. Check the vendor\'s genealogy — if property was originally a waqf grant',
        consequence:
            'If Waqf Board claims the property after purchase, courts have upheld Waqf '
            'claims over registered sale deeds in several cases.',
        level: HiddenIssueLevel.medium,
        questions: [
          'Is this property near a mosque, dargah, or Islamic institution?',
          'Was this property ever part of a waqf or religious endowment?',
        ],
        checkUrl: 'https://waqf.karnataka.gov.in',
      ),

      // ── SURVEY DISPUTES ──────────────────────────────────────────────────
      HiddenIssue(
        id: 'survey_dispute',
        title: 'Survey / Boundary Dispute with Neighbours',
        why: 'A boundary dispute with an adjoining owner may be ongoing in '
            'the village panchayat or taluk courts WITHOUT being in the RTC. '
            'Only when a court order is passed and mutation done does it appear.',
        howToDetect:
            '1. Walk the physical boundary with the FMB sketch — match every marker\n'
            '2. Ask the village accountant (village patwari) if there are any boundary disputes\n'
            '3. Talk to adjacent landowners — are there any disputed portions?\n'
            '4. Check if any encroachment structures (walls, fences) cross the boundary',
        consequence:
            'A boundary dispute can result in a portion of your land being legally '
            'owned by a neighbour, reducing the usable area.',
        level: HiddenIssueLevel.medium,
        questions: [
          'Is there any dispute with adjoining landowners about the boundary?',
          'Does the physical boundary match the FMB sketch exactly?',
          'Has any neighbour built any structure that crosses into this land?',
        ],
      ),

      // ── ENVIRONMENTAL / CRZ ──────────────────────────────────────────────
      HiddenIssue(
        id: 'environmental',
        title: 'Environmental / CRZ / Forest Buffer Restrictions',
        why: 'Land near lakes (FTL buffer zone), forests (eco-sensitive zones), '
            'coastline (CRZ), or rivers (riparian zone) may have construction '
            'restrictions that are NOT shown in the RTC land type column.',
        howToDetect:
            '1. Check BBMP lake/FTL map for proximity to any water body\n'
            '2. Check KSPCB (Pollution Control Board) for notified green zones\n'
            '3. For coastal property: CRZ notification from Ministry of Environment\n'
            '4. Forest boundary maps from Karnataka Forest Department',
        consequence:
            'Building on restricted land = BBMP demolition order. '
            'BBMP has demolished hundreds of buildings on lake buffer zones.',
        level: HiddenIssueLevel.high,
        questions: [
          'Is this property within 50 metres of any lake, pond, river, or water body?',
          'Is this property within 500 metres of a forest boundary?',
          'Is this near the coast? If yes, check CRZ notification.',
          'Has BBMP or Forest Dept issued any notice for this area?',
        ],
        checkUrl: 'https://bbmpeaasthi.karnataka.gov.in',
      ),

      // ── CEILING SURPLUS ──────────────────────────────────────────────────
      HiddenIssue(
        id: 'ceiling_surplus',
        title: 'Land Ceiling Surplus — Government Can Claim',
        why: 'Karnataka Land Reforms Act sets a maximum land holding limit. '
            'If the owner holds more than the permitted ceiling across all properties, '
            'surplus land vests in the government — but this may not be reflected in '
            'the individual survey\'s RTC.',
        howToDetect:
            '1. Ask seller to declare ALL land holdings (Form 7 declaration)\n'
            '2. Ask at the Taluk Office if this survey has any ceiling proceedings\n'
            '3. If seller owns multiple large plots — verify total holding',
        consequence:
            'If the land is declared ceiling surplus, it vests in the government. '
            'Your sale deed is void for that portion.',
        level: HiddenIssueLevel.medium,
        questions: [
          'How much total agricultural land do you own across all properties?',
          'Has any ceiling notice been issued to you by the government?',
          'Are there any surplus land proceedings pending against you?',
        ],
      ),

      // ── TEMPLE / MUTT LAND ───────────────────────────────────────────────
      HiddenIssue(
        id: 'religious_land',
        title: 'Temple / Mutt / Religious Endowment Land',
        why: 'Land belonging to religious institutions (temples, mathas, churches) '
            'often shows a private person\'s name in RTC — but may be a '
            '"Inam" (grant) with restrictions on transfer.',
        howToDetect:
            '1. Check RTC for "Inam" classification in land type\n'
            '2. Check if survey number has any HR&CE (Hindu Religious & Charitable Endowments) notation\n'
            '3. Ask at the local Sub-Registrar if the survey is an Inam survey\n'
            '4. Check if EC shows any transaction with a religious institution',
        consequence:
            'Inam/endowment land has restrictions on sale. Without government permission, '
            'the sale can be declared void.',
        level: HiddenIssueLevel.medium,
        questions: [
          'Is this property originally an Inam grant (land given by a ruler or government)?',
          'Is this property in any way connected to a temple, mosque, church, or mutt?',
          'Has the property been converted from Inam to private title?',
        ],
      ),
    ];

    // Filter by property type
    if (propType == 'apartment') {
      // For apartments, hide agricultural-specific issues, add apartment-specific
      return all.where((i) => !['ceiling_surplus', 'survey_dispute', 'religious_land'].contains(i.id)).toList();
    }
    return all;
  }

  int get _issueCount => _issues.where((i) => i.answered == false).length;
  int get _checkedCount => _issues.where((i) => i.answered != null).length;

  @override
  Widget build(BuildContext context) {
    final critical = _issues.where((i) => i.level == HiddenIssueLevel.critical).toList();
    final high     = _issues.where((i) => i.level == HiddenIssueLevel.high).toList();
    final medium   = _issues.where((i) => i.level == HiddenIssueLevel.medium).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hidden Legal Issues Check'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 16),
          _unregisteredAgreementGuide(),
          const SizedBox(height: 20),
          _buildGroup('Critical — Could Void the Sale', critical, Colors.red.shade800),
          const SizedBox(height: 16),
          _buildGroup('High Risk — Significant Impact', high, Colors.orange.shade800),
          const SizedBox(height: 16),
          _buildGroup('Medium Risk — Should Investigate', medium, AppColors.info),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _headerCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade900.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.red.shade300.withOpacity(0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Issues That WILL NOT Appear in Official Records',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
          )),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Arth ID checks official portals — but some critical risks exist '
          'only in private documents, oral agreements, physical possession, and '
          'government records not linked to the land registry.\n\n'
          'These require asking the seller directly and doing physical checks.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _statChip('${_issues.length}', 'Total checks', Colors.grey),
          const SizedBox(width: 8),
          _statChip('$_checkedCount', 'Checked', Colors.blue),
          const SizedBox(width: 8),
          _statChip('$_issueCount', 'Issues found', Colors.red),
        ]),
      ],
    ),
  );

  Widget _statChip(String num, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(num, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ]),
  );

  Widget _unregisteredAgreementGuide() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.handshake_outlined, color: Colors.deepOrange, size: 18),
          SizedBox(width: 8),
          Text('Unregistered Agreement — The Most Common Hidden Risk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  color: Colors.deepOrange)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'An Agreement of Sale does NOT need to be registered in Karnataka to be valid. '
          'A seller can sign a private agreement for ₹1,00,000 advance on stamp paper '
          'with Buyer A — and then sell to you (Buyer B) fully registered. '
          'Buyer A\'s agreement is invisible to you.\n\n'
          'Buyer A can then file a case for Specific Performance and get a court order '
          'to transfer the property back to them — even after your registration.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to protect yourself:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                      color: Colors.green)),
              SizedBox(height: 4),
              Text(
                '1. Always ask seller to sign a Declaration that no prior agreement exists\n'
                '2. Search seller\'s name on eCourts for any Specific Performance suits\n'
                '3. Add a indemnity clause in your sale agreement\n'
                '4. NEVER pay advance without a legally reviewed sale agreement\n'
                '5. Get a lawyer to do a 30-year title search',
                style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildGroup(String heading, List<HiddenIssue> issues, Color color) {
    if (issues.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(heading, style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 10),
        ...issues.map((issue) => _buildIssueCard(issue, color)),
      ],
    );
  }

  Widget _buildIssueCard(HiddenIssue issue, Color levelColor) {
    final isAnswered = issue.answered != null;
    final hasIssue   = issue.answered == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasIssue ? Colors.red.shade300
              : isAnswered ? AppColors.safe.withOpacity(0.4)
              : AppColors.borderColor,
        ),
      ),
      child: ExpansionTile(
        title: Row(children: [
          Icon(
            hasIssue ? Icons.warning : isAnswered ? Icons.check_circle : Icons.radio_button_unchecked,
            color: hasIssue ? Colors.red : isAnswered ? AppColors.safe : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(issue.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Why it won't show in RTC
                _detailSection('Why it won\'t appear in official records:',
                    issue.why, Colors.red.shade800),
                const SizedBox(height: 10),
                // How to detect
                _detailSection('How to detect it:', issue.howToDetect, AppColors.primary),
                const SizedBox(height: 10),
                // Consequence
                _detailSection('If missed:', issue.consequence, Colors.orange.shade800),
                const SizedBox(height: 14),
                // Questions to ask seller
                const Text('Ask the seller:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                ...issue.questions.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 18, height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${e.key + 1}',
                          style: TextStyle(fontSize: 10, color: levelColor,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value,
                        style: const TextStyle(fontSize: 12, height: 1.4))),
                  ]),
                )),
                const SizedBox(height: 10),
                if (issue.checkUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(issue.checkUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser, size: 14),
                      label: const Text('Check Online →'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: levelColor,
                        side: BorderSide(color: levelColor.withOpacity(0.5)),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Mark as checked
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => issue.answered = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.safe,
                        side: BorderSide(color: AppColors.safe.withOpacity(0.5)),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('No Issue Found ✓'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => issue.answered = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Issue Found ⚠'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String label, String text, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontWeight: FontWeight.bold,
          fontSize: 11, color: color)),
      const SizedBox(height: 3),
      Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54,
          height: 1.5)),
    ],
  );
}
