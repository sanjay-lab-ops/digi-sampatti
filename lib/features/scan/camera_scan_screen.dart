import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/camera_service.dart';
import 'package:digi_sampatti/core/services/gps_service.dart';
import 'package:digi_sampatti/core/services/gps_lookup_service.dart';
import 'package:digi_sampatti/core/services/ocr_service.dart';

class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen> {
  final _cameraService = CameraService();
  final _gpsService = GpsService();
  final _ocrService = OcrService();
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isRunningOcr = false;
  bool _isGpsLookup = false;        // true when doing GPS→survey lookup
  bool _scanMode = false;           // false=document OCR, true=GPS site scan
  GpsLocation? _currentLocation;
  String? _captureError;
  OcrResult? _ocrResult;
  GpsLookupResult? _gpsResult;

  @override
  void initState() {
    super.initState();
    _initialize();
    _ocrService.initialize();
  }

  Future<void> _initialize() async {
    final cameraOk = await _cameraService.initializeCamera();
    final location = await _gpsService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _isInitialized = cameraOk;
        _currentLocation = location;
      });
      ref.read(currentLocationProvider.notifier).state = location;
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isInitialized) return;
    setState(() { _isCapturing = true; _captureError = null; });

    try {
      final photoPath = await _cameraService.takePicture();
      if (photoPath == null) {
        setState(() { _captureError = 'Failed to capture photo'; });
        return;
      }

      // Refresh GPS at time of capture
      final freshLocation = await _gpsService.getCurrentLocation();
      final location = freshLocation ?? _currentLocation;

      // Run OCR in background while showing preview
      setState(() { _isRunningOcr = true; });
      OcrResult ocrResult = const OcrResult();
      _ocrService.extractFromDocument(photoPath).then((result) {
        if (mounted) setState(() { _ocrResult = result; _isRunningOcr = false; });
      });

      final scan = PropertyScan(
        id: const Uuid().v4(),
        photoPath: photoPath,
        location: location,
        scanMethod: ScanMethod.camera,
        scannedAt: DateTime.now(),
        // Pre-fill from OCR if available
        surveyNumber: ocrResult.surveyNumber,
      );

      ref.read(currentScanProvider.notifier).state = scan;
      ref.read(propertyCheckNotifierProvider.notifier).setScan(scan);

      if (mounted) {
        // Show GPS-stamped preview with OCR result + Dishank option
        await _showPhotoPreview(context, photoPath, location, scan);
      }
    } finally {
      if (mounted) setState(() { _isCapturing = false; });
    }
  }

  // ── GPS Site Scan ────────────────────────────────────────────────────────
  Future<void> _doGpsLookup() async {
    final loc = _currentLocation;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS not available — move to open area')));
      return;
    }
    setState(() { _isGpsLookup = true; _gpsResult = null; });
    final result = await GpsLookupService().lookup(loc.latitude, loc.longitude);
    if (!mounted) return;
    setState(() { _isGpsLookup = false; _gpsResult = result; });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not identify property — try entering details manually')));
      return;
    }

    // Navigate to manual search with GPS data pre-filled
    context.push('/scan/manual', extra: {
      'fromCamera': true,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'address': loc.address,
      'ocrDistrict': result.district,
      'ocrTaluk': result.taluk,
      'ocrVillage': result.village,
      'ocrSurveyNumber': result.surveyNumber,
      'source': 'gps_dishank',
    });
  }

  Widget _modeTab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : Colors.white60),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.white60)),
          ],
        ),
      ),
    );
  }

  Future<void> _showPhotoPreview(
      BuildContext context, String photoPath, GpsLocation? location, PropertyScan scan) async {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoPreviewSheet(
        photoPath: photoPath,
        location: location,
        dateStr: dateStr,
        onContinue: () {
          Navigator.pop(context);
          context.push('/scan/manual', extra: {
            'fromCamera': true,
            'latitude': location?.latitude,
            'longitude': location?.longitude,
            'address': location?.address,
            'photoPath': photoPath,
            // Pass OCR results so manual_search can pre-fill the form
            'ocrSurveyNumber': _ocrResult?.surveyNumber,
            'ocrOwnerName': _ocrResult?.ownerName,
            'ocrTaluk': _ocrResult?.taluk,
            'ocrDistrict': _ocrResult?.district,
            'ocrDocumentType': _ocrResult?.documentType,
            'ocrConfidence': _ocrResult?.confidence,
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan Property', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_isInitialized && _cameraService.controller != null)
            CameraPreview(_cameraService.controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // GPS Overlay
          Positioned(
            top: 16, left: 16, right: 16,
            child: _GpsOverlay(location: _currentLocation),
          ),

          // OCR status overlay (shown while reading document)
          if (_isRunningOcr)
            Positioned(
              top: 70, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.greenAccent,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reading document...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // OCR result banner (shown after OCR completes with data)
          if (!_isRunningOcr && _ocrResult != null && _ocrResult!.hasUsefulData)
            Positioned(
              top: 70, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Icon(Icons.auto_fix_high,
                          color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      const Text('Document scanned',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ]),
                    if (_ocrResult!.surveyNumber != null)
                      Text('Survey No: ${_ocrResult!.surveyNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    if (_ocrResult!.ownerName != null)
                      Text('Owner: ${_ocrResult!.ownerName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ),

          // Mode toggle — Document OCR vs GPS Site Scan
          Positioned(
            top: 120, left: 0, right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeTab(label: 'Scan Document', icon: Icons.document_scanner,
                        active: !_scanMode, onTap: () => setState(() => _scanMode = false)),
                    _modeTab(label: 'Scan Site', icon: Icons.place,
                        active: _scanMode, onTap: () => setState(() => _scanMode = true)),
                  ],
                ),
              ),
            ),
          ),

          // GPS lookup result banner
          if (_isGpsLookup)
            Positioned(
              top: 170, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent)),
                    SizedBox(width: 10),
                    Text('Looking up property at your location...',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),

          if (!_isGpsLookup && _gpsResult != null && _gpsResult!.hasPartialData)
            Positioned(
              top: 170, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(children: [
                      Icon(Icons.location_on, color: Colors.greenAccent, size: 14),
                      SizedBox(width: 5),
                      Text('Property identified', style: TextStyle(
                          color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                    if (_gpsResult!.district != null)
                      Text('${_gpsResult!.district}  ›  ${_gpsResult!.taluk ?? ""}  ›  ${_gpsResult!.village ?? ""}',
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    if (_gpsResult!.surveyNumber != null)
                      Text('Survey No: ${_gpsResult!.surveyNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    if (_gpsResult!.surveyNumber == null)
                      const Text('Survey number not found — check Dishank manually',
                          style: TextStyle(color: Colors.orange, fontSize: 10)),
                  ],
                ),
              ),
            ),

          // Capture Grid Lines
          CustomPaint(
            painter: _GridPainter(),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _CaptureControls(
              isCapturing: _isCapturing || _isGpsLookup,
              location: _currentLocation,
              error: _captureError,
              scanMode: _scanMode,
              onCapture: _scanMode ? _doGpsLookup : _capturePhoto,
              onGallery: () async {
                final path = await _cameraService.pickFromGallery();
                if (path != null && mounted) {
                  final scan = PropertyScan(
                    id: const Uuid().v4(),
                    photoPath: path,
                    location: _currentLocation,
                    scanMethod: ScanMethod.camera,
                    scannedAt: DateTime.now(),
                  );
                  ref.read(currentScanProvider.notifier).state = scan;
                  context.push('/scan/manual');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GPS Overlay ───────────────────────────────────────────────────────────────
class _GpsOverlay extends StatelessWidget {
  final GpsLocation? location;
  const _GpsOverlay({this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            location != null ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: location != null ? Colors.greenAccent : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location != null
                  ? location!.coordinatesString
                  : 'Acquiring GPS...',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (location != null)
            Text(
              '±${location!.accuracy.toStringAsFixed(0)}m',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

// ─── Capture Controls ──────────────────────────────────────────────────────────
class _CaptureControls extends StatelessWidget {
  final bool isCapturing;
  final GpsLocation? location;
  final String? error;
  final bool scanMode; // false=document, true=GPS site
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  const _CaptureControls({
    required this.isCapturing, required this.location,
    required this.error, required this.onCapture, required this.onGallery,
    this.scanMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          Text(
            scanMode
                ? 'Stand at the property. Tap to identify survey number via GPS.'
                : 'Point camera at RTC / sale deed to scan. GPS will be captured.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
              ),
              GestureDetector(
                onTap: isCapturing ? null : onCapture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: isCapturing ? Colors.grey : Colors.white,
                  ),
                  child: isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(scanMode ? Icons.my_location : Icons.camera_alt,
                          color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Photo Preview Sheet ───────────────────────────────────────────────────────
class _PhotoPreviewSheet extends StatelessWidget {
  final String photoPath;
  final GpsLocation? location;
  final String dateStr;
  final VoidCallback onContinue;

  const _PhotoPreviewSheet({
    required this.photoPath, required this.location,
    required this.dateStr, required this.onContinue,
  });

  Future<void> _openDishank() async {
    // Try Dishank app first, fall back to Play Store
    final appUri = Uri.parse('intent://open#Intent;package=in.ksrsac.dishank;scheme=dishank;end');
    final playUri = Uri.parse('https://play.google.com/store/apps/details?id=in.ksrsac.dishank');
    if (!await launchUrl(appUri, mode: LaunchMode.externalApplication)) {
      await launchUrl(playUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),

          // GPS-stamped photo
          Expanded(
            child: Stack(
              children: [
                // Photo
                SizedBox.expand(
                  child: Image.file(File(photoPath), fit: BoxFit.cover),
                ),

                // GPS stamp overlay — bottom left (like GPS Map Camera)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: Colors.black.withOpacity(0.65),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // DigiSampatti brand
                        Row(children: [
                          const Icon(Icons.verified_user, color: Color(0xFF4CAF50), size: 14),
                          const SizedBox(width: 4),
                          const Text('DigiSampatti',
                              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(dateStr,
                              style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ]),
                        const SizedBox(height: 4),
                        if (location != null) ...[
                          Text(
                            'Lat ${location!.latitude.toStringAsFixed(6)}°  Long ${location!.longitude.toStringAsFixed(6)}°',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                          ),
                          if (location!.address != null && location!.address!.isNotEmpty)
                            Text(
                              location!.address!,
                              style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ] else
                          const Text('GPS not available',
                              style: TextStyle(color: Colors.orange, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                // Dishank tip
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Don\'t know the survey number? Open Dishank — tap your plot on the map to get it.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                        ),
                      ),
                      TextButton(
                        onPressed: _openDishank,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Open\nDishank', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue — Enter Survey No.'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid Lines Painter ────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
