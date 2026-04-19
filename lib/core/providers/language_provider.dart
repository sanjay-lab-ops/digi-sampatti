import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }
}

// ─── All 22 Scheduled Languages of India + English ────────────────────────────
const List<Map<String, String>> kSupportedLanguages = [
  {'code': 'en',  'name': 'English',       'native': 'English'},
  {'code': 'hi',  'name': 'Hindi',         'native': 'हिन्दी'},
  {'code': 'kn',  'name': 'Kannada',       'native': 'ಕನ್ನಡ'},
  {'code': 'ta',  'name': 'Tamil',         'native': 'தமிழ்'},
  {'code': 'te',  'name': 'Telugu',        'native': 'తెలుగు'},
  {'code': 'ml',  'name': 'Malayalam',     'native': 'മലയാളം'},
  {'code': 'mr',  'name': 'Marathi',       'native': 'मराठी'},
  {'code': 'bn',  'name': 'Bengali',       'native': 'বাংলা'},
  {'code': 'gu',  'name': 'Gujarati',      'native': 'ગુજરાતી'},
  {'code': 'pa',  'name': 'Punjabi',       'native': 'ਪੰਜਾਬੀ'},
  {'code': 'or',  'name': 'Odia',          'native': 'ଓଡ଼ିଆ'},
  {'code': 'as',  'name': 'Assamese',      'native': 'অসমীয়া'},
  {'code': 'ur',  'name': 'Urdu',          'native': 'اردو'},
  {'code': 'ne',  'name': 'Nepali',        'native': 'नेपाली'},
  {'code': 'ks',  'name': 'Kashmiri',      'native': 'کٲشُر'},
  {'code': 'kok', 'name': 'Konkani',       'native': 'कोंकणी'},
  {'code': 'mai', 'name': 'Maithili',      'native': 'मैथिली'},
  {'code': 'mni', 'name': 'Manipuri',      'native': 'ꯃꯩꯇꯩꯂꯣꯟ'},
  {'code': 'doi', 'name': 'Dogri',         'native': 'डोगरी'},
  {'code': 'brx', 'name': 'Bodo',          'native': 'बर\''},
  {'code': 'sat', 'name': 'Santali',       'native': 'ᱥᱟᱱᱛᱟᱲᱤ'},
  {'code': 'sd',  'name': 'Sindhi',        'native': 'سنڌي'},
  {'code': 'sa',  'name': 'Sanskrit',      'native': 'संस्कृतम्'},
];

