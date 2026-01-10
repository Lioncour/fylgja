import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import '../viewmodels/main_viewmodel.dart';
import '../theme/app_theme.dart';
import '../models/search_state.dart';
import '../utils/haptic_feedback.dart';
import '../services/native_notification_service.dart';
import 'about_page.dart';
import 'settings_page.dart';
import 'onboarding_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _modalPulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _modalPulseAnimation;
  bool _hasShownOnboarding = false;
  bool _isModalShowing = false;

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    _modalPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _modalPulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _modalPulseController,
      curve: Curves.easeInOut,
    ));

    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    // Check if user has seen onboarding
    // For now, we'll show it once per session
    if (!_hasShownOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Show onboarding on first launch (you can add SharedPreferences check here)
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _modalPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Consumer<MainViewModel>(
        builder: (context, viewModel, child) {
          // Control rotation animation based on searching state
          if (viewModel.state == SearchState.searching && !_rotationController.isAnimating) {
            _rotationController.repeat();
          } else if (viewModel.state != SearchState.searching && _rotationController.isAnimating) {
            _rotationController.stop();
          }

          // Show coverage found modal (only once, and not if paused)
          print('MainPage: ===== BUILD CHECK =====');
          print('MainPage: Current state: ${viewModel.state}');
          print('MainPage: isModalShowing: $_isModalShowing');
          
          if (viewModel.state == SearchState.coverageFound && !_isModalShowing) {
            print('MainPage: Conditions met to show modal - coverageFound and not showing');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('MainPage: PostFrameCallback - state: ${viewModel.state}, isModalShowing: $_isModalShowing, mounted: $mounted');
              if (mounted && viewModel.state == SearchState.coverageFound && !_isModalShowing && viewModel.state != SearchState.paused) {
                print('MainPage: ✅ Showing coverage modal');
                _showCoverageFoundDialog(context, viewModel);
              } else {
                print('MainPage: ❌ Not showing modal - state: ${viewModel.state}, isModalShowing: $_isModalShowing, mounted: $mounted');
              }
            });
          } else if (viewModel.state == SearchState.paused) {
            // When paused, ALWAYS keep modal flag true to prevent reopening
            if (!_isModalShowing) {
              print('MainPage: ⚠️ State is paused but modal flag is false - setting to true');
            }
            _isModalShowing = true;
            print('MainPage: State is paused, keeping modal flag true to prevent reopening');
          } else if (viewModel.state == SearchState.idle) {
            // Always reset when idle
            _isModalShowing = false;
            print('MainPage: State is idle, modal flag reset');
          } else if (viewModel.state != SearchState.coverageFound) {
            // Reset modal flag when state changes away from coverageFound (but not when pausing or going to idle)
            print('MainPage: Resetting modal flag - state changed to: ${viewModel.state}');
            _isModalShowing = false;
          }

          // Show error snackbar if there's an error (but not for coverage found)
          if (viewModel.errorMessage != null && viewModel.state != SearchState.coverageFound) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage!),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () => viewModel.clearError(),
                  ),
                ),
              );
            });
          }

          return Column(
            children: [
              // Top section - 62.5% of screen (reduced to make bottom panel bigger)
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Main status indicator
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.25,
                        ),
                        child: Semantics(
                          label: _getStatusSemanticLabel(viewModel.state),
                          child: _buildStatusIndicator(viewModel),
                        ),
                      ),
                    ),

                    // Top left version number
                    Positioned(
                      top: 60,
                      left: 40,
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                'v${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    // Top right buttons
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Row(
                        children: [
                          // Settings button
                          Semantics(
                            label: 'Innstillinger',
                            button: true,
                            child: GestureDetector(
                              onTap: () async {
                                await HapticFeedbackUtil.selectionClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0BC35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  color: Color(0xFF0F0F0F),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          // About button
                          Semantics(
                            label: 'Om Fylgja',
                            button: true,
                            child: GestureDetector(
                              onTap: () async {
                                await HapticFeedbackUtil.selectionClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AboutPage()),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0BC35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFF0F0F0F),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom panel - 37.5% of screen (25% bigger than before)
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

  Widget _buildStatusIndicator(MainViewModel viewModel) {
    Widget indicator;

    switch (viewModel.state) {
      case SearchState.searching:
        indicator = RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            width: 211,
            height: 211,
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
                width: 211,
                height: 211,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
        break;

      case SearchState.coverageFound:
        indicator = ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 211,
            height: 211,
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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indicatorAndIcon.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/searchlogo.png',
                width: 211,
                height: 211,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
        break;

      case SearchState.paused:
        indicator = Transform.rotate(
          angle: -1.5708, // 90 degrees to the left in radians (-90 degrees = -π/2)
          child: Container(
            width: 211,
            height: 211,
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
                width: 211,
                height: 211,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
        break;

      default:
        indicator = Container(
          width: 211,
          height: 211,
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
              width: 176,
              height: 176,
              fit: BoxFit.cover,
            ),
          ),
        );
    }

    return indicator;
  }

  Widget _buildBottomPanel(MainViewModel viewModel) {
    switch (viewModel.state) {
      case SearchState.coverageFound:
        return _buildCoverageFoundPanel(viewModel);
      case SearchState.paused:
        return _buildPausedPanel(viewModel);
      default:
        return _buildInitialPanel(viewModel);
    }
  }

  Widget _buildInitialPanel(MainViewModel viewModel) {
    final searchDuration = viewModel.searchStartTime != null
        ? DateTime.now().difference(viewModel.searchStartTime!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 38),
      decoration: const BoxDecoration(
        color: AppTheme.bottomPanel,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const Text(
                'Fylgja',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF6EEA1),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Din Mág i fjell og dal',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFF6EEA1),
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (searchDuration != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Søkt i ${_formatDuration(searchDuration)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.whiteText,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Center(
              child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: Semantics(
                label: viewModel.state == SearchState.searching ? 'Stop søk' : 'Start søk',
                button: true,
                enabled: !viewModel.isProcessing,
                child: ElevatedButton(
                  onPressed: viewModel.isProcessing
                      ? null
                      : () async {
                          await HapticFeedbackUtil.mediumImpact();
                          await viewModel.startSearch();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: viewModel.state == SearchState.searching
                        ? const Color(0xFFE53E3E)
                        : const Color(0xFFDBC3C5),
                    foregroundColor: viewModel.state == SearchState.searching
                        ? AppTheme.whiteText
                        : AppTheme.darkText,
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: viewModel.isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          viewModel.state == SearchState.searching
                              ? 'Stop søk'
                              : 'Start søk',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
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
      onTap: () async {
        await HapticFeedbackUtil.mediumImpact();
        await viewModel.pauseSearch();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFDBC3C5),
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
                color: Color(0xFFF6EEA1),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Din Mág i fjell og dal',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFF6EEA1),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isProcessing
                    ? null
                    : () async {
                        await HapticFeedbackUtil.mediumImpact();
                        await viewModel.stopSearch();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53E3E),
                  foregroundColor: AppTheme.whiteText,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: viewModel.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Stop søk',
                        style: TextStyle(
                          fontSize: 20,
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
    final remaining = viewModel.pauseRemaining ?? Duration(minutes: viewModel.pauseDuration);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

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
              color: Color(0xFFF6EEA1),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Din Mág i fjell og dal',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFF6EEA1),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Søkingen er pauset',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Gjenopptas om: ',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.whiteText,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.indicatorAndIcon,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Circular progress indicator for pause countdown
          SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: 1.0 - (remaining.inSeconds / (viewModel.pauseDuration * 60)),
              backgroundColor: AppTheme.notificationPanel,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.indicatorAndIcon),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: ElevatedButton(
                onPressed: viewModel.isProcessing
                    ? null
                    : () async {
                        await HapticFeedbackUtil.mediumImpact();
                        await viewModel.stopSearch();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD67369),
                  foregroundColor: AppTheme.whiteText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: viewModel.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Avbryt pause',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCoverageFoundDialog(BuildContext context, MainViewModel viewModel) {
    if (_isModalShowing) {
      print('MainPage: Modal already showing, skipping');
      return;
    }
    
    print('MainPage: ===== SHOWING COVERAGE MODAL =====');
    print('MainPage: Current state: ${viewModel.state}');
    print('MainPage: isModalShowing before: $_isModalShowing');
    _isModalShowing = true;
    print('MainPage: isModalShowing after: $_isModalShowing');
    
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.36,
          decoration: const BoxDecoration(
            color: Color(0xFFDBC3C5),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 38),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                      const SizedBox(height: 40),

                      // Text only
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nå har du jammen meg dekning',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),

                  // Help text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Søkingen vil pause og automatisk starte på nytt etter valgt tid',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            print('MainPage: ===== PAUSE BUTTON PRESSED IN MODAL =====');
                            print('MainPage: Current state: ${viewModel.state}');
                            
                            await HapticFeedbackUtil.mediumImpact();
                            
                            // CRITICAL: Set flag and pause search FIRST (changes state to paused)
                            // This ensures state is paused before modal closes, preventing rebuild from showing modal again
                            _isModalShowing = true;
                            print('MainPage: Set isModalShowing to TRUE');
                            
                            // Pause search immediately - this changes state to paused
                            print('MainPage: Calling pauseSearch to change state to paused...');
                            await viewModel.pauseSearch();
                            print('MainPage: State after pauseSearch: ${viewModel.state}');
                            
                            // Now close the modal - state is already paused, so rebuild won't show modal
                            if (context.mounted) {
                              print('MainPage: Closing modal (state is already paused)');
                              Navigator.of(context).pop();
                              print('MainPage: Modal closed');
                            }
                            
                            print('MainPage: ===== PAUSE BUTTON HANDLING COMPLETE =====');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B3C52),
                            foregroundColor: AppTheme.whiteText,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('Nytt søk om ${viewModel.pauseDuration} min'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            print('MainPage: ===== OK BUTTON PRESSED IN MODAL =====');
                            print('MainPage: Current state: ${viewModel.state}');
                            print('MainPage: isModalShowing before: $_isModalShowing');
                            
                            await HapticFeedbackUtil.mediumImpact();
                            
                            // CRITICAL: Stop sound and vibration IMMEDIATELY when OK is pressed
                            print('MainPage: ===== STOPPING SOUND AND VIBRATION IMMEDIATELY =====');
                            print('MainPage: Timestamp: ${DateTime.now().toIso8601String()}');
                            try {
                              print('MainPage: Calling NativeNotificationService.stopSound() - FIRST TIME');
                              await NativeNotificationService.stopSound();
                              print('MainPage: First stopSound() completed');
                              
                              await Future.delayed(const Duration(milliseconds: 50));
                              
                              print('MainPage: Calling NativeNotificationService.stopSound() - SECOND TIME');
                              await NativeNotificationService.stopSound();
                              print('MainPage: Second stopSound() completed');
                              
                              print('MainPage: Calling NativeNotificationService.cancelNotification()');
                              await NativeNotificationService.cancelNotification();
                              print('MainPage: cancelNotification() completed');
                              
                              print('MainPage: ===== SOUND AND VIBRATION STOP COMPLETE =====');
                            } catch (e, stackTrace) {
                              print('MainPage: ERROR stopping sound/vibration: $e');
                              print('MainPage: Stack trace: $stackTrace');
                            }
                            
                            // Set flag to prevent reopening BEFORE closing
                            _isModalShowing = true;
                            print('MainPage: Set isModalShowing to true to prevent reopening');
                            
                            // Close modal first and return a value to indicate button press
                            if (context.mounted) {
                              print('MainPage: Closing modal...');
                              Navigator.of(context).pop('ok_pressed');
                              print('MainPage: Modal closed');
                            }
                            
                            // Wait a moment for modal to fully close
                            await Future.delayed(const Duration(milliseconds: 200));
                            
                            // Stop search - this will change state to idle
                            print('MainPage: Calling stopSearch...');
                            await viewModel.stopSearch();
                            print('MainPage: stopSearch completed, state should be idle now');
                            
                            // Wait for state to fully change
                            await Future.delayed(const Duration(milliseconds: 300));
                            
                            // Reset flag after state has changed
                            _isModalShowing = false;
                            print('MainPage: Reset isModalShowing to false');
                            print('MainPage: ===== OK BUTTON HANDLING COMPLETE =====');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.indicatorAndIcon,
                            foregroundColor: AppTheme.darkText,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((value) async {
      // Modal was dismissed (either by swipe or button press)
      print('MainPage: ===== MODAL DISMISSED =====');
      print('MainPage: Return value: $value');
      print('MainPage: Current state: ${viewModel.state}');
      
      // If modal was dismissed by swipe (value is null) and state is still coverageFound, stop search
      // OK button returns 'ok_pressed', so null means swipe
      if (value == null && viewModel.state == SearchState.coverageFound) {
        print('MainPage: Modal dismissed by swipe - stopping search (same as OK button)');
        _isModalShowing = true;
        
        // Wait a moment for modal to fully close
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Stop search - this will change state to idle (same as OK button)
        print('MainPage: Calling stopSearch...');
        await viewModel.stopSearch();
        print('MainPage: stopSearch completed');
        
        // Wait for state to fully change
        await Future.delayed(const Duration(milliseconds: 300));
        
        _isModalShowing = false;
        print('MainPage: Reset isModalShowing to false');
      } else if (value == 'ok_pressed') {
        // OK button was pressed - flag already reset in button handler
        print('MainPage: OK button was pressed - flag already handled');
      } else {
        // Other dismissal (shouldn't happen)
        _isModalShowing = false;
        print('MainPage: Reset isModalShowing to false');
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}t ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _getStatusSemanticLabel(SearchState state) {
    switch (state) {
      case SearchState.searching:
        return 'Søker etter dekning';
      case SearchState.coverageFound:
        return 'Dekning funnet';
      case SearchState.paused:
        return 'Søking pauset';
      default:
        return 'Klar til å søke';
    }
  }
}
