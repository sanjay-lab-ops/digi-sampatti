class AppStrings {
  AppStrings._();

  // ─── App ───────────────────────────────────────────────────────────────────
  static const String appName = 'DigiSampatti';
  static const String appTagline = 'Know Your Property. Own Your Decision.';
  static const String appVersion = '1.0.6';
  static const String stateKarnataka = 'Karnataka';

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static const String enterPhone = 'Enter your mobile number';
  static const String enterOtp = 'Enter OTP';
  static const String otpSent = 'OTP sent to ';
  static const String verifyOtp = 'Verify OTP';
  static const String sendOtp = 'Send OTP';
  static const String resendOtp = 'Resend OTP';

  // ─── Home ──────────────────────────────────────────────────────────────────
  static const String homeTitle = 'Property Legal Check';
  static const String scanProperty = 'Scan Property';
  static const String manualSearch = 'Manual Search';
  static const String recentReports = 'Recent Reports';
  static const String viewAll = 'View All';
  static const String noReports = 'No reports yet';
  static const String startScan = 'Start your first property scan';

  // ─── Scan ──────────────────────────────────────────────────────────────────
  static const String takePicture = 'Take Photo';
  static const String alignCamera = 'Align camera with property';
  static const String gpsCapturing = 'Capturing GPS coordinates...';
  static const String gpsCaptureed = 'GPS Captured';
  static const String searchByNumber = 'Search by Survey Number';
  static const String enterSurveyNo = 'Survey Number';
  static const String selectDistrict = 'Select District';
  static const String selectTaluk = 'Select Taluk';
  static const String selectHobli = 'Select Hobli';
  static const String selectVillage = 'Select Village';
  static const String searchRecords = 'Search Land Records';

  // ─── Land Records ──────────────────────────────────────────────────────────
  static const String landRecords = 'Land Records';
  static const String rtcDetails = 'RTC Details';
  static const String ownerName = 'Owner Name';
  static const String surveyNumber = 'Survey Number';
  static const String landType = 'Land Type';
  static const String area = 'Area';
  static const String hobli = 'Hobli';
  static const String village = 'Village';
  static const String taluk = 'Taluk';
  static const String district = 'District';
  static const String khataNumber = 'Khata Number';
  static const String khataType = 'Khata Type';
  static const String mutationHistory = 'Mutation History';
  static const String encumbranceDetails = 'Encumbrance Details';
  static const String reraStatus = 'RERA Status';

  // ─── AI Analysis ───────────────────────────────────────────────────────────
  static const String aiAnalysis = 'AI Legal Analysis';
  static const String analyzing = 'Analyzing property records...';
  static const String analysisComplete = 'Analysis Complete';
  static const String riskScore = 'Risk Score';
  static const String recommendation = 'Recommendation';
  static const String legalStatus = 'Legal Status';
  static const String buyRecommendation = 'Safe to Buy';
  static const String cautionRecommendation = 'Buy with Caution';
  static const String dontBuyRecommendation = 'Do Not Buy';
  static const String bankLoanEligibility = 'Bank Loan Eligibility';

  // ─── Report ────────────────────────────────────────────────────────────────
  static const String legalReport = 'Legal Report';
  static const String downloadPdf = 'Download PDF';
  static const String shareReport = 'Share Report';
  static const String reportGenerated = 'Report Generated';
  static const String reportDate = 'Report Date';
  static const String disclaimer =
      'This report is for informational purposes only. '
      'It is not a substitute for professional legal advice. '
      'Consult a registered lawyer before making any property purchase decision.';
  static const String govtDataDisclaimer =
      'Land records sourced from publicly available Karnataka government portals '
      '(bhoomi.karnataka.gov.in, rera.karnataka.gov.in). '
      'Arth ID is an independent information service. '
      'Not affiliated with the Government of Karnataka.';

  // ─── Partners & Commission ──────────────────────────────────────────────────
  static const String partnersTitle = 'Get Expert Help';
  static const String partnersSubtitle = 'Verified professionals for your property';
  static const String partnerLawyerTitle = 'Verified Property Advocates';
  static const String partnerLawyerDesc = 'Physical verification, title search, court checks';
  static const String partnerLawyerCta = 'Connect — ₹2,999 onwards';
  static const String partnerBankTitle = 'Apply for Home Loan';
  static const String partnerBankDesc = 'This property is legally verified — fast approval';
  static const String partnerBankCta = 'Check Eligibility — Free';
  static const String partnerInsuranceTitle = 'Title Insurance';
  static const String partnerInsuranceDesc = 'Protect your investment from future legal disputes';
  static const String partnerInsuranceCta = 'Get Quote — ₹3,000–8,000/year';
  static const String partnerSurveyorTitle = 'Licensed Property Surveyor';
  static const String partnerSurveyorDesc = 'Physical boundary & measurement verification';
  static const String partnerSurveyorCta = 'Book Visit — ₹1,500 onwards';
  static const String partnerDisclaimer =
      'All partners are independently verified by Arth ID. '
      'Arth ID earns a referral fee from partners, '
      'not from you. Your service cost is fixed and transparent.';

  // ─── Payment ───────────────────────────────────────────────────────────────
  static const String generateReport = 'Generate Report';
  static const String reportPrice = '₹499';
  static const String paymentSuccess = 'Payment Successful';
  static const String paymentFailed = 'Payment Failed';
  static const String subscribeMonthly = 'Subscribe - ₹1,999/month';
  static const String unlimitedReports = 'Unlimited Reports';

  // ─── Error Messages ────────────────────────────────────────────────────────
  static const String errorNoInternet = 'No internet connection';
  static const String errorLocationDenied = 'Location permission denied';
  static const String errorCameraDenied = 'Camera permission denied';
  static const String errorRecordsNotFound = 'Land records not found';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorBhoomiDown = 'Bhoomi portal is temporarily unavailable';

  // ─── Karnataka Districts ───────────────────────────────────────────────────
  static const List<String> karnatakaDistricts = [
    'Bagalkot', 'Ballari', 'Belagavi', 'Bengaluru Rural', 'Bengaluru Urban',
    'Bidar', 'Chamarajanagar', 'Chikkaballapura', 'Chikkamagaluru', 'Chitradurga',
    'Dakshina Kannada', 'Davanagere', 'Dharwad', 'Gadag', 'Hassan',
    'Haveri', 'Kalaburagi', 'Kodagu', 'Kolar', 'Koppal',
    'Mandya', 'Mysuru', 'Raichur', 'Ramanagara', 'Shivamogga',
    'Tumakuru', 'Udupi', 'Uttara Kannada', 'Vijayapura', 'Yadgir',
  ];
}
