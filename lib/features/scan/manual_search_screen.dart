import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:digi_sampatti/core/constants/api_constants.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/services/user_service.dart';
import 'package:digi_sampatti/core/services/gps_service.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';
import 'package:digi_sampatti/core/models/property_scan_model.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';

class ManualSearchScreen extends ConsumerStatefulWidget {
  // Pre-fill values from OCR or GPS
  final String? prefillSurveyNumber;
  final String? prefillOwnerName;
  final String? prefillDistrict;
  final String? prefillTaluk;
  final String? prefillDocumentType;
  // Building scan extras
  final String? buildingName;
  final String? selectedBlock;
  final String? selectedFlat;
  final String? buildingInfo;

  const ManualSearchScreen({
    super.key,
    this.prefillSurveyNumber,
    this.prefillOwnerName,
    this.prefillDistrict,
    this.prefillTaluk,
    this.prefillDocumentType,
    this.buildingName,
    this.selectedBlock,
    this.selectedFlat,
    this.buildingInfo,
  });

  @override
  ConsumerState<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surveyController = TextEditingController();
  final _ownerNameController = TextEditingController();
  String? _selectedDistrict;
  String? _selectedTaluk;
  String? _selectedHobli;
  String? _selectedVillage;
  bool _isDetectingGps = false;
  String? _gpsMessage;
  bool _prefillApplied = false;  // banner: show when OCR pre-filled

  // Dynamic dropdown data (fetched from Bhoomi)
  List<String> _hobliList  = [];
  List<String> _villageList = [];
  bool _loadingHobli   = false;
  bool _loadingVillage = false;

  // 0 = Survey Number mode, 1 = Village/Name mode (rural friendly)
  int _searchMode = 0;

  // Property type — controls which portals are checked
  String _propertyType = 'site';

  // State selector
  String _selectedState = 'Karnataka';

  static const List<Map<String, dynamic>> _states = [
    {'name': 'Karnataka',       'live': true,  'flag': '🟢'},
    {'name': 'Andhra Pradesh',  'live': false, 'flag': '🔜'},
    {'name': 'Tamil Nadu',      'live': false, 'flag': '🔜'},
    {'name': 'Telangana',       'live': false, 'flag': '🔜'},
    {'name': 'Maharashtra',     'live': false, 'flag': '🔜'},
    {'name': 'Goa',             'live': false, 'flag': '🔜'},
    {'name': 'Kerala',          'live': false, 'flag': '🔜'},
  ];

  // ─── Karnataka district → taluk ──────────────────────────────────────────
  static const Map<String, List<String>> districtTaluks = {
    'Bengaluru Urban': ['Anekal', 'Bengaluru East', 'Bengaluru North', 'Bengaluru South', 'Yelahanka'],
    'Bengaluru Rural': ['Devanahalli', 'Doddaballapura', 'Hoskote', 'Nelamangala'],
    'Mysuru':          ['Hunsur', 'K.R.Nagar', 'Mysuru', 'Nanjangud', 'Periyapatna', 'T.Narasipura'],
    'Tumakuru':        ['Chikkanayakanahalli', 'Gubbi', 'Koratagere', 'Kunigal', 'Madhugiri', 'Pavagada', 'Sira', 'Tiptur', 'Tumakuru'],
    'Mangaluru':       ['Belthangady', 'Bantwal', 'Puttur', 'Sullia', 'Mangaluru'],
    'Hubballi-Dharwad':['Dharwad', 'Hubballi', 'Kundgol', 'Kalghatgi', 'Navalgund'],
    'Belagavi':        ['Athani', 'Bailhongal', 'Belagavi', 'Chikkodi', 'Gokak', 'Hukkeri', 'Khanapur', 'Raibag', 'Ramdurg', 'Savadatti'],
    'Kalaburagi':      ['Afzalpur', 'Aland', 'Chincholi', 'Chittapur', 'Gurmatkal', 'Jevargi', 'Kalaburagi', 'Sedam'],
    'Hassan':          ['Alur', 'Arakalagudu', 'Arsikere', 'Belur', 'Channarayapatna', 'Hassan', 'Holenarasipur', 'Sakleshpur'],
    'Shivamogga':      ['Bhadravati', 'Hosanagara', 'Sagar', 'Shikaripura', 'Shivamogga', 'Sorab', 'Thirthahalli'],
    'Chikkaballapura': ['Bagepalli', 'Chikkaballapura', 'Chintamani', 'Gauribidanur', 'Gudibanda', 'Sidlaghatta'],
    'Ramanagara':      ['Channapatna', 'Kanakapura', 'Magadi', 'Ramanagara'],
    'Kolar':           ['Bangarpet', 'KGF', 'Kolar', 'Malur', 'Mulbagal', 'Srinivasapura'],
    'Chitradurga':     ['Challakere', 'Chitradurga', 'Hiriyur', 'Holalkere', 'Hosadurga', 'Molakalmuru'],
    'Davanagere':      ['Channagiri', 'Davanagere', 'Harihara', 'Honnali', 'Jagalur', 'Nyamathi'],
    'Vijayapura':      ['Basavana Bagevadi', 'Bijapur', 'Indi', 'Muddebihal', 'Sindagi'],
    'Dharwad':         ['Dharwad', 'Hubli', 'Kalghatgi', 'Kundgol', 'Navalgund'],
    'Uttara Kannada':  ['Ankola', 'Bhatkal', 'Haliyal', 'Karwar', 'Kumta', 'Mundgod', 'Siddapur', 'Sirsi', 'Supa', 'Yellapur'],
    'Chikkamagaluru':  ['Birur', 'Chikkamagaluru', 'Kadur', 'Koppa', 'Mudigere', 'N.R.Pura', 'Sringeri', 'Tarikere'],
    'Mandya':          ['Krishnarajapete', 'Maddur', 'Malavalli', 'Mandya', 'Nagamangala', 'Pandavapura', 'Shrirangapattana'],
    'Kodagu':          ['Madikeri', 'Somwarpet', 'Virajpet'],
    'Ballari':         ['Ballari', 'Hadagali', 'Hagaribommanahalli', 'Hospet', 'Kudligi', 'Sandur', 'Siruguppa'],
    'Gadag':           ['Gadag', 'Mundargi', 'Nargund', 'Ron', 'Shirahatti'],
    'Haveri':          ['Byadagi', 'Hangal', 'Haveri', 'Hirekerur', 'Ranebennur', 'Savanur', 'Shiggaon'],
    'Koppal':          ['Gangavathi', 'Koppal', 'Kushtagi', 'Yelburga'],
    'Raichur':         ['Deodurga', 'Lingsugur', 'Manvi', 'Raichur', 'Sindhanur'],
    'Yadgir':          ['Shahapur', 'Shorapur', 'Yadgir'],
    'Bidar':           ['Aurad', 'Basavakalyan', 'Bidar', 'Bhalki', 'Humnabad'],
    'Chamarajanagar':  ['Chamarajanagar', 'Gundlupete', 'Kollegal', 'Yelandur'],
    'Udupi':           ['Karkala', 'Kundapura', 'Udupi'],
    'Dakshina Kannada':['Belthangady', 'Bantwal', 'Mangaluru', 'Puttur', 'Sullia'],
  };

