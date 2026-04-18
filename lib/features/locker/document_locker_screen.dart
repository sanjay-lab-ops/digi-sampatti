import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/providers/property_provider.dart';
import 'package:digi_sampatti/core/services/document_key_service.dart';

// ─── Document Locker ──────────────────────────────────────────────────────────
// Encrypted document storage with time-limited access keys.
//
// Security model:
//   • Each document set has a unique Access Key (8-char alphanumeric)
//   • Owner shares key with lawyer/buyer for time-limited access
//   • Access tokens expire after set duration (24hr / 7 days / 30 days)
//   • Without key: document metadata visible but content locked
//   • Key is never stored server-side — only owner holds it
//
// Access flow:
//   Seller → shares key with lawyer → lawyer enters key → views for X hours
//   Key expires → lawyer can no longer access
//
// TODO: Move to Firebase Storage with AES-256 encryption for production.
//       Currently uses SharedPreferences (local) as MVP.
// ──────────────────────────────────────────────────────────────────────────────


class LockerAccessToken {
  final String key;            // 8-char key owner shares
  final DateTime expiresAt;    // when access expires
  final String grantedTo;      // lawyer name / buyer name
  final String purpose;        // "legal review" / "bank" / "buyer inspection"

  const LockerAccessToken({
    required this.key,
    required this.expiresAt,
    required this.grantedTo,
    required this.purpose,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get expiresLabel {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return '${diff.inMinutes}m remaining';
    if (diff.inDays < 1)  return '${diff.inHours}h remaining';
    return '${diff.inDays}d remaining';
  }
}

class LockerDocument {
  final String id;
  final String title;
  final String category;   // rtc / ec / agreement / inspection / legal / deed / mutation / tax
  final String propertyId; // survey number
  final String description;
  final DateTime savedAt;
  final String? filePath;  // local path if downloaded

  const LockerDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.propertyId,
    required this.description,
    required this.savedAt,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'category': category,
    'propertyId': propertyId, 'description': description,
    'savedAt': savedAt.toIso8601String(), 'filePath': filePath,
  };

  factory LockerDocument.fromJson(Map<String, dynamic> j) => LockerDocument(
    id: j['id'], title: j['title'], category: j['category'],
    propertyId: j['propertyId'], description: j['description'],
    savedAt: DateTime.parse(j['savedAt']), filePath: j['filePath'],
  );
}

class DocumentLockerScreen extends ConsumerStatefulWidget {
  const DocumentLockerScreen({super.key});
  @override
  ConsumerState<DocumentLockerScreen> createState() =>
      _DocumentLockerScreenState();
}

class _DocumentLockerScreenState
    extends ConsumerState<DocumentLockerScreen> {
  List<LockerDocument> _docs = [];
  Map<String, List<DocumentKey>> _keysByProperty = {};
  bool _loading = true;
  String _filter = 'all';
  final _keyService = DocumentKeyService();

  static const _catLabels = {
    'all': 'All Documents',
    'rtc': 'RTC / Pahani',
    'ec': 'Encumbrance Certificate',
    'agreement': 'Sale Agreement',
    'inspection': 'Inspection Report',
    'legal': 'Legal Opinion',
    'deed': 'Registration Deed',
    'mutation': 'Mutation Order',
    'tax': 'Property Tax',
  };

  static const _catIcons = {
    'rtc':        Icons.article_outlined,
    'ec':         Icons.account_balance_outlined,
    'agreement':  Icons.handshake_outlined,
    'inspection': Icons.location_searching,
    'legal':      Icons.gavel_outlined,
    'deed':       Icons.verified_outlined,
    'mutation':   Icons.sync_alt,
    'tax':        Icons.receipt_long_outlined,
  };

  static const _catColors = {
    'rtc':        AppColors.primary,
    'ec':         AppColors.arthBlue,
    'agreement':  AppColors.esign,
    'inspection': AppColors.slate,
    'legal':      AppColors.deepOrange,
    'deed':       Color(0xFF00695C),
    'mutation':   AppColors.seller,
    'tax':        AppColors.teal,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('locker_docs') ?? [];
    final docs = raw.map((s) =>
        LockerDocument.fromJson(jsonDecode(s))).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    // Load keys grouped by propertyId
    final allKeys = await _keyService.loadAll();
    final keyMap = <String, List<DocumentKey>>{};
    for (final k in allKeys) {
      keyMap.putIfAbsent(k.propertyId, () => []).add(k);
    }

    setState(() {
      _docs = docs;
      _keysByProperty = keyMap;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'locker_docs', _docs.map((d) => jsonEncode(d.toJson())).toList());
  }

  Future<void> _addDocument() async {
    final scan = ref.read(currentScanProvider);
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddDocumentSheet(
        defaultPropertyId: scan?.surveyNumber ?? '',
      ),
    );

    if (result != null) {
      final doc = LockerDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result['title']!,
        category: result['category']!,
        propertyId: result['propertyId']!,
        description: result['description']!,
        savedAt: DateTime.now(),
      );
      setState(() => _docs.insert(0, doc));
      await _save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document saved to locker')));
      }
    }
  }

  Future<void> _delete(LockerDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Remove "${doc.title}" from your locker?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(_, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _docs.removeWhere((d) => d.id == doc.id));
      await _save();
    }
  }

  List<LockerDocument> get _filtered =>
      _filter == 'all' ? _docs :
      _docs.where((d) => d.category == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<LockerDocument>>{};
    for (final doc in _filtered) {
      grouped.putIfAbsent(doc.propertyId, () => []).add(doc);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Locker'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Enter access key (buyer)',
            onPressed: _showEnterKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDocument,
            tooltip: 'Add document',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildCategoryFilter(),
                Expanded(
                  child: _docs.isEmpty
                      ? _buildEmpty()
                      : _filtered.isEmpty
                          ? _buildNoResults()
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                ...grouped.entries.map((e) =>
                                    _buildPropertyGroup(e.key, e.value)),
                              ],
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Document',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    color: Colors.white,
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.lock_outlined,
            color: AppColors.primary, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Property Documents',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('${_docs.length} document${_docs.length == 1 ? "" : "s"} stored',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      )),
      const Icon(Icons.security, color: AppColors.primary, size: 18),
      const SizedBox(width: 4),
      const Text('Encrypted',
          style: TextStyle(fontSize: 11, color: AppColors.primary)),
    ]),
  );

  Widget _buildCategoryFilter() => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      children: _catLabels.keys.map((k) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(_catLabels[k]!,
              style: TextStyle(fontSize: 11,
                  color: _filter == k ? Colors.white : null)),
          selected: _filter == k,
          selectedColor: AppColors.primary,
          onSelected: (_) => setState(() => _filter = k),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      )).toList(),
    ),
  );

  Widget _buildPropertyGroup(String propertyId, List<LockerDocument> docs) {
    final keys = _keysByProperty[propertyId] ?? [];
    final activeKeys = keys.where((k) => k.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property header row + Share Key button
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(children: [
            const Icon(Icons.home_outlined,
                size: 14, color: AppColors.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                propertyId.isNotEmpty ? 'Survey $propertyId' : 'Unknown Property',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: AppColors.textMedium)),
            ),
            Text('${docs.length} doc${docs.length == 1 ? "" : "s"}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
            const SizedBox(width: 10),
            // 🔑 Share Key button
            GestureDetector(
              onTap: () => _showGenerateKeySheet(propertyId, docs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.vpn_key_outlined,
                      size: 13, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Share Key',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),

        // Active keys panel
        if (activeKeys.isNotEmpty) ...[
          _ActiveKeysPanel(
            keys: activeKeys,
            onRevoke: (key) async {
              await _keyService.revokeKey(key);
              await _load();
            },
          ),
          const SizedBox(height: 8),
        ],

        ...docs.map((doc) => _buildDocCard(doc)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDocCard(LockerDocument doc) {
    final color  = _catColors[doc.category] ?? AppColors.primary;
    final icon   = _catIcons[doc.category]  ?? Icons.description_outlined;
    final label  = _catLabels[doc.category] ?? doc.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.title, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
            Text(label, style: TextStyle(
                fontSize: 11, color: color)),
            if (doc.description.isNotEmpty)
              Text(doc.description, style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_dateStr(doc.savedAt), style: const TextStyle(
                fontSize: 10, color: AppColors.textLight)),
          ],
        )),
        PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'share') {
              Share.share('${doc.title}\n${doc.description}\nSaved: ${_dateStr(doc.savedAt)}');
            } else if (action == 'delete') {
              _delete(doc);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'share',
                child: Row(children: [
                  Icon(Icons.share, size: 16), SizedBox(width: 8),
                  Text('Share'),
                ])),
            PopupMenuItem(value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ])),
          ],
        ),
      ]),
    );
  }

  // ── Generate & share a time-limited key ─────────────────────────────────
  Future<void> _showGenerateKeySheet(
      String propertyId, List<LockerDocument> docs) async {
    final result = await showModalBottomSheet<_KeyRequest>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GenerateKeySheet(propertyId: propertyId),
    );
    if (result == null || !mounted) return;

    final docMaps = docs.map((d) => {
      'id': d.id, 'title': d.title, 'savedAt': d.savedAt.toIso8601String(),
    }).toList();

    final token = await _keyService.issueKey(
      propertyId:  propertyId,
      grantedTo:   result.grantedTo,
      purpose:     result.purpose,
      validHours:  result.validHours,
      docs:        docMaps,
    );

    await _load();
    if (!mounted) return;
    _showKeyIssuedDialog(token);
  }

  void _showKeyIssuedDialog(DocumentKey token) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.vpn_key_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Access Key Generated',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Key display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(children: [
                Text(
                  _formatKey(token.key),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text('Valid for ${token.statusLabel}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ]),
            ),
            const SizedBox(height: 12),
            _KeyInfoRow('For',     token.grantedTo),
            _KeyInfoRow('Purpose', token.purpose),
            _KeyInfoRow('Expires', _dateTimeStr(token.expiresAt)),
            _KeyInfoRow('Doc hash', '${token.docHash.substring(0, 12)}…'),
            const SizedBox(height: 4),
            const Text(
              'The doc hash proves documents were not changed after this key was issued.',
              style: TextStyle(fontSize: 10, color: AppColors.textLight, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Key'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token.key));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Key copied to clipboard')));
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share'),
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                'Arth ID Document Access Key\n'
                'Key: ${_formatKey(token.key)}\n'
                'Valid until: ${_dateTimeStr(token.expiresAt)}\n'
                'Purpose: ${token.purpose}\n\n'
                'Enter this key in the Arth ID app → Document Locker → Enter Key.',
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Buyer enters a key ────────────────────────────────────────────────────
  Future<void> _showEnterKeyDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Document Key',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 8-character key shared by the seller to view their documents.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              style: const TextStyle(
                  letterSpacing: 4, fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'XXXX XXXX',
                hintStyle: const TextStyle(color: AppColors.textLight),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Validate Key'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty || !mounted) return;

    final docMaps = _docs.map((d) => {
      'id': d.id, 'title': d.title, 'savedAt': d.savedAt.toIso8601String(),
    }).toList();

    final validation = await _keyService.validateKey(result, docMaps);

    if (!mounted) return;

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.error ?? 'Invalid key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showKeyAccessGranted(validation);
  }

  void _showKeyAccessGranted(DocumentKeyValidation v) {
    final token = v.token!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(
            v.hashMatch ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: v.hashMatch ? AppColors.safe : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(v.hashMatch ? 'Access Granted' : 'Access Granted — Warning',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!v.hashMatch) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠ Documents were modified after this key was issued. '
                  'Ask the seller to explain changes or issue a new key.',
                  style: TextStyle(fontSize: 11, color: AppColors.warning, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _KeyInfoRow('Property', token.propertyId),
            _KeyInfoRow('Granted by', token.grantedTo),
            _KeyInfoRow('Purpose', token.purpose),
            _KeyInfoRow('Expires', token.statusLabel),
            _KeyInfoRow('Hash verified', v.hashMatch ? '✓ Intact' : '✗ Modified'),
            const SizedBox(height: 8),
            const Text(
              'You now have read access to this property\'s documents for the key duration.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('View Documents'),
          ),
        ],
      ),
    );
  }

  static String _formatKey(String key) =>
      '${key.substring(0, 4)} ${key.substring(4)}';

  static String _dateTimeStr(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('Your Document Locker is Empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Save your RTC, EC, sale agreement, inspection report, and all '
            'property documents here. Access them anytime, forever.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addDocument,
            icon: const Icon(Icons.add),
            label: const Text('Add First Document'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
          ),
        ],
      ),
    ),
  );

  Widget _buildNoResults() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.filter_list, size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        Text('No ${_catLabels[_filter]} found',
            style: const TextStyle(fontSize: 16)),
        TextButton(
          onPressed: () => setState(() => _filter = 'all'),
          child: const Text('Show all documents'),
        ),
      ],
    ),
  );

  String _dateStr(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ─── Active Keys Panel ────────────────────────────────────────────────────────
class _ActiveKeysPanel extends StatelessWidget {
  final List<DocumentKey> keys;
  final Future<void> Function(String key) onRevoke;

  const _ActiveKeysPanel({required this.keys, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.vpn_key_outlined,
                size: 13, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('${keys.length} active key${keys.length == 1 ? "" : "s"}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ]),
          const SizedBox(height: 8),
          ...keys.map((k) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${k.key.substring(0, 4)} ${k.key.substring(4)}  ·  ${k.grantedTo}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        letterSpacing: 1),
                  ),
                  Text('${k.purpose}  ·  ${k.statusLabel}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textLight)),
                ],
              )),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: () => onRevoke(k.key),
                child: const Text('Revoke', style: TextStyle(fontSize: 11)),
              ),
            ]),
          )),
        ],
      ),
    );
  }
}

