// ─── Bhoomi RTC (Record of Rights, Tenancy & Crops) ──────────────────────────
class LandRecord {
  final String surveyNumber;
  final String district;
  final String taluk;
  final String hobli;
  final String village;
  final String? khataNumber;
  final KhataType? khataType;
  final List<LandOwner> owners;
  final String? landType;         // Dry / Wet / Garden / Kharab
  final double? totalAreaAcres;
  final String? cropDetails;
  final List<MutationEntry> mutations;
  final List<EncumbranceEntry> encumbrances;
  final bool isRevenueSite;
  final bool isGovernmentLand;
  final bool isForestLand;
  final bool isLakeBed;
  final String? remarks;
  final DateTime? fetchedAt;
  final double? guidanceValuePerSqft;   // Karnataka stamp duty guidance value
  final double? estimatedMarketValue;   // Estimated market value in lakhs
  final bool areaMismatch;              // Area in RTC differs from sale docs
  final bool hasOwnershipGap;           // Gap in mutation/ownership chain

  const LandRecord({
    required this.surveyNumber,
    required this.district,
    required this.taluk,
    required this.hobli,
    required this.village,
    this.khataNumber,
    this.khataType,
    required this.owners,
    this.landType,
    this.totalAreaAcres,
    this.cropDetails,
    required this.mutations,
    required this.encumbrances,
    required this.isRevenueSite,
    required this.isGovernmentLand,
    required this.isForestLand,
    required this.isLakeBed,
    this.remarks,
    this.fetchedAt,
    this.guidanceValuePerSqft,
    this.estimatedMarketValue,
    this.areaMismatch = false,
    this.hasOwnershipGap = false,
  });

  Map<String, dynamic> toJson() => {
    'surveyNumber': surveyNumber,
    'district': district,
    'taluk': taluk,
    'hobli': hobli,
    'village': village,
    'khataNumber': khataNumber,
    'khataType': khataType?.name,
    'owners': owners.map((o) => o.toJson()).toList(),
    'landType': landType,
    'totalAreaAcres': totalAreaAcres,
    'cropDetails': cropDetails,
    'mutations': mutations.map((m) => m.toJson()).toList(),
    'encumbrances': encumbrances.map((e) => e.toJson()).toList(),
    'isRevenueSite': isRevenueSite,
    'isGovernmentLand': isGovernmentLand,
    'isForestLand': isForestLand,
    'isLakeBed': isLakeBed,
    'remarks': remarks,
    'fetchedAt': fetchedAt?.toIso8601String(),
    'guidanceValuePerSqft': guidanceValuePerSqft,
    'estimatedMarketValue': estimatedMarketValue,
    'areaMismatch': areaMismatch,
    'hasOwnershipGap': hasOwnershipGap,
  };

  factory LandRecord.fromJson(Map<String, dynamic> json) => LandRecord(
    surveyNumber: json['surveyNumber'],
    district: json['district'],
    taluk: json['taluk'],
    hobli: json['hobli'],
    village: json['village'],
    khataNumber: json['khataNumber'],
    khataType: json['khataType'] != null
        ? KhataType.values.byName(json['khataType'])
        : null,
    owners: (json['owners'] as List? ?? [])
        .map((o) => LandOwner.fromJson(o))
        .toList(),
    landType: json['landType'],
    totalAreaAcres: json['totalAreaAcres']?.toDouble(),
    cropDetails: json['cropDetails'],
    mutations: (json['mutations'] as List? ?? [])
        .map((m) => MutationEntry.fromJson(m))
        .toList(),
    encumbrances: (json['encumbrances'] as List? ?? [])
        .map((e) => EncumbranceEntry.fromJson(e))
        .toList(),
    isRevenueSite: json['isRevenueSite'] ?? false,
    isGovernmentLand: json['isGovernmentLand'] ?? false,
    isForestLand: json['isForestLand'] ?? false,
    isLakeBed: json['isLakeBed'] ?? false,
    remarks: json['remarks'],
    fetchedAt: json['fetchedAt'] != null
        ? DateTime.parse(json['fetchedAt'])
        : null,
    guidanceValuePerSqft: json['guidanceValuePerSqft']?.toDouble(),
    estimatedMarketValue: json['estimatedMarketValue']?.toDouble(),
    areaMismatch: json['areaMismatch'] ?? false,
    hasOwnershipGap: json['hasOwnershipGap'] ?? false,
  );
}

// ─── Land Owner ───────────────────────────────────────────────────────────────
class LandOwner {
  final String name;
  final String? fatherName;
  final String? address;
  final double? sharePercentage;
  final String? surveyShare;   // e.g. "1/2", "3/4"

  const LandOwner({
    required this.name,
    this.fatherName,
    this.address,
    this.sharePercentage,
    this.surveyShare,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'fatherName': fatherName,
    'address': address,
    'sharePercentage': sharePercentage,
    'surveyShare': surveyShare,
  };

  factory LandOwner.fromJson(Map<String, dynamic> json) => LandOwner(
    name: json['name'],
    fatherName: json['fatherName'],
    address: json['address'],
    sharePercentage: json['sharePercentage']?.toDouble(),
    surveyShare: json['surveyShare'],
  );
}

// ─── Mutation Entry ───────────────────────────────────────────────────────────
class MutationEntry {
  final String mutationNumber;
  final String reason;     // Sale / Inheritance / Gift / Court order
  final String fromOwner;
  final String toOwner;
  final DateTime? date;
  final String? remarks;

