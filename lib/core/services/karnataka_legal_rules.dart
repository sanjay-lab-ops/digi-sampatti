// ─── Karnataka Property Legal Rules Engine ────────────────────────────────────
// Encodes all Karnataka-specific property laws, rules, and regulations.
// Sources:
//   • Karnataka Land Revenue Act, 1964 (KLRA)
//   • Karnataka Land Reforms Act, 1961 (KLRA-61)
//   • Karnataka Town & Country Planning Act, 1961 (KTCPA)
//   • BDA Act, 1976
//   • BBMP Act, 2020
//   • Registration Act, 1908
//   • Transfer of Property Act, 1882
//   • RERA Karnataka Rules, 2017
//   • Benami Transactions (Prohibition) Act, 2016
//   • FEMA, 1999 (for NRI purchases)
//   • Income Tax Act §194IA (TDS)
//   • Forest Conservation Act, 1980
//   • Karnataka Lake Conservation & Development Authority Rules
//   • Supreme Court & Karnataka HC judgments
// ──────────────────────────────────────────────────────────────────────────────

import 'package:digi_sampatti/core/models/portal_findings_model.dart';

class LegalRuling {
  final String title;
  final String verdict;          // SAFE / CAUTION / DO_NOT_BUY / BLOCKED
  final String lawSection;       // e.g. "§95 KLRA 1964"
  final String explanation;      // Plain English explanation
  final List<String> whatToDo;
  final List<String> whatNotToDo;
  final String? conversionPath;  // If there's a legal remedy, describe it
  final bool canGetBankLoan;
  final bool canRegister;
  final int riskPenalty;         // Points deducted from score (0–40)

  const LegalRuling({
    required this.title,
    required this.verdict,
    required this.lawSection,
    required this.explanation,
    required this.whatToDo,
    required this.whatNotToDo,
    this.conversionPath,
    required this.canGetBankLoan,
    required this.canRegister,
    required this.riskPenalty,
  });
}

class KarnatakaLegalEngine {
  // ── Analyse all portal findings against Karnataka law ──────────────────────
  KarnatakaLegalResult analyse(PortalFindings f) {
    final rulings = <LegalRuling>[];
    int score = 80;
    bool canRegister = true;
    bool canGetBankLoan = true;

    // ── 1. KHATA TYPE ──────────────────────────────────────────────────────
    rulings.addAll(_analyseKhata(f));

    // ── 2. RTC REMARKS ─────────────────────────────────────────────────────
    rulings.addAll(_analyseRtcRemarks(f));

    // ── 3. ENCUMBRANCE / LOANS ─────────────────────────────────────────────
    rulings.addAll(_analyseEncumbrance(f));

    // ── 4. RERA ────────────────────────────────────────────────────────────
    rulings.addAll(_analyseRera(f));

    // ── 5. COURT CASES ─────────────────────────────────────────────────────
    rulings.addAll(_analyseCourts(f));

    // ── 6. BBMP TAX ────────────────────────────────────────────────────────
    rulings.addAll(_analyseBbmp(f));

    // ── 7. CERSAI ──────────────────────────────────────────────────────────
    rulings.addAll(_analyseCersai(f));

    // ── 8. BOUNDARIES ──────────────────────────────────────────────────────
    rulings.addAll(_analyseBoundaries(f));

    // Calculate final score and flags
    for (final r in rulings) {
      score -= r.riskPenalty;
      if (!r.canGetBankLoan) canGetBankLoan = false;
      if (!r.canRegister) canRegister = false;
    }

    score = score.clamp(0, 100);

    // Determine overall verdict
    final String overallVerdict;
    if (!canRegister || score < 40) {
      overallVerdict = 'DO_NOT_BUY';
    } else if (!canGetBankLoan || score < 65) {
      overallVerdict = 'CAUTION';
    } else {
      overallVerdict = 'SAFE';
    }

    // Always-applicable Karnataka guidance
    final alwaysDo = [
      'Get Encumbrance Certificate (EC) for minimum 30 years before buying (§17, Registration Act)',
      'Verify seller identity — Aadhaar + PAN must match all land records',
      'Pay stamp duty at guidance value minimum — understating is a criminal offence (§47A, Karnataka Stamp Act)',
      'Register the sale deed at the Sub-Registrar Office (SRO) within 4 months of execution (§23, Registration Act)',
      'Apply for Khata transfer (mutation) at BBMP/panchayat within 3 months of registration (§128, KLRA 1964)',
      if (/* property >= 50 lakhs */ true)
        'Deduct 1% TDS if property value ≥ ₹50 lakhs and deposit via Form 26QB within 30 days (§194IA, Income Tax Act)',
    ];

    final alwaysDont = [
      'Do NOT pay any cash "black money" — 100% white transaction protects you legally',
      'Do NOT rely on Power of Attorney sales — SC ruled POA is NOT a valid mode of transfer (Suraj Lamp Industries v. State of Haryana, 2011)',
      'Do NOT register without confirming all co-owners have signed (§7, Transfer of Property Act)',
      'Do NOT skip mutation after registration — you are not legally the owner until mutation is done',
    ];

    // Collect all dos and don'ts from individual rulings
    final allDo = [...alwaysDo];
    final allDont = [...alwaysDont];
    for (final r in rulings) {
      allDo.addAll(r.whatToDo);
      allDont.addAll(r.whatNotToDo);
    }

    return KarnatakaLegalResult(
      score: score,
      verdict: overallVerdict,
      canRegister: canRegister,
      canGetBankLoan: canGetBankLoan,
      rulings: rulings,
      whatToDo: allDo,
      whatNotToDo: allDont,
      conversionPaths: rulings
          .where((r) => r.conversionPath != null)
          .map((r) => r.conversionPath!)
          .toList(),
      stampDutyInfo: _stampDutyInfo(),
      registrationInfo: _registrationInfo(),
    );
  }

