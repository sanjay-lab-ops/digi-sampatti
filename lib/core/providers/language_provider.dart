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

// Strings
class AppL10n {
  final String lang;
  const AppL10n(this.lang);

  bool get isKannada => lang == 'kn';

  String get homeTitle => isKannada ? 'ಡಿಜಿ ಸಂಪತ್ತಿ' : 'DigiSampatti';
  String get knowBeforeYouBuy => isKannada ? 'ಖರೀದಿಸುವ ಮೊದಲು ತಿಳಿಯಿರಿ' : 'Know Before You Buy';
  String get startPropertyCheck => isKannada ? 'ಆಸ್ತಿ ಪರಿಶೀಲನೆ ಪ್ರಾರಂಭಿಸಿ' : 'Start Property Check';
  String get scanProperty => isKannada ? 'ಆಸ್ತಿ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ' : 'Scan Property';
  String get manualSearch => isKannada ? 'ಕೈಯಾರೆ ಹುಡುಕಿ' : 'Manual Search';
  String get myReports => isKannada ? 'ನನ್ನ ವರದಿಗಳು' : 'My Reports';
  String get brokerZone => isKannada ? 'ಬ್ರೋಕರ್ ಜೋನ್' : 'Broker Zone';
  String get moreTools => isKannada ? 'ಇನ್ನಷ್ಟು ಸಾಧನಗಳು' : 'More Tools';
  String get askQuestion => isKannada ? 'ಪ್ರಶ್ನೆ ಕೇಳಿ' : 'Ask a Question';
  String get safetyScore => isKannada ? 'ಸುರಕ್ಷತಾ ಅಂಕ' : 'Safety Score';
  String get whatWeFound => isKannada ? 'ನಾವು ಕಂಡದ್ದು' : 'What We Found';
  String get yourNextSteps => isKannada ? 'ನಿಮ್ಮ ಮುಂದಿನ ಹಂತಗಳು' : 'Your Next Steps';
  String get recentReports => isKannada ? 'ಇತ್ತೀಚಿನ ವರದಿಗಳು' : 'Recent Reports';
  String get noReports => isKannada ? 'ಯಾವುದೇ ವರದಿ ಇಲ್ಲ' : 'No reports yet';
  String get betaBanner => isKannada
      ? 'ಬೀಟಾ: ಮಾದರಿ ಡೇಟಾ ತೋರಿಸಲಾಗಿದೆ. ನೈಜ ಭೂಮಿ ದಾಖಲೆಗಳು ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿವೆ.'
      : 'Beta: Sample data shown. Real Bhoomi records coming soon.';
}
