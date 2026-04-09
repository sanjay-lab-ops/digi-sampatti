import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Professional Types ────────────────────────────────────────────────────────
enum ProfessionalType {
  advocate,       // Property lawyer — Bar Council of Karnataka
  broker,         // Real estate broker — RERA Karnataka
  surveyor,       // Licensed government surveyor
  vastu,          // Vastu consultant — certified
  interior,       // Interior designer
  packersMovers,  // Packers & movers — GST registered
  khataAgent,     // Khata / mutation liaison agent
  bank,           // Bank / NBFC home loan officer
  developer,      // Builder / developer — RERA project
}

extension ProfessionalTypeInfo on ProfessionalType {
  String get label {
    switch (this) {
      case ProfessionalType.advocate:      return 'Property Advocate';
      case ProfessionalType.broker:        return 'Real Estate Broker';
      case ProfessionalType.surveyor:      return 'Licensed Surveyor';
      case ProfessionalType.vastu:         return 'Vastu Consultant';
      case ProfessionalType.interior:      return 'Interior Designer';
      case ProfessionalType.packersMovers: return 'Packers & Movers';
      case ProfessionalType.khataAgent:    return 'Khata / Mutation Agent';
      case ProfessionalType.bank:          return 'Bank / Home Loan';
      case ProfessionalType.developer:     return 'Builder / Developer';
    }
  }

  String get licenseLabel {
    switch (this) {
      case ProfessionalType.advocate:      return 'Bar Council Enrollment No.';
      case ProfessionalType.broker:        return 'RERA Broker Registration No.';
      case ProfessionalType.surveyor:      return 'Survey Dept. License No.';
      case ProfessionalType.vastu:         return 'Certification / Membership No.';
      case ProfessionalType.interior:      return 'GST No. / IIID Membership';
      case ProfessionalType.packersMovers: return 'GST Registration No.';
      case ProfessionalType.khataAgent:    return 'Service Provider ID / GST No.';
      case ProfessionalType.bank:          return 'Employee ID / Branch IFSC';
      case ProfessionalType.developer:     return 'RERA Project / Developer No.';
    }
  }

  String get licenseHint {
    switch (this) {
      case ProfessionalType.advocate:      return 'e.g. KAR/2015/1234';
      case ProfessionalType.broker:        return 'e.g. PRM/KA/RERA/2017/01234';
      case ProfessionalType.surveyor:      return 'e.g. KSD/BLR/2019/0567';
      case ProfessionalType.vastu:         return 'e.g. AIVC/2020/789';
      case ProfessionalType.interior:      return 'e.g. 29ABCDE1234F1Z5';
      case ProfessionalType.packersMovers: return 'e.g. 29ABCDE1234F1Z5';
      case ProfessionalType.khataAgent:    return 'e.g. 29ABCDE1234F1Z5';
      case ProfessionalType.bank:          return 'e.g. SBIN0001234 or EMP001';
      case ProfessionalType.developer:     return 'e.g. PRM/KA/RERA/1251/2019';
    }
  }

  String get feeLabel {
    switch (this) {
      case ProfessionalType.advocate:      return 'Consultation fee (₹)';
      case ProfessionalType.broker:        return 'Brokerage (% or ₹ fixed)';
      case ProfessionalType.surveyor:      return 'Site visit fee (₹)';
      case ProfessionalType.vastu:         return 'Consultation fee (₹)';
      case ProfessionalType.interior:      return 'Design fee per sqft (₹)';
      case ProfessionalType.packersMovers: return 'Starting charge (₹)';
      case ProfessionalType.khataAgent:    return 'Service charge (₹)';
      case ProfessionalType.bank:          return 'Processing fee info';
      case ProfessionalType.developer:     return 'Price per sqft (₹)';
    }
  }

  bool get requiresLicense => this != ProfessionalType.interior;

