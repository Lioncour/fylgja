import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_feedback.dart';
import 'onboarding_page.dart';

class DeveloperSettingsPage extends StatelessWidget {
  const DeveloperSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDBC3C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.indicatorAndIcon,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          onPressed: () async {
            await HapticFeedbackUtil.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Developer Settings',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Developer Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 24),
              
              // Reset onboarding toggle
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.indicatorAndIcon,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppTheme.darkText,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Show Onboarding Again',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                subtitle: const Text(
                  'Reset onboarding to show introduction screens on next app launch',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                  ),
                ),
                trailing: FutureBuilder<bool>(
                  future: _getOnboardingResetState(),
                  builder: (context, snapshot) {
                    return Switch(
                      value: snapshot.data ?? false,
                      activeColor: AppTheme.indicatorAndIcon,
                      onChanged: (value) async {
                        await HapticFeedbackUtil.selectionClick();
                        await _setOnboardingResetState(value);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Onboarding will show on next app launch'
                                    : 'Onboarding reset disabled',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> _getOnboardingResetState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('developer_reset_onboarding') ?? false;
  }

  static Future<void> _setOnboardingResetState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // Reset onboarding flag
      await OnboardingPage.resetOnboarding();
      await prefs.setBool('developer_reset_onboarding', true);
    } else {
      await prefs.setBool('developer_reset_onboarding', false);
    }
  }
}