  // ── 1. Khata Analysis ──────────────────────────────────────────────────────
  List<LegalRuling> _analyseKhata(PortalFindings f) {
    if (f.khataFound == null) return [];

    switch (f.khataFound!) {
      case KhataFound.aKhata:
        return [
          LegalRuling(
            title: 'A Khata — Legally Valid',
            verdict: 'SAFE',
            lawSection: 'BBMP Act 2020 + §128 KLRA 1964',
            explanation:
                'A Khata means the property is fully recognised by BBMP, all dues are paid, '
                'layout is approved, and DC conversion (if required) is complete. '
                'Eligible for building plan sanction, bank home loans, and BESCOM/BWSSB connections.',
            whatToDo: [
              'Confirm A Khata number matches the survey number in RTC',
              'Verify khata is in the SELLER\'s name — not a previous owner',
              'Get a fresh Khata certificate (not older than 6 months) from BBMP',
            ],
            whatNotToDo: [
              'Do NOT assume A Khata means all other checks are clear — verify EC and court cases too',
            ],
            canGetBankLoan: true,
            canRegister: true,
            riskPenalty: 0,
          )
        ];

      case KhataFound.bKhata:
        // B Khata has two very different scenarios
        final isRevenueSite = f.isRevenueSite == true;
        if (isRevenueSite) {
          return [
            LegalRuling(
              title: 'B Khata — Revenue Site: CANNOT Convert',
              verdict: 'DO_NOT_BUY',
              lawSection: 'SC Judgment 2014 + §95 KLRA 1964 + §79A KLRA 1961',
              explanation:
                  'This B Khata is on a REVENUE SITE — an unauthorized layout formed on '
                  'agricultural land without BDA/BBMP approval and without DC conversion. '
                  'The Supreme Court has explicitly ruled that revenue sites CANNOT be regularized '
                  'under any scheme (Bangalore Development Authority v. R. Hanumaiah, 2005 and subsequent). '
                  'The "Akrama-Sakrama" scheme was struck down. No future regularization is legally possible. '
                  'No bank will give a home loan. BESCOM/BWSSB connections are not legal. '
                  'This property has ZERO conversion path.',
              whatToDo: [
                'Walk away from this property — there is no legal remedy',
                'Inform the seller you cannot proceed due to revenue site status',
                'If you have already paid token money, demand it back citing revenue site status',
                'Consult a lawyer if the seller refuses to refund',
              ],
              whatNotToDo: [
                'Do NOT buy a revenue site even if it\'s cheap — you cannot get bank loans, '
                    'building plans, or legal water/electricity connections ever',
                'Do NOT trust agents who say "it will be regularized later" — the Supreme Court has shut this door permanently',
                'Do NOT register a revenue site — registration of an illegal property does not make it legal',
                'Do NOT pay even ₹1 advance without confirming it is NOT a revenue site',
              ],
              conversionPath: null, // NO conversion possible
              canGetBankLoan: false,
              canRegister: false,
              riskPenalty: 40,
            )
          ];
        } else {
          // B Khata in approved layout — conversion IS possible
          return [
            LegalRuling(
              title: 'B Khata — Conversion Required Before Purchase',
              verdict: 'CAUTION',
              lawSection: 'BBMP Act 2020 §108A + §95 KLRA 1964',
              explanation:
                  'B Khata exists in an approved/regularized layout where DC conversion is done. '
                  'This CAN be converted to A Khata, but the conversion must happen BEFORE you register. '
                  'Most banks do not give loans on B Khata. BBMP does not sanction building plans on B Khata. '
                  'Conversion requires paying betterment charges to BBMP.',
              whatToDo: [
                'Confirm the layout has a valid BDA/BBMP approved layout plan (LP number)',
                'Confirm DC Conversion Order exists for the land (§95 KLRA)',
                'Ask seller to complete B Khata → A Khata conversion BEFORE registration',
                'Alternatively: negotiate for a price reduction and convert yourself post-registration (risky)',
                'Check BBMP betterment charges applicable: typically ₹50–500 per sqft depending on zone',
                'Timeline for conversion: 3–6 months after paying betterment charges',
              ],
              whatNotToDo: [
                'Do NOT register a B Khata property thinking you will convert later without getting it in writing',
                'Do NOT expect bank home loan approval on a B Khata property — most banks will reject',
                'Do NOT confuse B Khata in an approved layout with a revenue site — they are different',
              ],
              conversionPath:
                  'B Khata → A Khata Conversion: (1) Verify approved layout plan (LP No.) '
                  '(2) Pay BBMP betterment charges (3) Submit Form + DC order copy to BBMP '
                  '(4) BBMP inspects and issues A Khata. Time: 3–6 months. Cost: ₹50–500/sqft.',
              canGetBankLoan: false,
              canRegister: true, // can register but not recommended before conversion
              riskPenalty: 15,
            )
          ];
        }

      case KhataFound.noKhata:
        return [
          LegalRuling(
            title: 'No Khata — Property Not Recognised by Municipality',
            verdict: 'DO_NOT_BUY',
            lawSection: 'BBMP Act 2020 + §128 KLRA 1964',
            explanation:
                'The property has no Khata in BBMP/Gram Panchayat records. '
                'This means either: (a) it is on government land, (b) it is in an illegal layout, '
                'or (c) the previous mutation was never done. Cannot get bank loans, building plans, '
                'or utility connections without Khata.',
            whatToDo: [
              'Ask seller to establish Khata in their name before proceeding',
              'Verify if property is within BBMP limits or Gram Panchayat limits',
              'If GP area: check if GP Khata exists instead of BBMP Khata',
              'Consult a lawyer to understand why no Khata exists',
            ],
            whatNotToDo: [
              'Do NOT buy property with no Khata — you cannot legally use it',
              'Do NOT believe the agent that "Khata can be arranged after purchase"',
            ],
            canGetBankLoan: false,
            canRegister: false,
            riskPenalty: 30,
          )
        ];

      case KhataFound.notShown:
        return [];
    }
  }

