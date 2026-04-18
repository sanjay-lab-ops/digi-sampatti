import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ─── SRO Locator — matches Kaveri Online portal structure ─────────────────────
// District → Taluka → Hobli/Town → Village → SRO Table
// Data sourced from kaveri2.karnataka.gov.in
// ─────────────────────────────────────────────────────────────────────────────

class SroLocatorScreen extends StatefulWidget {
  const SroLocatorScreen({super.key});

  @override
  State<SroLocatorScreen> createState() => _SroLocatorScreenState();
}

class _SroLocatorScreenState extends State<SroLocatorScreen> {
  String? _district;
  String? _taluka;
  String? _hobli;
  String? _village;

  // ── District → Taluka map ─────────────────────────────────────────────────
  static const Map<String, List<String>> _talukas = {
    'Bangalore Urban': [
      'Bangalore North', 'Bangalore South', 'Bangalore East',
      'Yelahanka', 'Rajarajeshwari Nagar',
    ],
    'Bangalore Rural': ['Devanahalli', 'Doddaballapur', 'Hosakote', 'Nelamangala'],
    'Mysuru': ['Mysuru', 'Nanjangud', 'Hunsur', 'H D Kote', 'K R Nagara', 'Tirumakudalu Narasipura'],
    'Tumakuru': ['Tumakuru', 'Tiptur', 'Madhugiri', 'Sira', 'Pavagada', 'Gubbi'],
    'Mandya': ['Mandya', 'Maddur', 'Malavalli', 'Pandavapura', 'Shrirangapattana'],
    'Ramanagara': ['Ramanagara', 'Channapatna', 'Kanakapura', 'Magadi'],
    'Hassan': ['Hassan', 'Belur', 'Sakleshpur', 'Arakalagudu', 'Alur'],
    'Shivamogga': ['Shivamogga', 'Bhadravati', 'Tirthahalli', 'Hosanagara', 'Sagar'],
    'Dakshina Kannada': ['Mangaluru', 'Belthangady', 'Sullia', 'Puttur', 'Bantwal'],
    'Udupi': ['Udupi', 'Kundapura', 'Karkala'],
    'Belagavi': ['Belagavi', 'Gokak', 'Chikodi', 'Hukkeri', 'Athani'],
    'Dharwad': ['Dharwad', 'Hubballi', 'Kalghatagi', 'Kundgol', 'Navalgund'],
    'Vijayapura': ['Vijayapura', 'Sindagi', 'Basavana Bagewadi', 'Muddebihal', 'Indi'],
    'Kalaburagi': ['Kalaburagi', 'Aland', 'Chincholi', 'Jewargi', 'Sedam', 'Yadgir'],
    'Ballari': ['Ballari', 'Sanduru', 'Hospete', 'Hagaribommanahalli', 'Harapanahalli'],
    'Davangere': ['Davangere', 'Honnali', 'Channagiri', 'Harihara', 'Jagaluru'],
    'Chitradurga': ['Chitradurga', 'Hiriyur', 'Challakere', 'Holalkere', 'Hosadurga'],
    'Chikkaballapur': ['Chikkaballapur', 'Chintamani', 'Gowribidanur', 'Bagepalli', 'Gudibanda', 'Sidlaghatta'],
    'Kolar': ['Kolar', 'Mulbagal', 'Bangarpet', 'Malur', 'Srinivaspura'],
    'Chamarajanagara': ['Chamarajanagara', 'Gundlupete', 'Kollegal', 'Yelandur'],
    'Kodagu': ['Madikeri', 'Virajpet', 'Somvarpet'],
    'Gadag': ['Gadag', 'Shirahatti', 'Nargund', 'Ron', 'Mundargi'],
  };

