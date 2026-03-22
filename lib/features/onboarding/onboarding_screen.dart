import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _Slide(
      icon: Icons.verified_user,
      title: 'Know Before You Buy',
      subtitle: 'Buying property in Karnataka?\nCheck land records in minutes — before paying any advance.',
      highlight: 'Used by 1,000+ buyers, brokers & investors',
      color: Color(0xFF1B5E20),
    ),
    _Slide(
      icon: Icons.search,
      title: 'Search Any Property',
      subtitle: 'Enter survey number or\ntake a photo + GPS to identify the land automatically.',
      highlight: 'Works for plots, apartments, villas & layouts',
      color: Color(0xFF0D47A1),
    ),
    _Slide(
      icon: Icons.checklist,
      title: 'We Check 8 Things',
      subtitle: 'Bhoomi RTC · EC · RERA · BDA/BBMP\nRaja Kaluve · Lake bed · Court cases · AI Score',
      highlight: 'Everything a lawyer checks — in 30 seconds',
      color: Color(0xFF4A148C),
    ),
    _Slide(
      icon: Icons.psychology,
      title: 'Safety Score + Next Steps',
      subtitle: 'Get a clear Safety Score (0–100)\nand a simple "What to do next" — no legal jargon.',
      highlight: 'Powered by Claude AI — India\'s most accurate',
      color: Color(0xFF37474F),
    ),
    _Slide(
      icon: Icons.picture_as_pdf,
      title: 'Share the Report',
      subtitle: 'Download PDF for ₹99.\nShare with your family, bank, or lawyer on WhatsApp.',
      highlight: 'Save ₹10,000–₹20,000 in initial legal fees',
      color: Color(0xFF1B5E20),
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip', style: TextStyle(color: AppColors.textLight)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? AppColors.primary : AppColors.borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    child: Text(_currentPage < _slides.length - 1 ? 'Next' : 'Get Started — Free'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String highlight;
  final Color color;
  const _Slide({required this.icon, required this.title, required this.subtitle, required this.highlight, required this.color});
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 60, color: slide.color),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMedium,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: slide.color.withOpacity(0.2)),
            ),
            child: Text(
              slide.highlight,
              style: TextStyle(
                fontSize: 12,
                color: slide.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
