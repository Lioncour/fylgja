import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    _loadStatistics();
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
          child: const Icon(
            Icons.wifi,
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
        subtitle: Text(
          'Søktid: $duration',
          style: const TextStyle(
            color: AppTheme.secondaryText,
          ),
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
