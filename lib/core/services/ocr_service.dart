import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  });

  bool get hasUsefulData =>
      surveyNumber != null || ownerName != null || khataNumber != null;

  @override
  String toString() =>
      'OcrResult(survey=$surveyNumber, owner=$ownerName, taluk=$taluk, '
      'district=$district, doc=$documentType, conf=$confidence)';
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
                  'text':
                      'Extract property details from this document. Return JSON only.',
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
    } catch (_) {
      // Fail silently — caller falls back to manual entry
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

      return OcrResult(
        surveyNumber:   _clean(data['survey_number']),
        ownerName:      _clean(data['owner_name']),
        taluk:          _clean(data['taluk']),
        district:       _clean(data['district']),
        khataNumber:    _clean(data['khata_number']),
        propertyAddress: _clean(data['property_address']),
        documentType:   _clean(data['document_type']),
        confidence:     (data['confidence'] as num?)?.toDouble() ?? 0.5,
        rawText:        _clean(data['raw_text']),
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
You are a property document OCR specialist for Karnataka, India.

The image will be one of:
- RTC (Record of Tenancy and Cultivation) — Hakkupatra
- Encumbrance Certificate (EC) — from IGRS/KAVERI
- Khata Certificate or Extract — from BBMP/CMC/Gram Panchayat
- Sale Deed / Agreement to Sell
- Property Tax Paid receipt
- Mutation order
- Any other land/property document

Extract the following fields. The document may contain Kannada text, English text, or both.

Return ONLY valid JSON (no explanation, no markdown, no extra text):
{
  "document_type": "RTC" | "EC" | "Khata" | "Sale Deed" | "Tax Receipt" | "Mutation" | "Other",
  "survey_number": "survey/sarvey/Sy. No. value — e.g. 123/4A",
  "owner_name": "current owner or seller name",
  "taluk": "taluk name",
  "district": "district name",
  "khata_number": "khata/katha number if visible",
  "property_address": "full address or location description",
  "confidence": 0.0 to 1.0 (how confident you are in the extraction),
  "raw_text": "first 300 chars of all text you can read from the document"
}

Rules:
- Survey number formats: "123", "123/4", "123/4A", "Sy.No.45/2B" — extract the numeric/alphanumeric part
- If a field is not visible or unclear, use null (not empty string)
- For Kannada text, transliterate the relevant fields into English
- confidence = 0.9 if document is clear; 0.6 if partially visible; 0.3 if very blurry
''';
}
