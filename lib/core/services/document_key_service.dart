import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Document Key Service ─────────────────────────────────────────────────────
// Generates time-limited access keys for a seller's document set.
//
// Chain-of-custody (blockchain-lite):
//   When a key is issued, we SHA-256 hash the document list (ids + titles + savedAt).
//   When buyer opens with the key, we re-hash and compare.
//   If hash differs → "Documents were modified after this key was issued" warning.
//   Each key + hash is stored locally (production: Firestore / IPFS anchor).
//
// Key format: 8 alphanumeric chars, case-insensitive, no ambiguous chars (0/O, 1/I/l).
// ─────────────────────────────────────────────────────────────────────────────

const _kLockerKeys = 'locker_access_keys';

class DocumentKey {
  final String key;
  final String propertyId;
  final String grantedTo;
  final String purpose;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String docHash;       // SHA-256 of doc state at key issue time
  final bool revoked;

  const DocumentKey({
    required this.key,
    required this.propertyId,
    required this.grantedTo,
    required this.purpose,
    required this.issuedAt,
    required this.expiresAt,
    required this.docHash,
    this.revoked = false,
  });

  bool get isExpired  => DateTime.now().isAfter(expiresAt);
  bool get isActive   => !isExpired && !revoked;

  String get statusLabel {
    if (revoked)   return 'Revoked';
    if (isExpired) return 'Expired';
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m left';
    if (diff.inHours < 24)   return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }

  Map<String, dynamic> toJson() => {
    'key':        key,
    'propertyId': propertyId,
    'grantedTo':  grantedTo,
    'purpose':    purpose,
    'issuedAt':   issuedAt.toIso8601String(),
    'expiresAt':  expiresAt.toIso8601String(),
    'docHash':    docHash,
    'revoked':    revoked,
  };

  factory DocumentKey.fromJson(Map<String, dynamic> j) => DocumentKey(
    key:        j['key'],
    propertyId: j['propertyId'],
    grantedTo:  j['grantedTo'],
    purpose:    j['purpose'],
    issuedAt:   DateTime.parse(j['issuedAt']),
    expiresAt:  DateTime.parse(j['expiresAt']),
    docHash:    j['docHash'],
    revoked:    j['revoked'] ?? false,
  );

  DocumentKey copyWith({bool? revoked}) => DocumentKey(
    key: key, propertyId: propertyId, grantedTo: grantedTo,
    purpose: purpose, issuedAt: issuedAt, expiresAt: expiresAt,
    docHash: docHash, revoked: revoked ?? this.revoked,
  );
}

class DocumentKeyValidation {
  final DocumentKey? token;
  final bool hashMatch;   // false = docs modified after key issued
  final String? error;

  const DocumentKeyValidation({
    this.token,
    this.hashMatch = true,
    this.error,
  });

  bool get isValid => token != null && token!.isActive && error == null;
}

class DocumentKeyService {
  // ── Generate a random 8-char key ──────────────────────────────────────────
  static String _newKey() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── SHA-256 hash of doc list — tamper detection ───────────────────────────
  // Hashes: docId + title + savedAt for each doc, sorted by id for stability.
  static String hashDocuments(List<Map<String, String>> docs) {
    final sorted = [...docs]..sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));
    final content = sorted.map((d) =>
        '${d['id']}|${d['title']}|${d['savedAt']}').join('\n');
    return sha256.convert(utf8.encode(content)).toString();
  }

  // ── Issue a new key ───────────────────────────────────────────────────────
  Future<DocumentKey> issueKey({
    required String propertyId,
    required String grantedTo,
    required String purpose,
    required int validHours,
    required List<Map<String, String>> docs, // [{id, title, savedAt}]
  }) async {
    final token = DocumentKey(
      key:        _newKey(),
      propertyId: propertyId,
      grantedTo:  grantedTo,
      purpose:    purpose,
      issuedAt:   DateTime.now(),
      expiresAt:  DateTime.now().add(Duration(hours: validHours)),
      docHash:    hashDocuments(docs),
    );
    await _save(token);
    return token;
  }

  // ── Validate a key entered by buyer ──────────────────────────────────────
  Future<DocumentKeyValidation> validateKey(
    String inputKey,
    List<Map<String, String>> currentDocs,
  ) async {
    final keys = await loadAll();
    final token = keys.where((k) =>
        k.key.toUpperCase() == inputKey.toUpperCase().trim()).firstOrNull;

    if (token == null) {
      return const DocumentKeyValidation(error: 'Key not found. Check for typos.');
    }
    if (token.revoked) {
      return const DocumentKeyValidation(error: 'This key has been revoked by the seller.');
    }
    if (token.isExpired) {
      return DocumentKeyValidation(
        error: 'Key expired ${_timeSince(token.expiresAt)} ago. Request a new one.',
      );
    }

    // Chain-of-custody check
    final currentHash = hashDocuments(currentDocs);
    final hashMatch   = currentHash == token.docHash;

    return DocumentKeyValidation(
      token:     token,
      hashMatch: hashMatch,
    );
  }

  // ── Revoke a key ──────────────────────────────────────────────────────────
  Future<void> revokeKey(String key) async {
    final all     = await loadAll();
    final updated = all.map((k) =>
        k.key == key ? k.copyWith(revoked: true) : k).toList();
    await _saveAll(updated);
  }

  // ── Get all keys for a property ───────────────────────────────────────────
  Future<List<DocumentKey>> keysForProperty(String propertyId) async {
    final all = await loadAll();
    return all.where((k) => k.propertyId == propertyId).toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<List<DocumentKey>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_kLockerKeys) ?? [];
    return raw.map((s) => DocumentKey.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _save(DocumentKey token) async {
    final all = await loadAll();
    all.add(token);
    await _saveAll(all);
  }

  Future<void> _saveAll(List<DocumentKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kLockerKeys, keys.map((k) => jsonEncode(k.toJson())).toList());
  }

  static String _timeSince(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