// ─── Translation Map ──────────────────────────────────────────────────────────
// Structure: _strings[key][langCode] = translation
// Falls back to 'en' if translation missing for a language.
const Map<String, Map<String, String>> _strings = {
  'homeTitle': {
    'en': 'DigiSampatti', 'hi': 'डिजीसम्पत्ति', 'kn': 'ಡಿಜಿಸಂಪತ್ತಿ', 'ta': 'டிஜிசம்பத்தி',
    'te': 'డిజిసంపత్తి', 'ml': 'ഡിജിസംപത്തി', 'mr': 'डिजीसंपत्ती', 'bn': 'ডিজিসম্পত্তি',
    'gu': 'ડિજીસંપત્તિ', 'pa': 'ਡਿਜੀਸੰਪਤੀ', 'or': 'ଡିଜିସମ୍ପତ୍ତି', 'as': 'ডিজিসম্পত্তি',
    'ur': 'ڈیجی سمپتی', 'ne': 'डिजीसम्पत्ति', 'ks': 'ڈیجی سمپتی', 'kok': 'डिजीसंपत्ती',
    'mai': 'डिजीसम्पत्ति', 'mni': 'DigiSampatti', 'doi': 'डिजीसम्पत्ति', 'brx': 'DigiSampatti',
    'sat': 'DigiSampatti', 'sd': 'ڊجيءِ سمپتي', 'sa': 'DigiSampatti',
  },
  'knowBeforeYouBuy': {
    'en': 'Know Before You Buy',
    'hi': 'खरीदने से पहले जानें', 'kn': 'ಖರೀದಿಸುವ ಮೊದಲು ತಿಳಿಯಿರಿ',
    'ta': 'வாங்குவதற்கு முன் தெரிந்து கொள்ளுங்கள்',
    'te': 'కొనుగోలు చేయడానికి ముందు తెలుసుకోండి',
    'ml': 'വാങ്ങുന്നതിനുമുൻപ് അറിയൂ', 'mr': 'खरेदी करण्यापूर्वी जाणून घ्या',
    'bn': 'কেনার আগে জানুন', 'gu': 'ખરીદ કરતાં પહેલા જાણો',
    'pa': 'ਖਰੀਦਣ ਤੋਂ ਪਹਿਲਾਂ ਜਾਣੋ', 'or': 'କିଣିବା ପୂର୍ବରୁ ଜାଣନ୍ତୁ',
    'as': 'কিনাৰ আগতে জানক', 'ur': 'خریدنے سے پہلے جانیں',
    'ne': 'किन्नु अघि जान्नुहोस्', 'sa': 'क्रयात् पूर्वं जानीत',
  },
  'startPropertyCheck': {
    'en': 'Start Property Check', 'hi': 'संपत्ति जांच शुरू करें',
    'kn': 'ಆಸ್ತಿ ಪರಿಶೀಲನೆ ಪ್ರಾರಂಭಿಸಿ', 'ta': 'சொத்து சரிபார்ப்பை தொடங்கு',
    'te': 'ఆస్తి తనిఖీ ప్రారంభించండి', 'ml': 'പ്രോപ്പർട്ടി പരിശോധന ആരംഭിക്കുക',
    'mr': 'मालमत्ता तपासणी सुरू करा', 'bn': 'সম্পত্তি যাচাই শুরু করুন',
    'gu': 'મિલ્કત ચકાસણી શરૂ કરો', 'pa': 'ਜਾਇਦਾਦ ਜਾਂਚ ਸ਼ੁਰੂ ਕਰੋ',
    'or': 'ସଂପତ୍ତି ଯାଞ୍ଚ ଆରମ୍ଭ କରନ୍ତୁ', 'ur': 'جائیداد کی جانچ شروع کریں',
  },
  'scanProperty': {
    'en': 'Scan Property', 'hi': 'संपत्ति स्कैन करें', 'kn': 'ಆಸ್ತಿ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    'ta': 'சொத்தை ஸ்கேன் செய்க', 'te': 'ఆస్తిని స్కాన్ చేయండి',
    'ml': 'പ്രോപ്പർട്ടി സ്കാൻ ചെയ്യൂ', 'mr': 'मालमत्ता स्कॅन करा',
    'bn': 'সম্পত্তি স্ক্যান করুন', 'gu': 'મિલ્કત સ્કૅન કરો',
    'pa': 'ਜਾਇਦਾਦ ਸਕੈਨ ਕਰੋ', 'or': 'ସଂପତ୍ତି ସ୍କ୍ୟାନ୍ କରନ୍ତୁ',
    'ur': 'جائیداد اسکین کریں',
  },
  'manualSearch': {
    'en': 'Manual Search', 'hi': 'मैन्युअल खोज', 'kn': 'ಕೈಯಾರೆ ಹುಡುಕಿ',
    'ta': 'கைமுறை தேடல்', 'te': 'మాన్యువల్ శోధన',
    'ml': 'മാനുവൽ തിരയൽ', 'mr': 'मॅन्युअल शोध',
    'bn': 'ম্যানুয়াল অনুসন্ধান', 'gu': 'મેન્યુઅલ શોધ',
    'pa': 'ਮੈਨੂਅਲ ਖੋਜ', 'or': 'ମ୍ୟାନୁଅଲ୍ ଖୋଜ', 'ur': 'دستی تلاش',
  },
  'myReports': {
    'en': 'My Reports', 'hi': 'मेरी रिपोर्ट', 'kn': 'ನನ್ನ ವರದಿಗಳು',
    'ta': 'என் அறிக்கைகள்', 'te': 'నా నివేదికలు',
    'ml': 'എന്റെ റിപ്പോർട്ടുകൾ', 'mr': 'माझे अहवाल',
    'bn': 'আমার রিপোর্ট', 'gu': 'મારા અહેવાલ',
    'pa': 'ਮੇਰੀਆਂ ਰਿਪੋਰਟਾਂ', 'or': 'ମୋ ରିପୋର୍ଟ', 'ur': 'میری رپورٹیں',
  },
  'moreTools': {
    'en': 'More Tools', 'hi': 'अधिक उपकरण', 'kn': 'ಇನ್ನಷ್ಟು ಸಾಧನಗಳು',
    'ta': 'மேலும் கருவிகள்', 'te': 'మరిన్ని సాధనాలు',
    'ml': 'കൂടുതൽ ഉപകരണങ്ങൾ', 'mr': 'अधिक साधने',
    'bn': 'আরো টুলস', 'gu': 'વધુ સાધનો',
    'pa': 'ਹੋਰ ਸੰਦ', 'or': 'ଅଧିକ ଉପକରଣ', 'ur': 'مزید ٹولز',
  },
  'safetyScore': {
    'en': 'Safety Score', 'hi': 'सुरक्षा अंक', 'kn': 'ಸುರಕ್ಷತಾ ಅಂಕ',
    'ta': 'பாதுகாப்பு மதிப்பெண்', 'te': 'భద్రతా స్కోరు',
    'ml': 'സുരക്ഷ സ്കോർ', 'mr': 'सुरक्षा स्कोर',
    'bn': 'নিরাপত্তা স্কোর', 'gu': 'સુરક્ષા સ્કોર',
    'pa': 'ਸੁਰੱਖਿਆ ਸਕੋਰ', 'or': 'ସୁରକ୍ଷା ସ୍କୋର', 'ur': 'حفاظتی اسکور',
  },
  'recentReports': {
    'en': 'Recent Reports', 'hi': 'हाल की रिपोर्ट', 'kn': 'ಇತ್ತೀಚಿನ ವರದಿಗಳು',
    'ta': 'சமீபத்திய அறிக்கைகள்', 'te': 'ఇటీవలి నివేదికలు',
    'ml': 'സമീപകാല റിപ്പോർട്ടുകൾ', 'mr': 'अलीकडील अहवाल',
    'bn': 'সাম্প্রতিক রিপোর্ট', 'gu': 'તાજેતરના અહેવાલ',
    'pa': 'ਹਾਲੀਆ ਰਿਪੋਰਟਾਂ', 'or': 'ସ୍ୱଳ୍ଭ ଦିନ ରିପୋର୍ଟ', 'ur': 'حالیہ رپورٹیں',
  },
  'noReports': {
    'en': 'No reports yet', 'hi': 'अभी कोई रिपोर्ट नहीं', 'kn': 'ಯಾವುದೇ ವರದಿ ಇಲ್ಲ',
    'ta': 'இன்னும் அறிக்கைகள் இல்லை', 'te': 'ఇంకా నివేదికలు లేవు',
    'ml': 'ഇതുവരെ റിപ്പോർട്ടുകൾ ഇല്ല', 'mr': 'अद्याप कोणतेही अहवाल नाहीत',
    'bn': 'এখনো কোনো রিপোর্ট নেই', 'gu': 'હજી કોઈ અહેવાલ નહીં',
    'pa': 'ਹੁਣ ਤੱਕ ਕੋਈ ਰਿਪੋਰਟ ਨਹੀਂ', 'ur': 'ابھی کوئی رپورٹ نہیں',
  },
  'enterMobileNumber': {
    'en': 'Enter Mobile Number', 'hi': 'मोबाइल नंबर दर्ज करें',
    'kn': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ', 'ta': 'மொபைல் எண் உள்ளிடுக',
    'te': 'మొబైల్ నంబర్ నమోదు చేయండి', 'ml': 'മൊബൈൽ നമ്പർ നൽകൂ',
    'mr': 'मोबाइल नंबर प्रविष्ट करा', 'bn': 'মোবাইল নম্বর দিন',
    'gu': 'મોબાઈલ નંબર દાખલ કરો', 'pa': 'ਮੋਬਾਈਲ ਨੰਬਰ ਦਰਜ ਕਰੋ',
    'or': 'ମୋବାଇଲ ନମ୍ବର ଦିଅନ୍ତୁ', 'ur': 'موبائل نمبر درج کریں',
  },
  'sendOtp': {
    'en': 'Send OTP', 'hi': 'OTP भेजें', 'kn': 'OTP ಕಳುಹಿಸಿ',
    'ta': 'OTP அனுப்பு', 'te': 'OTP పంపండి', 'ml': 'OTP അയക്കൂ',
    'mr': 'OTP पाठवा', 'bn': 'OTP পাঠান', 'gu': 'OTP મોકલો',
    'pa': 'OTP ਭੇਜੋ', 'or': 'OTP ପଠାନ୍ତୁ', 'ur': 'OTP بھیجیں',
  },
  'verifyOtp': {
    'en': 'Verify OTP', 'hi': 'OTP सत्यापित करें', 'kn': 'OTP ಪರಿಶೀಲಿಸಿ',
    'ta': 'OTP சரிபார்க்கவும்', 'te': 'OTP ధృవీకరించండి',
    'ml': 'OTP പരിശോധിക്കൂ', 'mr': 'OTP सत्यापित करा',
    'bn': 'OTP যাচাই করুন', 'gu': 'OTP ચકાસો',
    'pa': 'OTP ਤਸਦੀਕ ਕਰੋ', 'or': 'OTP ଯାଞ୍ଚ କରନ୍ତୁ', 'ur': 'OTP تصدیق کریں',
  },
  'enterOtpHint': {
    'en': 'Enter 6-digit OTP', 'hi': '6 अंकों का OTP दर्ज करें',
    'kn': '6 ಅಂಕಿಯ OTP ನಮೂದಿಸಿ', 'ta': '6 இலக்க OTP உள்ளிடுக',
    'te': '6 అంకెల OTP నమోదు చేయండి', 'ml': '6 അക്ക OTP നൽകൂ',
    'mr': '6 अंकी OTP प्रविष्ट करा', 'bn': '৬ সংখ্যার OTP দিন',
    'gu': '6 અંકનો OTP દાખલ કરો', 'pa': '6 ਅੰਕਾਂ ਵਾਲਾ OTP ਦਰਜ ਕਰੋ',
    'ur': '6 ہندسوں کا OTP درج کریں',
  },
  'otpSentTo': {
    'en': 'OTP sent to: ', 'hi': 'OTP भेजा गया: ', 'kn': 'OTP ಕಳುಹಿಸಲಾಗಿದೆ: ',
    'ta': 'OTP அனுப்பப்பட்டது: ', 'te': 'OTP పంపబడింది: ',
    'ml': 'OTP അയച്ചു: ', 'mr': 'OTP पाठवला: ', 'bn': 'OTP পাঠানো হয়েছে: ',
    'gu': 'OTP મોકલ્યો: ', 'pa': 'OTP ਭੇਜਿਆ: ', 'ur': 'OTP بھیجا گیا: ',
  },
  'changeNumber': {
    'en': 'Change Number', 'hi': 'नंबर बदलें', 'kn': 'ಸಂಖ್ಯೆ ಬದಲಿಸಿ',
    'ta': 'எண்ணை மாற்று', 'te': 'నంబర్ మార్చండి', 'ml': 'നമ്പർ മാറ്റൂ',
    'mr': 'नंबर बदला', 'bn': 'নম্বর পরিবর্তন করুন', 'gu': 'નંબર બદલો',
    'pa': 'ਨੰਬਰ ਬਦਲੋ', 'or': 'ନମ୍ବର ବଦଳାନ୍ତୁ', 'ur': 'نمبر تبدیل کریں',
  },
  'agreeTerms': {
    'en': 'By continuing, you agree to our Terms of Service\nand Privacy Policy',
    'hi': 'जारी रखने पर आप हमारी सेवा की शर्तें और गोपनीयता नीति से सहमत हैं',
    'kn': 'ಮುಂದುವರೆಯುವ ಮೂಲಕ ನೀವು ನಮ್ಮ ನಿಯಮಗಳು ಮತ್ತು ಗೌಪ್ಯತಾ ನೀತಿಗೆ ಒಪ್ಪುತ್ತೀರಿ',
    'ta': 'தொடரும்போது நீங்கள் எங்கள் விதிமுறைகளுக்கு ஒப்புக்கொள்கிறீர்கள்',
    'te': 'కొనసాగించడం ద్వారా మీరు మా నిబంధనలకు అంగీకరిస్తున్నారు',
    'ml': 'തുടരുന്നതിലൂടെ നിങ്ങൾ ഞങ്ങളുടെ നിബന്ധനകൾ അംഗീകരിക്കുന്നു',
    'mr': 'पुढे जाताना आपण आमच्या अटी व शर्तींना मान्यता देतो',
    'bn': 'চালিয়ে গেলে আপনি আমাদের শর্তাবলীতে সম্মত হচ্ছেন',
    'gu': 'આગળ વધવાથી તમે અમારી સેવા શરતો સ્વીকારો છો',
    'pa': 'ਜਾਰੀ ਰੱਖਣ ਨਾਲ ਤੁਸੀਂ ਸਾਡੀਆਂ ਸ਼ਰਤਾਂ ਨਾਲ ਸਹਿਮਤ ਹੋ',
    'ur': 'جاری رکھنے پر آپ ہماری شرائط سے متفق ہیں',
  },
  'platformTagline': {
    'en': 'Property Verification Platform', 'hi': 'संपत्ति सत्यापन मंच',
    'kn': 'ಆಸ್ತಿ ಪರಿಶೀಲನಾ ವೇದಿಕೆ', 'ta': 'சொத்து சரிபார்ப்பு தளம்',
    'te': 'ఆస్తి ధృవీకరణ వేదిక', 'ml': 'പ്രോപ്പർട്ടി സ്ഥിരീകരണ വേദി',
    'mr': 'मालमत्ता पडताळणी व्यासपीठ', 'bn': 'সম্পত্তি যাচাই প্ল্যাটফর্ম',
    'gu': 'મિલ્કત ચકાસણી પ્લેટફોર્મ', 'pa': 'ਜਾਇਦਾਦ ਤਸਦੀਕ ਪਲੇਟਫਾਰਮ',
    'or': 'ସଂପତ୍ତି ଯାଞ୍ଚ ମଞ୍ଚ', 'ur': 'جائیداد تصدیق پلیٹ فارم',
  },
  'propertyTransfer': {
    'en': 'Property Transfer', 'hi': 'संपत्ति हस्तांतरण',
    'kn': 'ಆಸ್ತಿ ವರ್ಗಾವಣೆ', 'ta': 'சொத்து பரிமாற்றம்',
    'te': 'ఆస్తి బదిలీ', 'ml': 'പ്രോപ്പർട്ടി കൈമാറ്റം',
    'mr': 'मालमत्ता हस्तांतरण', 'bn': 'সম্পত্তি হস্তান্তর',
    'gu': 'મિલ્કત ટ્રાન્સ્ફર', 'pa': 'ਜਾਇਦਾਦ ਤਬਾਦਲਾ', 'ur': 'جائیداد منتقلی',
  },
  'financialTools': {
    'en': 'Financial Tools', 'hi': 'वित्तीय उपकरण',
    'kn': 'ಹಣಕಾಸು ಸಾಧನಗಳು', 'ta': 'நிதி கருவிகள்',
    'te': 'ఆర్థిక సాధనాలు', 'ml': 'ധനകാര്യ ഉപകരണങ്ങൾ',
    'mr': 'आर्थिक साधने', 'bn': 'আর্থিক সরঞ্জাম',
    'gu': 'નાણાકીય સાધનો', 'pa': 'ਵਿੱਤੀ ਸੰਦ', 'ur': 'مالی ٹولز',
  },
  'buyerGuides': {
    'en': 'Buyer Guides', 'hi': 'खरीदार गाइड',
    'kn': 'ಖರೀದಿದಾರ ಮಾರ್ಗದರ್ಶಿ', 'ta': 'வாங்குபவர் வழிகாட்டி',
    'te': 'కొనుగోలుదారు మార్గదర్శి', 'ml': 'ക്രേതാ ഗൈഡ്',
    'mr': 'खरेदीदार मार्गदर्शक', 'bn': 'ক্রেতা গাইড',
    'gu': 'ખરીદદાર માર્ગદર્શિકા', 'pa': 'ਖਰੀਦਦਾਰ ਗਾਈਡ', 'ur': 'خریدار گائیڈ',
  },
  'expertHelp': {
    'en': 'Expert Help', 'hi': 'विशेषज्ञ सहायता',
    'kn': 'ತಜ್ಞರ ಸಹಾಯ', 'ta': 'நிபுணர் உதவி',
    'te': 'నిపుణుల సహాయం', 'ml': 'വിദഗ്ദ്ധ സഹായം',
    'mr': 'तज्ञांची मदत', 'bn': 'বিশেষজ্ঞ সহায়তা',
    'gu': 'નિષ્ણાત મદદ', 'pa': 'ਮਾਹਰ ਮਦਦ', 'ur': 'ماہر مدد',
  },
  'courtCaseCheck': {
    'en': 'Court Case Check', 'hi': 'न्यायालय मामला जांच',
    'kn': 'ನ್ಯಾಯಾಲಯ ಪ್ರಕರಣ ಪರಿಶೀಲನೆ', 'ta': 'நீதிமன்ற வழக்கு சரிபார்ப்பு',
    'te': 'కోర్టు కేసు తనిఖీ', 'ml': 'കോടതി കേസ് പരിശോധന',
    'mr': 'न्यायालय प्रकरण तपासणी', 'bn': 'আদালতের মামলা যাচাই',
    'gu': 'કોર્ટ કેસ ચેક', 'pa': 'ਅਦਾਲਤੀ ਕੇਸ ਜਾਂਚ', 'ur': 'عدالتی کیس چیک',
  },
  'buyingJourney': {
    'en': 'Buying Journey', 'hi': 'खरीद यात्रा',
    'kn': 'ಖರೀದಿ ಮಾರ್ಗದರ್ಶಿ', 'ta': 'வாங்குதல் பயணம்',
    'te': 'కొనుగోలు ప్రయాణం', 'ml': 'വാങ്ങൽ യാത്ര',
    'mr': 'खरेदी प्रवास', 'bn': 'কেনাকাটার যাত্রা',
    'gu': 'ખરીદ પ્રવાસ', 'pa': 'ਖਰੀਦ ਯਾਤਰਾ', 'ur': 'خریداری سفر',
  },
  'nriMode': {
    'en': 'NRI Mode', 'hi': 'NRI मोड',
    'kn': 'NRI ಮಾರ್ಗದರ್ಶಿ', 'ta': 'NRI முறை',
    'te': 'NRI మోడ్', 'ml': 'NRI മോഡ്',
    'mr': 'NRI मोड', 'bn': 'NRI মোড',
    'gu': 'NRI મોડ', 'pa': 'NRI ਮੋਡ', 'ur': 'NRI موڈ',
  },
  'photoGps': {
    'en': 'Photo + GPS', 'hi': 'फ़ोटो + GPS', 'kn': 'ಫೋಟೋ + GPS',
    'ta': 'புகைப்படம் + GPS', 'te': 'ఫోటో + GPS', 'ml': 'ഫോട്ടോ + GPS',
    'mr': 'फोटो + GPS', 'bn': 'ছবি + GPS', 'gu': 'ફોટો + GPS',
    'pa': 'ਫੋਟੋ + GPS', 'ur': 'تصویر + GPS',
  },
  'surveyNo': {
    'en': 'Survey No.', 'hi': 'सर्वे नं.', 'kn': 'ಸರ್ವೆ ಸಂಖ್ಯೆ',
    'ta': 'சர்வே எண்', 'te': 'సర్వే నం.', 'ml': 'സർവ്വേ നം.',
    'mr': 'सर्वे क्र.', 'bn': 'সার্ভে নং.', 'gu': 'સર્વે નં.',
    'pa': 'ਸਰਵੇ ਨੰ.', 'ur': 'سروے نمبر',
  },
  'myProfile': {
    'en': 'My Profile', 'hi': 'मेरी प्रोफ़ाइल', 'kn': 'ನನ್ನ ಪ್ರೊಫೈಲ್',
    'ta': 'என் சுயவிவரம்', 'te': 'నా ప్రొఫైల్', 'ml': 'എന്റെ പ്രൊഫൈൽ',
    'mr': 'माझी प्रोफाइल', 'bn': 'আমার প্রোফাইল', 'gu': 'મારી પ્રોફાઇલ',
    'pa': 'ਮੇਰਾ ਪ੍ਰੋਫਾਈਲ', 'ur': 'میری پروفائل',
  },
  'signOut': {
    'en': 'Sign Out', 'hi': 'साइन आउट', 'kn': 'ಹೊರಗೆ ಹೋಗಿ',
    'ta': 'வெளியேறு', 'te': 'సైన్ అవుట్', 'ml': 'സൈൻ ഔട്ട്',
    'mr': 'साइन आउट', 'bn': 'সাইন আউট', 'gu': 'સાઇન આઉટ',
    'pa': 'ਸਾਈਨ ਆਊਟ', 'ur': 'سائن آؤٹ',
  },
  'viewAll': {
    'en': 'View All', 'hi': 'सब देखें', 'kn': 'ಎಲ್ಲ ನೋಡಿ',
    'ta': 'அனைத்தும் பார்', 'te': 'అన్నీ చూడండి', 'ml': 'എല്ലാം കാണൂ',
    'mr': 'सर्व पहा', 'bn': 'সব দেখুন', 'gu': 'બધું જુઓ',
    'pa': 'ਸਭ ਵੇਖੋ', 'ur': 'سب دیکھیں',
  },
  'knowBeforeYouBuyTag': {
    'en': 'Know Before You Buy', 'hi': 'खरीदने से पहले जानें',
    'kn': 'ಖರೀದಿಸುವ ಮೊದಲು ತಿಳಿಯಿರಿ', 'ta': 'வாங்குவதற்கு முன் தெரிந்துகொள்',
    'te': 'కొనుగోలు చేయడానికి ముందు తెలుసుకోండి',
    'ml': 'വാങ്ങുന்നതിനുമുൻപ് അറിയൂ', 'mr': 'खरेदी करण्यापूर्वी जाणून घ्या',
    'bn': 'কেনার আগে জানুন', 'gu': 'ખરીદ કરતાં પહેલા જાણો',
    'pa': 'ਖਰੀਦਣ ਤੋਂ ਪਹਿਲਾਂ ਜਾਣੋ', 'ur': 'خریدنے سے پہلے جانیں',
  },
  'verifyInMinutes': {
    'en': 'Property verification in minutes',
    'hi': 'मिनटों में संपत्ति सत्यापन',
    'kn': 'ನಿಮಿಷಗಳಲ್ಲಿ ಆಸ್ತಿ ಪರಿಶೀಲನೆ',
    'ta': 'நிமிடங்களில் சொத்து சரிபார்ப்பு',
    'te': 'నిమిషాల్లో ఆస్తి ధృవీకరణ',
    'ml': 'മിനിറ്റുകളിൽ ആസ്തി പരിശോധന',
    'mr': 'काही मिनिटांत मालमत्ता पडताळणी',
    'bn': 'মিনিটে সম্পত্তি যাচাই',
    'gu': 'મિનિટોમાં મિલ્કત ચકાસણી',
    'pa': 'ਮਿੰਟਾਂ ਵਿੱਚ ਜਾਇਦਾਦ ਤਸਦੀਕ',
    'ur': 'منٹوں میں جائیداد تصدیق',
  },
  'homeTitle_appbar': {
    'en': 'DigiSampatti', 'hi': 'डिजीसम्पत्ति', 'kn': 'ಡಿಜಿಸಂಪತ್ತಿ',
    'ta': 'டிஜிசம்பத்தி', 'te': 'డిజిసంపత్తి', 'ml': 'ഡിജിസംപത്തി',
    'mr': 'डिजीसंपत्ती', 'bn': 'ডিজিসম্পত্তি', 'gu': 'ડિજીસંપત્તિ',
    'pa': 'ਡਿਜੀਸੰਪਤੀ', 'or': 'ଡିଜିସମ୍ପତ୍ତି', 'ur': 'ڈیجی سمپتی',
  },
  'brokerZone': {
    'en': 'Broker Zone', 'hi': 'ब्रोकर जोन', 'kn': 'ಬ್ರೋಕರ್ ಜೋನ್',
    'ta': 'தரகர் பகுதி', 'te': 'బ్రోకర్ జోన్', 'ml': 'ബ്രോക്കർ സോൺ',
    'mr': 'ब्रोकर झोन', 'bn': 'ব্রোকার জোন', 'gu': 'બ્રોકર ઝોન',
    'pa': 'ਦਲਾਲ ਜ਼ੋਨ', 'ur': 'بروکر زون',
  },
  'askQuestion': {
    'en': 'Ask a Question', 'hi': 'प्रश्न पूछें', 'kn': 'ಪ್ರಶ್ನೆ ಕೇಳಿ',
    'ta': 'கேள்வி கேளுங்கள்', 'te': 'ప్రశ్న అడగండి', 'ml': 'ഒരു ചോദ്യം ചോദിക്കൂ',
    'mr': 'प्रश्न विचारा', 'bn': 'প্রশ্ন জিজ্ঞেস করুন', 'gu': 'સવાલ પૂછો',
    'pa': 'ਸਵਾਲ ਪੁੱਛੋ', 'ur': 'سوال پوچھیں',
  },
  'whatWeFound': {
    'en': 'What We Found', 'hi': 'हमें क्या मिला', 'kn': 'ನಾವು ಕಂಡದ್ದು',
    'ta': 'நாங்கள் கண்டது', 'te': 'మేము కనుగొన్నది', 'ml': 'ഞങ്ങൾ കണ്ടെത്തിയത്',
    'mr': 'आम्हाला काय आढळले', 'bn': 'আমরা কী পেয়েছি', 'gu': 'અમને શું મળ્યું',
    'pa': 'ਸਾਨੂੰ ਕੀ ਮਿਲਿਆ', 'ur': 'ہمیں کیا ملا',
  },
  'yourNextSteps': {
    'en': 'Your Next Steps', 'hi': 'आपके अगले कदम', 'kn': 'ನಿಮ್ಮ ಮುಂದಿನ ಹಂತಗಳು',
    'ta': 'உங்கள் அடுத்த படிகள்', 'te': 'మీ తదుపరి దశలు',
    'ml': 'നിങ്ങളുടെ അടുത്ത ഘട്ടങ്ങൾ', 'mr': 'तुमची पुढील पावले',
    'bn': 'আপনার পরবর্তী পদক্ষেপ', 'gu': 'તમારા આગળના પગલા',
    'pa': 'ਤੁਹਾਡੇ ਅਗਲੇ ਕਦਮ', 'ur': 'آپ کے اگلے اقدامات',
  },
  'pastSearches': {
    'en': 'Past searches', 'hi': 'पिछली खोजें', 'kn': 'ಹಿಂದಿನ ಹುಡುಕಾಟಗಳು',
    'ta': 'கடந்த தேடல்கள்', 'te': 'గత శోధనలు', 'ml': 'കഴിഞ്ഞ തിരയലുകൾ',
    'mr': 'मागील शोध', 'bn': 'আগের অনুসন্ধান', 'gu': 'ભૂતકાળની શોધ',
    'pa': 'ਪਿਛਲੀਆਂ ਖੋਜਾਂ', 'ur': 'پرانی تلاشیں',
  },
  'freeReports': {
    'en': '5 free reports', 'hi': '5 मुफ़्त रिपोर्ट', 'kn': '5 ಉಚಿತ ವರದಿಗಳು',
    'ta': '5 இலவச அறிக்கைகள்', 'te': '5 ఉచిత నివేదికలు',
    'ml': '5 സൗജന്യ റിപ്പോർട്ടുകൾ', 'mr': '5 विनामूल्य अहवाल',
    'bn': '5টি বিনামূল্যে রিপোর্ট', 'gu': '5 મફત અહેવાલ',
    'pa': '5 ਮੁਫ਼ਤ ਰਿਪੋਰਟਾਂ', 'ur': '5 مفت رپورٹیں',
  },
  'memberSince': {
    'en': 'DigiSampatti Member', 'hi': 'DigiSampatti सदस्य', 'kn': 'DigiSampatti ಸದಸ್ಯ',
    'ta': 'DigiSampatti உறுப்பினர்', 'te': 'DigiSampatti సభ్యుడు',
    'ml': 'DigiSampatti അംഗം', 'mr': 'DigiSampatti सदस्य', 'bn': 'DigiSampatti সদস্য',
    'gu': 'DigiSampatti સભ્ય', 'pa': 'DigiSampatti ਮੈਂਬਰ', 'ur': 'DigiSampatti رکن',
  },
  'reportsGenerated': {
    'en': 'Reports\nGenerated', 'hi': 'रिपोर्ट\nबनाई', 'kn': 'ವರದಿಗಳು\nರಚಿಸಲಾಗಿದೆ',
    'ta': 'அறிக்கைகள்\nஉருவாக்கப்பட்டவை', 'te': 'నివేదికలు\nసృష్టించబడ్డాయి',
    'ml': 'റിപ്പോർട്ടുകൾ\nസൃഷ്ടിക്കപ്പെട്ടു', 'mr': 'अहवाल\nतयार केले',
    'bn': 'রিপোর্ট\nতৈরি হয়েছে', 'gu': 'અહેવાલ\nતૈયાર', 'pa': 'ਰਿਪੋਰਟਾਂ\nਬਣਾਈਆਂ',
    'ur': 'رپورٹیں\nبنائی گئیں',
  },
  'lastSafetyScore': {
    'en': 'Last Safety\nScore', 'hi': 'अंतिम सुरक्षा\nअंक',
    'kn': 'ಕೊನೆಯ ಸುರಕ್ಷತಾ\nಅಂಕ', 'ta': 'கடைசி பாதுகாப்பு\nமதிப்பெண்',
    'te': 'చివరి భద్రతా\nస్కోరు', 'ml': 'അവസാന സുരക്ഷ\nസ്കോർ',
    'mr': 'अंतिम सुरक्षा\nस्कोर', 'bn': 'শেষ নিরাপত্তা\nস্কোর',
    'gu': 'છેલ્લો સુરક્ષા\nસ્કોર', 'pa': 'ਆਖਰੀ ਸੁਰੱਖਿਆ\nਸਕੋਰ',
    'ur': 'آخری حفاظتی\nاسکور',
  },
  'plansPricing': {
    'en': 'Plans & Pricing', 'hi': 'योजनाएं और कीमत', 'kn': 'ಯೋಜನೆ & ಬೆಲೆ',
    'ta': 'திட்டங்கள் & விலை', 'te': 'ప్లాన్లు & ధర',
    'ml': 'പ്ലാനുകൾ & വില', 'mr': 'योजना आणि किंमत',
    'bn': 'প্ল্যান ও মূল্য', 'gu': 'પ્લાન્સ & ભાવ',
    'pa': 'ਯੋਜਨਾਵਾਂ & ਕੀਮਤ', 'ur': 'پلان اور قیمت',
  },
  'language': {
    'en': 'Language / ಭಾಷೆ', 'hi': 'भाषा / Language', 'kn': 'ಭಾಷೆ / Language',
    'ta': 'மொழி / Language', 'te': 'భాష / Language', 'ml': 'ഭാഷ / Language',
    'mr': 'भाषा / Language', 'bn': 'ভাষা / Language', 'gu': 'ભાષા / Language',
    'pa': 'ਭਾਸ਼ਾ / Language', 'ur': 'زبان / Language',
  },
  'aboutApp': {
    'en': 'About DigiSampatti', 'hi': 'DigiSampatti के बारे में', 'kn': 'DigiSampatti ಬಗ್ಗೆ',
    'ta': 'DigiSampatti பற்றி', 'te': 'DigiSampatti గురించి', 'ml': 'Arth ID കുറിച്ച്',
    'mr': 'DigiSampatti बद्दल', 'bn': 'DigiSampatti সম্পর্কে', 'gu': 'Arth ID વિषे',
    'pa': 'DigiSampatti ਬਾਰੇ', 'ur': 'DigiSampatti کے بارے میں',
  },
  'whyArthId': {
    'en': 'Why DigiSampatti?', 'hi': 'Arth ID क्यों?', 'kn': 'Arth ID ಏಕೆ?',
    'ta': 'Arth ID ஏன்?', 'te': 'Arth ID ఎందుకు?', 'ml': 'Arth ID എന്തുകൊണ്ട്?',
    'mr': 'Arth ID का?', 'bn': 'Arth ID কেন?', 'gu': 'Arth ID શા માટે?',
    'pa': 'Arth ID ਕਿਉਂ?', 'ur': 'Arth ID کیوں؟',
  },
  'applyAndTrack': {
    'en': 'Apply & Track', 'hi': 'आवेदन करें और ट्रैक करें',
    'kn': 'ಅರ್ಜಿ & ಟ್ರ್ಯಾಕ್', 'ta': 'விண்ணப்பி & கண்காணி',
    'te': 'దరఖాస్తు & ట్రాక్', 'ml': 'അപ്ലൈ & ട്രാക്ക്',
    'mr': 'अर्ज करा आणि ट्रॅक करा', 'bn': 'আবেদন করুন ও ট্র্যাক করুন',
    'gu': 'અરજી & ટ્રેક', 'pa': 'ਅਰਜ਼ੀ ਅਤੇ ਟ੍ਰੈਕ', 'ur': 'درخواست اور ٹریک',
  },
  'appVersion': {
    'en': 'App\nVersion', 'hi': 'ऐप\nवर्शन', 'kn': 'ಆ್ಯಪ್\nಆವೃತ್ತಿ',
    'ta': 'பயன்பாடு\nபதிப்பு', 'te': 'యాప్\nవెర్షన్', 'ml': 'ആപ്പ്\nവേർഷൻ',
    'mr': 'अॅप\nआवृत्ती', 'bn': 'অ্যাপ\nভার্সন', 'gu': 'એપ\nઆ版本',
    'pa': 'ਐਪ\nਵਰਜ਼ਨ', 'ur': 'ایپ\nورژن',
  },

  // ── Home screen role cards ────────────────────────────────────────────────────
  'whatBringsYouHere': {
    'en': 'What brings you here today?',
    'hi': 'आज आप यहाँ क्यों आए हैं?',
    'kn': 'ಇಂದು ನೀವು ಇಲ್ಲಿ ಏಕೆ ಬಂದಿದ್ದೀರಿ?',
    'ta': 'இன்று நீங்கள் இங்கு ஏன் வந்தீர்கள்?',
    'te': 'నేడు మీరు ఇక్కడకు ఎందుకు వచ్చారు?',
    'ml': 'ഇന്ന് നിങ്ങൾ ഇവിടെ എന്തിന് വന്നു?',
    'mr': 'आज तुम्ही इथे का आलात?',
    'bn': 'আজ আপনি এখানে কেন এসেছেন?',
    'gu': 'આજ તમે અહીં શા માટે આવ્યા?',
    'pa': 'ਅੱਜ ਤੁਸੀਂ ਇੱਥੇ ਕਿਉਂ ਆਏ ਹੋ?',
    'ur': 'آج آپ یہاں کیوں آئے ہیں؟',
  },
  'imABuyer': {
    'en': "I'm a Buyer", 'hi': 'मैं खरीदार हूँ', 'kn': 'ನಾನು ಖರೀದಿದಾರ',
    'ta': 'நான் வாங்குபவன்', 'te': 'నేను కొనుగోలుదారుడిని', 'ml': 'ഞാൻ ഒരു വാങ്ങുന്നവൻ',
    'mr': 'मी खरेदीदार आहे', 'bn': 'আমি একজন ক্রেতা', 'gu': 'હું ખરીદનાર છું',
    'pa': 'ਮੈਂ ਖਰੀਦਦਾਰ ਹਾਂ', 'ur': 'میں خریدار ہوں',
  },
  'imASeller': {
    'en': "I'm a Seller", 'hi': 'मैं विक्रेता हूँ', 'kn': 'ನಾನು ಮಾರಾಟಗಾರ',
    'ta': 'நான் விற்பவன்', 'te': 'నేను విక్రేతను', 'ml': 'ഞാൻ ഒരു വിൽക്കുന്നവൻ',
    'mr': 'मी विक्रेता आहे', 'bn': 'আমি একজন বিক্রেতা', 'gu': 'હું વેચાણ કરનાર છું',
    'pa': 'ਮੈਂ ਵੇਚਣ ਵਾਲਾ ਹਾਂ', 'ur': 'میں بیچنے والا ہوں',
  },
  'propertyFinanceTools': {
    'en': 'Property & Finance Tools',
    'hi': 'संपत्ति और वित्त उपकरण',
    'kn': 'ಆಸ್ತಿ ಮತ್ತು ಹಣಕಾಸು ಉಪಕರಣಗಳು',
    'ta': 'சொத்து & நிதி கருவிகள்',
    'te': 'ఆస్తి & ఆర్థిక సాధనాలు',
    'ml': 'സ്വത്ത് & ഫിനാൻസ് ടൂളുകൾ',
    'mr': 'मालमत्ता आणि वित्त साधने',
    'bn': 'সম্পত্তি ও অর্থ সরঞ্জাম',
    'gu': 'મિલકત અને ફાઇનાન્સ સાધનો',
    'pa': 'ਜਾਇਦਾਦ ਅਤੇ ਵਿੱਤ ਸਾਧਨ',
    'ur': 'پراپرٹی اور فنانس ٹولز',
  },
  'quickAccessLabel': {
    'en': 'Quick Access', 'hi': 'त्वरित पहुँच', 'kn': 'ತ್ವರಿತ ಪ್ರವೇಶ',
    'ta': 'விரைவு அணுகல்', 'te': 'త్వరిత యాక్సెస్', 'ml': 'ദ്രുത ആക്സസ്',
    'mr': 'जलद प्रवेश', 'bn': 'দ্রুত অ্যাক্সেস', 'gu': 'ઝડપી ઍક્સેસ',
    'pa': 'ਤੇਜ਼ ਪਹੁੰਚ', 'ur': 'فوری رسائی',
  },
  'sroLocator': {
    'en': 'SRO\nLocator', 'hi': 'SRO\nखोजक', 'kn': 'SRO\nಪತ್ತೆ',
    'ta': 'SRO\nகண்டுபிடிப்பு', 'te': 'SRO\nలొకేటర్', 'ml': 'SRO\nലൊക്കേറ്റർ',
    'mr': 'SRO\nशोधक', 'bn': 'SRO\nলোকেটার', 'gu': 'SRO\nલોકેટર',
    'pa': 'SRO\n�ੋਜਕ', 'ur': 'SRO\nلوکیٹر',
  },
  'stampDutyLabel': {
    'en': 'Stamp\nDuty', 'hi': 'स्टाम्प\nड्यूटी', 'kn': 'ಸ್ಟಾಂಪ್\nಶುಲ್ಕ',
    'ta': 'ஸ்டாம்ப்\nதீர்வை', 'te': 'స్టాంప్\nడ్యూటీ', 'ml': 'സ്റ്റാംപ്\nഡ്യൂട്ടി',
    'mr': 'मुद्रांक\nशुल्क', 'bn': 'স্ট্যাম্প\nশুল্ক', 'gu': 'સ્ટેમ્પ\nડ્યૂટી',
    'pa': 'ਸਟੈਂਪ\nਡਿਊਟੀ', 'ur': 'اسٹامپ\nڈیوٹی',
  },
  'guidanceValue': {
    'en': 'Guidance\nValue', 'hi': 'मार्गदर्शन\nमूल्य', 'kn': 'ಮಾರ್ಗದರ್ಶನ\nಮೌಲ್ಯ',
    'ta': 'வழிகாட்டல்\nமதிப்பு', 'te': 'గైడెన్స్\nవాల్యూ', 'ml': 'ഗൈഡൻസ്\nവാല്യൂ',
    'mr': 'मार्गदर्शन\nमूल्य', 'bn': 'গাইডেন্স\nভ্যালু', 'gu': 'ગાઇડન્સ\nવેલ્યુ',
    'pa': 'ਮਾਰਗਦਰਸ਼ਨ\nਮੁੱਲ', 'ur': 'گائیڈنس\nویلیو',
  },
  'propertyTaxLabel': {
    'en': 'Property\nTax', 'hi': 'संपत्ति\nकर', 'kn': 'ಆಸ್ತಿ\nತೆರಿಗೆ',
    'ta': 'சொத்து\nவரி', 'te': 'ఆస్తి\nపన్ను', 'ml': 'സ്വത്ത്\nനികുതി',
    'mr': 'मालमत्ता\nकर', 'bn': 'সম্পত্তি\nকর', 'gu': 'મિલકત\nવેરો',
    'pa': 'ਜਾਇਦਾਦ\nਟੈਕਸ', 'ur': 'پراپرٹی\nٹیکس',
  },
  'emiCalc': {
    'en': 'EMI\nCalc', 'hi': 'EMI\nकैलकुलेटर', 'kn': 'EMI\nಲೆಕ್ಕ',
    'ta': 'EMI\nகணக்கீடு', 'te': 'EMI\nలెక్క', 'ml': 'EMI\nകാൽക്',
    'mr': 'EMI\nकॅल्क', 'bn': 'EMI\nক্যালক', 'gu': 'EMI\nકૅલ્ક',
    'pa': 'EMI\nਕੈਲਕ', 'ur': 'EMI\nکیلک',
  },
  'buyerGuideLabel': {
    'en': 'Buyer\nGuide', 'hi': 'खरीदार\nगाइड', 'kn': 'ಖರೀದಿದಾರ\nಮಾರ್ಗದರ್ಶಿ',
    'ta': 'வாங்குபவர்\nவழிகாட்டி', 'te': 'కొనుగోలుదారు\nగైడ్', 'ml': 'വാങ്ങുന്നവർ\nഗൈഡ്',
    'mr': 'खरेदीदार\nमार्गदर्शिका', 'bn': 'ক্রেতা\nগাইড', 'gu': 'ખરીદનાર\nગાઇડ',
    'pa': 'ਖਰੀਦਦਾਰ\nਗਾਈਡ', 'ur': 'خریدار\nگائیڈ',
  },
  'glossaryLabel': {
    'en': 'Glossary', 'hi': 'शब्दकोश', 'kn': 'ಪದಕೋಶ',
    'ta': 'சொல்லகராதி', 'te': 'గ్లాసరీ', 'ml': 'ഗ്ലോസ്സറി',
    'mr': 'शब्दकोश', 'bn': 'গ্লোসারি', 'gu': 'ગ્લોસરી',
    'pa': 'ਸ਼ਬਦਕੋਸ਼', 'ur': 'لغت',
  },
  'finSelfLite': {
    'en': 'FinSelf\nLite', 'hi': 'फिनसेल्फ\nलाइट', 'kn': 'ಫಿನ್‌ಸೆಲ್ಫ್\nಲೈಟ್',
    'ta': 'ஃபின்செல்ஃப்\nலைட்', 'te': 'ఫిన్‌సెల్ఫ్\nలైట్', 'ml': 'ഫിൻസെൽഫ്\nലൈറ്റ്',
    'mr': 'फिनसेल्फ\nलाइट', 'bn': 'ফিনসেলফ\nলাইট', 'gu': 'ફિનસેલ્ફ\nલાઇટ',
    'pa': 'ਫਿਨਸੈਲਫ\nਲਾਈਟ', 'ur': 'فن سیلف\nلائٹ',
  },
  'postPurchase': {
    'en': 'Post\nPurchase', 'hi': 'खरीद\nबाद', 'kn': 'ಖರೀದಿ\nನಂತರ',
    'ta': 'வாங்கிய\nபிறகு', 'te': 'కొనుగోలు\nతర్వాత', 'ml': 'വാങ്ങിയ\nശേഷം',
    'mr': 'खरेदी\nनंतर', 'bn': 'কেনার\nপরে', 'gu': 'ખરીદ\nપછી',
    'pa': 'ਖਰੀਦ\nਬਾਅਦ', 'ur': 'خریداری\nبعد',
  },
  'findProperty': {
    'en': 'Find Your Property', 'hi': 'अपनी संपत्ति खोजें', 'kn': 'ನಿಮ್ಮ ಆಸ್ತಿ ಹುಡುಕಿ',
    'ta': 'உங்கள் சொத்தை கண்டுபிடியுங்கள்', 'te': 'మీ ఆస్తి కనుగొనండి',
    'ml': 'നിങ്ങളുടെ സ്വത്ത് കണ്ടെത്തുക', 'mr': 'तुमची मालमत्ता शोधा',
    'bn': 'আপনার সম্পত্তি খুঁজুন', 'gu': 'તમારી મિલકત શોધો',
    'pa': 'ਆਪਣੀ ਜਾਇਦਾਦ ਲੱਭੋ', 'ur': 'اپنی پراپرٹی تلاش کریں',
  },
  'listProperty': {
    'en': 'List Your Property', 'hi': 'अपनी संपत्ति सूचीबद्ध करें', 'kn': 'ನಿಮ್ಮ ಆಸ್ತಿ ಪಟ್ಟಿ ಮಾಡಿ',
    'ta': 'உங்கள் சொத்தை பட்டியலிடுங்கள்', 'te': 'మీ ఆస్తి లిస్ట్ చేయండి',
    'ml': 'നിങ്ങളുടെ സ്വത്ത് ലിസ്റ്റ് ചെയ്യുക', 'mr': 'तुमची मालमत्ता यादीत टाका',
    'bn': 'আপনার সম্পত্তি তালিকাভুক্ত করুন', 'gu': 'તમારી મિલકત સૂચિ કરો',
    'pa': 'ਆਪਣੀ ਜਾਇਦਾਦ ਸੂਚੀਬੱਧ ਕਰੋ', 'ur': 'اپنی پراپرٹی کی فہرست بنائیں',
  },
};