  // ── Taluka → Hobli map ────────────────────────────────────────────────────
  static const Map<String, List<String>> _hoblis = {
    'Bangalore North': ['Dasanapura', 'Jala', 'Kasaba', 'Yelahanka', 'Begur'],
    'Bangalore South': ['Begur', 'Kasaba', 'Uttarahalli', 'Kengeri'],
    'Bangalore East': ['Kasaba', 'Varthur', 'K R Puram', 'Marathahalli'],
    'Yelahanka': ['Jala', 'Yelahanka', 'Kasaba'],
    'Rajarajeshwari Nagar': ['Kengeri', 'Uttarahalli', 'Begur'],
    'Devanahalli': ['Devanahalli', 'Kasaba', 'Vijayapura'],
    'Doddaballapur': ['Doddaballapur', 'Kasaba', 'Tubagere'],
    'Hosakote': ['Hosakote', 'Kasaba', 'Sulibele'],
    'Nelamangala': ['Nelamangala', 'Kasaba', 'Magadi'],
    'Mysuru': ['Kasaba', 'Jayapura', 'Krishnarajanagara', 'Naganahalli'],
    'Nanjangud': ['Kasaba', 'Nanjangud', 'T Narasipur'],
    'Hunsur': ['Kasaba', 'Hunsur', 'Koppa'],
    'Tumakuru': ['Kasaba', 'Koratagere', 'Madhugiri'],
    'Tiptur': ['Kasaba', 'Gubbi', 'Koratagere'],
    'Mangaluru': ['Kasaba', 'Mulki', 'Natekar'],
    'Belagavi': ['Kasaba', 'Gokak', 'Mudalagi'],
    'Dharwad': ['Kasaba', 'Dharwad', 'Kundgol'],
    'Hubballi': ['Kasaba', 'Dharwad', 'Kalghatagi'],
    'Davangere': ['Kasaba', 'Honnali', 'Channagiri'],
    'Kalaburagi': ['Kasaba', 'Chincholi', 'Jewargi'],
    'Vijayapura': ['Kasaba', 'Sindagi', 'Indi'],
    'Ballari': ['Kasaba', 'Hosapete', 'Sanduru'],
    'Hassan': ['Kasaba', 'Belur', 'Channarayapatna'],
    'Shivamogga': ['Kasaba', 'Bhadravati', 'Sagar'],
    'Ramanagara': ['Kasaba', 'Channapatna', 'Kanakapura'],
    'Kolar': ['Kasaba', 'Malur', 'Mulbagal'],
    'Chikkaballapur': ['Kasaba', 'Chintamani', 'Gowribidanur'],
    'Mandya': ['Kasaba', 'Maddur', 'Malavalli'],
    'Gadag': ['Kasaba', 'Nargund', 'Ron'],
    'Chamarajanagara': ['Kasaba', 'Kollegal', 'Yelandur'],
    'Udupi': ['Kasaba', 'Kundapura', 'Brahmavara'],
    'Chitradurga': ['Kasaba', 'Challakere', 'Hiriyur'],
    'Kodagu': ['Kasaba', 'Virajpet', 'Somvarpet'],
  };