  // ── 2. RTC Remarks ────────────────────────────────────────────────────────
  List<LegalRuling> _analyseRtcRemarks(PortalFindings f) {
    if (f.bhoomiHasRemarks != true) return [];
    return [
      LegalRuling(
        title: 'RTC Has Remarks / Govt Notice',
        verdict: 'CAUTION',
        lawSection: '§128 & §136 Karnataka Land Revenue Act 1964',
        explanation:
            'Remarks in the RTC (Record of Rights, Tenancy & Crops) could indicate: '
            'government acquisition notice, court attachment order, forest/lake/kaluve encroachment, '
            'disputed ownership, or pending mutation. Each type has different implications. '
            'Red text or special column entries (Col. 9-11 of RTC) must be read carefully.',
        whatToDo: [
          'Get a physical copy of the RTC from the Bhoomi kiosk',
          'Have a qualified property lawyer read and interpret each remark',
          'If remark says "Government Land" → do not proceed (cannot be sold)',
          'If remark mentions acquisition notification → verify status with BDA/NHAI/Karnataka PWD',
          'If remark is a court order (lis pendens) → wait for case resolution',
          'If remark is a pending mutation → resolve it first',
        ],
        whatNotToDo: [
          'Do NOT proceed without understanding EVERY remark in the RTC',
          'Do NOT trust verbal assurances from seller — get written legal opinion',
          'Do NOT register if remark shows govt acquisition — it may be void ab initio',
        ],
        canGetBankLoan: false,
        canRegister: false, // pending legal clarity
        riskPenalty: 20,
      )
    ];
  }

