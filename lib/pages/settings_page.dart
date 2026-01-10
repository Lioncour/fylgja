import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../viewmodels/main_viewmodel.dart';
import '../theme/app_theme.dart';
import '../services/coverage_history_service.dart';
import '../utils/haptic_feedback.dart';
import 'statistics_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDBC3C5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
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
          'Innstillinger',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Pause duration setting
              Consumer<MainViewModel>(
                builder: (context, viewModel, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lengde på varselpause',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hvor lenge skal søkingen pause etter at dekning er funnet?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                          Slider(
                            value: viewModel.pauseDuration.toDouble(),
                            min: 1,
                            max: 120,
                            divisions: 23,
                            activeColor: AppTheme.indicatorAndIcon,
                            inactiveColor: AppTheme.bottomPanel,
                            onChanged: (value) async {
                              await HapticFeedbackUtil.selectionClick();
                              // Round to nearest 5
                              final roundedValue = ((value.round() / 5).round() * 5).clamp(1, 120);
                              await viewModel.setPauseDuration(roundedValue);
                            },
                          ),
                          Center(
                            child: Text(
                              '${viewModel.pauseDuration} minutter',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Statistics section
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
                    Icons.bar_chart,
                    color: AppTheme.darkText,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Statistikk',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                subtitle: const Text(
                  'Se historikk over funnet dekning',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.secondaryText,
                ),
                onTap: () async {
                  await HapticFeedbackUtil.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Clear history option
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Slett historikk',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                subtitle: const Text(
                  'Fjern all lagret statistikk',
                  style: TextStyle(
                    color: AppTheme.secondaryText,
                  ),
                ),
                onTap: () async {
                  await HapticFeedbackUtil.mediumImpact();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Slett historikk?'),
                      content: const Text(
                        'Er du sikker på at du vil slette all historikk? Denne handlingen kan ikke angres.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Avbryt'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Slett'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await CoverageHistoryService.clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Historie slettet'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),

                    const Spacer(),

                    // Build number and footer
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        return Column(
                          children: [
                            const SizedBox(height: 32),
                            if (snapshot.hasData)
                              Text(
                                'Build ${snapshot.data!.buildNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              'a flokroll projects',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
