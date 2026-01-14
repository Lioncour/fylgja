import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
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
  
  // Request location permission at startup
  await _requestLocationPermission();
  
  runApp(const FylgjaApp());
}

Future<void> _requestLocationPermission() async {
  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.info('Location services are disabled');
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.info('Location permission denied by user');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.info('Location permission denied forever');
      return;
    }

    AppLogger.info('Location permission granted');
  } catch (e) {
    AppLogger.error('Error requesting location permission', e);
  }
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
    final prefs = await SharedPreferences.getInstance();
    final resetEnabled = prefs.getBool('developer_reset_onboarding') ?? false;
    
    bool shouldShow;
    if (resetEnabled) {
      // If developer reset is enabled, always check onboarding flag
      shouldShow = await OnboardingPage.shouldShowOnboarding();
    } else {
      // Normal behavior
      shouldShow = await OnboardingPage.shouldShowOnboarding();
    }
    
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