  // ── 3. Encumbrance / Loans ────────────────────────────────────────────────
  List<LegalRuling> _analyseEncumbrance(PortalFindings f) {
    final rulings = <LegalRuling>[];
    if (f.hasActiveLoan == true) {
      rulings.add(LegalRuling(
        title: 'Active Loan / Mortgage on Property',
        verdict: 'CAUTION',
        lawSection: '§54 & §58, Transfer of Property Act 1882 + §17 Registration Act 1908',
        explanation:
            'The Encumbrance Certificate shows an active mortgage or loan. '
            'Selling a mortgaged property without clearing the loan is fraudulent. '
            'The buyer must ensure the loan is cleared BEFORE or AT THE TIME OF registration. '
            'A tripartite agreement between buyer, seller, and bank is the standard mechanism.',
        whatToDo: [
          'Demand the loan outstanding statement from seller\'s bank',
          'Use a "Tripartite Agreement" — your bank (if taking loan) pays seller\'s bank directly',
          'Get a No Objection Certificate (NOC) from seller\'s bank confirming loan will be cleared at registration',
          'Ask for "Release Deed" from seller\'s bank after loan clearance, before you pay full amount',
          'Verify EC is clear AFTER loan is closed (get fresh EC post-closure)',
        ],
        whatNotToDo: [
          'Do NOT pay the full sale amount to the seller before the bank loan is cleared',
          'Do NOT register unless you have the NOC or release deed from the mortgagee bank',
          'Do NOT assume the seller will clear the loan from your payment — specify in agreement',
        ],
        canGetBankLoan: true, // can get if existing loan is cleared at registration
        canRegister: false, // not until loan is cleared
        riskPenalty: 15,
      ));
    }
    if (f.multipleSales == true) {
      rulings.add(LegalRuling(
        title: 'Multiple Sale Transactions — Title Chain Risk',
        verdict: 'CAUTION',
        lawSection: '§17 Registration Act 1908 + §41 Transfer of Property Act',
        explanation:
            'Multiple sales in a short period could indicate: property sold to multiple buyers '
            '(double selling fraud), disputed title, or seller trying to dispose quickly due to hidden defect.',
        whatToDo: [
          'Collect ALL previous sale deeds in the chain and verify each is registered',
          'Check if any previous buyer has filed a legal claim',
          'Verify the current seller is the actual last purchaser in the chain',
          'Search eCourts specifically for this survey number',
        ],
        whatNotToDo: [
          'Do NOT buy without a clean title chain going back at least 30 years',
          'Do NOT pay advance without lawyer verifying the full chain of sale deeds',
        ],
        canGetBankLoan: true,
        canRegister: true,
        riskPenalty: 10,
      ));
    }
    return rulings;
  }

