import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Opens a hidden WebView on the user's device that navigates Bhoomi's
/// ASP.NET form automatically. The user's carrier IP (Jio/Airtel/BSNL) is
/// not blocked by Bhoomi — only Railway's cloud IP is.
///
/// Usage:
///   final result = await Navigator.push<Map<String, dynamic>?>(context,
///     MaterialPageRoute(builder: (_) => BhoomiDeviceScraperScreen(
///       district: 'Bengaluru Urban', taluk: 'Bengaluru North',
///       hobli: 'Kasaba', village: 'Karivobinahalli', surveyNumber: '123',
///     )));
class BhoomiDeviceScraperScreen extends StatefulWidget {
  final String district;
  final String taluk;
  final String hobli;
  final String village;
  final String surveyNumber;

  const BhoomiDeviceScraperScreen({
    super.key,
    required this.district,
    required this.taluk,
    required this.hobli,
    required this.village,
    required this.surveyNumber,
  });

  @override
  State<BhoomiDeviceScraperScreen> createState() =>
      _BhoomiDeviceScraperScreenState();
}

enum _Step {
  loading,
  connecting,
  selectingDistrict,
  selectingTaluk,
  selectingHobli,
  selectingVillage,
  fetchingDetails,
  parsing,
  done,
  manual, // user fills the form manually in visible WebView
  error,
}