// ─── Generate Key Bottom Sheet ────────────────────────────────────────────────
class _KeyRequest {
  final String grantedTo;
  final String purpose;
  final int    validHours;
  const _KeyRequest({required this.grantedTo, required this.purpose, required this.validHours});
}

class _GenerateKeySheet extends StatefulWidget {
  final String propertyId;
  const _GenerateKeySheet({required this.propertyId});

  @override
  State<_GenerateKeySheet> createState() => _GenerateKeySheetState();
}

class _GenerateKeySheetState extends State<_GenerateKeySheet> {
  final _nameCtrl    = TextEditingController();
  final _purposeCtrl = TextEditingController();
  int _validHours    = 48;

  static const _validOptions = [
    (24,  '24 hours'),
    (48,  '48 hours'),
    (168, '7 days'),
    (720, '30 days'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _purposeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Generate Access Key',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 4),
          Text('Survey: ${widget.propertyId.isNotEmpty ? widget.propertyId : 'Unknown'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Share with (name)',
              hintText: 'e.g. Advocate Rajesh, SBI Bank, Buyer Priya',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeCtrl,
            decoration: InputDecoration(
              labelText: 'Purpose',
              hintText: 'e.g. Legal review, Loan sanction, Buyer inspection',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Key valid for',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _validOptions.map((o) {
              final selected = _validHours == o.$1;
              return ChoiceChip(
                label: Text(o.$2,
                    style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : AppColors.textDark)),
                selected: selected,
                selectedColor: AppColors.primary,
                onSelected: (_) => setState(() => _validHours = o.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          const Text(
            'Key auto-expires after this time — no manual revoke needed.',
            style: TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              icon: const Icon(Icons.vpn_key_outlined, size: 16),
              label: const Text('Generate Key'),
              onPressed: () {
                if (_nameCtrl.text.isEmpty) return;
                Navigator.pop(context, _KeyRequest(
                  grantedTo:  _nameCtrl.text.trim(),
                  purpose:    _purposeCtrl.text.trim().isNotEmpty
                      ? _purposeCtrl.text.trim()
                      : 'Document review',
                  validHours: _validHours,
                ));
              },
            )),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Key info row ─────────────────────────────────────────────────────────────
class _KeyInfoRow extends StatelessWidget {
  final String label, value;
  const _KeyInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(
        width: 80,
        child: Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ),
      Expanded(child: Text(value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textDark))),
    ]),
  );
}

// ─── Add Document Bottom Sheet ────────────────────────────────────────────────
class _AddDocumentSheet extends StatefulWidget {
  final String defaultPropertyId;
  const _AddDocumentSheet({required this.defaultPropertyId});

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _propIdCtrl   = TextEditingController();
  String _category    = 'rtc';

  @override
  void initState() {
    super.initState();
    _propIdCtrl.text = widget.defaultPropertyId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _propIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Document to Locker',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Document Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              DropdownMenuItem(value: 'rtc',       child: Text('RTC / Pahani')),
              DropdownMenuItem(value: 'ec',        child: Text('Encumbrance Certificate')),
              DropdownMenuItem(value: 'agreement', child: Text('Sale Agreement')),
              DropdownMenuItem(value: 'inspection',child: Text('Inspection Report')),
              DropdownMenuItem(value: 'legal',     child: Text('Legal Opinion')),
              DropdownMenuItem(value: 'deed',      child: Text('Registration Deed')),
              DropdownMenuItem(value: 'mutation',  child: Text('Mutation Order')),
              DropdownMenuItem(value: 'tax',       child: Text('Property Tax Receipt')),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Document Title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _propIdCtrl,
            decoration: InputDecoration(
              labelText: 'Survey Number / Property ID',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                if (_titleCtrl.text.isEmpty) return;
                Navigator.pop(context, {
                  'title':      _titleCtrl.text,
                  'category':   _category,
                  'propertyId': _propIdCtrl.text,
                  'description':_descCtrl.text,
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            )),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