  // ── 4. RERA ───────────────────────────────────────────────────────────────
  List<LegalRuling> _analyseRera(PortalFindings f) {
    if (f.isApartmentProject != true) return [];
    if (f.reraRegistered == null) return [];

    if (f.reraRegistered == false) {
      return [
        LegalRuling(
          title: 'Apartment NOT Registered on RERA — Builder Illegal',
          verdict: 'DO_NOT_BUY',
          lawSection: '§3, Real Estate (Regulation & Development) Act 2016 + RERA Karnataka Rules 2017',
          explanation:
              'Under RERA, all residential/commercial projects above 500 sqm OR more than 8 units '
              'MUST be registered before marketing or selling. Selling without RERA registration is '
              'a criminal offence (§59 RERA) punishable with up to 3 years imprisonment and/or fine. '
              'Buyers have NO legal protection from an unregistered builder.',
          whatToDo: [
            'Immediately stop payment — do not pay any further instalments',
            'File a complaint with RERA Karnataka at rera.karnataka.gov.in or call 080-23118888',
            'Demand refund of all amounts paid with 10% interest p.a. under §18 RERA',
            'If builder refuses refund, file RERA complaint — adjudicating officer can order refund',
            'Consult a property lawyer specialising in RERA cases',
          ],
          whatNotToDo: [
            'Do NOT make any further payment to an unregistered builder',
            'Do NOT sign any agreement that waives your RERA rights',
            'Do NOT believe the builder\'s claim that "registration is in process" — it\'s been mandatory since May 2017',
          ],
          canGetBankLoan: false,
          canRegister: false,
          riskPenalty: 35,
        )
      ];
    } else {
      return [
        LegalRuling(
          title: 'RERA Registered — Builder Legally Compliant',
          verdict: 'SAFE',
          lawSection: '§3 & §11, RERA 2016',
          explanation:
              'Builder is registered on RERA Karnataka. Must deposit 70% of collections in a '
              'separate escrow account, deliver on time, and disclose all project details.',
          whatToDo: [
            'Download the project\'s RERA registration certificate and verify the registration number',
            'Check RERA portal for any complaints filed against this builder/project',
            'Verify the RERA registration is not expired (check expiry date)',
            'Confirm the flat you are buying is part of the registered project',
            'Keep all builder correspondence referencing the RERA number',
          ],
          whatNotToDo: [
            'Do NOT pay more than 10% as booking amount before signing a RERA-compliant agreement',
            'Do NOT accept a sale agreement that does not mention the RERA registration number',
          ],
          canGetBankLoan: true,
          canRegister: true,
          riskPenalty: 0,
        )
      ];
    }
  }

  // ── 5. Court Cases ────────────────────────────────────────────────────────
  List<LegalRuling> _analyseCourts(PortalFindings f) {
    if (f.hasCourtCases != true) return [];
    return [
      LegalRuling(
        title: 'Active Court Cases — Lis Pendens',
        verdict: 'DO_NOT_BUY',
        lawSection: '§52 Transfer of Property Act 1882 (Lis Pendens)',
        explanation:
            'Section 52 of the Transfer of Property Act creates "lis pendens" — '
            'any sale during active litigation is subject to the court\'s final order. '
            'If you buy now and the court rules against the seller, your title is void. '
            'This is one of the most dangerous situations in property purchase.',
        whatToDo: [
          'Get the full case details (court, case number, parties) from eCourts',
          'Consult a property lawyer to assess the nature and likely outcome of the case',
          'If the case is old and the seller is winning, get a legal opinion before proceeding',
          'Wait for the court\'s final order before purchasing — ideally wait 90 days after order for any appeal period',
          'If you must proceed, get "interim injunction" status confirmed — if injunction exists, do not buy',
        ],
        whatNotToDo: [
          'Do NOT buy property under active litigation — §52 TPA makes your title voidable',
          'Do NOT trust seller\'s claim that "the case is minor" — any active case is a risk',
          'Do NOT register property if it has a court attachment order (kavulu) on it',
        ],
        canGetBankLoan: false,
        canRegister: false,
        riskPenalty: 30,
      )
    ];
  }