// ─── Strings accessor ─────────────────────────────────────────────────────────
class AppL10n {
  final String lang;
  const AppL10n(this.lang);

  String _t(String key) {
    final map = _strings[key];
    if (map == null) return key;
    return map[lang] ?? map['en'] ?? key;
  }

  String get homeTitle          => _t('homeTitle');
  String get knowBeforeYouBuy   => _t('knowBeforeYouBuy');
  String get startPropertyCheck => _t('startPropertyCheck');
  String get scanProperty       => _t('scanProperty');
  String get manualSearch       => _t('manualSearch');
  String get myReports          => _t('myReports');
  String get brokerZone         => _t('brokerZone');
  String get moreTools          => _t('moreTools');
  String get askQuestion        => _t('askQuestion');
  String get safetyScore        => _t('safetyScore');
  String get whatWeFound        => _t('whatWeFound');
  String get yourNextSteps      => _t('yourNextSteps');
  String get recentReports      => _t('recentReports');
  String get noReports          => _t('noReports');
  String get betaBanner         => lang == 'kn'
      ? 'ಬೀಟಾ: ಮಾದರಿ ಡೇಟಾ ತೋರಿಸಲಾಗಿದೆ. ನೈಜ ಭೂಮಿ ದಾಖಲೆಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ.'
      : lang == 'hi' ? 'बीटा: नमूना डेटा दिखाया जा रहा है। असली भूमि रिकॉर्ड जल्द आएंगे।'
      : 'Beta: Sample data shown. Real land records coming soon.';