  // ── Hobli → Villages map ──────────────────────────────────────────────────
  static const Map<String, List<String>> _villages = {
    'Dasanapura': ['Hunnigere', 'Dasanapura', 'Hesaraghatta', 'Soladevanahalli',
        'Chikkabanavara', 'Nagasandra', 'Jalahalli', 'Laggere', 'Nagarabhavi'],
    'Jala': ['Jala', 'Thanisandra', 'Byrathi', 'Kothanur', 'Singasandra', 'Horamavu'],
    'Kasaba': ['Kasaba', 'Rajajinagar', 'Srirampuram', 'Vijayanagar',
        'Yeshwanthpura', 'Peenya', 'Malleshwaram', 'Sadashivanagar'],
    'Yelahanka': ['Yelahanka', 'Yelahanka New Town', 'Kogilu', 'Amruthahalli',
        'Kodigehalli', 'Attur', 'Bettahalasur'],
    'Begur': ['Begur', 'Bannerghatta', 'Electronic City', 'Hulimavu',
        'Hongasandra', 'Bommanahalli'],
    'Uttarahalli': ['Uttarahalli', 'Kengeri', 'Subramanyapura', 'Nagarbhavi',
        'Gottigere', 'Puttenahalli'],
    'Varthur': ['Varthur', 'Whitefield', 'Kadugodi', 'Thubarahalli',
        'Marathahalli', 'Doddanekkundi'],
    'K R Puram': ['KR Puram', 'Banaswadi', 'Hoodi', 'Ramamurthy Nagar',
        'Virgonagar', 'Bagalur'],
    'Devanahalli': ['Devanahalli', 'Doddaballapur Road', 'Sadahalli',
        'Vijayapura', 'Nandagudi'],
    'Hosakote': ['Hosakote', 'Sulibele', 'Kadugodi', 'Jadigenahalli'],
    'Kasaba (Mysuru)': ['Nazarbad', 'Gokulam', 'Kuvempunagara',
        'Vijayanagara', 'Chamundipuram'],
    'Kasaba (Mangaluru)': ['Kadri', 'Kankanady', 'Urwa', 'Balmatta',
        'Pumpwell', 'Falnir', 'Attavar'],
    'Kasaba (Kolar)': ['Kolar', 'Gold Fields', 'Robertsonpet', 'Bangarpet'],
  };

