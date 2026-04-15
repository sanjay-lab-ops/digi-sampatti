import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── Government Portal WebView ────────────────────────────────────────────────
// Opens real govt portal inside the app.
// User searches their property on the official site.
// When done, taps "Done — Analyse This Property" to continue.
// ─────────────────────────────────────────────────────────────────────────────

enum GovPortal {
  bhoomi,
  kaveri,
  rera,
  eCourts,
  bbmp,
  cersai,
  dishank,
  sakala,       // Mutation / Khata transfer application
  janaspandana, // Karnataka grievance portal
  rtiOnline,    // RTI filing
  benami,       // Benami property check / report
  bdaLayout,      // BDA layout approval check (housing.bdabangalore.org)
  bdaTax,         // BDA property tax portal (app.bda.karnataka.gov.in)
  bmrda,          // BMRDA — peri-urban layout approvals (bmrda.karnataka.gov.in)
  nocBank,        // Bank NOC / CERSAI mortgage check
  kaveriGuidance, // Guidance value / stamp duty calculator
  bbmpPlan,       // BBMP building plan approval check
  dcConversion,   // DC Conversion / agricultural to residential
  wakfBoard,      // Wakf Board — check if Wakf land
  gramPanchayat,  // Gram Panchayat Khata (rural properties)
  digilocker,     // DigiLocker — access govt-issued property documents
  igrGuidance,    // IGR Karnataka — guidance value PDFs
}

extension GovPortalInfo on GovPortal {
  String get title {
    switch (this) {
      case GovPortal.bhoomi:   return 'Bhoomi — Land Records';
      case GovPortal.kaveri:   return 'Kaveri — EC / Registration';
      case GovPortal.rera:     return 'RERA Karnataka';
      case GovPortal.eCourts:  return 'eCourts — Court Cases';
      case GovPortal.bbmp:     return 'BBMP — Khata';
      case GovPortal.cersai:   return 'CERSAI — Bank Mortgage';
      case GovPortal.dishank:  return 'Bhoomi — FMB / Sketch Maps';
      case GovPortal.sakala:       return 'SAKALA — Apply for Mutation';
      case GovPortal.janaspandana: return 'Janaspandana — File Grievance';
      case GovPortal.rtiOnline:    return 'RTI Online — File RTI';
      case GovPortal.benami:    return 'Benami — Property Check';
      case GovPortal.bdaLayout:  return 'BDA — Layout Approval (Housing)';
      case GovPortal.bdaTax:     return 'BDA — Property Tax Portal';
      case GovPortal.bmrda:      return 'BMRDA — Peri-Urban Layout Approval';
      case GovPortal.nocBank:    return 'CERSAI — Bank NOC Check';
      case GovPortal.kaveriGuidance: return 'IGR / Kaveri — Guidance Value';
      case GovPortal.bbmpPlan:       return 'BBMP — Building Plan Approval';
      case GovPortal.dcConversion:   return 'Bhoomi — DC Conversion Status';
      case GovPortal.wakfBoard:      return 'Wakf Board Karnataka';
      case GovPortal.gramPanchayat:  return 'Gram Panchayat — Rural Khata';
      case GovPortal.digilocker:     return 'DigiLocker — Property Documents';
      case GovPortal.igrGuidance:    return 'IGR Karnataka — Guidance Value PDFs';
    }
  }

