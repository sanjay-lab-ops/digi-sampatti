import 'package:flutter/material.dart';

// ─── GPS Location Model ────────────────────────────────────────────────────────
class GpsLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;
  final String? address;

  const GpsLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'capturedAt': capturedAt.toIso8601String(),
    'address': address,
  };

  factory GpsLocation.fromJson(Map<String, dynamic> json) => GpsLocation(
    latitude: json['latitude'],
    longitude: json['longitude'],
    accuracy: json['accuracy'],
    capturedAt: DateTime.parse(json['capturedAt']),
    address: json['address'],
  );

  String get coordinatesString =>
      '${latitude.toStringAsFixed(6)}° N, ${longitude.toStringAsFixed(6)}° E';
}

// ─── Property Scan Model ──────────────────────────────────────────────────────
class PropertyScan {
  final String id;
  final String? photoPath;
  final GpsLocation? location;
  final String? surveyNumber;
  final String? district;
  final String? taluk;
  final String? hobli;
  final String? village;
  final ScanMethod scanMethod;
  final DateTime scannedAt;

  const PropertyScan({
    required this.id,
    this.photoPath,
    this.location,
    this.surveyNumber,
    this.district,
    this.taluk,
    this.hobli,
    this.village,
    required this.scanMethod,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'photoPath': photoPath,
    'location': location?.toJson(),
    'surveyNumber': surveyNumber,
    'district': district,
    'taluk': taluk,
    'hobli': hobli,
    'village': village,
    'scanMethod': scanMethod.name,
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory PropertyScan.fromJson(Map<String, dynamic> json) => PropertyScan(
    id: json['id'],
    photoPath: json['photoPath'],
    location: json['location'] != null
        ? GpsLocation.fromJson(json['location'])
        : null,
    surveyNumber: json['surveyNumber'],
    district: json['district'],
    taluk: json['taluk'],
    hobli: json['hobli'],
    village: json['village'],
    scanMethod: ScanMethod.values.byName(json['scanMethod']),
    scannedAt: DateTime.parse(json['scannedAt']),
  );
}

enum ScanMethod { camera, manual }
