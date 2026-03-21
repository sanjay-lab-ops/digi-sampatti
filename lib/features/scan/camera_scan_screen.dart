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

class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen> {
  final _cameraService = CameraService();
  final _gpsService = GpsService();
  bool _isInitialized = false;
  bool _isCapturing = false;
  GpsLocation? _currentLocation;
  String? _captureError;

  @override
  void initState() {
    super.initState();
    _initialize();
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

      final scan = PropertyScan(
        id: const Uuid().v4(),
        photoPath: photoPath,
        location: location,
        scanMethod: ScanMethod.camera,
        scannedAt: DateTime.now(),
      );

      ref.read(currentScanProvider.notifier).state = scan;
      ref.read(propertyCheckNotifierProvider.notifier).setScan(scan);

      if (mounted) {
        // If GPS captured address, try to auto-detect survey details
        context.push('/scan/manual', extra: {
          'fromCamera': true,
          'latitude': location?.latitude,
          'longitude': location?.longitude,
          'address': location?.address,
          'photoPath': photoPath,
        });
      }
    } finally {
      if (mounted) setState(() { _isCapturing = false; });
    }
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

          // Capture Grid Lines
          CustomPaint(
            painter: _GridPainter(),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _CaptureControls(
              isCapturing: _isCapturing,
              location: _currentLocation,
              error: _captureError,
              onCapture: _capturePhoto,
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
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  const _CaptureControls({
    required this.isCapturing, required this.location,
    required this.error, required this.onCapture, required this.onGallery,
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
          const Text(
            'Point camera at the property. GPS will be auto-captured.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      : const Icon(Icons.camera_alt, color: AppColors.primary, size: 36),
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