  // ── District → SRO table (Kaveri portal format) ───────────────────────────
  static const Map<String, List<_SroEntry>> _sroTable = {
    'Bangalore Urban': [
      _SroEntry(1, 'Bangalore Development Authority', 'Bangalore Development Authority, Kumara Park East, Bengaluru - 560001'),
      _SroEntry(2, 'Dasanapura', 'Dasanapura, Bengaluru North - 560073'),
      _SroEntry(3, 'Laggere', 'Laggere, Bengaluru - 560058'),
      _SroEntry(4, 'Jadanayakanahalli', 'Jadanayakanahalli, Bengaluru - 560072'),
      _SroEntry(5, 'Nagarabhavi', 'Nagarabhavi, Bengaluru - 560072'),
      _SroEntry(6, 'Peenya', 'Peenya Industrial Area, Bengaluru - 560058'),
      _SroEntry(7, 'Rajajinagar', 'Rajajinagar, Bengaluru - 560010'),
      _SroEntry(8, 'Srirampuram', 'Srirampuram, Bengaluru - 560021'),
      _SroEntry(9, 'Vijayanagar', 'Vijayanagar, Bengaluru - 560040'),
      _SroEntry(10, 'Yeshwanthpura', 'Yeshwanthpura, Bengaluru - 560022'),
      _SroEntry(11, 'Bengaluru South', 'No. 15, Lalbagh Road, Bengaluru - 560027'),
      _SroEntry(12, 'Bengaluru North', 'Sadashivanagar, Bengaluru - 560080'),
      _SroEntry(13, 'Bengaluru East', 'Indiranagar, Bengaluru - 560038'),
      _SroEntry(14, 'Yelahanka', 'Yelahanka New Town, Bengaluru - 560064'),
      _SroEntry(15, 'KR Puram', 'KR Puram, Bengaluru - 560036'),
      _SroEntry(16, 'Whitefield', 'Whitefield, Bengaluru - 560066'),
      _SroEntry(17, 'Marathahalli', 'Marathahalli, Bengaluru - 560037'),
      _SroEntry(18, 'Bannerghatta Road', 'Bannerghatta Road, Bengaluru - 560076'),
      _SroEntry(19, 'Electronic City', 'Electronic City, Bengaluru - 560100'),
      _SroEntry(20, 'Bommanahalli', 'Bommanahalli, Bengaluru - 560068'),
    ],
    'Bangalore Rural': [
      _SroEntry(1, 'Devanahalli', 'Devanahalli Town, Bengaluru Rural - 562110'),
      _SroEntry(2, 'Doddaballapur', 'Doddaballapur, Bengaluru Rural - 561203'),
      _SroEntry(3, 'Hosakote', 'Hosakote Town, Bengaluru Rural - 562114'),
      _SroEntry(4, 'Nelamangala', 'Nelamangala, Bengaluru Rural - 562123'),
      _SroEntry(5, 'KIADB Industrial Area', 'KIADB Devanahalli, Bengaluru Rural - 562110'),
    ],
    'Mysuru': [
      _SroEntry(1, 'Mysuru City', 'Nazarbad, Mysuru - 570010'),
      _SroEntry(2, 'Mysuru Rural', 'T Narasipur Road, Mysuru - 570019'),
      _SroEntry(3, 'Nanjangud', 'Nanjangud Town, Mysuru - 571301'),
      _SroEntry(4, 'Hunsur', 'Hunsur Town, Mysuru - 571105'),
      _SroEntry(5, 'H D Kote', 'H D Kote, Mysuru - 571114'),
      _SroEntry(6, 'K R Nagara', 'K R Nagara, Mysuru - 571602'),
    ],
    'Tumakuru': [
      _SroEntry(1, 'Tumakuru', 'B H Road, Tumakuru - 572101'),
      _SroEntry(2, 'Tiptur', 'Tiptur, Tumakuru - 572201'),
      _SroEntry(3, 'Madhugiri', 'Madhugiri, Tumakuru - 572132'),
      _SroEntry(4, 'Sira', 'Sira, Tumakuru - 572137'),
      _SroEntry(5, 'Pavagada', 'Pavagada, Tumakuru - 561202'),
    ],
    'Mandya': [
      _SroEntry(1, 'Mandya', 'M C Road, Mandya - 571401'),
      _SroEntry(2, 'Maddur', 'Maddur, Mandya - 571428'),
      _SroEntry(3, 'Malavalli', 'Malavalli, Mandya - 571430'),
      _SroEntry(4, 'Pandavapura', 'Pandavapura, Mandya - 571434'),
      _SroEntry(5, 'Shrirangapattana', 'Shrirangapattana, Mandya - 571438'),
    ],
    'Ramanagara': [
      _SroEntry(1, 'Ramanagara', 'Station Road, Ramanagara - 562159'),
      _SroEntry(2, 'Channapatna', 'Channapatna, Ramanagara - 562160'),
      _SroEntry(3, 'Kanakapura', 'Kanakapura, Ramanagara - 562117'),
      _SroEntry(4, 'Magadi', 'Magadi, Ramanagara - 562120'),
    ],
    'Hassan': [
      _SroEntry(1, 'Hassan', 'BM Road, Hassan - 573201'),
      _SroEntry(2, 'Belur', 'Belur, Hassan - 573115'),
      _SroEntry(3, 'Sakleshpur', 'Sakleshpur, Hassan - 573134'),
      _SroEntry(4, 'Arakalagudu', 'Arakalagudu, Hassan - 573102'),
      _SroEntry(5, 'Channarayapatna', 'Channarayapatna, Hassan - 573116'),
    ],
    'Shivamogga': [
      _SroEntry(1, 'Shivamogga', 'Vinoba Road, Shivamogga - 577201'),
      _SroEntry(2, 'Bhadravati', 'Bhadravati, Shivamogga - 577301'),
      _SroEntry(3, 'Tirthahalli', 'Tirthahalli, Shivamogga - 577432'),
      _SroEntry(4, 'Hosanagara', 'Hosanagara, Shivamogga - 577418'),
      _SroEntry(5, 'Sagar', 'Sagar, Shivamogga - 577401'),
    ],
    'Dakshina Kannada': [
      _SroEntry(1, 'Mangaluru City', 'Lalbagh, Mangaluru - 575001'),
      _SroEntry(2, 'Mangaluru Rural', 'Kankanady, Mangaluru - 575002'),
      _SroEntry(3, 'Belthangady', 'Belthangady, DK - 574214'),
      _SroEntry(4, 'Sullia', 'Sullia, DK - 574239'),
      _SroEntry(5, 'Puttur', 'Puttur, DK - 574201'),
      _SroEntry(6, 'Bantwal', 'Bantwal, DK - 574219'),
    ],
    'Belagavi': [
      _SroEntry(1, 'Belagavi City', 'Station Road, Belagavi - 590001'),
      _SroEntry(2, 'Belagavi Rural', 'Camp, Belagavi - 590001'),
      _SroEntry(3, 'Gokak', 'Gokak, Belagavi - 591307'),
      _SroEntry(4, 'Chikodi', 'Chikodi, Belagavi - 591201'),
      _SroEntry(5, 'Hukkeri', 'Hukkeri, Belagavi - 591309'),
    ],
    'Dharwad': [
      _SroEntry(1, 'Dharwad', 'Market Road, Dharwad - 580001'),
      _SroEntry(2, 'Hubballi', 'Koppikar Road, Hubballi - 580020'),
      _SroEntry(3, 'Kalghatagi', 'Kalghatagi, Dharwad - 581204'),
      _SroEntry(4, 'Kundgol', 'Kundgol, Dharwad - 581113'),
    ],
    'Kalaburagi': [
      _SroEntry(1, 'Kalaburagi', 'Super Market, Kalaburagi - 585101'),
      _SroEntry(2, 'Aland', 'Aland, Kalaburagi - 585302'),
      _SroEntry(3, 'Chincholi', 'Chincholi, Kalaburagi - 585307'),
      _SroEntry(4, 'Jewargi', 'Jewargi, Kalaburagi - 585310'),
      _SroEntry(5, 'Sedam', 'Sedam, Kalaburagi - 585222'),
    ],
    'Ballari': [
      _SroEntry(1, 'Ballari', 'Gandhi Nagar, Ballari - 583101'),
      _SroEntry(2, 'Sanduru', 'Sanduru, Ballari - 583119'),
      _SroEntry(3, 'Hospete', 'Hospete, Ballari - 583201'),
      _SroEntry(4, 'Hagaribommanahalli', 'Hagaribommanahalli, Ballari - 583212'),
    ],
    'Davangere': [
      _SroEntry(1, 'Davangere', 'P J Extension, Davangere - 577002'),
      _SroEntry(2, 'Honnali', 'Honnali, Davangere - 577217'),
      _SroEntry(3, 'Channagiri', 'Channagiri, Davangere - 577213'),
      _SroEntry(4, 'Harihara', 'Harihara, Davangere - 577601'),
    ],
    'Udupi': [
      _SroEntry(1, 'Udupi', 'Car Street, Udupi - 576101'),
      _SroEntry(2, 'Kundapura', 'Kundapura, Udupi - 576201'),
      _SroEntry(3, 'Karkala', 'Karkala, Udupi - 574104'),
    ],
    'Vijayapura': [
      _SroEntry(1, 'Vijayapura', 'Station Road, Vijayapura - 586101'),
      _SroEntry(2, 'Sindagi', 'Sindagi, Vijayapura - 586128'),
      _SroEntry(3, 'Basavana Bagewadi', 'Basavana Bagewadi, Vijayapura - 586203'),
      _SroEntry(4, 'Indi', 'Indi, Vijayapura - 586209'),
    ],
    'Gadag': [
      _SroEntry(1, 'Gadag', 'Station Road, Gadag - 582101'),
      _SroEntry(2, 'Shirahatti', 'Shirahatti, Gadag - 582116'),
      _SroEntry(3, 'Nargund', 'Nargund, Gadag - 582207'),
      _SroEntry(4, 'Ron', 'Ron, Gadag - 582209'),
    ],
    'Chitradurga': [
      _SroEntry(1, 'Chitradurga', 'Fort Road, Chitradurga - 577501'),
      _SroEntry(2, 'Hiriyur', 'Hiriyur, Chitradurga - 572143'),
      _SroEntry(3, 'Challakere', 'Challakere, Chitradurga - 577522'),
    ],
    'Chikkaballapur': [
      _SroEntry(1, 'Chikkaballapur', 'Gandhi Road, Chikkaballapur - 562101'),
      _SroEntry(2, 'Chintamani', 'Chintamani, Chikkaballapur - 563125'),
      _SroEntry(3, 'Gowribidanur', 'Gowribidanur, Chikkaballapur - 561208'),
      _SroEntry(4, 'Bagepalli', 'Bagepalli, Chikkaballapur - 561207'),
    ],
    'Kolar': [
      _SroEntry(1, 'Kolar', 'Civil Station, Kolar - 563101'),
      _SroEntry(2, 'Mulbagal', 'Mulbagal, Kolar - 563131'),
      _SroEntry(3, 'Bangarpet', 'Bangarpet, Kolar - 563114'),
      _SroEntry(4, 'Malur', 'Malur, Kolar - 563130'),
      _SroEntry(5, 'KGF', 'Robertsonpet, KGF - 563122'),
    ],
    'Chamarajanagara': [
      _SroEntry(1, 'Chamarajanagara', 'BM Road, Chamarajanagara - 571313'),
      _SroEntry(2, 'Gundlupete', 'Gundlupete, Chamarajanagara - 571111'),
      _SroEntry(3, 'Kollegal', 'Kollegal, Chamarajanagara - 571440'),
    ],
    'Kodagu': [
      _SroEntry(1, 'Madikeri', 'School Road, Madikeri - 571201'),
      _SroEntry(2, 'Virajpet', 'Virajpet, Kodagu - 571218'),
      _SroEntry(3, 'Somvarpet', 'Somvarpet, Kodagu - 571236'),
    ],
  };

