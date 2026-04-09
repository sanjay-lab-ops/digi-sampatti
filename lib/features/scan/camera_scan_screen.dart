import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/camera_service.dart';
import 'package:digi_sampatti/core/services/gps_service.dart';
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
  GpsLocation? _currentLocation;
  String? _captureError;

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

      // Await OCR so survey number is available before showing preview
      setState(() { _isRunningOcr = true; });
      OcrResult ocrResult;
      try {
        ocrResult = await _ocrService.extractFromDocument(photoPath);
      } catch (e) {
        ocrResult = const OcrResult();
      }
      if (mounted) setState(() { _isRunningOcr = false; });

      final scan = PropertyScan(
        id: const Uuid().v4(),
        photoPath: photoPath,
        location: location,
        scanMethod: ScanMethod.camera,
        scannedAt: DateTime.now(),
        surveyNumber: ocrResult.surveyNumber,
      );

      ref.read(currentScanProvider.notifier).state = scan;
      ref.read(propertyCheckNotifierProvider.notifier).setScan(scan);

      if (mounted) {
        if (ocrResult.isBuilding) {
          // Building detected — show block selector first
          await _showBuildingBlockPicker(context, photoPath, location, ocrResult);
        } else {
          // Document detected — show GPS-stamped preview
          await _showPhotoPreview(context, photoPath, location, scan, ocrResult);
        }
      }
    } finally {
      if (mounted) setState(() { _isCapturing = false; });
    }
  }

  // ── Building Block Picker ─────────────────────────────────────────────────
  Future<void> _showBuildingBlockPicker(
      BuildContext context, String photoPath, GpsLocation? location, OcrResult ocrResult) async {
    String? selectedBlock;
    String? selectedFlat;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final blocks = ocrResult.visibleBlocks;
          final flats  = ocrResult.visibleFlats;
          final hasBlocks = blocks.isNotEmpty;
          final hasFlats  = flats.isNotEmpty;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),

                // Building name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.apartment, color: Colors.greenAccent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        ocrResult.buildingName ?? 'Building Detected',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (ocrResult.buildingAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(ocrResult.buildingAddress!,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                              textAlign: TextAlign.center),
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select your block / flat to check property details',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Block selector
                        if (hasBlocks) ...[
                          const Text('Select Block / Tower / Wing',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: blocks.map((b) => GestureDetector(
                              onTap: () => setModalState(() { selectedBlock = b; selectedFlat = null; }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedBlock == b ? AppColors.primary : Colors.white12,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedBlock == b ? AppColors.primary : Colors.white24,
                                  ),
                                ),
                                child: Text(b,
                                    style: TextStyle(
                                      color: selectedBlock == b ? Colors.white : Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Flat selector (if visible)
                        if (hasFlats) ...[
                          const Text('Select Flat / Unit',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: flats
                              .where((f) => selectedBlock == null || f.startsWith(selectedBlock!))
                              .map((f) => GestureDetector(
                              onTap: () => setModalState(() => selectedFlat = f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedFlat == f ? Colors.green.shade700 : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedFlat == f ? Colors.greenAccent : Colors.white24,
                                  ),
                                ),
                                child: Text(f, style: TextStyle(
                                  color: selectedFlat == f ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                )),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Manual entry if no blocks/flats detected
                        if (!hasBlocks && !hasFlats) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(children: [
                              Icon(Icons.info_outline, color: Colors.white54, size: 16),
                              SizedBox(width: 8),
                              Expanded(child: Text(
                                'No block numbers detected on this building. You can enter the flat/block number manually on the next screen.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              )),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final blockInfo = [
                          if (ocrResult.buildingName != null) ocrResult.buildingName,
                          if (selectedBlock != null) 'Block $selectedBlock',
                          if (selectedFlat != null) 'Flat $selectedFlat',
                        ].join(', ');

                        context.push('/scan/manual', extra: {
                          'fromCamera': true,
                          'latitude':  location?.latitude,
                          'longitude': location?.longitude,
                          'address':   location?.address ?? ocrResult.buildingAddress,
                          'photoPath': photoPath,
                          'ocrOwnerName':    null,
                          'ocrSurveyNumber': null,
                          'ocrDistrict':     null,
                          'ocrTaluk':        null,
                          'ocrDocumentType': 'Building',
                          'ocrConfidence':   ocrResult.confidence,
                          // Building-specific extras shown in manual search
                          'buildingName':  ocrResult.buildingName,
                          'selectedBlock': selectedBlock,
                          'selectedFlat':  selectedFlat,
                          'buildingInfo':  blockInfo.isEmpty ? null : blockInfo,
                        });
                      },
                      icon: const Icon(Icons.search),
                      label: Text(
                        selectedBlock != null || selectedFlat != null
                            ? 'Check ${selectedFlat ?? selectedBlock ?? 'Property'}'
                            : 'Continue — Enter Details',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPhotoPreview(
      BuildContext context, String photoPath, GpsLocation? location, PropertyScan scan, OcrResult ocrResult) async {
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
        ocrResult: ocrResult,
        onContinue: () {
          Navigator.pop(context);
          context.push('/scan/manual', extra: {
            'fromCamera': true,
            'latitude': location?.latitude,
            'longitude': location?.longitude,
            'address': location?.address,
            'photoPath': photoPath,
            'ocrSurveyNumber': ocrResult.surveyNumber,
            'ocrOwnerName': ocrResult.ownerName,
            'ocrTaluk': ocrResult.taluk,
            'ocrDistrict': ocrResult.district,
            'ocrDocumentType': ocrResult.documentType,
            'ocrConfidence': ocrResult.confidence,
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

          // GPS status
          if (_currentLocation != null)
            Positioned(
              top: 70, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'GPS: ${_currentLocation!.address ?? _currentLocation!.coordinatesString}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Capture Grid Lines
          CustomPaint(
            painter: _GridPainter(),
          ),

          // OCR loading overlay
          if (_isRunningOcr)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Reading document with AI...',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    SizedBox(height: 6),
                    Text('Extracting survey number, owner, taluk...',
                        style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _CaptureControls(
              isCapturing: _isCapturing,
              location: _currentLocation,
              error: _captureError,
              scanMode: false,
              onCapture: _capturePhoto,
              onGallery: () async {
                final path = await _cameraService.pickFromGallery();
                if (path == null || !mounted) return;

                // Run OCR on the gallery image — same as camera path
                setState(() { _isRunningOcr = true; });
                OcrResult ocrResult;
                try {
                  ocrResult = await _ocrService.extractFromDocument(path);
                } catch (e) {
                  ocrResult = const OcrResult();
                }
                if (mounted) setState(() { _isRunningOcr = false; });

                final scan = PropertyScan(
                  id: const Uuid().v4(),
                  photoPath: path,
                  location: _currentLocation,
                  scanMethod: ScanMethod.camera,
                  scannedAt: DateTime.now(),
                  surveyNumber: ocrResult.surveyNumber,
                );
                ref.read(currentScanProvider.notifier).state = scan;
                ref.read(propertyCheckNotifierProvider.notifier).setScan(scan);

                if (mounted) {
                  context.push('/scan/manual', extra: {
                    'ocrSurveyNumber': ocrResult.surveyNumber,
                    'ocrOwnerName':    ocrResult.ownerName,
                    'ocrDistrict':     ocrResult.district,
                    'ocrTaluk':        ocrResult.taluk,
                    'ocrDocumentType': ocrResult.documentType,
                  });
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
  final OcrResult ocrResult;
  final VoidCallback onContinue;

  const _PhotoPreviewSheet({
    required this.photoPath, required this.location,
    required this.dateStr, required this.ocrResult, required this.onContinue,
  });

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
                // OCR results banner
                if (ocrResult.hasUsefulData)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 14),
                          SizedBox(width: 6),
                          Text('AI extracted from document',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 6),
                        if (ocrResult.surveyNumber != null)
                          _ocrRow('Survey No.', ocrResult.surveyNumber!),
                        if (ocrResult.ownerName != null)
                          _ocrRow('Owner', ocrResult.ownerName!),
                        if (ocrResult.taluk != null)
                          _ocrRow('Taluk', ocrResult.taluk!),
                        if (ocrResult.district != null)
                          _ocrRow('District', ocrResult.district!),
                        if (ocrResult.documentType != null)
                          _ocrRow('Doc Type', ocrResult.documentType!),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white54, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not read document. You can enter survey number manually on the next screen.',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(ocrResult.hasUsefulData
                        ? 'Continue — Verify Details'
                        : 'Continue — Enter Survey No.'),
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

Widget _ocrRow(String label, String value) => Padding(
  padding: const EdgeInsets.only(top: 3),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 72,
        child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))),
      Expanded(child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
    ],
  ),
);

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