  // ── Auth screen ──────────────────────────────────────────────────────────────
  String get enterMobileNumber  => _t('enterMobileNumber');
  String get sendOtp            => _t('sendOtp');
  String get verifyOtp          => _t('verifyOtp');
  String get enterOtpHint       => _t('enterOtpHint');
  String get otpSentTo          => _t('otpSentTo');
  String get changeNumber       => _t('changeNumber');
  String get agreeTerms         => _t('agreeTerms');
  String get platformTagline    => _t('platformTagline');

  // ── More Tools ───────────────────────────────────────────────────────────────
  String get propertyTransfer   => _t('propertyTransfer');
  String get financialTools     => _t('financialTools');
  String get buyerGuides        => _t('buyerGuides');
  String get expertHelp         => _t('expertHelp');
  String get courtCaseCheck     => _t('courtCaseCheck');
  String get applyAndTrack      => _t('applyAndTrack');
  String get buyingJourney      => _t('buyingJourney');
  String get nriMode            => _t('nriMode');

  // ── Action card subtitles ────────────────────────────────────────────────────
  String get photoGps           => _t('photoGps');
  String get surveyNo           => _t('surveyNo');
  String get pastSearches       => _t('pastSearches');
  String get freeReports        => _t('freeReports');

  // ── Profile screen ───────────────────────────────────────────────────────────
  String get myProfile          => _t('myProfile');
  String get memberSince        => _t('memberSince');
  String get reportsGenerated   => _t('reportsGenerated');
  String get lastSafetyScore    => _t('lastSafetyScore');
  String get appVersion         => _t('appVersion');
  String get plansPricing       => _t('plansPricing');
  String get signOut            => _t('signOut');
  String get language           => _t('language');
  String get aboutApp           => _t('aboutApp');

