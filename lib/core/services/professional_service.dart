import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:digi_sampatti/core/models/professional_model.dart';

// ─── Professional Service ──────────────────────────────────────────────────────
// Firestore collections:
//   professionals/{uid}           — verified + pending profiles (read: authenticated users)
//   professional_leads/{leadId}   — buyer→pro connection requests
//
// Security model:
//   - Any authenticated user can READ professionals where status == 'verified'
//   - A professional can WRITE their own profile (except status/verifiedAt/rating — admin only)
//   - Admin changes status via Firebase console or admin SDK
//   - License images stored in Firebase Storage: professional_docs/{uid}/license.jpg (private)
//   - Profile photos: professional_photos/{uid}/profile.jpg (public)
// ─────────────────────────────────────────────────────────────────────────────

class ProfessionalService {
  static final ProfessionalService _i = ProfessionalService._();
  factory ProfessionalService() => _i;
  ProfessionalService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  // ─── Registration ──────────────────────────────────────────────────────────

  /// Submit a new professional registration. Returns error message or null on success.
  Future<String?> register({
    required ProfessionalType type,
    required String fullName,
    String? firmName,
    required String licenseNumber,
    required List<String> districtsServed,
    required int yearsExperience,
    double? feeAmount,
    String? feeNote,
    required List<String> languages,
    required String bio,
    String? upiId,
    String? whatsappNumber,
    File? licenseImageFile,
    File? profilePhotoFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'Not logged in';

    try {
      // Check if already registered
      final existing = await _db.collection('professionals').doc(user.uid).get();
      if (existing.exists) return 'You already have a professional profile';

      // Upload license image if provided
      String? licenseImageUrl;
      if (licenseImageFile != null) {
        final ref = _storage.ref('professional_docs/${user.uid}/license.jpg');
        await ref.putFile(licenseImageFile);
        licenseImageUrl = await ref.getDownloadURL();
      }

      // Upload profile photo if provided
      String? profilePhotoUrl;
      if (profilePhotoFile != null) {
        final ref = _storage.ref('professional_photos/${user.uid}/profile.jpg');
        await ref.putFile(profilePhotoFile);
        profilePhotoUrl = await ref.getDownloadURL();
      }

      final profile = ProfessionalProfile(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        fullName: fullName,
        firmName: firmName,
        type: type,
        licenseNumber: licenseNumber,
        licenseImageUrl: licenseImageUrl,
        profilePhotoUrl: profilePhotoUrl,
        districtsServed: districtsServed,
        yearsExperience: yearsExperience,
        feeAmount: feeAmount,
        feeNote: feeNote,
        languages: languages,
        bio: bio,
        upiId: upiId,
        whatsappNumber: whatsappNumber,
        status: VerificationStatus.pending,
        registeredAt: DateTime.now(),
      );

      await _db.collection('professionals').doc(user.uid).set(profile.toMap());

      // Notify admin via a separate collection (admin monitors this)
      await _db.collection('admin_notifications').add({
        'type': 'new_professional_application',
        'uid': user.uid,
        'phone': user.phoneNumber ?? '',
        'professionalType': type.label,
        'fullName': fullName,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      return null; // success
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  // ─── Get Own Profile ───────────────────────────────────────────────────────

  Future<ProfessionalProfile?> getMyProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('professionals').doc(user.uid).get();
      if (!doc.exists) return null;
      return ProfessionalProfile.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Stream<ProfessionalProfile?> watchMyProfile() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('professionals')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists
            ? ProfessionalProfile.fromMap(doc.id, doc.data()!)
            : null);
  }

  // ─── Update Profile (non-admin fields only) ────────────────────────────────

  Future<String?> updateProfile({
    String? firmName,
    String? feeNote,
    double? feeAmount,
    List<String>? districtsServed,
    String? bio,
    String? upiId,
    String? whatsappNumber,
    File? profilePhotoFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return 'Not logged in';
    try {
      final updates = <String, dynamic>{};
      if (firmName != null) updates['firmName'] = firmName;
      if (feeNote != null) updates['feeNote'] = feeNote;
      if (feeAmount != null) updates['feeAmount'] = feeAmount;
      if (districtsServed != null) updates['districtsServed'] = districtsServed;
      if (bio != null) updates['bio'] = bio;
      if (upiId != null) updates['upiId'] = upiId;
      if (whatsappNumber != null) updates['whatsappNumber'] = whatsappNumber;

      if (profilePhotoFile != null) {
        final ref = _storage.ref('professional_photos/${user.uid}/profile.jpg');
        await ref.putFile(profilePhotoFile);
        updates['profilePhotoUrl'] = await ref.getDownloadURL();
      }

      await _db.collection('professionals').doc(user.uid).update(updates);
      return null;
    } catch (e) {
      return 'Update failed: $e';
    }
  }

  // ─── Marketplace — Buyer-Facing Queries ───────────────────────────────────

  /// Get verified professionals by type, optionally filtered by district.
  Future<List<ProfessionalProfile>> getVerifiedProfessionals({
    required ProfessionalType type,
    String? district,
  }) async {
    try {
      Query query = _db
          .collection('professionals')
          .where('status', isEqualTo: 'verified')
          .where('type', isEqualTo: type.name)
          .orderBy('rating', descending: true)
          .limit(20);

      final snap = await query.get();
      var results = snap.docs
          .map((d) => ProfessionalProfile.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      // Client-side district filter (Firestore array-contains needs single value)
      if (district != null && district.isNotEmpty) {
        final dl = district.toLowerCase();
        final filtered = results.where((p) =>
          p.districtsServed.any((d) => d.toLowerCase().contains(dl))).toList();
        // If nobody serves that district, show everyone (graceful fallback)
        if (filtered.isNotEmpty) results = filtered;
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get all verified professionals across all types for a district.
  Future<Map<ProfessionalType, List<ProfessionalProfile>>> getAllForDistrict(
      String? district) async {
    final result = <ProfessionalType, List<ProfessionalProfile>>{};
    await Future.wait(ProfessionalType.values.map((type) async {
      result[type] = await getVerifiedProfessionals(type: type, district: district);
    }));
    return result;
  }

  /// Get single professional profile.
  Future<ProfessionalProfile?> getProfile(String uid) async {
    try {
      final doc = await _db.collection('professionals').doc(uid).get();
      if (!doc.exists) return null;
      return ProfessionalProfile.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ─── Leads — Buyer requests connection ────────────────────────────────────

  /// Buyer sends a connection request to a professional.
  Future<bool> sendLeadRequest({
    required String professionalUid,
    String? surveyNumber,
    String? district,
    String? message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final lead = ProfessionalLead(
        id: '',
        professionalUid: professionalUid,
        buyerUid: user.uid,
        buyerPhone: user.phoneNumber ?? '',
        surveyNumber: surveyNumber,
        district: district,
        message: message,
        requestedAt: DateTime.now(),
      );

      // Save to global leads collection (professional reads this)
      await _db.collection('professional_leads').add(lead.toMap());

      // Increment lead count on professional profile
      await _db.collection('professionals').doc(professionalUid).update({
        'leadCount': FieldValue.increment(1),
      });

      // Save under buyer's history
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('professional_requests')
          .add(lead.toMap());

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Leads — Professional reads their leads ────────────────────────────────

  Stream<List<ProfessionalLead>> watchMyLeads() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('professional_leads')
        .where('professionalUid', isEqualTo: user.uid)
        .orderBy('requestedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProfessionalLead.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> markLeadViewed(String leadId) async {
    await _db.collection('professional_leads').doc(leadId).update({'status': 'viewed'});
  }

  Future<void> markLeadContacted(String leadId) async {
    await _db.collection('professional_leads').doc(leadId).update({'status': 'contacted'});
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────

  Future<bool> submitReview({
    required String professionalUid,
    required double rating,
    required String review,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _db
          .collection('professionals')
          .doc(professionalUid)
          .collection('reviews')
          .doc(user.uid) // one review per buyer per professional
          .set({
        'buyerUid': user.uid,
        'buyerPhone': user.phoneNumber ?? '',
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Recalculate average rating via Firestore transaction
      await _db.runTransaction((tx) async {
        final reviews = await _db
            .collection('professionals')
            .doc(professionalUid)
            .collection('reviews')
            .get();
        final ratings = reviews.docs
            .map((d) => (d.data()['rating'] as num).toDouble())
            .toList();
        final avg = ratings.isEmpty ? 0.0
            : ratings.reduce((a, b) => a + b) / ratings.length;
        tx.update(_db.collection('professionals').doc(professionalUid), {
          'rating': double.parse(avg.toStringAsFixed(1)),
          'reviewCount': ratings.length,
        });
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Check if current user is a registered professional ───────────────────

  Future<bool> isRegisteredProfessional() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _db.collection('professionals').doc(user.uid).get();
    return doc.exists;
  }
}