  // ─── Hobli map (district_taluk → hoblis) — from Bhoomi portal ───────────
  static const Map<String, List<String>> talukHoblis = {
    // Bengaluru Urban — EXACT from Bhoomi portal (confirmed live)
    // Bhoomi Bangalore North: DASANAPURA1, DASANAPURA2, DASANAPURA3, KASABA1, KASABA2, YASHAVANTAPURA1, YASHAVANTAPURA2
    'Bengaluru Urban_Yelahanka':       ['Kasaba 1', 'Kasaba 2', 'Yelahanka 1', 'Yelahanka 2'],
    'Bengaluru Urban_Bengaluru North': [
      'Dasanapura 1', 'Dasanapura 2', 'Dasanapura 3',
      'Kasaba 1', 'Kasaba 2',
      'Yashavantapura 1', 'Yashavantapura 2',
    ],
    'Bengaluru Urban_Bengaluru South': ['Kasaba', 'Begur', 'Kengeri', 'Uttarahalli'],
    'Bengaluru Urban_Bengaluru East':  ['Kasaba', 'Varthur', 'Bidarahalli', 'Krishnarajapura'],
    'Bengaluru Urban_Anekal':          ['Kasaba (Anekal)', 'Attibele', 'Sarjapura', 'Jigani'],
    // Bengaluru Rural
    'Bengaluru Rural_Devanahalli':     ['Kasaba (Devanahalli)', 'Devanahalli', 'Vijayapura', 'Nandagudi'],
    'Bengaluru Rural_Hoskote':         ['Kasaba (Hoskote)', 'Hoskote', 'Jadigenahalli', 'Sulibele'],
    'Bengaluru Rural_Nelamangala':     ['Kasaba (Nelamangala)', 'Nelamangala', 'Savandurga', 'Tavarekere'],
    'Bengaluru Rural_Doddaballapura':  ['Kasaba (Doddaballapura)', 'Doddaballapura', 'Tubugere', 'Koratagere'],
    // Mysuru
    'Mysuru_Mysuru':                   ['Kasaba', 'Jayapura', 'Krishnarajanagara', 'Varuna'],
    'Mysuru_Hunsur':                   ['Hunsur', 'Antharasante', 'Kasaba'],
    'Mysuru_Nanjangud':                ['Kasaba', 'Nanjangud', 'Gundlupete'],
    // Mangaluru
    'Mangaluru_Mangaluru':             ['Kasaba', 'Mulki', 'Bajpe', 'Moodabidre'],
    'Mangaluru_Bantwal':               ['Kasaba', 'Bantwal', 'Belthangady'],
    // Ramanagara
    'Ramanagara_Kanakapura':           ['Kanakapura', 'Sathanur', 'Dodda Alada Mara'],
    'Ramanagara_Ramanagara':           ['Ramanagara', 'Channapatna'],
    'Ramanagara_Magadi':               ['Kasaba', 'Magadi', 'Solur'],
    // Tumakuru
    'Tumakuru_Tumakuru':               ['Kasaba', 'Madhugiri', 'Tiptur', 'Gubbi'],
    'Tumakuru_Tiptur':                 ['Kasaba', 'Tiptur', 'Turuvekere'],
    'Tumakuru_Madhugiri':              ['Kasaba', 'Madhugiri', 'Sira', 'Pavagada'],
    'Tumakuru_Kunigal':                ['Kasaba', 'Kunigal', 'Yediyur'],
    'Tumakuru_Chikkanayakanahalli':    ['Kasaba', 'Chikkanayakanahalli'],
    'Tumakuru_Koratagere':             ['Kasaba', 'Koratagere'],
    'Tumakuru_Gubbi':                  ['Kasaba', 'Gubbi'],
    'Tumakuru_Pavagada':               ['Kasaba', 'Pavagada'],
    'Tumakuru_Sira':                   ['Kasaba', 'Sira'],
    // Kolar
    'Kolar_Kolar':                     ['Kasaba', 'Bangarpet', 'Mulbagal', 'Malur'],
    'Kolar_KGF':                       ['Kasaba', 'Robertsonpet'],
    'Kolar_Bangarpet':                 ['Kasaba', 'Bangarpet'],
    'Kolar_Malur':                     ['Kasaba', 'Malur'],
    'Kolar_Mulbagal':                  ['Kasaba', 'Mulbagal'],
    'Kolar_Srinivasapura':             ['Kasaba', 'Srinivasapura'],
    // Chikkaballapura
    'Chikkaballapura_Chikkaballapura': ['Kasaba', 'Gudibanda', 'Nandi'],
    'Chikkaballapura_Chintamani':      ['Kasaba', 'Chintamani', 'Shidlaghatta'],
    'Chikkaballapura_Gauribidanur':    ['Kasaba', 'Gauribidanur'],
    'Chikkaballapura_Bagepalli':       ['Kasaba', 'Bagepalli'],
    'Chikkaballapura_Gudibanda':       ['Kasaba', 'Gudibanda'],
    'Chikkaballapura_Sidlaghatta':     ['Kasaba', 'Sidlaghatta'],
    // Hassan
    'Hassan_Hassan':                   ['Kasaba', 'Arakalagudu', 'Channarayapatna', 'Holenarasipur'],
    'Hassan_Arsikere':                 ['Kasaba', 'Arsikere', 'Belur'],
    'Hassan_Belur':                    ['Kasaba', 'Belur'],
    'Hassan_Holenarasipur':            ['Kasaba', 'Holenarasipur'],
    'Hassan_Sakleshpur':               ['Kasaba', 'Sakleshpur'],
    'Hassan_Alur':                     ['Kasaba', 'Alur'],
    // Shivamogga
    'Shivamogga_Shivamogga':          ['Kasaba', 'Bhadravati', 'Hosanagara', 'Sagar'],
    'Shivamogga_Bhadravati':           ['Kasaba', 'Bhadravati'],
    'Shivamogga_Sagar':                ['Kasaba', 'Sagar', 'Sorab'],
    'Shivamogga_Shikaripura':          ['Kasaba', 'Shikaripura'],
    'Shivamogga_Thirthahalli':         ['Kasaba', 'Thirthahalli'],
    'Shivamogga_Hosanagara':           ['Kasaba', 'Hosanagara'],
    'Shivamogga_Sorab':                ['Kasaba', 'Sorab'],
    // Chikkamagaluru
    'Chikkamagaluru_Chikkamagaluru':   ['Kasaba', 'Birur', 'Kadur', 'Mudigere'],
    'Chikkamagaluru_Kadur':            ['Kasaba', 'Kadur', 'Birur'],
    'Chikkamagaluru_Koppa':            ['Kasaba', 'Koppa'],
    'Chikkamagaluru_Mudigere':         ['Kasaba', 'Mudigere'],
    'Chikkamagaluru_Tarikere':         ['Kasaba', 'Tarikere'],
    'Chikkamagaluru_Sringeri':         ['Kasaba', 'Sringeri'],
    'Chikkamagaluru_N.R.Pura':         ['Kasaba', 'N.R.Pura'],
    'Chikkamagaluru_Birur':            ['Kasaba', 'Birur'],
    // Dakshina Kannada
    'Dakshina Kannada_Mangaluru':      ['Kasaba', 'Mulki', 'Bajpe', 'Moodabidre', 'Ullal'],
    'Dakshina Kannada_Bantwal':        ['Kasaba', 'Bantwal', 'Puttur'],
    'Dakshina Kannada_Puttur':         ['Kasaba', 'Puttur', 'Sullia'],
    'Dakshina Kannada_Belthangady':    ['Kasaba', 'Belthangady', 'Dharmasthala'],
    'Dakshina Kannada_Sullia':         ['Kasaba', 'Sullia'],
    // Udupi
    'Udupi_Udupi':                     ['Kasaba', 'Brahmavar', 'Kaup', 'Kota'],
    'Udupi_Kundapura':                 ['Kasaba', 'Kundapura', 'Byndoor'],
    'Udupi_Karkala':                   ['Kasaba', 'Karkala', 'Moodbidri'],
    // Uttara Kannada
    'Uttara Kannada_Karwar':           ['Kasaba', 'Karwar', 'Ankola'],
    'Uttara Kannada_Ankola':           ['Kasaba', 'Ankola'],
    'Uttara Kannada_Sirsi':            ['Kasaba', 'Sirsi', 'Siddapur', 'Yellapur'],
    'Uttara Kannada_Kumta':            ['Kasaba', 'Kumta', 'Honnavar'],
    'Uttara Kannada_Bhatkal':          ['Kasaba', 'Bhatkal', 'Honnavar'],
    'Uttara Kannada_Haliyal':          ['Kasaba', 'Haliyal', 'Mundgod'],
    'Uttara Kannada_Siddapur':         ['Kasaba', 'Siddapur'],
    'Uttara Kannada_Mundgod':          ['Kasaba', 'Mundgod'],
    'Uttara Kannada_Yellapur':         ['Kasaba', 'Yellapur'],
    'Uttara Kannada_Supa':             ['Kasaba', 'Supa'],
    // Kodagu
    'Kodagu_Madikeri':                 ['Kasaba', 'Madikeri', 'Napoklu', 'Bhagamandala'],
    'Kodagu_Somwarpet':                ['Kasaba', 'Somwarpet', 'Shanthally'],
    'Kodagu_Virajpet':                 ['Kasaba', 'Virajpet', 'Ponnampet', 'Gonikoppal'],
    // Mandya
    'Mandya_Mandya':                   ['Kasaba', 'Maddur', 'Malavalli', 'Pandavapura'],
    'Mandya_Maddur':                   ['Kasaba', 'Maddur'],
    'Mandya_Malavalli':                ['Kasaba', 'Malavalli'],
    'Mandya_Krishnarajapete':          ['Kasaba', 'Krishnarajapete'],
    'Mandya_Nagamangala':              ['Kasaba', 'Nagamangala'],
    'Mandya_Pandavapura':              ['Kasaba', 'Pandavapura'],
    'Mandya_Shrirangapattana':         ['Kasaba', 'Shrirangapattana'],
    // Chamarajanagar
    'Chamarajanagar_Chamarajanagar':   ['Kasaba', 'Gundlupete', 'Yelandur'],
    'Chamarajanagar_Gundlupete':       ['Kasaba', 'Gundlupete', 'Hanur'],
    'Chamarajanagar_Kollegal':         ['Kasaba', 'Kollegal'],
    'Chamarajanagar_Yelandur':         ['Kasaba', 'Yelandur'],
    // Mysuru (expanded)
    'Mysuru_K.R.Nagar':               ['Kasaba', 'K.R.Nagar', 'Hunsur'],
    'Mysuru_T.Narasipura':             ['Kasaba', 'T.Narasipura', 'Bannur'],
    'Mysuru_Periyapatna':              ['Kasaba', 'Periyapatna'],
    // Davanagere
    'Davanagere_Davanagere':           ['Kasaba', 'Jagalur', 'Honnali', 'Channagiri'],
    'Davanagere_Channagiri':           ['Kasaba', 'Channagiri'],
    'Davanagere_Harihara':             ['Kasaba', 'Harihara'],
    'Davanagere_Honnali':              ['Kasaba', 'Honnali'],
    'Davanagere_Jagalur':              ['Kasaba', 'Jagalur'],
    'Davanagere_Nyamathi':             ['Kasaba', 'Nyamathi'],
    // Chitradurga
    'Chitradurga_Chitradurga':         ['Kasaba', 'Hiriyur', 'Holalkere', 'Hosadurga'],
    'Chitradurga_Hiriyur':             ['Kasaba', 'Hiriyur'],
    'Chitradurga_Holalkere':           ['Kasaba', 'Holalkere'],
    'Chitradurga_Hosadurga':           ['Kasaba', 'Hosadurga'],
    'Chitradurga_Challakere':          ['Kasaba', 'Challakere', 'Molakalmuru'],
    'Chitradurga_Molakalmuru':         ['Kasaba', 'Molakalmuru'],
    // Gadag
    'Gadag_Gadag':                     ['Kasaba', 'Ron', 'Nargund', 'Mundargi'],
    'Gadag_Ron':                       ['Kasaba', 'Ron'],
    'Gadag_Nargund':                   ['Kasaba', 'Nargund'],
    'Gadag_Mundargi':                  ['Kasaba', 'Mundargi'],
    'Gadag_Shirahatti':                ['Kasaba', 'Shirahatti'],
    // Haveri
    'Haveri_Haveri':                   ['Kasaba', 'Ranebennur', 'Shiggaon', 'Savanur'],
    'Haveri_Ranebennur':               ['Kasaba', 'Ranebennur'],
    'Haveri_Shiggaon':                 ['Kasaba', 'Shiggaon'],
    'Haveri_Byadagi':                  ['Kasaba', 'Byadagi'],
    'Haveri_Hangal':                   ['Kasaba', 'Hangal'],
    'Haveri_Hirekerur':                ['Kasaba', 'Hirekerur'],
    'Haveri_Savanur':                  ['Kasaba', 'Savanur'],
    // Dharwad / Hubballi-Dharwad
    'Hubballi-Dharwad_Hubballi':       ['Kasaba', 'Hubballi', 'Dharwad', 'Kundgol'],
    'Hubballi-Dharwad_Dharwad':        ['Kasaba', 'Dharwad', 'Navalgund'],
    'Hubballi-Dharwad_Kundgol':        ['Kasaba', 'Kundgol'],
    'Hubballi-Dharwad_Kalghatgi':      ['Kasaba', 'Kalghatgi'],
    'Hubballi-Dharwad_Navalgund':      ['Kasaba', 'Navalgund'],
    'Dharwad_Dharwad':                 ['Kasaba', 'Navalgund', 'Kundgol'],
    'Dharwad_Hubli':                   ['Kasaba', 'Hubli'],
    // Koppal
    'Koppal_Koppal':                   ['Kasaba', 'Gangavathi', 'Kushtagi', 'Yelburga'],
    'Koppal_Gangavathi':               ['Kasaba', 'Gangavathi'],
    'Koppal_Kushtagi':                 ['Kasaba', 'Kushtagi'],
    'Koppal_Yelburga':                 ['Kasaba', 'Yelburga'],
    // Ballari
    'Ballari_Ballari':                 ['Kasaba', 'Hospet', 'Sandur', 'Siruguppa'],
    'Ballari_Hospet':                  ['Kasaba', 'Hospet', 'Kampli'],
    'Ballari_Sandur':                  ['Kasaba', 'Sandur'],
    'Ballari_Siruguppa':               ['Kasaba', 'Siruguppa'],
    'Ballari_Hadagali':                ['Kasaba', 'Hadagali'],
    'Ballari_Hagaribommanahalli':      ['Kasaba', 'Hagaribommanahalli'],
    'Ballari_Kudligi':                 ['Kasaba', 'Kudligi'],
    // Raichur
    'Raichur_Raichur':                 ['Kasaba', 'Sindhanur', 'Manvi', 'Lingsugur'],
    'Raichur_Sindhanur':               ['Kasaba', 'Sindhanur'],
    'Raichur_Manvi':                   ['Kasaba', 'Manvi'],
    'Raichur_Lingsugur':               ['Kasaba', 'Lingsugur'],
    'Raichur_Deodurga':                ['Kasaba', 'Deodurga'],
    // Yadgir
    'Yadgir_Yadgir':                   ['Kasaba', 'Shorapur', 'Shahapur'],
    'Yadgir_Shorapur':                 ['Kasaba', 'Shorapur', 'Gurmatkal'],
    'Yadgir_Shahapur':                 ['Kasaba', 'Shahapur'],
    // Kalaburagi
    'Kalaburagi_Kalaburagi':           ['Kasaba', 'Aland', 'Afzalpur', 'Sedam'],
    'Kalaburagi_Aland':                ['Kasaba', 'Aland'],
    'Kalaburagi_Afzalpur':             ['Kasaba', 'Afzalpur'],
    'Kalaburagi_Chincholi':            ['Kasaba', 'Chincholi'],
    'Kalaburagi_Chittapur':            ['Kasaba', 'Chittapur'],
    'Kalaburagi_Gurmatkal':            ['Kasaba', 'Gurmatkal'],
    'Kalaburagi_Jevargi':              ['Kasaba', 'Jevargi'],
    'Kalaburagi_Sedam':                ['Kasaba', 'Sedam'],
    // Bidar
    'Bidar_Bidar':                     ['Kasaba', 'Basavakalyan', 'Bhalki', 'Humnabad'],
    'Bidar_Basavakalyan':              ['Kasaba', 'Basavakalyan'],
    'Bidar_Bhalki':                    ['Kasaba', 'Bhalki'],
    'Bidar_Humnabad':                  ['Kasaba', 'Humnabad'],
    'Bidar_Aurad':                     ['Kasaba', 'Aurad'],
    // Vijayapura
    'Vijayapura_Vijayapura':           ['Kasaba', 'Indi', 'Sindagi', 'Muddebihal'],
    'Vijayapura_Bijapur':              ['Kasaba', 'Bijapur', 'Indi'],
    'Vijayapura_Indi':                 ['Kasaba', 'Indi'],
    'Vijayapura_Sindagi':              ['Kasaba', 'Sindagi'],
    'Vijayapura_Muddebihal':           ['Kasaba', 'Muddebihal'],
    'Vijayapura_Basavana Bagevadi':    ['Kasaba', 'Basavana Bagevadi'],
    // Belagavi (expanded)
    'Belagavi_Belagavi':               ['Kasaba', 'Khanapur', 'Gokak', 'Chikkodi'],
    'Belagavi_Athani':                 ['Kasaba', 'Athani'],
    'Belagavi_Bailhongal':             ['Kasaba', 'Bailhongal'],
    'Belagavi_Chikkodi':               ['Kasaba', 'Chikkodi'],
    'Belagavi_Gokak':                  ['Kasaba', 'Gokak'],
    'Belagavi_Hukkeri':                ['Kasaba', 'Hukkeri'],
    'Belagavi_Khanapur':               ['Kasaba', 'Khanapur'],
    'Belagavi_Raibag':                 ['Kasaba', 'Raibag'],
    'Belagavi_Ramdurg':                ['Kasaba', 'Ramdurg'],
    'Belagavi_Savadatti':              ['Kasaba', 'Savadatti'],
    // Mangaluru (expanded)
    'Mangaluru_Puttur':                ['Kasaba', 'Puttur'],
    'Mangaluru_Sullia':                ['Kasaba', 'Sullia'],
    'Mangaluru_Belthangady':           ['Kasaba', 'Belthangady'],
    // Ramanagara (expanded)
    'Ramanagara_Channapatna':          ['Kasaba', 'Channapatna'],
  };

