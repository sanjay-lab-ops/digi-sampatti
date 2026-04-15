import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? locationData;
  // Optional: property details for Bhoomi map
  final String? district;
  final String? taluk;
  final String? hobli;
  final String? village;
  final String? surveyNumber;

  const MapViewScreen({
    super.key,
    this.locationData,
    this.district,
    this.taluk,
    this.hobli,
    this.village,
    this.surveyNumber,
  });

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _showBhoomiMap = false;

  // Default: Bengaluru center
  static const _defaultLocation = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _setupMarkers() {
    final location = ref.read(currentLocationProvider);
    if (location == null) return;

    final latlng = LatLng(location.latitude, location.longitude);

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('property'),
          position: latlng,
          infoWindow: InfoWindow(
            title: 'Property Location',
            snippet: location.address ?? location.coordinatesString,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };

      // GPS accuracy circle
      _circles = {
        Circle(
          circleId: const CircleId('accuracy'),
          center: latlng,
          radius: location.accuracy,
          fillColor: AppColors.primary.withOpacity(0.1),
          strokeColor: AppColors.primary,
          strokeWidth: 1,
        ),
      };
    });
  }

  LatLng get _center {
    final location = ref.read(currentLocationProvider);
    if (location != null) return LatLng(location.latitude, location.longitude);
    return _defaultLocation;
  }

  Future<void> _openInGoogleMaps() async {
    final location = ref.read(currentLocationProvider);
    if (location == null) return;
    final url = Uri.parse(
        'https://maps.google.com/?q=${location.latitude},${location.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Build Bhoomi map URL for this survey
  String _bhoomiMapUrl(String? survey) {
    // Bhoomi beta map with survey search
    return 'https://landrecords.karnataka.gov.in/service54/';
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final scan = ref.watch(currentScanProvider);
    // Use widget param if passed, otherwise fall back to current scan
    final effectiveSurveyNumber = (widget.surveyNumber != null && widget.surveyNumber!.isNotEmpty)
        ? widget.surveyNumber
        : scan?.surveyNumber;
    final hasSurvey = effectiveSurveyNumber != null && effectiveSurveyNumber.isNotEmpty;

    if (_showBhoomiMap && hasSurvey) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Survey $effectiveSurveyNumber — Bhoomi Map'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _showBhoomiMap = false),
          ),
        ),
        body: WebViewWidget(
          controller: WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(_bhoomiMapUrl(effectiveSurveyNumber))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property on Map'),
        actions: [
          if (location != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInGoogleMaps,
              tooltip: 'Open in Google Maps',
            ),
        ],
      ),
      body: location == null
          ? _buildNoGps(hasSurvey, effectiveSurveyNumber)
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _center, zoom: 17),
                      ),
                    );
                  },
                  initialCameraPosition: CameraPosition(target: _center, zoom: 17),
                  markers: _markers,
                  circles: _circles,
                  mapType: MapType.hybrid,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                ),
                Positioned(
                  bottom: 80, left: 16, right: 16,
                  child: _infoCard(location),
                ),
              ],
            ),
      floatingActionButton: hasSurvey
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showBhoomiMap = true),
              backgroundColor: const Color(0xFF1B5E20),
              icon: const Icon(Icons.map, color: Colors.white),
              label: Text('Survey $effectiveSurveyNumber Boundary Map',
                  style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildNoGps(bool hasSurvey, String? surveyNumber) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No GPS location captured',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            hasSurvey
                ? 'Tap below to see the actual survey plot boundary from Bhoomi — '
                  'the official blue-line land map from landrecords.karnataka.gov.in'
                : 'GPS shows your current location, not the property location. '
                  'To see property on map, enter the survey number first.',
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          if (hasSurvey) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showBhoomiMap = true),
              icon: const Icon(Icons.satellite_alt),
              label: Text('Open Survey $surveyNumber Map on Bhoomi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(dynamic location) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.gps_fixed, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('±${location.accuracy.toStringAsFixed(0)}m',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Text(location.coordinatesString,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (location.address != null)
              Text(location.address!,
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
