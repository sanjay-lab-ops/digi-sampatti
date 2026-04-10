import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:digi_sampatti/core/constants/api_constants.dart';

// ─── OCR Service ───────────────────────────────────────────────────────────────
// Uses Anthropic Vision API (Claude claude-sonnet-4-6) to extract property details
// from a scanned document photo:
//   - Survey number / Sarvey Sankhya
//   - Owner name
//   - Taluk & district
//   - Khata number
//   - Property address
//
// Why Anthropic Vision instead of Google ML Kit:
//   - Handles handwritten + printed mixed Kannada/English docs
//   - Understands document context (RTC, EC, sale deed headers)
//   - Already integrated — no extra dependency or billing account
// ──────────────────────────────────────────────────────────────────────────────

/// What the camera captured — determines which UI flow to show
enum ScanType { document, building, unknown }

class OcrResult {
  final String? surveyNumber;
  final String? ownerName;
  final String? taluk;
  final String? district;
  final String? khataNumber;
  final String? propertyAddress;
  final String? documentType;   // RTC / EC / Sale Deed / Khata / Other
  final double confidence;      // 0.0 – 1.0
  final String? rawText;        // Full extracted text for fallback

  // Building detection fields
  final ScanType scanType;               // document / building / unknown
  final String? buildingName;            // "Prestige Lakeside Habitat"
  final List<String> visibleBlocks;      // ["A", "B", "C"] or ["Block 1", "Tower 2"]
  final List<String> visibleFlats;       // ["A101", "A102", ...] if flat numbers visible
  final String? buildingAddress;         // street address of building

  const OcrResult({
    this.surveyNumber,
    this.ownerName,
    this.taluk,
    this.district,
    this.khataNumber,
    this.propertyAddress,
    this.documentType,
    this.confidence = 0.0,
    this.rawText,
    this.scanType = ScanType.unknown,
    this.buildingName,
    this.visibleBlocks = const [],
    this.visibleFlats = const [],
    this.buildingAddress,
  });

  bool get hasUsefulData =>
      surveyNumber != null || ownerName != null || khataNumber != null;

  bool get isBuilding => scanType == ScanType.building;

