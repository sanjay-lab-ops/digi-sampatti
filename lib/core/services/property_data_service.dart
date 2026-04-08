import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Property Data Service ────────────────────────────────────────────────────
// Central Firestore service for:
//   • Buying journey progress
//   • Tracked properties (court case monitor)
//   • Government applications
//   • Loan enquiries
//   • RERA / RTI complaints
//   • Broker listings
// ─────────────────────────────────────────────────────────────────────────────

class PropertyDataService {
  static final PropertyDataService _i = PropertyDataService._();
  factory PropertyDataService() => _i;
  PropertyDataService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── helpers ──────────────────────────────────────────────────────────────────
  DocumentReference _userDoc() => _db.collection('users').doc(_uid);

  // ═══════════════════════════════════════════════════════════════════════════
  // BUYING JOURNEY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a single checklist item tick
  Future<void> saveJourneyCheckItem({
    required String journeyId, // surveyNo or custom ID
    required String stage,     // preAdvance / agreement / registration
    required int itemIndex,
    required bool checked,
  }) async {
    if (_uid == null) return;
    await _userDoc()
        .collection('journeys')
        .doc(journeyId)
        .set({
      'stage_$stage': {itemIndex.toString(): checked},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Load all checklist state for a journey
  Future<Map<String, Map<int, bool>>> loadJourneyChecks(String journeyId) async {
    if (_uid == null) return {};
    final doc = await _userDoc().collection('journeys').doc(journeyId).get();
    if (!doc.exists) return {};
    final data = doc.data()!;
    Map<String, Map<int, bool>> result = {};
    for (final stage in ['preAdvance', 'agreement', 'registration']) {
      final raw = data['stage_$stage'] as Map<String, dynamic>?;
      if (raw != null) {
        result[stage] = raw.map((k, v) => MapEntry(int.parse(k), v as bool));
      }
    }
    return result;
  }

  /// Save journey stage completion + property info
  Future<void> saveJourneyMeta({
    required String journeyId,
    required String surveyNumber,
    String? district,
    String? sellerName,
    double? propertyValue,
  }) async {
    if (_uid == null) return;
    await _userDoc().collection('journeys').doc(journeyId).set({
      'surveyNumber': surveyNumber,
      if (district != null) 'district': district,
      if (sellerName != null) 'sellerName': sellerName,
      if (propertyValue != null) 'propertyValue': propertyValue,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get all journeys (for history)
  Stream<QuerySnapshot> streamJourneys() {
    if (_uid == null) return const Stream.empty();
    return _userDoc()
        .collection('journeys')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COURT CASE TRACKER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> trackProperty({
    required String surveyNumber,
    required String district,
    String? ownerName,
    String? taluk,
  }) async {
    if (_uid == null) return;
    final id = '${surveyNumber}_$district'.replaceAll('/', '_').replaceAll(' ', '_');
    await _userDoc().collection('tracked_properties').doc(id).set({
      'surveyNumber': surveyNumber,
      'district': district,
      if (taluk != null) 'taluk': taluk,
      if (ownerName != null) 'ownerName': ownerName,
      'trackedAt': FieldValue.serverTimestamp(),
      'lastChecked': FieldValue.serverTimestamp(),
      'alertStatus': 'monitoring', // monitoring / alert / clear
    });
  }

  Future<void> updateLastChecked(String docId) async {
    if (_uid == null) return;
    await _userDoc().collection('tracked_properties').doc(docId).update({
      'lastChecked': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePropertyStatus(String docId, String status) async {
    if (_uid == null) return;
    await _userDoc().collection('tracked_properties').doc(docId).update({
      'alertStatus': status,
      'lastChecked': FieldValue.serverTimestamp(),
    });
  }

  Future<void> untrackProperty(String docId) async {
    if (_uid == null) return;
    await _userDoc().collection('tracked_properties').doc(docId).delete();
  }

  Stream<QuerySnapshot> streamTrackedProperties() {
    if (_uid == null) return const Stream.empty();
    return _userDoc()
        .collection('tracked_properties')
        .orderBy('trackedAt', descending: true)
        .snapshots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOVERNMENT APPLICATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> submitApplication({
    required String serviceType,
    required String serviceTitle,
    required String department,
    required int slaDays,
    required Map<String, dynamic> formData,
    String? surveyNumber,
    String? district,
  }) async {
    if (_uid == null) throw Exception('Not logged in');
    final ref = await _userDoc().collection('applications').add({
      'serviceType': serviceType,
      'serviceTitle': serviceTitle,
      'department': department,
      'slaDays': slaDays,
      'status': 'submitted',
      'surveyNumber': surveyNumber,
      'district': district,
      'formData': formData,
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline': [
        {
          'label': 'Application submitted via DigiSampatti',
          'timestamp': DateTime.now().toIso8601String(),
          'isDone': true,
        }
      ],
    });
    return ref.id;
  }

  Stream<QuerySnapshot> streamApplications() {
    if (_uid == null) return const Stream.empty();
    return _userDoc()
        .collection('applications')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAN ENQUIRIES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> saveLoanEnquiry({
    required double propertyValue,
    required double monthlyIncome,
    required double loanAmount,
    required String preferredBank,
    String? surveyNumber,
    String? district,
    String? phone,
  }) async {
    if (_uid == null) return;
    await _db.collection('loan_enquiries').add({
      'uid': _uid,
      'phone': phone ?? FirebaseAuth.instance.currentUser?.phoneNumber,
      'propertyValue': propertyValue,
      'monthlyIncome': monthlyIncome,
      'loanAmount': loanAmount,
      'preferredBank': preferredBank,
      if (surveyNumber != null) 'surveyNumber': surveyNumber,
      if (district != null) 'district': district,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    // Also save to user's sub-collection
    await _userDoc().collection('loan_enquiries').add({
      'propertyValue': propertyValue,
      'loanAmount': loanAmount,
      'preferredBank': preferredBank,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RERA COMPLAINTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> submitReraComplaint({
    required String projectName,
    required String builderName,
    required String complaintType,
    required String description,
    String? reraRegNumber,
    String? district,
  }) async {
    if (_uid == null) throw Exception('Not logged in');
    final ref = await _db.collection('rera_complaints').add({
      'uid': _uid,
      'phone': FirebaseAuth.instance.currentUser?.phoneNumber,
      'projectName': projectName,
      'builderName': builderName,
      'complaintType': complaintType,
      'description': description,
      if (reraRegNumber != null) 'reraRegNumber': reraRegNumber,
      if (district != null) 'district': district,
      'status': 'draft',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await _userDoc().collection('complaints').doc(ref.id).set({
      'type': 'rera',
      'title': 'RERA Complaint — $projectName',
      'status': 'draft',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BROKERS
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<QuerySnapshot> streamVerifiedBrokers({String? city}) {
    Query q = _db
        .collection('brokers')
        .where('verified', isEqualTo: true);
    if (city != null) q = q.where('city', isEqualTo: city);
    return q.limit(20).snapshots();
  }

  Stream<QuerySnapshot> streamAllBrokers({String? city}) {
    Query q = _db.collection('brokers');
    if (city != null) q = q.where('city', isEqualTo: city);
    return q.orderBy('verifiedAt', descending: true).limit(30).snapshots();
  }
}