  // ── Misc ─────────────────────────────────────────────────────────────────────
  String get viewAll            => _t('viewAll');
  String get whyArthId          => _t('whyArthId');
  String get whyDigiSampatti    => _t('whyArthId');
  String get knowBeforeYouBuyTag => _t('knowBeforeYouBuyTag');
  String get verifyInMinutes    => _t('verifyInMinutes');

  // ── Home screen role cards & tools ───────────────────────────────────────────
  String get whatBringsYouHere  => _t('whatBringsYouHere');
  String get imABuyer           => _t('imABuyer');
  String get imASeller          => _t('imASeller');
  String get propertyFinanceTools => _t('propertyFinanceTools');
  String get quickAccessLabel   => _t('quickAccessLabel');
  String get sroLocator         => _t('sroLocator');
  String get stampDutyLabel     => _t('stampDutyLabel');
  String get guidanceValue      => _t('guidanceValue');
  String get propertyTaxLabel   => _t('propertyTaxLabel');
  String get emiCalc            => _t('emiCalc');
  String get buyerGuideLabel    => _t('buyerGuideLabel');
  String get glossaryLabel      => _t('glossaryLabel');
  String get finSelfLite        => _t('finSelfLite');
  String get postPurchase       => _t('postPurchase');
  String get findProperty       => _t('findProperty');
  String get listProperty       => _t('listProperty');
}