  @override
  String toString() =>
      'OcrResult(type=$scanType, survey=$surveyNumber, owner=$ownerName, '
      'taluk=$taluk, district=$district, doc=$documentType, conf=$confidence, '
      'building=$buildingName, blocks=$visibleBlocks)';
}

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  late final Dio _dio;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.claudeBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    _initialized = true;
  }

  // ─── Full Document Extraction via Backend (Claude Vision) ────────────────
  // Sends image to Railway backend → Claude Vision → returns all RTC/EC/Deed fields
  // This bypasses Bhoomi portal entirely — works for physical documents user has.
  Future<Map<String, dynamic>?> extractFullDocumentFromBackend(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

      final resp = await http.post(
        Uri.parse('${ApiConstants.backendBaseUrl}/rtc-from-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_base64': base64Image,
          'image_type': mimeType,
          'document_hint': '',
        }),
      ).timeout(const Duration(seconds: 45));

      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[OCR-backend] extractFullDocument failed: $e');
    }
    return null;
  }

  // ─── Extract Property Details from Document Photo ─────────────────────────
  Future<OcrResult> extractFromDocument(String imagePath) async {
    if (!_initialized) initialize();

    final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
    if (apiKey.isEmpty) return const OcrResult(confidence: 0.0);

    try {
      // Read image as base64
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return const OcrResult(confidence: 0.0);

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Detect mime type (camera always produces JPEG)
      final mimeType = imagePath.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final response = await _dio.post(
        '/messages',
        options: Options(headers: ApiConstants.claudeHeaders(apiKey)),
        data: json.encode({
          'model': ApiConstants.claudeModel,
          'max_tokens': 800,
          'system': _ocrSystemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mimeType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': 'Analyze this image. Is it a property DOCUMENT (RTC, EC, sale deed, etc.) or a BUILDING PHOTO (apartment, house, plot)? Return JSON only.',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final content = response.data['content'] as List;
        final text = (content.first['text'] as String).trim();
        return _parseOcrResponse(text);
      }
    } catch (e, stack) {
      // Log error so we can diagnose — caller falls back to manual entry
      debugPrint('[OCR] extractFromDocument failed: $e');
      debugPrint('[OCR] stack: $stack');
    }

    return const OcrResult(confidence: 0.0);
  }

  // ─── Parse JSON Response ───────────────────────────────────────────────────
  OcrResult _parseOcrResponse(String text) {
    try {
      // Extract JSON block if wrapped in markdown
      String jsonStr = text;
      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)```').firstMatch(text);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1)!.trim();
      } else {
        // Find first { ... }
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start != -1 && end != -1) {
          jsonStr = text.substring(start, end + 1);
        }
      }

      final Map<String, dynamic> data = json.decode(jsonStr);

      // Determine scan type
      final scanTypeStr = (data['scan_type'] as String? ?? 'unknown').toLowerCase();
      final scanType = scanTypeStr == 'building'
          ? ScanType.building
          : scanTypeStr == 'document'
              ? ScanType.document
              : ScanType.unknown;

      // Parse visible blocks/flats lists
      List<String> parseList(dynamic v) {
        if (v == null) return [];
        if (v is List) return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        if (v is String && v.isNotEmpty) return [v];
        return [];
      }

      return OcrResult(
        scanType:        scanType,
        // Document fields
        surveyNumber:    _clean(data['survey_number']),
        ownerName:       _clean(data['owner_name']),
        taluk:           _clean(data['taluk']),
        district:        _clean(data['district']),
        khataNumber:     _clean(data['khata_number']),
        propertyAddress: _clean(data['property_address']),
        documentType:    _clean(data['document_type']),
        confidence:      (data['confidence'] as num?)?.toDouble() ?? 0.5,
        rawText:         _clean(data['raw_text']),
        // Building fields
        buildingName:    _clean(data['building_name']),
        visibleBlocks:   parseList(data['visible_blocks']),
        visibleFlats:    parseList(data['visible_flats']),
        buildingAddress: _clean(data['building_address']),
      );
    } catch (_) {
      return OcrResult(rawText: text, confidence: 0.2);
    }
  }

  String? _clean(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'N/A' || s == 'Unknown') return null;
    return s;
  }

  // ─── System Prompt ─────────────────────────────────────────────────────────
  static const String _ocrSystemPrompt = '''
You are a property scan AI for Karnataka, India. The image is either:
A) A PROPERTY DOCUMENT (RTC, EC, Sale Deed, Khata, Tax Receipt, Mutation)
B) A BUILDING PHOTO (apartment complex, house exterior, plot, construction site)

FIRST decide which it is, then extract the relevant fields.

Return ONLY valid JSON — no explanation, no markdown:

FOR A DOCUMENT:
{
  "scan_type": "document",
  "document_type": "RTC" | "EC" | "Khata" | "Sale Deed" | "Tax Receipt" | "Mutation" | "Other",
  "survey_number": "Sy.No value e.g. 45/2A — extract only the number/alphanumeric",
  "owner_name": "current owner name (transliterate Kannada to English)",
  "taluk": "taluk name in English",
  "district": "district name in English",
  "khata_number": "khata number if visible, else null",
  "property_address": "full address if visible, else null",
  "confidence": 0.0 to 1.0,
  "raw_text": "first 300 chars of all readable text",
  "building_name": null,
  "visible_blocks": [],
  "visible_flats": [],
  "building_address": null
}

FOR A BUILDING PHOTO:
{
  "scan_type": "building",
  "document_type": null,
  "survey_number": null,
  "owner_name": null,
  "taluk": null,
  "district": null,
  "khata_number": null,
  "property_address": null,
  "confidence": 0.0 to 1.0,
  "raw_text": "any text visible on the building",
  "building_name": "apartment/project name if visible on signboard, else null",
  "visible_blocks": ["A", "B", "C"] or ["Block 1", "Tower 2"] — list all block/tower/wing identifiers visible. If individual units visible: ["A", "B", "C"]. If none visible: [],
  "visible_flats": ["A101", "A102", "B201"] — only if flat numbers are clearly visible on doors/boards, else [],
  "building_address": "street address or landmark if visible on board, else null"
}

Rules:
- Survey number: extract ONLY the numeric/alphanumeric part e.g. "45" or "123/4A"
- Kannada text: transliterate owner name, taluk, district to English
- confidence: 0.9=clear, 0.6=partially visible, 0.3=blurry
- null for any field not clearly visible
- For buildings: even if only 1 block visible, list it. Guess blocks from context (e.g. if "Block A" and "Block B" are typical for this size).
''';
}
