import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Firestore Schema (DigiSampatti) ─────────────────────────────────────────
//
//  users/{uid}                       — user profile (buyer OR seller OR both)
//    /searches/{id}                  — buyer: property search history
//    /reports/{id}                   — buyer: AI property risk reports
//    /journeys/{id}                  — buyer: buying journey stages
//    /tracked_properties/{id}        — buyer: saved properties
//
//  seller_profiles/{uid}             — extended seller profile + verification
//
//  properties/{propId}               — property listings
//    /documents/{docId}              — seller-uploaded documents for this listing
//    /offers/{offerId}               — buyer offers on this property
//
//  offers/{offerId}                  — top-level index (all offers across props)
//  deals/{dealId}                    — active transaction records (escrow stage)
//  trust_scores/{propId}             — AI-computed trust score per property
//
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Collection refs ────────────────────────────────────────────────────────
  static CollectionReference get _properties   => _db.collection('properties');
  static CollectionReference get _offers       => _db.collection('offers');
  static CollectionReference get _deals        => _db.collection('deals');
  static CollectionReference get _trustScores  => _db.collection('trust_scores');
  static CollectionReference get _sellerProfiles => _db.collection('seller_profiles');

  static DocumentReference _prop(String propId) => _properties.doc(propId);

  // ══════════════════════════════════════════════════════════════════════════
  // SELLER: Property Listings
  // ══════════════════════════════════════════════════════════════════════════

  /// Create a new property listing draft. Returns the new propId.
  static Future<String> createPropertyListing({
    required String address,
    required String district,
    required String taluk,
    required String surveyNumber,
    required String propertyType, // 'residential' | 'agricultural' | 'commercial'
    required int salePrice,
    required double area,
    required String areaUnit, // 'sqft' | 'acres' | 'guntas'
    String title = '',
    String description = '',
    String listingPlan = 'basic',
    String? planTxnRef,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _properties.add({
      'sellerId': _uid,
      'address': address,
      'district': district,
      'taluk': taluk,
      'surveyNumber': surveyNumber,
      'propertyType': propertyType,
      'salePrice': salePrice,
      'area': area,
      'areaUnit': areaUnit,
      'title': title,
      'description': description,
      'status': 'draft',
      'listingPlan': listingPlan,
      'planTxnRef': planTxnRef,
      'planPaidAt': planTxnRef != null ? now : null,
      'trustScore': null,
      'verificationStatus': {
        'docsVerified': false,
        'sellerVerified': false,
        'reraCompliant': false,
        'noEncumbrance': false,
        'noLitigation': false,
      },
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  /// Publish a draft listing (makes it visible to buyers).
  static Future<void> publishListing(String propId) async {
    await _prop(propId).update({
      'status': 'listed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch all listings by the current seller.
  static Future<List<Map<String, dynamic>>> getMyListings() async {
    final snap = await _properties
        .where('sellerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
  }

  /// Fetch all active listings (for buyer browse).
  static Future<List<Map<String, dynamic>>> getActiveListings({
    String? district,
    String? propertyType,
    int? maxPrice,
  }) async {
    Query q = _properties.where('status', isEqualTo: 'listed');
    if (district != null) q = q.where('district', isEqualTo: district);
    if (propertyType != null) q = q.where('propertyType', isEqualTo: propertyType);
    if (maxPrice != null) q = q.where('salePrice', isLessThanOrEqualTo: maxPrice);
    final snap = await q.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELLER: Document Uploads
  // ══════════════════════════════════════════════════════════════════════════

  /// Save metadata after a document is uploaded (OCR runs separately).
  static Future<String> saveSellerDocument({
    required String propId,
    required String docType, // 'rtc' | 'ec' | 'khata' | 'sale_deed' | 'other'
    required String fileName,
    required String fileUrl,   // Firebase Storage URL
    String fileExt = 'pdf',
    Map<String, dynamic>? ocrData,
    bool hasPropertyData = false,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _prop(propId).collection('documents').add({
      'sellerId': _uid,
      'propId': propId,
      'docType': docType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileExt': fileExt,
      'ocrData': ocrData,
      'hasPropertyData': hasPropertyData,
      'ocrProcessedAt': ocrData != null ? now : null,
      'uploadedAt': now,
    });
    await _prop(propId).update({'updatedAt': now});
    return ref.id;
  }

  /// Update OCR result on an existing document.
  static Future<void> updateDocumentOcr({
    required String propId,
    required String docId,
    required Map<String, dynamic> ocrData,
    required bool hasPropertyData,
  }) async {
    await _prop(propId).collection('documents').doc(docId).update({
      'ocrData': ocrData,
      'hasPropertyData': hasPropertyData,
      'ocrProcessedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch all documents for a property.
  static Future<List<Map<String, dynamic>>> getPropertyDocuments(String propId) async {
    final snap = await _prop(propId)
        .collection('documents')
        .orderBy('uploadedAt', descending: false)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUYER: Offers / Negotiation
  // ══════════════════════════════════════════════════════════════════════════

  /// Buyer submits a price offer on a property.
  static Future<String> submitOffer({
    required String propId,
    required String sellerId,
    required int amount,
    String message = '',
  }) async {
    final now = FieldValue.serverTimestamp();
    final data = {
      'propertyId': propId,
      'buyerId': _uid,
      'sellerId': sellerId,
      'amount': amount,
      'message': message,
      'status': 'pending', // pending | accepted | countered | rejected | expired
      'counterAmount': null,
      'counterMessage': null,
      'createdAt': now,
      'updatedAt': now,
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 48))),
    };
    // Write to both top-level index and property subcollection
    final ref = await _offers.add(data);
    await _prop(propId).collection('offers').doc(ref.id).set(data);
    // Mark property as under negotiation if not already
    await _prop(propId).update({
      'status': 'under_negotiation',
      'updatedAt': now,
    });
    return ref.id;
  }

  /// Seller responds to an offer (accept / counter / reject).
  static Future<void> respondToOffer({
    required String propId,
    required String offerId,
    required String response, // 'accepted' | 'countered' | 'rejected'
    int? counterAmount,
    String? counterMessage,
  }) async {
    final update = {
      'status': response,
      'counterAmount': counterAmount,
      'counterMessage': counterMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _offers.doc(offerId).update(update);
    await _prop(propId).collection('offers').doc(offerId).update(update);
  }

  /// Fetch all offers for a property (seller view).
  static Future<List<Map<String, dynamic>>> getPropertyOffers(String propId) async {
    final snap = await _prop(propId)
        .collection('offers')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
  }

  /// Fetch all offers made by the current buyer.
  static Future<List<Map<String, dynamic>>> getMyOffers() async {
    final snap = await _offers
        .where('buyerId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DEALS / TRANSACTIONS (Escrow lifecycle)
  // ══════════════════════════════════════════════════════════════════════════

  /// Create a deal record when both parties agree on a price.
  static Future<String> createDeal({
    required String propId,
    required String sellerId,
    required String offerId,
    required int agreedAmount,
    required int advanceAmount,
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await _deals.add({
      'propertyId': propId,
      'buyerId': _uid,
      'sellerId': sellerId,
      'offerId': offerId,
      'agreedAmount': agreedAmount,
      'advanceAmount': advanceAmount,
      'escrowStatus': 'fund', // matches EscrowState enum values
      'advancePaidAt': null,
      'advanceTxnRef': null,
      'agreementSignedAt': null,
      'registrationCompletedAt': null,
      'disputeRaisedAt': null,
      'disputeResolvedAt': null,
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  /// Update deal escrow stage.
  static Future<void> updateDealStage({
    required String dealId,
    required String escrowStatus,
    Map<String, dynamic> extra = const {},
  }) async {
    await _deals.doc(dealId).update({
      'escrowStatus': escrowStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      ...extra,
    });
  }

  /// Record advance payment for a deal.
  static Future<void> recordAdvancePayment({
    required String dealId,
    required String txnRef,
  }) async {
    await updateDealStage(
      dealId: dealId,
      escrowStatus: 'docVerify',
      extra: {
        'advancePaidAt': FieldValue.serverTimestamp(),
        'advanceTxnRef': txnRef,
      },
    );
  }

  /// Fetch deals involving the current user (as buyer or seller).
  static Future<List<Map<String, dynamic>>> getMyDeals() async {
    final asBuyer = await _deals.where('buyerId', isEqualTo: _uid).get();
    final asSeller = await _deals.where('sellerId', isEqualTo: _uid).get();
    final all = {...asBuyer.docs, ...asSeller.docs};
    return all.map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)}).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRUST SCORES
  // ══════════════════════════════════════════════════════════════════════════

  /// Save computed AI trust score for a property.
  static Future<void> saveTrustScore({
    required String propId,
    required String sellerId,
    required int totalScore,
    required Map<String, int> breakdown, // keys: docReads, ownership, survey, noMortgage, noCourt, landType
    List<String> flags = const [],
  }) async {
    final now = FieldValue.serverTimestamp();
    await _trustScores.doc(propId).set({
      'propertyId': propId,
      'sellerId': sellerId,
      'score': totalScore,
      'breakdown': breakdown,
      'flags': flags,
      'lastUpdatedAt': now,
    }, SetOptions(merge: true));
    // Mirror score on the property document
    await _prop(propId).update({
      'trustScore': {'total': totalScore, 'breakdown': breakdown, 'flags': flags},
      'updatedAt': now,
    });
  }

  /// Fetch trust score for a property.
  static Future<Map<String, dynamic>?> getTrustScore(String propId) async {
    final doc = await _trustScores.doc(propId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SELLER VERIFICATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Create or update seller profile with verification flags.
  static Future<void> upsertSellerProfile({
    required String name,
    required String phone,
    String email = '',
    bool aadharVerified = false,
    bool panVerified = false,
    bool ownershipVerified = false,
    Map<String, dynamic>? ocrData,
  }) async {
    await _sellerProfiles.doc(_uid).set({
      'uid': _uid,
      'name': name,
      'phone': phone,
      'email': email,
      'aadharVerified': aadharVerified,
      'panVerified': panVerified,
      'ownershipVerified': ownershipVerified,
      'ocrData': ocrData,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mark seller as verified (admin or portal-confirmed).
  static Future<void> markSellerVerified({
    required String uid,
    required String verifiedBy, // 'bhoomi' | 'admin' | 'aadhaar'
  }) async {
    await _sellerProfiles.doc(uid).update({
      'ownershipVerified': true,
      'verifiedBy': verifiedBy,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update property verification flags after portal checks.
  static Future<void> updatePropertyVerification({
    required String propId,
    bool? docsVerified,
    bool? sellerVerified,
    bool? reraCompliant,
    bool? noEncumbrance,
    bool? noLitigation,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (docsVerified != null) updates['verificationStatus.docsVerified'] = docsVerified;
    if (sellerVerified != null) updates['verificationStatus.sellerVerified'] = sellerVerified;
    if (reraCompliant != null) updates['verificationStatus.reraCompliant'] = reraCompliant;
    if (noEncumbrance != null) updates['verificationStatus.noEncumbrance'] = noEncumbrance;
    if (noLitigation != null) updates['verificationStatus.noLitigation'] = noLitigation;
    await _prop(propId).update(updates);
  }

  /// Fetch seller profile + verification status.
  static Future<Map<String, dynamic>?> getSellerProfile(String uid) async {
    final doc = await _sellerProfiles.doc(uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }
}