  String get iconName {
    switch (this) {
      case ProfessionalType.advocate:      return 'gavel';
      case ProfessionalType.broker:        return 'real_estate_agent';
      case ProfessionalType.surveyor:      return 'straighten';
      case ProfessionalType.vastu:         return 'self_improvement';
      case ProfessionalType.interior:      return 'design_services';
      case ProfessionalType.packersMovers: return 'local_shipping';
      case ProfessionalType.khataAgent:    return 'receipt_long';
      case ProfessionalType.bank:          return 'account_balance';
      case ProfessionalType.developer:     return 'apartment';
    }
  }
}

// ─── Verification Status ───────────────────────────────────────────────────────
enum VerificationStatus {
  pending,    // Application submitted, not yet reviewed
  verified,   // Admin approved — appears in marketplace
  rejected,   // Admin rejected (with reason)
  suspended,  // Suspended after complaints
}

extension VerificationStatusInfo on VerificationStatus {
  String get label {
    switch (this) {
      case VerificationStatus.pending:   return 'Under Review';
      case VerificationStatus.verified:  return 'Verified';
      case VerificationStatus.rejected:  return 'Rejected';
      case VerificationStatus.suspended: return 'Suspended';
    }
  }

  String get description {
    switch (this) {
      case VerificationStatus.pending:
        return 'Your application is under review. We will call you within 24 hours.';
      case VerificationStatus.verified:
        return 'Your profile is live and visible to buyers.';
      case VerificationStatus.rejected:
        return 'Your application was rejected. See reason below.';
      case VerificationStatus.suspended:
        return 'Your profile has been suspended. Contact support.';
    }
  }
}

// ─── Professional Profile Model ────────────────────────────────────────────────
class ProfessionalProfile {
  final String uid;
  final String phone;
  final String fullName;
  final String? firmName;
  final ProfessionalType type;
  final String licenseNumber;
  final String? licenseImageUrl;      // Firebase Storage — only readable by admin
  final String? profilePhotoUrl;      // Firebase Storage — public
  final List<String> districtsServed; // e.g. ['Bengaluru Urban', 'Mysuru']
  final int yearsExperience;
  final double? feeAmount;            // ₹ or % depending on type
  final String? feeNote;              // Human-readable fee description
  final List<String> languages;       // ['Kannada', 'English', 'Hindi']
  final String bio;
  final String? upiId;                // For receiving payments from buyers
  final String? whatsappNumber;       // Display number for buyers to contact
  final VerificationStatus status;
  final String? rejectionReason;
  final double rating;                // 0.0–5.0
  final int reviewCount;
  final int leadCount;                // How many buyer requests received
  final DateTime registeredAt;
  final DateTime? verifiedAt;

  const ProfessionalProfile({
    required this.uid,
    required this.phone,
    required this.fullName,
    this.firmName,
    required this.type,
    required this.licenseNumber,
    this.licenseImageUrl,
    this.profilePhotoUrl,
    required this.districtsServed,
    required this.yearsExperience,
    this.feeAmount,
    this.feeNote,
    required this.languages,
    required this.bio,
    this.upiId,
    this.whatsappNumber,
    required this.status,
    this.rejectionReason,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.leadCount = 0,
    required this.registeredAt,
    this.verifiedAt,
  });