  // ─── Village map (district_taluk_hobli → villages) ───────────────────────
  static const Map<String, List<String>> hobliVillages = {
    // Dasanapura 3 — EXACT village names from Bhoomi portal (confirmed live)
    // Yashavantapura hoblis — Bhoomi portal confirmed names
    'Bengaluru Urban_Bengaluru North_Yashavantapura 1': [
      'Yeshwanthapura', 'Rajajinagar', 'Subramanyanagar', 'Mahalakshmi Layout',
      'Srirampuram', 'Vijayanagar', 'Basaveshwaranagar',
    ],
    'Bengaluru Urban_Bengaluru North_Yashavantapura 2': [
      'Mathikere', 'Sadashivanagar', 'Gokula', 'Gayatrinagar',
      'Jalahalli', 'Hesaraghatta', 'Nagasandra',
    ],
    // Kasaba hoblis — Bangalore North
    'Bengaluru Urban_Bengaluru North_Kasaba 1': [
      'Kasaba', 'Hebbal', 'Kodigehalli', 'Sadahalli', 'Yeshwanthapura',
      'Karivobinahalli', 'Rachenahalli', 'Nagawara',
    ],
    'Bengaluru Urban_Bengaluru North_Kasaba 2': [
      'Kasaba', 'Hebbal', 'Rachenahalli', 'Thanisandra',
      'Karivobinahalli', 'Kogilu', 'Singanayakanahalli',
    ],
    'Bengaluru Urban_Bengaluru North_Dasanapura 3': [
      'Avarehalli', 'Bairegowdanahalli', 'Gattisiddanahalli', 'Gejjagadahalli',
      'Gowdahalli', 'Gullarapalya', 'Hullegowdanahalli', 'Hunnigere',
      'Kenganahalli', 'Kittanahalli', 'Lakkenahalli', 'Mallasandra',
      'Nagasandra', 'Ravutanahalli', 'Shivanapura', 'Sondekoppa', 'Vankatapura',
    ],
    'Bengaluru Urban_Bengaluru North_Dasanapura 1': [
      'T. Dasarahalli', 'Agrahara Dasarahalli', 'Nagasandra', 'Chikkabanavara',
    ],
    'Bengaluru Urban_Bengaluru North_Dasanapura 2': [
      'Bhoganhalli', 'Machohalli', 'Madavara', 'Thigalarpalya',
    ],
    'Bengaluru Urban_Bengaluru North_Kasaba (Bangalore North)': [
      'Kasaba', 'Hebbal', 'Sadahalli', 'Kodigehalli', 'Yeshwanthapura',
    ],
    'Bengaluru Urban_Bengaluru North_Yelahanka': [
      'Yelahanka', 'Kogilu', 'Bagalur', 'Hunasemaranahalli', 'Doddabidarakallu',
    ],
    'Bengaluru Urban_Bengaluru North_Jala 1': [
      'Jala', 'Singanayakanahalli', 'Attur', 'Rajanukunte',
    ],
    'Bengaluru Urban_Bengaluru North_Jala 2': [
      'Jala', 'Chikkanahalli', 'Bettahalsur', 'Laxmipura',
    ],
    // Yelahanka taluk
    'Bengaluru Urban_Yelahanka_Yelahanka':   ['Yelahanka', 'Kogilu', 'Doddabidarakallu', 'Kodigehalli', 'Bagalur', 'Hunasemaranahalli'],
    'Bengaluru Urban_Yelahanka_Kasaba':      ['Kasaba', 'Amruthahalli', 'Sahakaranagar', 'Hebbal'],
    'Bengaluru Urban_Yelahanka_Jala 1':      ['Jala', 'Singanayakanahalli', 'Attur', 'Rajanukunte'],
    'Bengaluru Urban_Yelahanka_Jala 2':      ['Jala', 'Chikkanahalli', 'Bettahalsur'],
    // South / East
    'Bengaluru Urban_Bengaluru South_Begur': ['Begur', 'Electronic City', 'Kudlu', 'Harlur', 'Carmelaram'],
    'Bengaluru Urban_Bengaluru South_Kengeri':['Kengeri', 'Uttarahalli', 'Bomanahalli'],
    'Bengaluru Urban_Bengaluru East_Varthur':['Varthur', 'Whitefield', 'Marathahalli', 'Kadugodi'],
    'Bengaluru Urban_Bengaluru East_Kasaba': ['Kasaba', 'Hebbal', 'Sadahalli', 'Kodigehalli'],
    'Bengaluru Urban_Anekal_Attibele':       ['Attibele', 'Dommasandra', 'Sarjapura', 'Carmelaram'],
    'Bengaluru Urban_Anekal_Jigani':         ['Jigani', 'Haragadde', 'Madiwala'],
    // Rural
    'Bengaluru Rural_Devanahalli_Devanahalli':['Devanahalli', 'Vijayapura', 'Kundana', 'Sulibele'],
    'Bengaluru Rural_Hoskote_Hoskote':       ['Hoskote', 'Jadigenahalli', 'Nandagudi', 'Sulibele'],
    'Bengaluru Rural_Nelamangala_Nelamangala':['Nelamangala', 'Soladevanahalli', 'Doddamagge'],
    // Other districts
    'Mysuru_Mysuru_Kasaba':                  ['Kasaba', 'Vijayanagar', 'Bannimantap', 'Chamundi Hill'],
    'Mangaluru_Mangaluru_Kasaba':            ['Kasaba', 'Kulur', 'Kankanady', 'Surathkal'],
    'Ramanagara_Kanakapura_Kanakapura':      ['Kanakapura', 'Sathanur', 'Harohalli', 'Gudemaranahalli'],
  };

