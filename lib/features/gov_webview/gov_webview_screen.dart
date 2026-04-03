import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
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
    }
  }

  String get url {
    switch (this) {
      case GovPortal.bhoomi:
        // Root URL — /service1/ requires server-side login credentials
        return 'https://landrecords.karnataka.gov.in/';
      case GovPortal.kaveri:
        return 'https://kaverionline.karnataka.gov.in/';
      case GovPortal.rera:
        // Main RERA portal — /viewAllProjects needs JS session
        return 'https://rera.karnataka.gov.in/';
      case GovPortal.eCourts:
        // National eCourts services home
        return 'https://services.ecourts.gov.in/';
      case GovPortal.bbmp:
        return 'https://bbmptax.karnataka.gov.in/';
      case GovPortal.cersai:
        // CERSAI public search — /CERSAI/home.htm returns 404 externally
        return 'https://www.cersai.org.in/';
      case GovPortal.dishank:
        // dishank.karnataka.gov.in is discontinued — use SSLR Bhoomi sketch map
        return 'https://landrecords.karnataka.gov.in/service2/';
    }
  }

  String get hint {
    switch (this) {
      case GovPortal.bhoomi:
        return 'Search your property using Survey Number, District & Taluk. See the official RTC record, then tap Done.';
      case GovPortal.kaveri:
        return 'Search Encumbrance Certificate (EC) using property details. View loans/mortgages, then tap Done.';
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
    }
  }

  Color get color {
    switch (this) {
      case GovPortal.bhoomi:  return const Color(0xFF1B5E20);
      case GovPortal.kaveri:  return const Color(0xFF0D47A1);
      case GovPortal.rera:    return const Color(0xFF4A148C);
      case GovPortal.eCourts: return const Color(0xFFBF360C);
      case GovPortal.bbmp:    return const Color(0xFF004D40);
      case GovPortal.cersai:  return const Color(0xFF37474F);
      case GovPortal.dishank: return const Color(0xFF1565C0);
    }
  }
}

class GovWebViewScreen extends StatefulWidget {
  final GovPortal portal;
  final String? surveyNumber;
  final String? district;
  final String? taluk;

  const GovWebViewScreen({
    super.key,
    required this.portal,
    this.surveyNumber,
    this.district,
    this.taluk,
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
    _initWebView();
    // Auto-hide hint after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() { _isLoading = true; _loadingProgress = 0; }),
        onProgress: (p) => setState(() => _loadingProgress = p),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (error) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(widget.portal.url));
  }

  @override
  Widget build(BuildContext context) {
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

          // Hint banner with property details
          if (_showHint)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Material(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  color: widget.portal.color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Property details to search
                      if (widget.surveyNumber != null || widget.district != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            const Icon(Icons.search, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Expanded(child: Text(
                              'Enter: ${widget.surveyNumber != null ? "Survey No ${widget.surveyNumber}" : ""}${widget.district != null ? " · ${widget.district}" : ""}${widget.taluk != null ? " · ${widget.taluk}" : ""}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            )),
                          ]),
                        ),
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
                        onPressed: () => context.pop(true),
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

// ─── Portal Launcher — opens the right portal with context ───────────────────
class GovPortalLauncher {
  static Future<bool> open(
    BuildContext context,
    GovPortal portal, {
    String? surveyNumber,
    String? district,
    String? taluk,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GovWebViewScreen(
          portal: portal,
          surveyNumber: surveyNumber,
          district: district,
          taluk: taluk,
        ),
      ),
    );
    return result ?? false;
  }
}