  factory ProfessionalProfile.fromMap(String uid, Map<String, dynamic> map) {
    return ProfessionalProfile(
      uid: uid,
      phone: map['phone'] ?? '',
      fullName: map['fullName'] ?? '',
      firmName: map['firmName'],
      type: ProfessionalType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ProfessionalType.advocate,
      ),
      licenseNumber: map['licenseNumber'] ?? '',
      licenseImageUrl: map['licenseImageUrl'],
      profilePhotoUrl: map['profilePhotoUrl'],
      districtsServed: List<String>.from(map['districtsServed'] ?? []),
      yearsExperience: map['yearsExperience'] ?? 0,
      feeAmount: (map['feeAmount'] as num?)?.toDouble(),
      feeNote: map['feeNote'],
      languages: List<String>.from(map['languages'] ?? ['Kannada']),
      bio: map['bio'] ?? '',
      upiId: map['upiId'],
      whatsappNumber: map['whatsappNumber'],
      status: VerificationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => VerificationStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      leadCount: map['leadCount'] ?? 0,
      registeredAt: (map['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'phone': phone,
    'fullName': fullName,
    'firmName': firmName,
    'type': type.name,
    'licenseNumber': licenseNumber,
    'licenseImageUrl': licenseImageUrl,
    'profilePhotoUrl': profilePhotoUrl,
    'districtsServed': districtsServed,
    'yearsExperience': yearsExperience,
    'feeAmount': feeAmount,
    'feeNote': feeNote,
    'languages': languages,
    'bio': bio,
    'upiId': upiId,
    'whatsappNumber': whatsappNumber,
    'status': status.name,
    'rejectionReason': rejectionReason,
    'rating': rating,
    'reviewCount': reviewCount,
    'leadCount': leadCount,
    'registeredAt': Timestamp.fromDate(registeredAt),
    'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
  };

  ProfessionalProfile copyWith({
    String? licenseImageUrl,
    String? profilePhotoUrl,
    VerificationStatus? status,
    String? rejectionReason,
    double? rating,
    int? reviewCount,
    int? leadCount,
  }) => ProfessionalProfile(
    uid: uid, phone: phone, fullName: fullName, firmName: firmName,
    type: type, licenseNumber: licenseNumber,
    licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
    profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    districtsServed: districtsServed, yearsExperience: yearsExperience,
    feeAmount: feeAmount, feeNote: feeNote, languages: languages, bio: bio,
    upiId: upiId, whatsappNumber: whatsappNumber,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    leadCount: leadCount ?? this.leadCount,
    registeredAt: registeredAt, verifiedAt: verifiedAt,
  );
}

// ─── Lead (buyer → professional connection request) ───────────────────────────
class ProfessionalLead {
  final String id;
  final String professionalUid;
  final String buyerUid;
  final String buyerPhone;
  final String? surveyNumber;
  final String? district;
  final String? message;
  final DateTime requestedAt;
  final String status; // 'new' | 'viewed' | 'contacted' | 'closed'

  const ProfessionalLead({
    required this.id,
    required this.professionalUid,
    required this.buyerUid,
    required this.buyerPhone,
    this.surveyNumber,
    this.district,
    this.message,
    required this.requestedAt,
    this.status = 'new',
  });

  factory ProfessionalLead.fromMap(String id, Map<String, dynamic> map) =>
    ProfessionalLead(
      id: id,
      professionalUid: map['professionalUid'] ?? '',
      buyerUid: map['buyerUid'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      surveyNumber: map['surveyNumber'],
      district: map['district'],
      message: map['message'],
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'new',
    );

  Map<String, dynamic> toMap() => {
    'professionalUid': professionalUid,
    'buyerUid': buyerUid,
    'buyerPhone': buyerPhone,
    'surveyNumber': surveyNumber,
    'district': district,
    'message': message,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'status': status,
  };
}

// ─── Constants ────────────────────────────────────────────────────────────────
const kKarnatakaDistricts = [
  'Bagalkot', 'Ballari', 'Belagavi', 'Bengaluru Rural', 'Bengaluru Urban',
  'Bidar', 'Chamarajanagar', 'Chikkaballapur', 'Chikkamagaluru', 'Chitradurga',
  'Dakshina Kannada', 'Davanagere', 'Dharwad', 'Gadag', 'Hassan',
  'Haveri', 'Kalaburagi', 'Kodagu', 'Kolar', 'Koppal',
  'Mandya', 'Mysuru', 'Raichur', 'Ramanagara', 'Shivamogga',
  'Tumakuru', 'Udupi', 'Uttara Kannada', 'Vijayapura', 'Yadgir',
];

const kLanguages = ['Kannada', 'English', 'Hindi', 'Tamil', 'Telugu', 'Urdu', 'Marathi', 'Tulu'];