  // ── 6. BBMP Tax ───────────────────────────────────────────────────────────
  List<LegalRuling> _analyseBbmp(PortalFindings f) {
    if (f.propertyTaxPaid != false) return [];
    return [
      LegalRuling(
        title: 'BBMP Tax Dues or Khata Not in Seller\'s Name',
        verdict: 'CAUTION',
        lawSection: '§108 BBMP Act 2020 + §103 Karnataka Municipal Corporations Act',
        explanation:
            'Outstanding property tax is a first charge on the property — meaning BBMP can '
            'attach and auction the property for tax recovery, even after you have bought it. '
            'If Khata is not in seller\'s name, the seller may not have legal authority to sell.',
        whatToDo: [
          'Demand seller pay all pending BBMP property tax before registration',
          'Get BBMP tax paid receipts for last 3 years as proof',
          'Confirm Khata is in seller\'s current name (not a previous owner)',
          'After purchase, apply for Khata transfer within 3 months (Form 1, BBMP)',
          'Outstanding tax dues: negotiate deduction from sale price',
        ],
        whatNotToDo: [
          'Do NOT assume BBMP dues are seller\'s problem — they attach to the property, not the person',
          'Do NOT register if Khata is in a previous owner\'s name without proper succession/mutation done',
        ],
        canGetBankLoan: true,
        canRegister: true,
        riskPenalty: 10,
      )
    ];
  }

  // ── 7. CERSAI ─────────────────────────────────────────────────────────────
  List<LegalRuling> _analyseCersai(PortalFindings f) {
    if (f.hasBankCharge != true) return [];
    return [
      LegalRuling(
        title: 'Registered Bank Charge on CERSAI',
        verdict: 'CAUTION',
        lawSection: 'SARFAESI Act 2002 + CERSAI Act 2012 §23C',
        explanation:
            'CERSAI registration means a bank/financial institution has a registered charge '
            '(mortgage/hypothecation) on this property. Until this charge is released, '
            'the bank has prior claim over the property. A buyer must get the charge released '
            'before taking title. This is legally stronger than an EC entry — CERSAI has priority.',
        whatToDo: [
          'Identify the lending institution from CERSAI record',
          'Contact the bank and get the outstanding loan amount',
          'At registration: use a tripartite agreement — your payment goes to clear bank charge first',
          'Get the bank\'s "Release of Charge" document before completing payment to seller',
          'Verify CERSAI is updated after charge release (banks must file within 30 days)',
        ],
        whatNotToDo: [
          'Do NOT pay the seller before the CERSAI charge is released',
          'Do NOT complete registration without a written release from the bank',
          'Do NOT rely on seller\'s verbal assurance that the loan is closed — CERSAI must be updated',
        ],
        canGetBankLoan: false, // until charge released
        canRegister: false,
        riskPenalty: 20,
      )
    ];
  }

  // ── 8. Boundary Mismatch ──────────────────────────────────────────────────
  List<LegalRuling> _analyseBoundaries(PortalFindings f) {
    if (f.boundariesCorrect != false) return [];
    return [
      LegalRuling(
        title: 'Physical Boundary Mismatch with FMB/Sketch Map',
        verdict: 'CAUTION',
        lawSection: '§105 & §107 Karnataka Land Revenue Act 1964 (Survey)',
        explanation:
            'If the physical property does not match the FMB (Field Measurement Book) sketch, '
            'it could mean: encroachment on neighbour\'s land, government land, road reserve, '
            'or the survey number itself is wrong (wrong property being sold). '
            'Karnataka law requires survey to be the final authority on boundaries.',
        whatToDo: [
          'Hire a licensed Karnataka Government Surveyor (Ameen/Surveyor) to do a physical survey',
          'Get a "Joint Measurement" done with neighbouring land owners present',
          'If there is encroachment: resolve legally before registration',
          'Verify the survey number being sold matches the property you are physically visiting',
          'Cost of private survey: ₹5,000–₹15,000 depending on area',
        ],
        whatNotToDo: [
          'Do NOT register property that physically extends beyond its survey number boundaries',
          'Do NOT accept a discrepancy of more than 1–2% in area — investigate further',
          'Do NOT buy if it appears government road reserve or lake buffer is inside the property',
        ],
        canGetBankLoan: true,
        canRegister: false, // until survey resolved
        riskPenalty: 10,
      )
    ];
  }