  List<String> get _districtList => _talukas.keys.toList()..sort();
  List<String> get _talukaList   => _district == null ? [] : (_talukas[_district] ?? []);
  List<String> get _hobliList    => _taluka  == null ? [] : (_hoblis[_taluka]   ?? []);
  List<String> get _villageList  => _hobli   == null ? [] : (_villages[_hobli]  ?? []);
  List<_SroEntry> get _sroResults => _district == null ? [] : (_sroTable[_district] ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('SRO Locator'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://kaverionline.karnataka.gov.in');
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Kaveri', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header info banner ──────────────────────────────────────
            Container(
              color: const Color(0xFF003087),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Find the SRO (Sub-Registrar Office) where you can register your property. '
                    'Select district, taluka, hobli & village to see the correct SRO.',
                    style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                  ),
                ),
              ]),
            ),

            // ── Know the SRO Card ───────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF003087).withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003087),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.account_balance, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('Know the SRO where you can register',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Row 1 — District + Taluka
                        Row(children: [
                          Expanded(child: _buildDropdown(
                            label: 'DISTRICT',
                            value: _district,
                            items: _districtList,
                            onChanged: (v) => setState(() {
                              _district = v; _taluka = null;
                              _hobli = null; _village = null;
                            }),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdown(
                            label: 'TALUKA',
                            value: _taluka,
                            items: _talukaList,
                            onChanged: _district == null ? null : (v) => setState(() {
                              _taluka = v; _hobli = null; _village = null;
                            }),
                          )),
                        ]),
                        const SizedBox(height: 12),
                        // Row 2 — Hobli/Town + Village
                        Row(children: [
                          Expanded(child: _buildDropdown(
                            label: 'HOBLI / TOWN',
                            value: _hobli,
                            items: _hobliList,
                            onChanged: _taluka == null ? null : (v) => setState(() {
                              _hobli = v; _village = null;
                            }),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDropdown(
                            label: 'INDEX II: VILLAGE',
                            value: _village,
                            items: _villageList,
                            onChanged: _hobli == null ? null : (v) => setState(() {
                              _village = v;
                            }),
                          )),
                        ]),
                      ],
                    ),
                  ),

                  // ── Results Table ─────────────────────────────────────
                  if (_sroResults.isNotEmpty) ...[
                    const Divider(height: 1),
                    // Table header
                    Container(
                      color: const Color(0xFF003087),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: const Row(children: [
                        SizedBox(width: 36,
                            child: Text('Sl\nNo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                        SizedBox(width: 12),
                        Expanded(flex: 2,
                            child: Text('SRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                        SizedBox(width: 12),
                        Expanded(flex: 3,
                            child: Text('Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                      ]),
                    ),
                    // Table rows
                    ...List.generate(_sroResults.length, (i) {
                      final entry = _sroResults[i];
                      final isEven = i % 2 == 0;
                      return GestureDetector(
                        onTap: () => _showSroDetail(context, entry),
                        child: Container(
                          color: isEven ? const Color(0xFFF0F4FF) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            SizedBox(width: 36,
                                child: Text('${entry.slNo}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                                    textAlign: TextAlign.center)),
                            const SizedBox(width: 12),
                            Expanded(flex: 2,
                                child: Text(entry.sro,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF003087), fontWeight: FontWeight.w600))),
                            const SizedBox(width: 12),
                            Expanded(flex: 3,
                                child: Text(entry.address,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium))),
                          ]),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('${_sroResults.length} SRO offices found in ${_district ?? ""}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ),
                  ] else if (_district == null) ...[
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(children: [
                        Icon(Icons.account_balance_outlined, size: 48, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text('Select a district to see SRO offices',
                            style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Quick tools ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                Expanded(child: _quickTile(
                  icon: Icons.attach_money,
                  label: 'Guidance Value',
                  sub: 'Check area rate',
                  color: AppColors.teal,
                  onTap: () => context.push('/guidance-value'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _quickTile(
                  icon: Icons.calculate_outlined,
                  label: 'Stamp Duty',
                  sub: 'Calculate cost',
                  color: AppColors.arthBlue,
                  onTap: () => context.push('/transfer/stamp-duty'),
                )),
                const SizedBox(width: 10),
                Expanded(child: _quickTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Book Slot',
                  sub: 'Kaveri Online',
                  color: const Color(0xFF003087),
                  onTap: () async {
                    final uri = Uri.parse('https://kaverionline.karnataka.gov.in');
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textMedium, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: onChanged == null
                ? AppColors.borderColor
                : const Color(0xFF003087).withOpacity(0.4)),
            borderRadius: BorderRadius.circular(8),
            color: onChanged == null ? const Color(0xFFF5F6FA) : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(onChanged == null ? 'Select above first' : 'Select',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              icon: Icon(Icons.expand_more,
                  color: onChanged == null ? AppColors.textLight : const Color(0xFF003087), size: 18),
              items: items.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
              )).toList(),
              onChanged: onChanged,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
        ),
      ],
    );
  }

  void _showSroDetail(BuildContext context, _SroEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFF003087).withOpacity(0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.account_balance, color: Color(0xFF003087), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SRO — ${entry.sro}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(_district ?? '', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 16),
            _detailRow(Icons.location_on_outlined, entry.address),
            const SizedBox(height: 8),
            _detailRow(Icons.access_time, '10:00 AM – 5:30 PM  |  Mon–Sat (2nd Sat holiday)'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.address));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied')));
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy Address'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final q = Uri.encodeComponent('${entry.sro} Sub Registrar Office Karnataka');
                    final uri = Uri.parse('https://maps.google.com/?q=$q');
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.map_outlined, size: 14),
                  label: const Text('Maps'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003087)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.textLight),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
    ],
  );

  Widget _quickTile({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
        Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
      ]),
    ),
  );
}

class _SroEntry {
  final int    slNo;
  final String sro;
  final String address;
  const _SroEntry(this.slNo, this.sro, this.address);
}
