import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'viewmodels/main_viewmodel.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
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
        home: const MainPage(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
