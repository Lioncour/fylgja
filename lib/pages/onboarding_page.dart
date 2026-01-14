import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_feedback.dart';
import 'main_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String _onboardingKey = 'has_seen_onboarding';
  
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, false);
  }

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: 'Velkommen til Fylgja',
          body: 'Din digitale følgesvenn i fjell og dal. Fylgja overvåker nettverksdekning og varsler deg når du får tilgang til internett.',
          image: _buildRotatingImage(),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: 'Hvordan det fungerer',
          body: 'Start et søk, og Fylgja vil overvåke nettverksdekning i bakgrunnen. Når dekning blir tilgjengelig, får du et varsel med lyd og vibrasjon.',
          image: _buildRotatingImage(),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: 'Batterioptimalisering',
          body: 'For best funksjonalitet, sørg for at Fylgja ikke er begrenset av batterioptimalisering. Dette sikrer at appen kan overvåke dekning selv når telefonen er i dyp søvn.',
          image: _buildRotatingImage(),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: 'Klar til å starte',
          body: 'Trykk på "Start søk" for å begynne overvåking. Du kan pause søkingen etter at dekning er funnet, eller stoppe den når som helst.',
          image: _buildRotatingImage(),
          decoration: _getPageDecoration(),
        ),
      ],
      onDone: () async {
        await HapticFeedbackUtil.mediumImpact();
        await OnboardingPage.markOnboardingComplete();
        if (context.mounted) {
          // Replace onboarding with MainPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      },
      onSkip: () async {
        await HapticFeedbackUtil.selectionClick();
        await OnboardingPage.markOnboardingComplete();
        if (context.mounted) {
          // Replace onboarding with MainPage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      },
      onChange: (index) {
        setState(() {
          _currentPage = index;
        });
        // Reset rotation animation on page change
        _rotationController.reset();
        _rotationController.forward();
      },
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: true,
      back: const Icon(Icons.arrow_back, color: AppTheme.indicatorAndIcon),
      skip: const Text(
        'Hopp over',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.secondaryText,
        ),
      ),
      next: const Icon(Icons.arrow_forward, color: AppTheme.indicatorAndIcon),
      done: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.indicatorAndIcon,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.indicatorAndIcon.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Text(
          'Ferdig',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: AppTheme.secondaryText,
        activeColor: AppTheme.indicatorAndIcon,
        activeSize: const Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
      globalBackgroundColor: AppTheme.primaryBackground,
      animationDuration: 600,
    );
  }

  Widget _buildRotatingImage() {
    return Center(
      child: RotationTransition(
        turns: _rotationAnimation,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppTheme.indicatorAndIcon,
                Color(0xFF8B4513),
              ],
              stops: [0.75, 1.0],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/searchlogo.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return PageDecoration(
      titleTextStyle: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryText,
      ),
      bodyTextStyle: const TextStyle(
        fontSize: 16,
        color: AppTheme.secondaryText,
        height: 1.5,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: AppTheme.primaryBackground,
      imagePadding: const EdgeInsets.only(top: 120),
    );
  }
}