  const MutationEntry({
    required this.mutationNumber,
    required this.reason,
    required this.fromOwner,
    required this.toOwner,
    this.date,
    this.remarks,
  });

  Map<String, dynamic> toJson() => {
    'mutationNumber': mutationNumber,
    'reason': reason,
    'fromOwner': fromOwner,
    'toOwner': toOwner,
    'date': date?.toIso8601String(),
    'remarks': remarks,
  };

  factory MutationEntry.fromJson(Map<String, dynamic> json) => MutationEntry(
    mutationNumber: json['mutationNumber'],
    reason: json['reason'],
    fromOwner: json['fromOwner'],
    toOwner: json['toOwner'],
    date: json['date'] != null ? DateTime.parse(json['date']) : null,
    remarks: json['remarks'],
  );
}

// ─── Encumbrance Entry (EC) ───────────────────────────────────────────────────
class EncumbranceEntry {
  final String ecNumber;
  final String type;           // Mortgage / Sale / Gift / Exchange / Lease
  final String partyName;
  final double? amount;
  final DateTime? date;
  final String? bankName;
  final bool isActive;
  final String? remarks;

  const EncumbranceEntry({
    required this.ecNumber,
    required this.type,
    required this.partyName,
    this.amount,
    this.date,
    this.bankName,
    required this.isActive,
    this.remarks,
  });

  Map<String, dynamic> toJson() => {
    'ecNumber': ecNumber,
    'type': type,
    'partyName': partyName,
    'amount': amount,
    'date': date?.toIso8601String(),
    'bankName': bankName,
    'isActive': isActive,
    'remarks': remarks,
  };

  factory EncumbranceEntry.fromJson(Map<String, dynamic> json) =>
      EncumbranceEntry(
    ecNumber: json['ecNumber'],
    type: json['type'],
    partyName: json['partyName'],
    amount: json['amount']?.toDouble(),
    date: json['date'] != null ? DateTime.parse(json['date']) : null,
    bankName: json['bankName'],
    isActive: json['isActive'] ?? false,
    remarks: json['remarks'],
  );
}

// ─── RERA Record ───────────────────────────────────────────────────────────────
class ReraRecord {
  final String? registrationNumber;
  final String? projectName;
  final String? promoterName;
  final bool isRegistered;
  final DateTime? registrationDate;
  final DateTime? expiryDate;
  final String? projectStatus;     // Ongoing / Completed / Lapsed
  final String? projectType;       // Residential / Commercial / Mixed
  final int? totalUnits;
  final String? websiteUrl;
  final bool hasComplaints;
  final int complaintCount;

  const ReraRecord({
    this.registrationNumber,
    this.projectName,
    this.promoterName,
    required this.isRegistered,
    this.registrationDate,
    this.expiryDate,
    this.projectStatus,
    this.projectType,
    this.totalUnits,
    this.websiteUrl,
    this.hasComplaints = false,
    this.complaintCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'registrationNumber': registrationNumber,
    'projectName': projectName,
    'promoterName': promoterName,
    'isRegistered': isRegistered,
    'registrationDate': registrationDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'projectStatus': projectStatus,
    'projectType': projectType,
    'totalUnits': totalUnits,
    'websiteUrl': websiteUrl,
    'hasComplaints': hasComplaints,
    'complaintCount': complaintCount,
  };

  factory ReraRecord.fromJson(Map<String, dynamic> json) => ReraRecord(
    registrationNumber: json['registrationNumber'],
    projectName: json['projectName'],
    promoterName: json['promoterName'],
    isRegistered: json['isRegistered'] ?? false,
    registrationDate: json['registrationDate'] != null
        ? DateTime.parse(json['registrationDate'])
        : null,
    expiryDate: json['expiryDate'] != null
        ? DateTime.parse(json['expiryDate'])
        : null,
    projectStatus: json['projectStatus'],
    projectType: json['projectType'],
    totalUnits: json['totalUnits'],
    websiteUrl: json['websiteUrl'],
    hasComplaints: json['hasComplaints'] ?? false,
    complaintCount: json['complaintCount'] ?? 0,
  );
}

// ─── Khata Type ───────────────────────────────────────────────────────────────
enum KhataType {
  aKhata,   // Legal - eligible for BBMP loans, building permits
  bKhata,   // Semi-legal - not eligible for bank loans/building permits
  eKhata,   // Electronic Khata - upgraded A Khata
}

extension KhataTypeExtension on KhataType {
  String get displayName {
    switch (this) {
      case KhataType.aKhata: return 'A Khata (Legal)';
      case KhataType.bKhata: return 'B Khata (Semi-legal)';
      case KhataType.eKhata: return 'E Khata (Legal)';
    }
  }

  bool get isLegal => this == KhataType.aKhata || this == KhataType.eKhata;
}
