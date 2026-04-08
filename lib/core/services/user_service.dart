import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── User Service ─────────────────────────────────────────────────────────────
// Manages user profiles in Firestore.
// Collection: users/{uid}
// Sub-collections: users/{uid}/searches, users/{uid}/reports
// ─────────────────────────────────────────────────────────────────────────────

enum UserType { buyer, broker, nri, seller, bank, lawyer }

extension UserTypeLabel on UserType {
  String get label {
    switch (this) {
      case UserType.buyer:  return 'Buyer';
      case UserType.broker: return 'Broker / Agent';
      case UserType.nri:    return 'NRI Buyer';
      case UserType.seller: return 'Seller';
      case UserType.bank:   return 'Bank / NBFC';
      case UserType.lawyer: return 'Lawyer / Advocate';
    }
  }

  String get icon {
    switch (this) {
      case UserType.buyer:  return '🏠';
      case UserType.broker: return '🤝';
      case UserType.nri:    return '✈️';
      case UserType.seller: return '📋';
      case UserType.bank:   return '🏦';
      case UserType.lawyer: return '⚖️';
    }
  }
}

class DigiUser {
  final String uid;
  final String phone;
  final UserType userType;
  final String? name;
  final String? email;
  final bool isFirstLogin;

  // Broker-specific
  final String? reraAgentId;
  final String? brokerOfficeName;
  final bool? brokerVerified;
  final String? brokerVerificationStatus; // pending/approved/rejected

  final DateTime createdAt;
  final DateTime lastLoginAt;

  const DigiUser({
    required this.uid,
    required this.phone,
    required this.userType,
    this.name,
    this.email,
    this.isFirstLogin = false,
    this.reraAgentId,
    this.brokerOfficeName,
    this.brokerVerified,
    this.brokerVerificationStatus,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory DigiUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return DigiUser(
      uid: uid,
      phone: data['phone'] ?? '',
      userType: UserType.values.firstWhere(
        (t) => t.name == (data['userType'] ?? 'buyer'),
        orElse: () => UserType.buyer,
      ),
      name: data['name'],
      email: data['email'],
      isFirstLogin: false,
      reraAgentId: data['reraAgentId'],
      brokerOfficeName: data['brokerOfficeName'],
      brokerVerified: data['brokerVerified'],
      brokerVerificationStatus: data['brokerVerificationStatus'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'phone': phone,
    'userType': userType.name,
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (reraAgentId != null) 'reraAgentId': reraAgentId,
    if (brokerOfficeName != null) 'brokerOfficeName': brokerOfficeName,
    if (brokerVerified != null) 'brokerVerified': brokerVerified,
    if (brokerVerificationStatus != null) 'brokerVerificationStatus': brokerVerificationStatus,
    'lastLoginAt': FieldValue.serverTimestamp(),
  };
}

class UserService {
  static final UserService _instance = UserService._();
  factory UserService() => _instance;
  UserService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;
  String? get phone => _auth.currentUser?.phoneNumber;

  // ── Get or create user profile after login ──────────────────────────────────
  Future<DigiUser> getOrCreateProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final doc = await _db.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      // First login — create profile, mark as new user
      final newUser = DigiUser(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        userType: UserType.buyer, // default, changed on setup screen
        isFirstLogin: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set({
        ...newUser.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': false,
      });
      return newUser;
    } else {
      // Returning user — update last login
      await _db.collection('users').doc(user.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      return DigiUser.fromFirestore(doc.data()!, user.uid);
    }
  }

  // ── Save user type and name after selection ──────────────────────────────────
  Future<void> saveUserType({
    required UserType userType,
    String? name,
    String? email,
  }) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'userType': userType.name,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      'isProfileComplete': true,
    });
  }

  // ── Save search to history ────────────────────────────────────────────────
  Future<void> saveSearch({
    required String surveyNumber,
    String? district,
    String? taluk,
    String? hobli,
    String? village,
  }) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('searches')
        .add({
      'surveyNumber': surveyNumber,
      'district': district,
      'taluk': taluk,
      'hobli': hobli,
      'village': village,
      'searchedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Save generated report ─────────────────────────────────────────────────
  Future<void> saveReport({
    required String surveyNumber,
    required String verdict,   // SAFE / CAUTION / DO_NOT_BUY
    required int score,
    required String district,
    Map<String, dynamic>? findings,
  }) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('reports')
        .add({
      'surveyNumber': surveyNumber,
      'verdict': verdict,
      'score': score,
      'district': district,
      'findings': findings,
      'generatedAt': FieldValue.serverTimestamp(),
    });
    // Also increment report count on user doc
    await _db.collection('users').doc(uid).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  // ── Submit broker verification request ───────────────────────────────────
  Future<void> submitBrokerVerification({
    required String reraAgentId,
    required String officeName,
    required String city,
    String? aadhaarLast4,
  }) async {
    if (uid == null) return;

    // Save to broker_verifications collection (admin reviews these)
    await _db.collection('broker_verifications').doc(uid).set({
      'uid': uid,
      'phone': phone,
      'reraAgentId': reraAgentId,
      'officeName': officeName,
      'city': city,
      if (aadhaarLast4 != null) 'aadhaarLast4': aadhaarLast4,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });

    // Update user profile
    await _db.collection('users').doc(uid).update({
      'reraAgentId': reraAgentId,
      'brokerOfficeName': officeName,
      'brokerVerificationStatus': 'pending',
      'brokerVerified': false,
    });
  }

  // ── Get recent searches ───────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRecentSearches({int limit = 5}) async {
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('searches')
        .orderBy('searchedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ── Get saved reports ─────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSavedReports({int limit = 10}) async {
    if (uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('reports')
        .orderBy('generatedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }
}
