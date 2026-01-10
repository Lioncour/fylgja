import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'viewmodels/main_viewmodel.dart';
import 'theme/app_theme.dart';
import 'pages/main_page.dart';
import 'pages/onboarding_page.dart';
import 'services/background_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service for standby mode
  AppLogger.info('Initializing background service for standby mode');
  await BackgroundService.initializeService();
  
  runApp(const FylgjaApp());
}

class FylgjaApp extends StatelessWidget {
  const FylgjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MainViewModel(),
      child: MaterialApp(
        title: 'Fylgja',
        theme: AppTheme.theme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.theme.textTheme),
        ),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingPage.shouldShowOnboarding();
    setState(() {
      _showOnboarding = shouldShow;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.indicatorAndIcon,
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return const OnboardingPage();
    }

    return const MainPage();
  }
}