  List<String> get _taluks =>
      _selectedDistrict != null ? (districtTaluks[_selectedDistrict] ?? []) : [];

  // ─── Load hoblis for selected district+taluk ──────────────────────────────
  Future<void> _loadHoblis(String district, String taluk) async {
    final key = '${district}_$taluk';
    final local = talukHoblis[key];
    if (local != null && local.isNotEmpty) {
      setState(() { _hobliList = local; _selectedHobli = null; _selectedVillage = null; _villageList = []; });
      return;
    }
    // Try Bhoomi API
    setState(() { _loadingHobli = true; _hobliList = []; _selectedHobli = null; });
    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.backendBaseUrl}/hoblis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'district': district, 'taluk': taluk}),
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final list = (data['hoblis'] as List?)?.map((e) => e.toString()).toList() ?? [];
        setState(() { _hobliList = list; });
      }
    } catch (_) {}
    setState(() { _loadingHobli = false; });
  }

  // ─── Load villages for selected district+taluk+hobli ─────────────────────
  Future<void> _loadVillages(String district, String taluk, String hobli) async {
    final key = '${district}_${taluk}_$hobli';
    final local = hobliVillages[key];
    if (local != null && local.isNotEmpty) {
      setState(() { _villageList = local; _selectedVillage = null; });
      return;
    }
    setState(() { _loadingVillage = true; _villageList = []; _selectedVillage = null; });
    try {
      final r = await http.post(
        Uri.parse('${ApiConstants.backendBaseUrl}/villages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'district': district, 'taluk': taluk, 'hobli': hobli}),
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final list = (data['villages'] as List?)?.map((e) => e.toString()).toList() ?? [];
        setState(() { _villageList = list; });
      }
    } catch (_) {}
    setState(() { _loadingVillage = false; });
  }

  // ─── Friendly display name for district dropdown ────────────────────────────
  static String _districtLabel(String d) {
    const aliases = {
      'Bengaluru Urban': 'Bengaluru (Urban) — Bangalore City',
      'Bengaluru Rural': 'Bengaluru (Rural) — Bangalore Outskirts',
      'Mysuru':          'Mysuru (Mysore)',
      'Kalaburagi':      'Kalaburagi (Gulbarga)',
      'Belagavi':        'Belagavi (Belgaum)',
      'Ballari':         'Ballari (Bellary)',
      'Shivamogga':      'Shivamogga (Shimoga)',
      'Vijayapura':      'Vijayapura (Bijapur)',
      'Tumakuru':        'Tumakuru (Tumkur)',
    };
    return aliases[d] ?? d;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill from OCR results passed by camera scan screen
    final sv = widget.prefillSurveyNumber;
    final owner = widget.prefillOwnerName;
    final district = widget.prefillDistrict;
    final taluk = widget.prefillTaluk;
    if (sv != null && sv.isNotEmpty) {
      _surveyController.text = sv;
      _prefillApplied = true;
    }
    if (owner != null && owner.isNotEmpty) {
      _ownerNameController.text = owner;
      _prefillApplied = true;
      // Also switch to village/name mode so the owner field is visible
      if (sv == null || sv.isEmpty) _searchMode = 1;
    }
    if (district != null && district.isNotEmpty) {
      // Try exact match first, then case-insensitive
      final matched = districtTaluks.keys.firstWhere(
        (d) => d.toLowerCase() == district.toLowerCase(),
        orElse: () => '',
      );
      if (matched.isNotEmpty) {
        _selectedDistrict = matched;
        _prefillApplied = true;
      }
    }
    if (taluk != null && taluk.isNotEmpty && _selectedDistrict != null) {
      final taluks = districtTaluks[_selectedDistrict] ?? [];
      final matched = taluks.firstWhere(
        (t) => t.toLowerCase() == taluk.toLowerCase(),
        orElse: () => '',
      );
      if (matched.isNotEmpty) {
        _selectedTaluk = matched;
      }
    }
  }

  @override
  void dispose() {
    _surveyController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  // ─── GPS Auto-Detect (Dishank-style) ──────────────────────────────────────
  Future<void> _detectFromGps() async {
    setState(() { _isDetectingGps = true; _gpsMessage = null; });
    try {
      final gpsService = GpsService();
      final result = await gpsService.detectAndFill();

      setState(() {
        _isDetectingGps = false;
        if (result.hasSurveyNumber) {
          _surveyController.text = result.surveyNumber!;
          _gpsMessage = 'Survey number detected from GPS (${result.source})';
        }
        // Auto-fill district — case-insensitive match
        if (result.district != null) {
          final raw = result.district!;
          String matched = AppStrings.karnatakaDistricts.firstWhere(
            (d) => d.toLowerCase() == raw.toLowerCase(),
            orElse: () => '',
          );
          if (matched.isEmpty) {
            // Partial match: "bangalore" → "Bengaluru Urban"
            final lower = raw.toLowerCase();
            matched = AppStrings.karnatakaDistricts.firstWhere(
              (d) => d.toLowerCase().contains(lower) ||
                     lower.contains(d.split(' ').first.toLowerCase()),
              orElse: () => '',
            );
          }
          if (matched.isNotEmpty) {
            _selectedDistrict = matched;
            _selectedTaluk = null;
            if (!result.hasSurveyNumber) {
              _gpsMessage = 'Location found — district set to $matched';
            }
          } else {
            if (!result.hasSurveyNumber) {
              _gpsMessage = 'Location found — please select district manually';
            }
          }
        } else if (!result.hasSurveyNumber) {
          _gpsMessage = 'GPS detected but location unclear. Please select district manually.';
        }
        // Auto-fill taluk
        if (result.taluk != null && result.taluk!.isNotEmpty && _selectedDistrict != null) {
          final taluks = districtTaluks[_selectedDistrict] ?? [];
          final matchedTaluk = taluks.firstWhere(
            (t) => t.toLowerCase() == result.taluk!.toLowerCase() ||
                   result.taluk!.toLowerCase().contains(t.toLowerCase()),
            orElse: () => '',
          );
          if (matchedTaluk.isNotEmpty) {
            _selectedTaluk = matchedTaluk;
            _loadHoblis(_selectedDistrict!, matchedTaluk);
          }
        }
        if (result.village != null && result.village!.isNotEmpty) {
          _selectedVillage = result.village;
        }
        if (result.hobli != null && result.hobli!.isNotEmpty) {
          _selectedHobli = result.hobli;
          if (_selectedDistrict != null && _selectedTaluk != null) {
            _loadVillages(_selectedDistrict!, _selectedTaluk!, result.hobli!);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isDetectingGps = false;
        _gpsMessage = 'Could not detect location. Please enable GPS and try again.';
      });
    }
  }

  void _search() {
    if (!_formKey.currentState!.validate()) return;
    final surveyNo = _searchMode == 0
        ? _surveyController.text.trim()
        : (_selectedVillage ?? '');
    final scan = PropertyScan(
      id: const Uuid().v4(),
      surveyNumber: surveyNo,
      district: _selectedDistrict,
      taluk: _selectedTaluk,
      hobli: _selectedHobli,
      village: _selectedVillage,
      location: ref.read(currentLocationProvider),
      scanMethod: ScanMethod.manual,
      scannedAt: DateTime.now(),
    );
    ref.read(currentScanProvider.notifier).state = scan;
    ref.read(propertyCheckNotifierProvider.notifier).setScan(scan);
    // Save search to Firestore history
    UserService().saveSearch(
      surveyNumber: surveyNo,
      district: _selectedDistrict,
      taluk: _selectedTaluk,
      hobli: _selectedHobli,
      village: _selectedVillage,
    );
    // Store property type so auto-scan knows which portals to show
    ref.read(propertyTypeProvider.notifier).state = _propertyType;
    // Go to Auto Scan — fetches all portals automatically, zero manual steps
    context.push('/auto-scan');
  }

  String get _propertyTypeHint {
    switch (_propertyType) {
      case 'apartment':  return 'RERA check included — mandatory for builder projects';
      case 'bda_layout': return 'BDA/BMRDA approval check included';
      case 'house':      return 'RERA not required for independent houses';
      default:           return 'RERA not required for sites/plots';
    }
  }

  Widget _typeChip(String type, String label, IconData icon) {
    final selected = _propertyType == type;
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.grey.shade800)),
      ]),
      selected: selected,
      selectedColor: const Color(0xFF1B5E20),
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => setState(() => _propertyType = type),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ಜಮೀನು ಪರಿಶೀಲನೆ / Property Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Building scan banner ─────────────────────────────────
              if (widget.buildingInfo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.apartment, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          widget.buildingName ?? 'Building Scan',
                          style: const TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.bold),
                        )),
                      ]),
                      if (widget.selectedBlock != null || widget.selectedFlat != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 26),
                          child: Text(
                            [
                              if (widget.selectedBlock != null) 'Block: ${widget.selectedBlock}',
                              if (widget.selectedFlat != null) 'Flat: ${widget.selectedFlat}',
                            ].join('  |  '),
                            style: const TextStyle(color: Color(0xFF1565C0), fontSize: 12),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.only(top: 4, left: 26),
                        child: Text(
                          'Enter the survey number from your sale deed or ask the builder for the property details.',
                          style: TextStyle(color: Colors.blue, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── OCR Pre-fill Banner ──────────────────────────────────
              if (_prefillApplied && widget.buildingInfo == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Fields pre-filled from your document scan. Review and confirm before checking.',
                          style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── State Selector ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.public, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('ರಾಜ್ಯ / State',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _states.map((s) {
                          final name = s['name'] as String;
                          final live = s['live'] as bool;
                          final selected = _selectedState == name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                if (live) {
                                  setState(() => _selectedState = name);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '$name — Coming Soon! We are expanding next.'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : live
                                          ? const Color(0xFFE8F5E9)
                                          : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : live
                                            ? AppColors.primary.withOpacity(0.3)
                                            : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selected
                                            ? Colors.white
                                            : live
                                                ? AppColors.primary
                                                : Colors.grey,
                                      ),
                                    ),
                                    if (!live) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('Soon',
                                            style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── GPS Auto-Detect Button ───────────────────────────────
              GestureDetector(
                onTap: _isDetectingGps ? null : _detectFromGps,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isDetectingGps
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Detecting from GPS...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.my_location, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GPS ನಿಂದ ಸರ್ವೆ ನಂಬರ್ ಪಡೆಯಿರಿ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  'Auto-detect survey number from current location',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
              if (_gpsMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gpsMessage!.contains('detected')
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _gpsMessage!.contains('detected')
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 16,
                        color: _gpsMessage!.contains('detected')
                            ? AppColors.primary
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _gpsMessage!.contains('detected')
                                ? AppColors.primary
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Mode Toggle ──────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderColor),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ModeTab(
                      icon: Icons.tag,
                      label: 'ಸರ್ವೆ ನಂಬರ್ ಇದೆ',
                      sublabel: 'I have survey number',
                      selected: _searchMode == 0,
                      onTap: () => setState(() => _searchMode = 0),
                    ),
                    _ModeTab(
                      icon: Icons.holiday_village,
                      label: 'ಹಳ್ಳಿ / ಹೆಸರಿನಿಂದ',
                      sublabel: 'Search by village / name',
                      selected: _searchMode == 1,
                      onTap: () => setState(() => _searchMode = 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── MODE 0: Survey Number ────────────────────────────────
              if (_searchMode == 0) ...[
                _KannadaFieldLabel(
                  kannada: 'ಸರ್ವೆ ನಂಬರ್',
                  english: 'Survey Number (from land document)',
                  required: true,
                ),
                TextFormField(
                  controller: _surveyController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 45/2  or  123  or  67/A',
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'ಸರ್ವೆ ನಂಬರ್ ನಮೂದಿಸಿ / Enter survey number'
                      : null,
                ),
                const SizedBox(height: 6),
                const _SurveyHint(),
                const SizedBox(height: 16),
              ],

              // ── MODE 1: Village / Owner Name ─────────────────────────
              if (_searchMode == 1) ...[
                // Rural-friendly banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ಸರ್ವೆ ನಂಬರ್ ಗೊತ್ತಿಲ್ಲವೇ? ಹಳ್ಳಿ ಮತ್ತು ಮಾಲೀಕರ ಹೆಸರಿನಿಂದ ಹುಡುಕಿ.\n'
                          'No survey number? Search by village + owner name.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _KannadaFieldLabel(
                  kannada: 'ಮಾಲೀಕರ ಹೆಸರು',
                  english: 'Owner / Seller Name',
                  required: false,
                ),
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Ramesh Kumar, Krishnappa...',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Property Type ─────────────────────────────────────────
              const SizedBox(height: 8),
              _KannadaFieldLabel(
                kannada: 'ಆಸ್ತಿ ವಿಧ',
                english: 'Property Type',
                required: false,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _typeChip('site',       'Site / Plot',     Icons.terrain),
                  _typeChip('house',      'House / Villa',   Icons.house),
                  _typeChip('apartment',  'Apartment / Flat', Icons.apartment),
                  _typeChip('bda_layout', 'BDA / BMRDA Layout', Icons.location_city),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _propertyTypeHint,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),

              // ── Common: District / Taluk / Village ───────────────────
              _KannadaFieldLabel(
                kannada: 'ಜಿಲ್ಲೆ',
                english: 'District (where the land is)',
                required: true,
              ),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_city)),
                hint: const Text('ಜಿಲ್ಲೆ ಆಯ್ಕೆ ಮಾಡಿ / Select District'),
                isExpanded: true,
                items: AppStrings.karnatakaDistricts
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(_districtLabel(d)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedDistrict = v;
                  _selectedTaluk = null;
                  _selectedHobli = null;
                  _selectedVillage = null;
                  _hobliList = [];
                  _villageList = [];
                }),
                validator: (v) =>
                    v == null ? 'ಜಿಲ್ಲೆ ಆಯ್ಕೆ ಮಾಡಿ / Select district' : null,
              ),
              const SizedBox(height: 16),

              if (_selectedDistrict != null) ...[
                _KannadaFieldLabel(
                  kannada: 'ತಾಲ್ಲೂಕು',
                  english: 'Taluk',
                  required: false,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedTaluk,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.map_outlined)),
                  hint: const Text('ತಾಲ್ಲೂಕು ಆಯ್ಕೆ ಮಾಡಿ / Select Taluk'),
                  isExpanded: true,
                  items: _taluks
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedTaluk = v;
                      _selectedHobli = null;
                      _selectedVillage = null;
                      _hobliList = [];
                      _villageList = [];
                    });
                    if (v != null && _selectedDistrict != null) {
                      _loadHoblis(_selectedDistrict!, v);
                    }
                  },
                ),
                const SizedBox(height: 16),

                _KannadaFieldLabel(
                  kannada: 'ಹೋಬಳಿ',
                  english: 'Hobli (Revenue Circle)',
                  required: false,
                ),
                if (_loadingHobli)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Loading hoblis...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                      ],
                    ),
                  )
                else if (_hobliList.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedHobli,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_tree_outlined)),
                    hint: const Text('ಹೋಬಳಿ ಆಯ್ಕೆ ಮಾಡಿ / Select Hobli'),
                    isExpanded: true,
                    items: _hobliList
                        .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedHobli = v;
                        _selectedVillage = null;
                        _villageList = [];
                      });
                      if (v != null && _selectedDistrict != null && _selectedTaluk != null) {
                        _loadVillages(_selectedDistrict!, _selectedTaluk!, v);
                      }
                    },
                  )
                else
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'e.g. Yelahanka, Kasaba, Attibele...',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    onChanged: (v) => setState(() => _selectedHobli = v.trim().isEmpty ? null : v.trim()),
                  ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Hobli is the revenue sub-division of a taluk. Found on your RTC document.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],

              _KannadaFieldLabel(
                kannada: 'ಹಳ್ಳಿ / ಬಡಾವಣೆ',
                english: 'Village / Area',
                required: false,
              ),
              if (_loadingVillage)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Loading villages...', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                )
              else if (_villageList.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedVillage,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.villa_outlined)),
                  hint: const Text('ಹಳ್ಳಿ ಆಯ್ಕೆ ಮಾಡಿ / Select Village'),
                  isExpanded: true,
                  items: _villageList
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedVillage = v),
                )
              else ...[
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'ಉದಾ: ಯಲಹಂಕ, ದೇವನಹಳ್ಳಿ... / e.g. Yelahanka...',
                    prefixIcon: Icon(Icons.villa_outlined),
                  ),
                  onChanged: (v) => setState(() => _selectedVillage = v.trim().isEmpty ? null : v.trim()),
                ),
                if (_selectedHobli != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.blue),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Type your village name exactly as shown on your RTC / Pahani document. '
                            'Example: Yeshwanthapura, Mathikere, Nagasandra',
                            style: TextStyle(fontSize: 11, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),

              // ── Rural Help Box ───────────────────────────────────────
              const _RuralHelpCard(),
              const SizedBox(height: 24),

              // ── Search Button ────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.radar),
                label: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ಸ್ವಯಂಚಾಲಿತ ಸ್ಕ್ಯಾನ್ / Auto Scan Property',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Bhoomi · Kaveri · eCourts · CERSAI · RERA — automatic',
                        style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/map'),
                icon: const Icon(Icons.map),
                label: const Text('ನಕ್ಷೆಯಲ್ಲಿ ನೋಡಿ / View on Map'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode Tab ──────────────────────────────────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.icon, required this.label, required this.sublabel,
    required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.grey)),
              Text(sublabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: selected ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kannada Field Label ───────────────────────────────────────────────────────
class _KannadaFieldLabel extends StatelessWidget {
  final String kannada, english;
  final bool required;
  const _KannadaFieldLabel({
    required this.kannada, required this.english, this.required = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(kannada,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary)),
          const SizedBox(width: 6),
          Text('/ $english',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (required)
            const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

// ── Rural Help Card ───────────────────────────────────────────────────────────
class _RuralHelpCard extends StatefulWidget {
  const _RuralHelpCard();
  @override
  State<_RuralHelpCard> createState() => _RuralHelpCardState();
}

class _RuralHelpCardState extends State<_RuralHelpCard> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ಸಹಾಯ ಬೇಕೇ? / Need help finding property details?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: Colors.amber),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Divider(),
                  SizedBox(height: 4),
                  _HelpRow('📄', 'ಆರ್‌ಟಿಸಿ / RTC ಪತ್ರ',
                      'ಸರ್ವೆ ನಂಬರ್ ಮೇಲ್ಭಾಗದಲ್ಲಿ ಇರುತ್ತದೆ\nSurvey number is on top of RTC document'),
                  SizedBox(height: 8),
                  _HelpRow('🏠', 'ಮಾರಾಟ ಪತ್ರ / Sale Deed',
                      '"Schedule of Property" ಅಡಿಯಲ್ಲಿ ಸರ್ವೆ ನಂಬರ್ ಇರುತ್ತದೆ\nSurvey number is under "Schedule of Property"'),
                  SizedBox(height: 8),
                  _HelpRow('📱', 'ಸಿಎಸ್ಸಿ ಕೇಂದ್ರ / CSC Centre',
                      'ಗ್ರಾಮ ಪಂಚಾಯತ್ ಡಿಜಿಟಲ್ ಕೇಂದ್ರದಲ್ಲಿ ಸಹಾಯ ಪಡೆಯಿರಿ\nGet help at your village panchayat CSC centre'),
                  SizedBox(height: 8),
                  _HelpRow('⚠️', 'ಎಚ್ಚರಿಕೆ / Warning',
                      'ಸರ್ವೆ ನಂಬರ್ ಇಲ್ಲದೆ ಮುಂಗಡ ಹಣ ನೀಡಬೇಡಿ\nNever pay advance without knowing survey number'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final String emoji, title, desc;
  const _HelpRow(this.emoji, this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
              Text(desc,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurveyHint extends StatefulWidget {
  const _SurveyHint();
  @override
  State<_SurveyHint> createState() => _SurveyHintState();
}

class _SurveyHintState extends State<_SurveyHint> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Row(
            children: [
              Icon(_open ? Icons.expand_less : Icons.help_outline,
                  size: 15, color: AppColors.info),
              const SizedBox(width: 5),
              const Text('Where do I find the survey number?',
                  style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HintRow('On the RTC / Pahani document', 'Top section — printed as "Sy. No." or "Survey No."'),
                SizedBox(height: 6),
                _HintRow('On the sale deed / agreement', 'First page — under "Schedule of Property"'),
                SizedBox(height: 6),
                _HintRow('Don\'t have it?', 'Ask the seller — every land has one. No survey number = verify before paying anything'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  final String title, desc;
  const _HintRow(this.title, this.desc);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
        Expanded(child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.4),
            children: [
              TextSpan(text: '$title — ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: desc),
            ],
          ),
        )),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark,
          )),
          if (required)
            const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
