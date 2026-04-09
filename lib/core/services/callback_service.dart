import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Callback / Lead Service ───────────────────────────────────────────────────
// Saves expert callback requests to Firestore.
// Collection: callback_requests/{docId}
// Admin sees these in Firebase console and calls users within 2 hrs.
// ─────────────────────────────────────────────────────────────────────────────

enum ExpertType {
  advocate,
  surveyor,
  homeLoan,
  titleInsurance,
  vastConsultant,
  interiorDesigner,
  packersMovers,
  khataAgent,
  developer,
}

extension ExpertTypeLabel on ExpertType {
  String get label {
    switch (this) {
      case ExpertType.advocate:        return 'Property Advocate';
      case ExpertType.surveyor:        return 'Licensed Surveyor';
      case ExpertType.homeLoan:        return 'Home Loan';
      case ExpertType.titleInsurance:  return 'Title Insurance';
      case ExpertType.vastConsultant:  return 'Vastu Consultant';
      case ExpertType.interiorDesigner:return 'Interior Designer';
      case ExpertType.packersMovers:   return 'Packers & Movers';
      case ExpertType.khataAgent:      return 'Khata & Mutation Agent';
      case ExpertType.developer:       return 'Developer / Builder';
    }
  }
}

class CallbackRequest {
  final String uid;
  final String phone;
  final ExpertType expertType;
  final String? surveyNumber;
  final String? district;
  final String? partnerName;   // e.g. "Mantri Developers"
  final String? notes;
  final DateTime requestedAt;
  String status; // pending / contacted / resolved

  CallbackRequest({
    required this.uid,
    required this.phone,
    required this.expertType,
    this.surveyNumber,
    this.district,
    this.partnerName,
    this.notes,
    required this.requestedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'phone': phone,
    'expertType': expertType.name,
    'surveyNumber': surveyNumber,
    'district': district,
    'partnerName': partnerName,
    'notes': notes,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'status': status,
  };
}

class CallbackService {
  static final CallbackService _instance = CallbackService._internal();
  factory CallbackService() => _instance;
  CallbackService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── Submit Callback Request ───────────────────────────────────────────────
  Future<bool> submitCallbackRequest({
    required ExpertType expertType,
    String? surveyNumber,
    String? district,
    String? partnerName,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final request = CallbackRequest(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        expertType: expertType,
        surveyNumber: surveyNumber,
        district: district,
        partnerName: partnerName,
        notes: notes,
        requestedAt: DateTime.now(),
      );

      await _firestore
          .collection('callback_requests')
          .add(request.toMap());

      // Also save under user's sub-collection for their history
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('callback_requests')
          .add(request.toMap());

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Get User's Callback History ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getUserCallbacks() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('callback_requests')
          .orderBy('requestedAt', descending: true)
          .limit(20)
          .get();

      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      return [];
    }
  }
}