  String get url {
    switch (this) {
      case GovPortal.bhoomi:
        return 'https://landrecords.karnataka.gov.in/';
      case GovPortal.kaveri:
        return 'https://kaveri.karnataka.gov.in/landing-page';
      case GovPortal.rera:
        return 'https://rera.karnataka.gov.in/home?language=en';
      case GovPortal.eCourts:
        return 'https://ecourts.gov.in/ecourts_home/';
      case GovPortal.bbmp:
        return 'https://bbmpeaasthi.karnataka.gov.in/';
      case GovPortal.cersai:
        // CERSAI blocks WebViews — must open in external browser
        return 'https://www.cersai.org.in/CERSAI/home.prg';
      case GovPortal.dishank:
        return 'https://landrecords.karnataka.gov.in/';
      case GovPortal.sakala:
        return 'https://nadakacheri.karnataka.gov.in/ajsk';
      case GovPortal.janaspandana:
        return 'https://janaspandana.karnataka.gov.in/';
      case GovPortal.rtiOnline:
        return 'https://rtionline.gov.in/';
      case GovPortal.benami:
        return 'https://benami.gov.in/';
      case GovPortal.bdaLayout:
        return 'https://housing.bdabangalore.org/';
      case GovPortal.bdaTax:
        return 'https://app.bda.karnataka.gov.in/bdaptax-citizen/login';
      case GovPortal.bmrda:
        return 'https://bmrda.karnataka.gov.in/en';
      case GovPortal.nocBank:
        return 'https://www.cersai.org.in/CERSAI/home.prg';
      case GovPortal.kaveriGuidance:
        return 'https://kaveri.karnataka.gov.in/landing-page';
      case GovPortal.bbmpPlan:
        return 'https://bbmp.karnataka.gov.in/NewKhata/';
      case GovPortal.dcConversion:
        return 'https://landrecords.karnataka.gov.in/';
      case GovPortal.wakfBoard:
        return 'https://wakfkarnataka.gov.in/';
      case GovPortal.gramPanchayat:
        return 'https://grpanchayat.karnataka.gov.in/';
      case GovPortal.digilocker:
        return 'https://digilocker.gov.in/';
      case GovPortal.igrGuidance:
        return 'https://igr.karnataka.gov.in/page/Revised+Guidelines+Value/en';
    }
  }

  // CERSAI, nocBank, and DigiLocker require Chrome (Aadhaar OTP / WebView restrictions)
  bool get requiresExternalBrowser {
    return this == GovPortal.cersai || this == GovPortal.nocBank || this == GovPortal.digilocker;
  }

  String get hint {
    switch (this) {
      case GovPortal.bhoomi:
        return 'Tap "RTC with sketch [Beta]" → fill District, Taluk, Hobli, Village, Survey No → tap Get Details. Read the owner name, khata type and any remarks.';
      case GovPortal.kaveri:
        return 'Tap "EC" → select district & SRO → enter property details → Search. Check 30 years EC to see all loans & transactions.';
      case GovPortal.rera:
        return 'Search your apartment project name or promoter. Check RERA registration status, then tap Done.';
      case GovPortal.eCourts:
        return 'Search court cases by owner name or survey number. Check for active litigation, then tap Done.';
      case GovPortal.bbmp:
        return 'Check BBMP property tax and khata status. Verify official municipal records, then tap Done.';
      case GovPortal.cersai:
        return 'Search if the property has any active bank mortgage or charge. Enter owner details, then tap Done.';
      case GovPortal.dishank:
        return 'View FMB / Sketch map for the survey number. Select District, Taluk, Village and enter survey number. Verify plot boundaries, then tap Done.';
      case GovPortal.sakala:
        return 'Fill the mutation form. Enter your Aadhaar OTP when asked. Note the reference number after submission.';
      case GovPortal.janaspandana:
        return 'File a grievance against any government officer. Describe the issue, attach documents if any. Note the ticket number.';
      case GovPortal.rtiOnline:
        return 'File an RTI to any central/state department. Pay ₹10 fee online. Note the registration number.';
      case GovPortal.benami:
        return 'Check if property is flagged as benami. You can also report suspected benami property here.';
      case GovPortal.bdaLayout:
        return 'For BDA-approved layouts: search your project name or layout number. Verify approval status and sanctioned plan.';
      case GovPortal.bdaTax:
        return 'Check BDA property tax payments and dues for your site. Login with property ID or owner details.';
      case GovPortal.bmrda:
        return 'For properties outside BBMP limits (Yelahanka, Devanahalli etc): check if layout has BMRDA approval. Unapproved layouts = illegal construction.';
      case GovPortal.nocBank:
        return 'Search if property has any registered mortgage or charge with a bank. Enter owner name and select Karnataka.';
      case GovPortal.kaveriGuidance:
        return 'Check government guidance value for your property area. Used to calculate minimum stamp duty.';
      case GovPortal.bbmpPlan:
        return 'Verify if the building has approved building plan from BBMP. Unapproved construction = legal risk.';
      case GovPortal.dcConversion:
        return 'Check if agricultural land has valid DC Conversion order. Without this, buying farm land is illegal.';
      case GovPortal.wakfBoard:
        return 'Verify property is not Wakf land. Wakf land cannot be sold — buying it = title void.';
      case GovPortal.gramPanchayat:
        return 'Check Gram Panchayat Khata for rural properties outside BBMP limits.';
      case GovPortal.digilocker:
        return 'Access your Aadhaar, PAN, land records and other government documents. Sign in with Aadhaar OTP or mobile number.';
      case GovPortal.igrGuidance:
        return 'Download the official IGR Karnataka Revised Guideline Value PDF for your district. Find your area in the PDF to see the government floor price per sqft.';
    }
  }

