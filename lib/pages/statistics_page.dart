import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/coverage_history_service.dart';
import '../models/coverage_event.dart';
import '../utils/haptic_feedback.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, dynamic>? _statistics;
  List<CoverageEvent>? _history;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _loadStatistics();
  }

  Future<void> _requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled, show a message
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied, user can enable it later
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission denied forever, show a message
      return;
    }
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude) async {
    // Try multiple URL formats without checking canLaunchUrl first
    // canLaunchUrl can return false even when Google Maps is installed
    
    final urls = [
      // Try Google Maps app intent (Android) - most reliable
      Uri.parse('google.navigation:q=$latitude,$longitude'),
      // Try geo: URI with query
      Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude'),
      // Try simple geo: URI
      Uri.parse('geo:$latitude,$longitude'),
      // Try Google Maps web URL (will open in browser or Maps app)
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'),
      // Try Google Maps URL without API parameter
      Uri.parse('https://www.google.com/maps?q=$latitude,$longitude'),
    ];

    for (final url in urls) {
      try {
        // Try to launch directly without checking canLaunchUrl
        // This works better on Android where canLaunchUrl can be unreliable
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        // If we get here without exception, it worked
        return;
      } catch (e) {
        // Continue to next URL format
        continue;
      }
    }

    // If all URLs failed, try with platform default mode
    try {
      final webUrl = Uri.parse('https://www.google.com/maps?q=$latitude,$longitude');
      await launchUrl(webUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      // Show error message only if all attempts failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kunne ikke åpne Google Maps. Prøv å installere Google Maps fra Play Store.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await CoverageHistoryService.getStatistics();
      final history = await CoverageHistoryService.getHistory();

      setState(() {
        _statistics = stats;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Set status bar to dark for visibility on light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.buttonAndAbout,
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
          'Statistikk',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryText),
            onPressed: () async {
              await HapticFeedbackUtil.selectionClick();
              await _loadStatistics();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.indicatorAndIcon,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadStatistics,
                color: AppTheme.indicatorAndIcon,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics cards
                      if (_statistics != null) ...[
                        _buildStatCard(
                          'Totalt funnet dekning',
                          '${_statistics!['totalEvents']}',
                          Icons.wifi,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Gjennomsnittlig søketid',
                          _formatDuration(_statistics!['averageSearchDuration'] as Duration),
                          Icons.timer,
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Total søketid',
                          _formatDuration(_statistics!['totalSearchTime'] as Duration),
                          Icons.access_time,
                        ),
                        const SizedBox(height: 32),
                      ],

                      // History section
                      const Text(
                        'Historikk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_history == null || _history!.isEmpty)
                        Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: AppTheme.secondaryText.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Ingen historikk ennå',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start et søk for å begynne å samle statistikk',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.secondaryText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._history!.map((event) => _buildHistoryItem(event)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.indicatorAndIcon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.indicatorAndIcon,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(CoverageEvent event) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final duration = _formatDuration(event.searchDuration);
    final hasLocation = event.latitude != null && event.longitude != null;

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.indicatorAndIcon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            hasLocation ? Icons.location_on : Icons.wifi,
            color: AppTheme.indicatorAndIcon,
            size: 20,
          ),
        ),
        title: Text(
          dateFormat.format(event.timestamp),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Søktid: $duration',
              style: const TextStyle(
                color: AppTheme.secondaryText,
              ),
            ),
            if (hasLocation) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  await HapticFeedbackUtil.selectionClick();
                  await _openInGoogleMaps(event.latitude!, event.longitude!);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map,
                      size: 16,
                      color: AppTheme.indicatorAndIcon,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Åpne i Google Maps',
                      style: TextStyle(
                        color: AppTheme.indicatorAndIcon,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: event.connectionType != null
            ? Chip(
                label: Text(
                  event.connectionType == 'wifi' ? 'WiFi' : 'Mobil',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppTheme.indicatorAndIcon.withOpacity(0.1),
                padding: EdgeInsets.zero,
              )
            : null,
      ),
    );
  }
}
