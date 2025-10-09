import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/main_viewmodel.dart';
import '../theme/app_theme.dart';
import 'about_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Consumer<MainViewModel>(
        builder: (context, viewModel, child) {
          // Control rotation animation based on searching state
          if (viewModel.isSearching && !_rotationController.isAnimating) {
            _rotationController.repeat();
          } else if (!viewModel.isSearching && _rotationController.isAnimating) {
            _rotationController.stop();
          }
          
          // Show coverage found modal
        if (viewModel.hasCoverage) {
          print('Coverage found, showing modal');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCoverageFoundDialog(context, viewModel);
          });
        }

          return Column(
            children: [
              // Top section - 70% of screen
              Expanded(
                flex: 7,
                child: Stack(
                  children: [
                    // Main status indicator - positioned at bottom of top section
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.25), // Push down toward purple section
                        child: RotationTransition(
                          turns: _rotationAnimation,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.indicatorAndIcon,
                                  Color(0xFF8B4513), // Brown color
                                ],
                                stops: [0.75, 1.0],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/searchlogo.png',
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Top right info button - positioned 80pt from top, 40pt from right
                    // About button
                    Positioned(
                      top: 80,
                      right: 40,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutPage()),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.indicatorAndIcon,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/about icon.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom panel - 30% of screen
              Expanded(
                flex: 3,
                child: _buildBottomPanel(viewModel),
              ),
            ],
          );
        },
        ),
    );
  }

  Widget _buildBottomPanel(MainViewModel viewModel) {
    print('_buildBottomPanel - hasCoverage: ${viewModel.hasCoverage}, isPaused: ${viewModel.isPaused}, isSearching: ${viewModel.isSearching}');
    
    if (viewModel.hasCoverage) {
      print('Building coverage found panel');
      return _buildCoverageFoundPanel(viewModel);
    } else if (viewModel.isPaused) {
      print('Building paused panel - isPaused is TRUE');
      return _buildPausedPanel(viewModel);
    } else {
      print('Building initial panel - isPaused is FALSE');
      return _buildInitialPanel(viewModel);
    }
  }

  Widget _buildInitialPanel(MainViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: AppTheme.bottomPanel,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fylgja',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.whiteText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Din Mág i fjell og dal',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.whiteText,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Superkort tekst som forklarer hva appen gjør',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.whiteText,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
              if (viewModel.isSearching) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.indicatorAndIcon),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: ElevatedButton(
              onPressed: viewModel.isSearching ? viewModel.stopSearch : viewModel.startSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: viewModel.isSearching
                  ? const Color(0xFFE53E3E) // Red color for stop button
                  : AppTheme.indicatorAndIcon, // Golden yellow like about icon
                foregroundColor: viewModel.isSearching
                  ? AppTheme.whiteText 
                  : AppTheme.darkText,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                viewModel.isSearching
                  ? (viewModel.hasCoverage ? 'Dekning funnet!' : 'Stop søk') 
                  : 'Start søk',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageFoundPanel(MainViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.pauseSearch,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: const BoxDecoration(
          color: AppTheme.notificationPanel,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fylgja',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.indicatorAndIcon,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Din Mág i fjell og dal',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.darkText,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Du har jammen meg dekning',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.buttonAndAbout,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trykk her for å pause søkingen i ${viewModel.pauseDuration} minutter',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.buttonAndAbout,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.stopSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E), // Red color for stop button
                  foregroundColor: AppTheme.whiteText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text(
                  'Stop søk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedPanel(MainViewModel viewModel) {
    print('Building paused panel content');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        color: AppTheme.notificationPanel,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fylgja',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.indicatorAndIcon,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Din Mág i fjell og dal',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.darkText,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Søkingen er pauset',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.buttonAndAbout,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Søkingen vil fortsette om ${viewModel.pauseDuration} minutter',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.buttonAndAbout,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: viewModel.stopSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: AppTheme.whiteText,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: const Text(
                'Avbryt pause',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCoverageFoundDialog(BuildContext context, MainViewModel viewModel) {
    print('Showing coverage found modal');
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.notificationPanel,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.darkText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header with icon and title
                  Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: AppTheme.indicatorAndIcon,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Dekning funnet!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'Du har nå nettverksdekning!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            print('Modal pause button pressed');
                            viewModel.pauseSearch();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.buttonAndAbout,
                            foregroundColor: AppTheme.darkText,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('Pause ${viewModel.pauseDuration} min'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            viewModel.stopSearch();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: AppTheme.whiteText,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Stop'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