  Color get color {
    switch (this) {
      case GovPortal.bhoomi:  return AppColors.primary;
      case GovPortal.kaveri:  return AppColors.arthBlue;
      case GovPortal.rera:    return AppColors.esign;
      case GovPortal.eCourts: return AppColors.deepOrange;
      case GovPortal.bbmp:    return AppColors.navy;
      case GovPortal.cersai:  return AppColors.slate;
      case GovPortal.dishank: return AppColors.info;
      case GovPortal.sakala:       return AppColors.seller;
      case GovPortal.janaspandana: return AppColors.esign;
      case GovPortal.rtiOnline:    return AppColors.slate;
      case GovPortal.benami:    return const Color(0xFFB71C1C);
      case GovPortal.bdaLayout:  return AppColors.indigo;
      case GovPortal.bdaTax:     return AppColors.info;
      case GovPortal.bmrda:      return AppColors.teal;
      case GovPortal.nocBank:    return AppColors.slate;
      case GovPortal.kaveriGuidance: return AppColors.arthBlue;
      case GovPortal.bbmpPlan:       return AppColors.navy;
      case GovPortal.dcConversion:   return const Color(0xFF4E342E);
      case GovPortal.wakfBoard:      return AppColors.indigo;
      case GovPortal.gramPanchayat:  return const Color(0xFF33691E);
      case GovPortal.digilocker:     return AppColors.info;
      case GovPortal.igrGuidance:    return AppColors.teal;
    }
  }
}

class GovWebViewScreen extends StatefulWidget {
  final GovPortal portal;
  final String? surveyNumber;
  final String? district;
  final String? taluk;
  final String? hobli;
  final String? village;

  const GovWebViewScreen({
    super.key,
    required this.portal,
    this.surveyNumber,
    this.district,
    this.taluk,
    this.hobli,
    this.village,
  });

  @override
  State<GovWebViewScreen> createState() => _GovWebViewScreenState();
}

