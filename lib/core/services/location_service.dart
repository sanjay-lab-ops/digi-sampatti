import 'dart:convert';
import 'package:flutter/services.dart';

class KaTaluk {
  final String name;
  final List<String> villages;
  const KaTaluk({required this.name, required this.villages});
}

class KaDistrict {
  final String name;
  final String guidance;
  final List<KaTaluk> taluks;
  const KaDistrict({required this.name, required this.guidance, required this.taluks});
  List<String> get talukNames => taluks.map((t) => t.name).toList();
  List<String> villagesFor(String taluk) =>
      taluks.firstWhere((t) => t.name == taluk, orElse: () => const KaTaluk(name: '', villages: [])).villages;
}

class SroOffice {
  final String id, name, district, address, phone, hours;
  final List<String> taluks, areas;
  const SroOffice({
    required this.id, required this.name, required this.district,
    required this.address, required this.phone, required this.hours,
    required this.taluks, required this.areas,
  });
}

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  List<KaDistrict>? _districts;
  List<SroOffice>? _sros;

  Future<List<KaDistrict>> getDistricts() async {
    if (_districts != null) return _districts!;
    final raw = await rootBundle.loadString('assets/data/locations.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _districts = (data['districts'] as List).map((d) {
      final taluks = (d['taluks'] as List).map((t) => KaTaluk(
        name: t['name'] as String,
        villages: List<String>.from(t['villages'] as List),
      )).toList();
      return KaDistrict(
        name: d['name'] as String,
        guidance: d['guidance'] as String,
        taluks: taluks,
      );
    }).toList();
    return _districts!;
  }

  Future<KaDistrict?> findDistrict(String name) async {
    final districts = await getDistricts();
    try {
      return districts.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<List<SroOffice>> getSros() async {
    if (_sros != null) return _sros!;
    final raw = await rootBundle.loadString('assets/data/sro.json');
    final data = jsonDecode(raw) as List;
    _sros = data.map((s) => SroOffice(
      id: s['id'] as String,
      name: s['name'] as String,
      district: s['district'] as String,
      address: s['address'] as String,
      phone: s['phone'] as String,
      hours: s['hours'] as String,
      taluks: List<String>.from(s['taluks'] as List),
      areas: List<String>.from(s['areas'] as List),
    )).toList();
    return _sros!;
  }

  Future<SroOffice?> getSroForTaluk(String taluk) async {
    final sros = await getSros();
    try {
      return sros.firstWhere((s) => s.taluks.contains(taluk));
    } catch (_) {
      return null;
    }
  }

  Future<List<SroOffice>> getSrosForDistrict(String district) async {
    final sros = await getSros();
    return sros.where((s) => s.district == district).toList();
  }
}
