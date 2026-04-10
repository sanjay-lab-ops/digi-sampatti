import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

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

  /// Maps user-facing taluk names (lowercase) → exact text in Bhoomi dropdown.
  /// Without this, "North" matches "Bangalore North(Additional)" before
  /// "BENGALURU-NORTH" because it appears first in the option list.
  static const _talukToBhoomi = {
    'bengaluru north':        'BENGALURU-NORTH',
    'bangalore north':        'BENGALURU-NORTH',
    'bengaluru-north':        'BENGALURU-NORTH',
    'bangalore-north':        'BENGALURU-NORTH',
    'bengaluru south':        'BENGALURU-South',
    'bangalore south':        'BENGALURU-South',
    'bengaluru east':         'BENGALURU-East',
    'bangalore east':         'BENGALURU-East',
    'yalahanka':              'YALAHANKA',
    'anekal':                 'Anekal',
    'bangalore north additional': 'Bangalore North(Additional)',
    'bengaluru north additional': 'Bangalore North(Additional)',
  };

  /// Returns the exact Bhoomi dropdown text for this taluk, or null if unknown.
  String? _bhoomiTaluk() {
    final key = widget.taluk.toLowerCase().trim();
    for (final entry in _talukToBhoomi.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

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
          Uri.parse('https://landrecords.karnataka.gov.in/service2/forM16A.aspx'));
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
      case 'err':
        _fail(d['msg'] as String? ?? 'Unknown error at step ${d['step']}');
        break;
    }
  }

  // ── Step helpers ───────────────────────────────────────────────────────────

  void _setStep(_Step s) => mounted ? setState(() => _step = s) : null;

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

  void _selectDistrict() {
    _setStep(_Step.selectingDistrict);
    final dist = widget.district.toUpperCase();
    final keywords = (dist.contains('BENGALURU') || dist.contains('BANGALORE'))
        ? ['BANGALORE', 'BENGALURU']
        : [dist];
    final kJson = jsonEncode(keywords);
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCDistrict');
  if(!sel){BC.postMessage(JSON.stringify({event:'err',step:'district',msg:'District dropdown not found'}));return;}
  var opts=Array.from(sel.options);
  var kw=$kJson;
  var t=null;
  for(var k of kw){ t=opts.find(function(o){return o.text.toUpperCase().includes(k);}); if(t)break; }
  if(!t){BC.postMessage(JSON.stringify({event:'err',step:'district',msg:'Not found: ${widget.district}',avail:opts.map(function(o){return o.text;})}));return;}
  sel.value=t.value;
  sel.dispatchEvent(new Event('change',{bubbles:true}));
  try{__doPostBack('ctl00\$MainContent\$ddlCDistrict','');}catch(e){}
  ${_pollScript('ctl00_MainContent_ddlCTaluk', 'taluk_loaded')}
})();
''');
  }

  void _pickTaluk(List opts) {
    _setStep(_Step.selectingTaluk);
    // Try exact map first — avoids "Bangalore North(Additional)" false match
    final exactBhoomi = _bhoomiTaluk();
    final String matchScript;
    if (exactBhoomi != null) {
      // Exact text match then fallback to partial
      final escaped = exactBhoomi.replaceAll("'", r"\'");
      matchScript = '''
  var t=opts.find(function(o){return o.text==='$escaped';});
  if(!t) t=opts.find(function(o){return o.text.toUpperCase()==='${exactBhoomi.toUpperCase()}';});
  if(!t) t=opts.find(function(o){return o.text.toUpperCase().includes('${exactBhoomi.toUpperCase().replaceAll('-', '').replaceAll(' ', '')}');});
''';
    } else {
      // Keyword fallback for unmapped taluks
      final taluk = widget.taluk.toUpperCase();
      final kws = taluk
          .replaceAll('BENGALURU', '').replaceAll('BANGALORE', '').trim()
          .split(' ').where((w) => w.length > 2).toList();
      final kJson = jsonEncode(kws.isEmpty ? [taluk] : kws);
      matchScript = '''
  var kw=$kJson;
  var t=opts.find(function(o){return kw.every(function(k){return o.text.toUpperCase().includes(k);});});
  if(!t) t=opts.find(function(o){return o.text.toUpperCase().includes(kw[0]);});
''';
    }
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCTaluk');
  if(!sel){BC.postMessage(JSON.stringify({event:'err',step:'taluk',msg:'Taluk dropdown not found'}));return;}
  var opts=Array.from(sel.options);
  $matchScript
  if(!t){BC.postMessage(JSON.stringify({event:'err',step:'taluk',msg:'Not found: ${widget.taluk}',avail:opts.map(function(o){return o.text;})}));return;}
  sel.value=t.value;
  sel.dispatchEvent(new Event('change',{bubbles:true}));
  try{__doPostBack('ctl00\$MainContent\$ddlCTaluk','');}catch(e){}
  ${_pollScript('ctl00_MainContent_ddlCHobli', 'hobli_loaded')}
})();
''');
  }

  void _pickHobli(List opts) {
    _setStep(_Step.selectingHobli);
    final hobli = widget.hobli.toUpperCase().replaceAll("'", r"\'");
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCHobli');
  var opts=Array.from(sel.options);
  var t=opts.find(function(o){return o.text.toUpperCase().includes('$hobli');});
  if(!t&&opts.length>1) t=opts[1];
  if(t){
    sel.value=t.value;
    sel.dispatchEvent(new Event('change',{bubbles:true}));
    try{__doPostBack('ctl00\$MainContent\$ddlCHobli','');}catch(e){}
  }
  ${_pollScript('ctl00_MainContent_ddlCVillage', 'village_loaded')}
})();
''');
  }

  void _pickVillage(List opts) {
    _setStep(_Step.selectingVillage);
    final village = widget.village.toUpperCase().replaceAll("'", r"\'");
    _js('''
(function(){
  var sel=document.getElementById('ctl00_MainContent_ddlCVillage');
  var opts=Array.from(sel.options);
  var t=opts.find(function(o){return o.text.toUpperCase().includes('$village');});
  if(!t){BC.postMessage(JSON.stringify({event:'err',step:'village',msg:'Not found: ${widget.village}',avail:opts.map(function(o){return o.text;})}));return;}
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Fetching from Bhoomi'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
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

  Widget _buildLoading() {
    final steps = [
      (_Step.connecting, 'Connect to Bhoomi portal'),
      (_Step.selectingDistrict, 'Select district'),
      (_Step.selectingTaluk, 'Select taluk'),
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
          const Icon(Icons.account_balance, size: 64, color: Color(0xFF1B5E20)),
          const SizedBox(height: 24),
          const Text(
            'Fetching RTC from Bhoomi',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20)),
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
                  const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
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
                        ? const Color(0xFF1B5E20)
                        : active
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[300],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    s.$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: done || active
                          ? const Color(0xFF1B5E20)
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
                backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Go Back',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