class _BhoomiDeviceScraperScreenState
    extends State<BhoomiDeviceScraperScreen> {
  late final WebViewController _wvc;
  _Step _step = _Step.loading;
  String? _errorMsg;
  bool _initialPageLoaded = false;
  bool _resultPageLoaded = false;

  static const _backendBase =
      'https://digi-sampatti-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('BC', onMessageReceived: _onMsg)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: _onPageFinished,
        onWebResourceError: (e) {
          if (e.isForMainFrame == true) _fail('Portal load failed: ${e.description}');
        },
      ))
      ..loadRequest(
          Uri.parse('https://landrecords.karnataka.gov.in/Service2'));
  }

  // ── Navigation events ──────────────────────────────────────────────────────

  void _onPageFinished(String url) {
    if (!_initialPageLoaded && url.contains('landrecords.karnataka.gov.in')) {
      _initialPageLoaded = true;
      _setStep(_Step.connecting);
      Future.delayed(const Duration(seconds: 2), _selectDistrict);
      return;
    }
    // After FetchDetails opens a popup URL in the same WebView
    if (_step == _Step.fetchingDetails && !_resultPageLoaded) {
      _resultPageLoaded = true;
      Future.delayed(const Duration(seconds: 1), _captureHtml);
    }
  }

  // ── JS → Dart message handler ──────────────────────────────────────────────

  void _onMsg(JavaScriptMessage msg) {
    final Map<String, dynamic> d;
    try {
      d = jsonDecode(msg.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final event = d['event'] as String? ?? '';
    switch (event) {
      case 'taluk_loaded':
        _pickTaluk(d['opts'] as List);
        break;
      case 'hobli_loaded':
        _pickHobli(d['opts'] as List);
        break;
      case 'village_loaded':
        _pickVillage(d['opts'] as List);
        break;
      case 'survey_ready':
        _clickGo();
        break;
      case 'surnoc_loaded':
        _pickSurnoc();
        break;
      case 'hissa_loaded':
        _clickFetch();
        break;
      case 'html':
        _parseHtml(d['v'] as String);
        break;
      case 'manual':
        // Auto-fill failed — show the real Bhoomi page so user can fill manually
        _switchToManual();
        break;
      case 'err':
        _fail(d['msg'] as String? ?? 'Unknown error at step ${d['step']}');
        break;
    }
  }

  // ── Step helpers ───────────────────────────────────────────────────────────

  void _setStep(_Step s) => mounted ? setState(() => _step = s) : null;

  // Switch to manual mode instead of failing — show the WebView to user
  void _switchToManual() {
    if (mounted) setState(() => _step = _Step.manual);
  }

  void _fail(String msg) {
    if (mounted) setState(() { _step = _Step.error; _errorMsg = msg; });
  }

  void _js(String code) => _wvc.runJavaScript(code);

  // Poll helper injected into the page: waits for an element to have > 1 option,
  // then fires BC.postMessage with the event name and options list.
  String _pollScript(String selId, String eventName, {int maxTries = 24}) => '''
(function(){
  var tries=0;
  function poll(){
    var el=document.getElementById('$selId');
    if(el&&el.options.length>1){
      var opts=Array.from(el.options).map(function(o){return{v:o.value,t:o.text};});
      BC.postMessage(JSON.stringify({event:'$eventName',opts:opts}));
    } else if(++tries<$maxTries){
      setTimeout(poll,500);
    } else {
      BC.postMessage(JSON.stringify({event:'$eventName',opts:[]}));
    }
  }
  setTimeout(poll,800);
})();
''';

  // ── Form steps ─────────────────────────────────────────────────────────────

  // Bhoomi uses inconsistent district names — hardcoded map from app label → portal label
  static const _districtMap = {
    'bengaluru urban': 'BENGALURU',
    'bangalore urban': 'BENGALURU',
    'bengaluru rural': 'Bangalore Rural',
    'bangalore rural': 'Bangalore Rural',
    'bengaluru south': 'Bengaluru South',
    'mysuru': 'Mysore',
    'belagavi': 'Belagavi',
  };

  // Bhoomi taluk exact labels as they appear in the portal dropdown
  // Verified from landrecords.karnataka.gov.in — use these for exact match
  static const _talukMap = {
    'bengaluru north': 'BANGALORE NORTH',
    'bangalore north': 'BANGALORE NORTH',
    'bengaluru south': 'BANGALORE SOUTH',
    'bangalore south': 'BANGALORE SOUTH',
    'bengaluru east': 'BANGALORE EAST',
    'bangalore east': 'BANGALORE EAST',
    'anekal': 'ANEKAL',
    'yelahanka': 'YALAHANKA',
    'yalahanka': 'YALAHANKA',
  };

  void _selectDistrict() {
    _setStep(_Step.selectingDistrict);
    final distKey = widget.district.toLowerCase();
    final distLabel = _districtMap[distKey] ?? widget.district.toUpperCase();
    // Also try keyword fallback
    final keywords = (distLabel.contains('BENGALURU') || distLabel.contains('BANGALORE') ||
            distKey.contains('bengaluru') || distKey.contains('bangalore'))
        ? ['BENGALURU', 'BANGALORE']
        : [distLabel.toUpperCase()];
    final kJson = jsonEncode(keywords);
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCDistrict');
  if(!sel){BC.postMessage(JSON.stringify({event:'manual',reason:'District dropdown not found'}));return;}
  var opts=Array.from(sel.options);
  var kw=$kJson;
  var label='${distLabel.replaceAll("'", "\\'")}';
  // Try exact label match first (e.g. "BENGALURU")
  var t=opts.find(function(o){return o.text.trim()===label;});
  // Then keyword match
  if(!t) for(var k of kw){ t=opts.find(function(o){return o.text.toUpperCase().includes(k);}); if(t)break; }
  if(!t){BC.postMessage(JSON.stringify({event:'manual',reason:'District not found: ${widget.district}'}));return;}
  sel.value=t.value;
  sel.dispatchEvent(new Event('change',{bubbles:true}));
  try{__doPostBack('ctl00\$MainContent\$ddlCDistrict','');}catch(e){}
  ${_pollScript('ctl00_MainContent_ddlCTaluk', 'taluk_loaded', maxTries: 40)}
})();
''');
  }

  void _pickTaluk(List opts) {
    _setStep(_Step.selectingTaluk);
    if (opts.isEmpty) { _switchToManual(); return; }

    // Use hardcoded map — exact Bhoomi labels verified from portal
    final talukKey = widget.taluk.toLowerCase();
    final talukLabel = (_talukMap[talukKey] ?? widget.taluk).toUpperCase();
    final label = talukLabel.replaceAll("'", "\\'");
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCTaluk');
  if(!sel){BC.postMessage(JSON.stringify({event:'manual',reason:'no taluk dropdown'}));return;}
  var opts=Array.from(sel.options);
  // 1. Exact match on verified label (e.g. "BANGALORE NORTH")
  var t=opts.find(function(o){return o.text.trim().toUpperCase()==='$label';});
  // 2. Keyword match: skip "(Additional)" options — they are sub-taluk rows
  if(!t){
    var dir='$label'.replace(/BANGALORE|BENGALURU/g,'').replace(/[\\s-]+/g,' ').trim();
    t=opts.find(function(o){
      var txt=o.text.trim().toUpperCase();
      return txt.includes(dir) && !txt.includes('ADDITIONAL');
    });
  }
  // 3. Last resort: includes match (may hit Additional — better than nothing)
  if(!t){
    var dir2='$label'.replace(/BANGALORE|BENGALURU/g,'').replace(/[\\s-]+/g,' ').trim();
    t=opts.find(function(o){return o.text.trim().toUpperCase().includes(dir2);});
  }
  if(!t){BC.postMessage(JSON.stringify({event:'manual',reason:'taluk not found: ${widget.taluk}'}));return;}
  sel.value=t.value;
  sel.dispatchEvent(new Event('change',{bubbles:true}));
  try{__doPostBack('ctl00\$MainContent\$ddlCTaluk','');}catch(e){}
  ${_pollScript('ctl00_MainContent_ddlCHobli', 'hobli_loaded', maxTries: 40)}
})();
''');
  }

  void _pickHobli(List opts) {
    _setStep(_Step.selectingHobli);
    if (opts.isEmpty) { _switchToManual(); return; }
    // Bhoomi hobli names have no spaces: "DASANAPURA3", "KASABA1", "YASHAVANTAPURA1"
    // App hobli names have spaces: "Dasanapura 3", "Kasaba 1"
    // Match by stripping spaces from both sides
    final hobliNorm = widget.hobli.toUpperCase().replaceAll(' ', '').replaceAll("'", "\\'");
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCHobli');
  if(!sel){BC.postMessage(JSON.stringify({event:'manual',reason:'no hobli dropdown'}));return;}
  var opts=Array.from(sel.options);
  var norm='$hobliNorm';
  // Match by stripping spaces (DASANAPURA3 matches "Dasanapura 3")
  var t=opts.find(function(o){return o.text.toUpperCase().replace(/\\s/g,'')===norm;});
  // Fallback: contains match
  if(!t) t=opts.find(function(o){return norm.includes(o.text.toUpperCase().replace(/\\s/g,'')) || o.text.toUpperCase().replace(/\\s/g,'').includes(norm);});
  // Last fallback: pick first non-select option
  if(!t&&opts.length>1) t=opts[1];
  if(t){
    sel.value=t.value;
    sel.dispatchEvent(new Event('change',{bubbles:true}));
    try{__doPostBack('ctl00\$MainContent\$ddlCHobli','');}catch(e){}
  }
  ${_pollScript('ctl00_MainContent_ddlCVillage', 'village_loaded', maxTries: 40)}
})();
''');
  }

  void _pickVillage(List opts) {
    _setStep(_Step.selectingVillage);
    if (opts.isEmpty) { _switchToManual(); return; }
    final village = widget.village.toUpperCase().replaceAll("'", r"\'");
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCVillage');
  var opts=Array.from(sel.options);
  var t=opts.find(function(o){return o.text.toUpperCase().includes('$village');});
  if(!t){BC.postMessage(JSON.stringify({event:'manual',reason:'village not found: ${widget.village}'}));return;}
  sel.value=t.value;
  sel.dispatchEvent(new Event('change',{bubbles:true}));
  try{__doPostBack('ctl00\$MainContent\$ddlCVillage','');}catch(e){}
  setTimeout(function(){
    var inp=document.getElementById('ctl00_MainContent_txtCSurveyNo');
    if(inp){
      inp.value='${widget.surveyNumber}';
      inp.dispatchEvent(new Event('change',{bubbles:true}));
      BC.postMessage(JSON.stringify({event:'survey_ready'}));
    } else {
      BC.postMessage(JSON.stringify({event:'err',step:'survey',msg:'Survey input not found'}));
    }
  },1000);
})();
''');
  }

  void _clickGo() {
    _setStep(_Step.fetchingDetails);
    _js('''
(function(){
  var btn=document.getElementById('ctl00_MainContent_btnCGo');
  if(!btn){BC.postMessage(JSON.stringify({event:'err',step:'go',msg:'Go button not found'}));return;}
  btn.click();
  ${_pollScript('ctl00_MainContent_ddlCSurnocNo', 'surnoc_loaded', maxTries: 20)}
})();
''');
  }

  void _pickSurnoc() {
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCSurnocNo');
  if(sel&&sel.options.length>1){
    sel.value=sel.options[1].value;
    sel.dispatchEvent(new Event('change',{bubbles:true}));
    try{__doPostBack('ctl00\$MainContent\$ddlCSurnocNo','');}catch(e){}
  }
  ${_pollScript('ctl00_MainContent_ddlCHissaNo', 'hissa_loaded', maxTries: 20)}
})();
''');
  }

  void _clickFetch() {
    // Override window.open so popup loads in current WebView page
    _js('''
