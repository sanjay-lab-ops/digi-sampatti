import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

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
          // Google Map
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
            mapType: MapType.hybrid,  // Satellite + roads (best for land verification)
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),

          // GPS Info Overlay
          if (location != null)
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