class _GovWebViewScreenState extends State<GovWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _showHint = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.portal.requiresExternalBrowser) {
      _initWebView();
    }
    // Auto-hide hint after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
    // For portals that block WebView, open Chrome immediately
    if (widget.portal.requiresExternalBrowser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInChrome();
      });
    }
  }

  Future<void> _openInChrome() async {
    final uri = Uri.parse(widget.portal.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { _isLoading = true; _loadingProgress = 0; }),
        onProgress: (p) => setState(() => _loadingProgress = p),
        onPageFinished: (url) {
          setState(() => _isLoading = false);
          // Inject auto-fill JS after every page navigation
          switch (widget.portal) {
            case GovPortal.bhoomi:
            case GovPortal.dishank:
              _autoFillBhoomi();
              break;
            case GovPortal.kaveri:
            case GovPortal.bbmp:
            case GovPortal.eCourts:
            case GovPortal.cersai:
              _autoFillKaveri();
              break;
            case GovPortal.rera:
              _autoFillRera();
              break;
            case GovPortal.sakala:
            case GovPortal.janaspandana:
            case GovPortal.rtiOnline:
            case GovPortal.benami:
            case GovPortal.bdaLayout:
            case GovPortal.bdaTax:
            case GovPortal.bmrda:
            case GovPortal.nocBank:
            case GovPortal.kaveriGuidance:
            case GovPortal.igrGuidance:
            case GovPortal.bbmpPlan:
            case GovPortal.dcConversion:
            case GovPortal.wakfBoard:
            case GovPortal.gramPanchayat:
            case GovPortal.digilocker:
              _autoFillKaveri();
              break;
          }
        },
        onWebResourceError: (error) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(widget.portal.url));
  }

  // ── Auto-fill Bhoomi RTC portal ─────────────────────────────────────────────
  // Fires on every page load. On the home page nothing matches; on the RTC/search
  // page the dropdowns and survey field get filled.
  void _autoFillBhoomi() {
    final survey  = widget.surveyNumber ?? '';
    final dist    = widget.district ?? '';
    final taluk   = widget.taluk ?? '';
    final hobli   = widget.hobli ?? '';
    final village = widget.village ?? '';

    // Retry at 1 s, 3 s, 6 s (covers slow AJAX / page-transition delays)
    for (final delay in [1, 3, 6]) {
      Future.delayed(Duration(seconds: delay), () {
        if (mounted) {
          _controller.runJavaScript(
              _bhoomiAutoFillScript(survey, dist, taluk, hobli, village));
        }
      });
    }
  }

  String _bhoomiAutoFillScript(
      String survey, String dist, String taluk, String hobli, String village) {
    // Escape values to avoid JS injection
    String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '''
(function() {
  // ── Trigger React/Angular synthetic events ──────────────────────────────────
  function nativeInputSetter(el, val) {
    var nativeSetter = Object.getOwnPropertyDescriptor(
        window.HTMLInputElement.prototype, 'value');
    if (nativeSetter) nativeSetter.set.call(el, val);
    el.dispatchEvent(new Event('input',  {bubbles: true}));
    el.dispatchEvent(new Event('change', {bubbles: true}));
  }

  function nativeSelectSetter(sel, idx) {
    var nativeSetter = Object.getOwnPropertyDescriptor(
        window.HTMLSelectElement.prototype, 'value');
    if (nativeSetter) nativeSetter.set.call(sel, sel.options[idx].value);
    sel.selectedIndex = idx;
    sel.dispatchEvent(new Event('change', {bubbles: true}));
    sel.dispatchEvent(new Event('input',  {bubbles: true}));
  }

  // ── Find a <select> by id/name/placeholder-option matching keywords ─────────
  function findSelect(keywords) {
    var sels = document.querySelectorAll('select');
    for (var i = 0; i < sels.length; i++) {
      var s   = sels[i];
      var id  = (s.id   || '').toLowerCase();
      var nm  = (s.name || '').toLowerCase();
      var ph  = (s.options.length > 0 ? s.options[0].text : '').toLowerCase();
      for (var j = 0; j < keywords.length; j++) {
        var kw = keywords[j];
        if (id.includes(kw) || nm.includes(kw) || ph.includes(kw)) return s;
      }
    }
    return null;
  }

  // ── Select option whose text contains the search value ──────────────────────
  function selectByText(sel, text) {
    if (!sel || !text) return false;
    var lower = text.trim().toLowerCase();
    for (var i = 0; i < sel.options.length; i++) {
      if (sel.options[i].text.trim().toLowerCase().includes(lower)) {
        nativeSelectSetter(sel, i);
        return true;
      }
    }
    return false;
  }

  // ── Fill a text input matching keywords ──────────────────────────────────────
  function fillInput(keywords, val) {
    if (!val) return false;
    var inputs = document.querySelectorAll('input[type="text"], input:not([type]), input[type="number"]');
    for (var i = 0; i < inputs.length; i++) {
      var inp = inputs[i];
      var ph  = (inp.placeholder || '').toLowerCase();
      var id  = (inp.id   || '').toLowerCase();
      var nm  = (inp.name || '').toLowerCase();
      for (var j = 0; j < keywords.length; j++) {
        var kw = keywords[j];
        if (ph.includes(kw) || id.includes(kw) || nm.includes(kw)) {
          nativeInputSetter(inp, val);
          return true;
        }
      }
    }
    return false;
  }

  var distVal    = "${esc(dist)}";
  var talukVal   = "${esc(taluk)}";
  var hobliVal   = "${esc(hobli)}";
  var villageVal = "${esc(village)}";
  var surveyVal  = "${esc(survey)}";

  // ── Cascading fill with AJAX wait delays ────────────────────────────────────
  // Step 1: District (immediate)
  var distSel = findSelect(['district', 'dist_id', 'districtid', 'dist', 'jilla']);
  if (distSel && distVal) selectByText(distSel, distVal);

  // Step 2: Taluk (wait for district AJAX)
  setTimeout(function() {
    var talukSel = findSelect(['taluk', 'taluka_id', 'talukid', 'taluka']);
    if (talukSel && talukVal) selectByText(talukSel, talukVal);

    // Step 3: Hobli (wait for taluk AJAX)
    setTimeout(function() {
      var hobliSel = findSelect(['hobli', 'hobly', 'hobli_id', 'hobliid']);
      if (hobliSel && hobliVal) selectByText(hobliSel, hobliVal);

      // Step 4: Village (wait for hobli AJAX)
      setTimeout(function() {
        var vilSel = findSelect(['village', 'gram', 'grama', 'village_id', 'villageid']);
        if (vilSel && villageVal) selectByText(vilSel, villageVal);

        // Step 5: Survey Number (wait for village load)
        setTimeout(function() {
          if (surveyVal) {
            fillInput(['survey', 'surveyno', 'survey_no', 'sy.no', 'syno', 'sno', 'hissa'], surveyVal);
          }
        }, 800);
      }, 1200);
    }, 1200);
  }, 1000);
})();
''';
  }

  // ── Auto-fill Kaveri (IGRS) portal ──────────────────────────────────────────
  void _autoFillKaveri() {
    final survey = widget.surveyNumber ?? '';
    final dist   = widget.district ?? '';
    final taluk  = widget.taluk ?? '';
    for (final delay in [1500, 3000, 6000]) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        _controller.runJavaScript(_genericFillScript(
          survey: survey, district: dist, taluk: taluk));
      });
    }
  }

  // ── Generic fill script used by Kaveri, eCourts, BBMP ────────────────────────
  String _genericFillScript({String survey = '', String district = '', String taluk = ''}) {
    String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '''
(function() {
  function nativeSet(el, val) {
    try {
      var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
      if (setter) setter.set.call(el, val);
    } catch(e) { el.value = val; }
    el.dispatchEvent(new Event('input',  {bubbles: true}));
    el.dispatchEvent(new Event('change', {bubbles: true}));
    el.dispatchEvent(new Event('blur',   {bubbles: true}));
  }
  function nativeSelectSet(sel, text) {
    var lower = text.trim().toLowerCase();
    for (var i = 0; i < sel.options.length; i++) {
      if (sel.options[i].text.trim().toLowerCase().includes(lower)) {
        try {
          var setter = Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype, 'value');
          if (setter) setter.set.call(sel, sel.options[i].value);
        } catch(e) {}
        sel.selectedIndex = i;
        sel.dispatchEvent(new Event('change', {bubbles: true}));
        sel.dispatchEvent(new Event('input',  {bubbles: true}));
        return true;
      }
    }
    return false;
  }
  function findAndFillSelect(keywords, text) {
    if (!text) return;
    document.querySelectorAll('select').forEach(function(s) {
      var combo = ((s.id||'')+(s.name||'')+(s.options[0]?s.options[0].text:'')).toLowerCase();
      for (var j = 0; j < keywords.length; j++) {
        if (combo.includes(keywords[j])) { nativeSelectSet(s, text); return; }
      }
    });
  }
  function findAndFillInput(keywords, text) {
    if (!text) return;
    document.querySelectorAll('input').forEach(function(inp) {
      var combo = ((inp.placeholder||'')+(inp.id||'')+(inp.name||'')).toLowerCase();
      for (var j = 0; j < keywords.length; j++) {
        if (combo.includes(keywords[j])) { nativeSet(inp, text); return; }
      }
    });
  }

  var distVal   = "${esc(district)}";
  var talukVal  = "${esc(taluk)}";
  var surveyVal = "${esc(survey)}";

  // District
  findAndFillSelect(['district','dist','jilla'], distVal);
  // Taluk (after AJAX)
  setTimeout(function() {
    findAndFillSelect(['taluk','taluka','sro'], talukVal);
    // Survey / property number
    setTimeout(function() {
      findAndFillInput(['survey','property','khata','doc','reg','sno'], surveyVal);
    }, 800);
  }, 1000);
})();
''';
  }

  // ── Auto-fill RERA Karnataka portal ──────────────────────────────────────────
  void _autoFillRera() {
    // RERA doesn't have cascading dropdowns; just fill search field with project/survey
    final survey = widget.surveyNumber ?? '';
    if (survey.isEmpty) return;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _controller.runJavaScript('''
(function() {
  function fill(inp, val) {
    try { Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set.call(inp,val); } catch(e){inp.value=val;}
    inp.dispatchEvent(new Event('input',  {bubbles:true}));
    inp.dispatchEvent(new Event('change', {bubbles:true}));
  }
  var s = "${survey.replaceAll('"', '')}";
  document.querySelectorAll('input[type="text"], input:not([type])').forEach(function(inp){
    var combo = ((inp.placeholder||'')+(inp.id||'')+(inp.name||'')).toLowerCase();
    if (combo.includes('project') || combo.includes('search') || combo.includes('name') || combo.includes('reg')) {
      fill(inp, s);
    }
  });
})();
''');
    });
  }

  // ── Ask user if they submitted, capture reference number ─────────────────────
  void _showSubmissionCapture(BuildContext ctx) {
    final isSubmitPortal = widget.portal == GovPortal.sakala ||
        widget.portal == GovPortal.janaspandana ||
        widget.portal == GovPortal.rtiOnline || widget.portal == GovPortal.benami;

    if (!isSubmitPortal) {
      Navigator.of(ctx).pop(true);
      return;
    }

    final refCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Did you submit?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Enter the reference number to track in the app',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: refCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Reference / Ticket Number',
                hintText: 'e.g. MUT/YLH/2026/00142',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    Navigator.of(ctx).pop(false);
                  },
                  child: const Text('Skip — Just Checking'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.portal.color),
                  onPressed: () async {
                    final ref = refCtrl.text.trim();
                    Navigator.pop(sheetCtx);
                    Navigator.of(ctx).pop(ref.isNotEmpty ? ref : true);
                  },
                  child: const Text('Save & Track'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Build step instructions with Copy buttons ──────────────────────────────
  // Step format:
  //   'normal text'           → numbered step (white)
  //   'AUTO:text'             → green check (survey no — actually fills)
  //   'COPY:Label|Value'      → shows label + orange COPY button (tap to copy)
  Widget _buildSteps() {
    final steps = _stepsForPortal();
    int stepNum = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        if (step.startsWith('AUTO:')) {
          final label = step.substring(5);
          return _StepRow(
            icon: const Icon(Icons.check, size: 11, color: Colors.white),
            iconBg: Colors.green[400]!,
            child: Text(label,
                style: const TextStyle(color: Color(0xFFB9F6CA), fontSize: 11.5, height: 1.3)),
          );
        } else if (step.startsWith('COPY:')) {
          final parts = step.substring(5).split('|');
          final label = parts[0];
          final value = parts.length > 1 ? parts[1] : '';
          return _CopyStepRow(
            label: label,
            value: value,
            color: widget.portal.color,
          );
        } else {
          stepNum++;
          final num = stepNum;
          return _StepRow(
            icon: Text('$num',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            iconBg: Colors.white.withOpacity(0.25),
            child: Text(step,
                style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3,
                    fontWeight: FontWeight.w500)),
          );
        }
      }).toList(),
    );
  }

  List<String> _stepsForPortal() {
    final sv   = widget.surveyNumber;
    final dist = widget.district;
    final taluk = widget.taluk;
    final hobli = widget.hobli;
    final village = widget.village;

    switch (widget.portal) {
      case GovPortal.bhoomi:
      case GovPortal.dishank:
        return [
          'Tap "RTC with sketch [Beta]" → "Advanced Search"',
          if (dist != null && dist.isNotEmpty)   'COPY:District|$dist'   else 'Type district name in District field',
          if (taluk != null && taluk.isNotEmpty) 'COPY:Taluk|$taluk'     else 'Type taluk name in Taluk field',
          if (hobli != null && hobli.isNotEmpty) 'COPY:Hobli|$hobli'     else 'Select Hobli (manual)',
          if (village != null && village.isNotEmpty) 'COPY:Village|$village' else 'Select Village (manual)',
          if (sv != null && sv.isNotEmpty)       'AUTO:Survey No: $sv ✓ (auto-typed)' else 'Type survey number',
          widget.portal == GovPortal.dishank
              ? 'View FMB sketch — compare with plot boundaries'
              : 'Tap ಹುಡುಕಿ/Search → read owner name, khata type, remarks',
        ];
      case GovPortal.kaveri:
        return [
          'Tap "Encumbrance Certificate (EC)"',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select District',
          'Select SRO for your area (manual)',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey / Property No|$sv' else 'Enter survey number',
          'Set date range: last 30 years → Search',
          'Check all loans, mortgages & sale deeds',
        ];
      case GovPortal.rera:
        return [
          'Tap "Projects" in top menu',
          'Search by builder name or project name',
          'Check: Registration number + Status (Active/Expired)',
          'Note expiry date and completion date',
        ];
      case GovPortal.eCourts:
        return [
          'Tap "Case Status" from the menu',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select State: Karnataka → District',
          'Search by "Party Name" — use owner name from Bhoomi',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey No (also search this)|$sv' else 'Also search by survey number',
          'Check if any active civil cases appear',
        ];
      case GovPortal.bbmp:
        return [
          'Tap "Property Tax"',
          'Search by Owner Name or Property Address',
          'Check: khata in seller\'s name? Tax paid?',
          'Note the PID (Property ID) number',
        ];
      case GovPortal.cersai:
        return [
          'Tap "Search" → "Asset Search"',
          'Enter Owner Name (from Bhoomi RTC)',
          'Select State: Karnataka',
          'Any result = active bank charge on this property',
        ];
      case GovPortal.sakala:
        return [
          'Fill Applicant Name, Survey No, District',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Enter District',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey Number|$sv' else 'Enter Survey Number',
          'Upload: Registered Sale Deed + Aadhaar',
          'Enter Aadhaar OTP sent to your mobile',
          'Submit → note the Application Reference Number',
        ];
      case GovPortal.janaspandana:
        return [
          'Tap "Lodge Grievance"',
          'Select Department: Revenue / BBMP / Registration',
          'Describe the issue clearly (officer delay, rejection etc.)',
          'Attach: rejection letter or SLA breach proof',
          'Submit → note the Grievance Ticket Number',
        ];
      case GovPortal.rtiOnline:
        return [
          'Tap "Submit Request"',
          'Select Ministry/Dept: Karnataka Revenue Dept.',
          'Type your question about the property/document',
          'Pay ₹10 fee via UPI/card',
          'Submit → note the RTI Registration Number',
        ];
      case GovPortal.benami:
        return [
          'Tap "Verify Property" or "Search"',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey Number|$sv' else 'Enter survey or property details',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Enter district',
          'Check if property is flagged as benami',
          'If suspicious → tap "Report" and submit complaint',
        ];
      case GovPortal.bdaLayout:
        return [
          'Tap "Online Services" → "Layout / Plan Approval"',
          'Search by layout name or survey number',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey No|$sv' else 'Enter survey number',
          'Verify: BDA/BMRDA approval exists?',
          'Check: Is the plot in approved area? Any violations?',
        ];
      case GovPortal.nocBank:
        return [
          'Tap "Search" → "Asset Search"',
          'Enter Owner Name (from Bhoomi RTC — exact spelling)',
          'Select State: Karnataka',
          'Any result = active bank mortgage on this property',
          'No result = property is free of registered bank charges',
        ];
      case GovPortal.kaveriGuidance:
        return [
          'Tap "Guidance Value" from the menu',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select District',
          if (taluk != null && taluk.isNotEmpty) 'COPY:Taluk|$taluk' else 'Select Taluk',
          'Select Village / Area / Road name',
          'Note the guidance value per sqft/acre shown',
          'Compare with the sale price being asked',
        ];
      case GovPortal.bbmpPlan:
        return [
          'Tap "Building Plan" or "Online Services"',
          'Search by address or owner name',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey/Plot No|$sv' else 'Enter plot/survey number',
          'Check: Is building plan approved?',
          'Check: Any deviation or unauthorized construction?',
          'Note the plan sanction number',
        ];
      case GovPortal.dcConversion:
        return [
          'Search for DC Conversion order',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select District',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey Number|$sv' else 'Enter survey number',
          'Check: Is there a valid DC Conversion order?',
          'Without conversion → agricultural land = cannot buy for residential use',
          'Note the order number and date',
        ];
      case GovPortal.wakfBoard:
        return [
          'Tap "Property Search" or "Wakf Properties"',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select District',
          'Search by survey number or area',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey Number|$sv' else 'Enter survey number',
          'If property appears → it is Wakf land — DO NOT BUY',
          'No result = not registered as Wakf property',
        ];
      case GovPortal.gramPanchayat:
        return [
          'Find your Gram Panchayat from the list',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select District',
          if (taluk != null && taluk.isNotEmpty) 'COPY:Taluk|$taluk' else 'Select Taluk',
          'Search by owner name or survey number',
          if (sv != null && sv.isNotEmpty) 'COPY:Survey No|$sv' else 'Enter survey number',
          'Check: Khata in seller\'s name? Tax paid?',
        ];
      case GovPortal.digilocker:
        return [
          'Sign in with Aadhaar OTP or mobile number',
          'Tap "Issued Documents" to see land records, EC, or property docs',
          'Download any document and share as PDF',
          'Use to get official RTC or EC without visiting office',
        ];
      case GovPortal.bdaTax:
        return [
          'Login with property ID or owner mobile number',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select Bengaluru',
          'Check property tax payments and outstanding dues',
          'Verify: Is tax in seller\'s name? Dues cleared?',
        ];
      case GovPortal.bmrda:
        return [
          'Search your layout name or survey number',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select district',
          'Look for "Layout Approval" or "Regularisation" section',
          'Verify: Is the layout BMRDA-approved?',
          'No approval = illegal layout, bank will not give loan',
        ];
      case GovPortal.igrGuidance:
        return [
          'Select your district from the dropdown',
          if (dist != null && dist.isNotEmpty) 'COPY:District|$dist' else 'Select district',
          'Download the PDF for your taluk',
          'Find your village/area name in the PDF table',
          'Note the guideline value per sqft — this is the minimum stamp duty base',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // CERSAI blocks WebViews — show an info screen with "Open in Chrome" button
    if (widget.portal.requiresExternalBrowser) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: widget.portal.color,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.portal.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Text('Official Government Portal',
                  style: TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_browser, size: 72, color: widget.portal.color),
              const SizedBox(height: 20),
              Text(widget.portal.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'This government portal blocks in-app browsers.\nIt will open in Chrome automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.portal.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.portal.hint,
                  style: TextStyle(fontSize: 12, color: widget.portal.color),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInChrome,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open in Chrome'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.portal.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done — Back to App'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.portal.color,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.portal.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Text('Official Government Portal',
                style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          // Reload
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _controller.reload(),
          ),
          // Back/Forward
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () async {
              if (await _controller.canGoBack()) _controller.goBack();
            },
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: widget.portal.color,
                  color: Colors.white,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          // WebView
          WebViewWidget(controller: _controller),

          // Step-by-step hint banner
          if (_showHint)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  color: widget.portal.color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Numbered steps
                      _buildSteps(),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white70, size: 15),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.portal.hint,
                              style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4))),
                          GestureDetector(
                            onTap: () => setState(() => _showHint = false),
                            child: const Icon(Icons.close, color: Colors.white54, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom "Done" button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12),
                      blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Official site badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: widget.portal.color, size: 14),
                      const SizedBox(width: 4),
                      Text('You are on the official Government of Karnataka portal',
                          style: TextStyle(fontSize: 10, color: widget.portal.color,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showHint = true),
                        icon: const Icon(Icons.help_outline, size: 15),
                        label: const Text('What to enter', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: widget.portal.color,
                          side: BorderSide(color: widget.portal.color),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSubmissionCapture(context),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Done — Back to App',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Row widgets ─────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final Widget icon;
  final Color iconBg;
  final Widget child;
  const _StepRow({required this.icon, required this.iconBg, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Center(child: icon),
      ),
      const SizedBox(width: 6),
      Expanded(child: child),
    ]),
  );
}

class _CopyStepRow extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  const _CopyStepRow({required this.label, required this.value, required this.color});

  @override
  State<_CopyStepRow> createState() => _CopyStepRowState();
}

class _CopyStepRowState extends State<_CopyStepRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(children: [
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          color: _copied ? Colors.green[400] : Colors.orange[400],
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(
          _copied ? Icons.check : Icons.copy,
          size: 11, color: Colors.white,
        )),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(widget.value,
              style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
      GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.value));
          setState(() => _copied = true);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _copied = false);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _copied ? Colors.green[400] : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Text(
            _copied ? 'Copied!' : 'Copy',
            style: const TextStyle(color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ]),
  );
}

// ─── Portal Launcher — opens the right portal with context ───────────────────
class GovPortalLauncher {
  static Future<String?> open(
    BuildContext context,
    GovPortal portal, {
    String? surveyNumber,
    String? district,
    String? taluk,
    String? hobli,
    String? village,
  }) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => GovWebViewScreen(
          portal: portal,
          surveyNumber: surveyNumber,
          district: district,
          taluk: taluk,
          hobli: hobli,
          village: village,
        ),
      ),
    );
    if (result == null || result == false) return null;
    if (result is String) return result;
    return ''; // done but no reference number entered
  }
}