(function(){
  window.open=function(url){window.location.href=url;return window;};
  var sel=document.getElementById('ctl00_MainContent_ddlCHissaNo');
  if(sel&&sel.options.length>1){
    sel.value=sel.options[1].value;
    sel.dispatchEvent(new Event('change',{bubbles:true}));
    try{__doPostBack('ctl00\$MainContent\$ddlCHissaNo','');}catch(e){}
  }
  setTimeout(function(){
    var btn=document.getElementById('ctl00_MainContent_btnCFetchDetails');
    if(btn&&!btn.disabled){ btn.click(); }
    else {
      // No FetchDetails button — capture current page directly
      var h=document.documentElement.outerHTML;
      BC.postMessage(JSON.stringify({event:'html',v:h}));
    }
  },1200);
})();
''');
  }

  void _captureHtml() {
    _js('''
(function(){
  var h=document.documentElement.outerHTML;
  BC.postMessage(JSON.stringify({event:'html',v:h}));
})();
''');
  }

  Future<void> _parseHtml(String html) async {
    _setStep(_Step.parsing);
    try {
      final res = await http.post(
        Uri.parse('$_backendBase/parse-rtc-html'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'html': html,
          'district': widget.district,
          'taluk': widget.taluk,
          'hobli': widget.hobli,
          'village': widget.village,
          'survey_number': widget.surveyNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) Navigator.of(context).pop(result);
      } else {
        _fail('Backend parse error ${res.statusCode}');
      }
    } catch (e) {
      _fail('Network error: $e');
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isManual = _step == _Step.manual;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(isManual ? 'Bhoomi — Fill & Capture' : 'Fetching from Bhoomi'),
        automaticallyImplyLeading: false,
        actions: isManual
            ? [
                TextButton.icon(
                  onPressed: _captureHtml,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Capture', style: TextStyle(color: Colors.white)),
                ),
              ]
            : null,
      ),
      body: isManual ? _buildManual() : Stack(
        children: [
          // Hidden WebView — doing the actual form interaction
          WebViewWidget(controller: _wvc),
          // Full overlay so user never sees raw Bhoomi page
          Container(
            color: Colors.white,
            child: _step == _Step.error ? _buildError() : _buildLoading(),
          ),
        ],
      ),
    );
  }

  Widget _buildManual() {
    return Column(
      children: [
        Container(
          color: Colors.orange.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-fill failed. Navigate to Survey ${widget.surveyNumber} manually, '
                  'then tap "Capture" (top right) to read the data.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: WebViewWidget(controller: _wvc)),
      ],
    );
  }

  Widget _buildLoading() {
    final steps = [
      (_Step.connecting, 'Connect to Bhoomi portal'),
      (_Step.selectingDistrict, 'Select district'),
      (_Step.selectingTaluk, 'Select taluk'),
      (_Step.selectingHobli, 'Select hobli'),
      (_Step.selectingVillage, 'Select village'),
      (_Step.fetchingDetails, 'Fetch RTC record'),
      (_Step.parsing, 'Extract & read data'),
    ];
    final currentIdx = _Step.values.indexOf(_step);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'Fetching RTC from Bhoomi',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Using your phone\'s internet connection\nto access the government portal directly',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: currentIdx > 0
                  ? currentIdx / (steps.length + 1)
                  : null,
              backgroundColor: Colors.grey[200],
              valueColor:
                  AlwaysStoppedAnimation(AppColors.primaryLight),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 32),
          ...steps.map((s) {
            final sIdx = _Step.values.indexOf(s.$1);
            final done = currentIdx > sIdx;
            final active = currentIdx == sIdx;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle
                        : active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    color: done
                        ? AppColors.primary
                        : active
                            ? AppColors.primaryLight
                            : Colors.grey[300],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s.$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: done || active
                          ? AppColors.primary
                          : Colors.grey[400],
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 24),
          const Text(
            'Could not fetch from Bhoomi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMsg ?? 'Unknown error',
              style: TextStyle(fontSize: 12, color: Colors.orange[900]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This can happen if Bhoomi portal is temporarily down,\nor the survey number / location details don\'t match\ntheir records exactly.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Go Back',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
