import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/features/gov_webview/gov_webview_screen.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? locationData;
  const MapViewScreen({super.key, this.locationData});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

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

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(currentLocationProvider);
    final scan = ref.watch(currentScanProvider);

    // No GPS — show Bhoomi FMB map shortcut instead of blank Google Map
    if (location == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Property on Map'),
          backgroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF1B5E20), size: 18),
                        SizedBox(width: 8),
                        Text('No GPS location captured',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You searched by survey number — no physical location was pinned. '
                      'Use the Bhoomi FMB Sketch or the satellite view below to view '
                      'the survey boundary on the government map.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    if (scan != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${scan.district ?? ""} · ${scan.taluk ?? ""} · Survey ${scan.surveyNumber ?? ""}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('View Survey Boundary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              // Open FMB Sketch on Bhoomi
              _MapOptionButton(
                icon: Icons.map,
                title: 'FMB Sketch on Bhoomi',
                subtitle: 'See digitized survey boundary on government map',
                color: const Color(0xFF1B5E20),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const GovWebviewScreen(portal: GovPortal.dishank),
                )),
              ),
              const SizedBox(height: 10),
              // Open the mutation+map view (service154) which shows satellite + blue boundaries
              _MapOptionButton(
                icon: Icons.satellite_alt,
                title: 'Mutation Preview Map (service154)',
                subtitle: 'Satellite view with blue survey boundary lines',
                color: const Color(0xFF0D47A1),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const GovWebviewScreen(portal: GovPortal.bhoomi),
                )),
              ),
              const SizedBox(height: 10),
              // Open bhuvan / KSRSAC for spatial reference
              _MapOptionButton(
                icon: Icons.public,
                title: 'Bhuvan / ISRO Satellite Map',
                subtitle: 'India\'s official satellite imagery (search by state/district)',
                color: const Color(0xFF37474F),
                onTap: () async {
                  final url = Uri.parse('https://bhuvan-app1.nrsc.gov.in/bhuvan2d/bhuvan/bhuvan2d.php');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property on Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInGoogleMaps,
            tooltip: 'Open in Google Maps',
          ),
        ],
      ),
      body: Stack(
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
            bottom: 16, left: 16, right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        const Text('GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('±${location.accuracy.toStringAsFixed(0)}m accuracy',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(location.coordinatesString,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (location.address != null) ...[
                      const SizedBox(height: 4),
                      Text(location.address!,
                          style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the property location on the satellite map to verify boundaries',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pop(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text('Use This Location', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _MapOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MapOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color, size: 20),
        ],
      ),
    ),
  );
}