  // ── Stamp Duty & Registration Info (Karnataka 2024–25) ────────────────────
  StampDutyInfo _stampDutyInfo() {
    return const StampDutyInfo(
      rates: [
        '₹0 – ₹20 lakhs: 2% stamp duty',
        '₹20 – ₹45 lakhs: 3% stamp duty',
        'Above ₹45 lakhs: 5% stamp duty',
        '+10% surcharge on stamp duty (all slabs)',
        '+2% cess (all slabs)',
        'Effective rate above ₹45L = 5% + 0.5% + 0.1% ≈ 5.6%',
      ],
      registrationCharge: '1% of property value (no cap)',
      totalEffective: '~6.6% for most Bengaluru properties above ₹45L',
      notes: [
        'Stamp duty calculated on guidance value OR actual sale price — whichever is HIGHER',
        'Guidance value is set by the state government and published on IGR Karnataka portal',
        'Women buyers get 1% concession on stamp duty in Karnataka',
        'Understating sale price to reduce stamp duty is a criminal offence under §47A Karnataka Stamp Act',
      ],
      law: '§3 Karnataka Stamp Act 1957 + IGR Karnataka Circular 2024',
    );
  }

  RegistrationInfo _registrationInfo() {
    return const RegistrationInfo(
      mandatoryDocuments: [
        'Original sale deed (on stamp paper of correct value)',
        'Encumbrance Certificate (Form 15/16) — minimum 30 years',
        'Khata certificate (original)',
        'Khata extract',
        'Latest property tax paid receipt',
        'Seller\'s Aadhaar + PAN',
        'Buyer\'s Aadhaar + PAN',
        'Two witnesses with Aadhaar',
        'Passport size photos of buyer + seller',
        'NOC from bank (if existing loan on property)',
        'DC Conversion Order (if agricultural land)',
        'Layout approval (LP number) — if in a layout',
      ],
      process: [
        '1. Finalise sale deed draft with lawyer',
        '2. Calculate guidance value on IGR Karnataka portal',
        '3. Buy stamp paper of correct value from licensed vendor / franking',
        '4. Execute sale deed — buyer, seller, and two witnesses sign',
        '5. Present at Sub-Registrar Office (SRO) with all documents',
        '6. SRO verifies, takes biometrics, and registers the deed',
        '7. Collect registered document (usually same day or next day)',
        '8. Apply for Khata transfer at BBMP/Panchayat within 3 months',
      ],
      timeFrame: 'Registration on same day at SRO. Khata transfer: 30–90 days.',
      cost: 'Stamp duty + 1% registration + lawyer fees (₹5,000–₹25,000) + misc',
    );
  }
}

// ─── Result Classes ────────────────────────────────────────────────────────────
class KarnatakaLegalResult {
  final int score;
  final String verdict;
  final bool canRegister;
  final bool canGetBankLoan;
  final List<LegalRuling> rulings;
  final List<String> whatToDo;
  final List<String> whatNotToDo;
  final List<String> conversionPaths;
  final StampDutyInfo stampDutyInfo;
  final RegistrationInfo registrationInfo;

  const KarnatakaLegalResult({
    required this.score,
    required this.verdict,
    required this.canRegister,
    required this.canGetBankLoan,
    required this.rulings,
    required this.whatToDo,
    required this.whatNotToDo,
    required this.conversionPaths,
    required this.stampDutyInfo,
    required this.registrationInfo,
  });

  String get recommendation {
    switch (verdict) {
      case 'SAFE': return 'Safe to Proceed';
      case 'CAUTION': return 'Proceed with Caution';
      case 'DO_NOT_BUY': return 'Do NOT Buy — Legal Issues Found';
      case 'BLOCKED': return 'Legally Blocked — Cannot Purchase';
      default: return 'Requires Legal Review';
    }
  }
}

class StampDutyInfo {
  final List<String> rates;
  final String registrationCharge;
  final String totalEffective;
  final List<String> notes;
  final String law;
  const StampDutyInfo({
    required this.rates,
    required this.registrationCharge,
    required this.totalEffective,
    required this.notes,
    required this.law,
  });
}

class RegistrationInfo {
  final List<String> mandatoryDocuments;
  final List<String> process;
  final String timeFrame;
  final String cost;
  const RegistrationInfo({
    required this.mandatoryDocuments,
    required this.process,
    required this.timeFrame,
    required this.cost,
  });
}
