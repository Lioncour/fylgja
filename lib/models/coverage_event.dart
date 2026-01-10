/// Model representing a coverage found event
class CoverageEvent {
  final DateTime timestamp;
  final String? connectionType; // 'wifi' or 'mobile'
  final Duration searchDuration;

  CoverageEvent({
    required this.timestamp,
    this.connectionType,
    required this.searchDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'connectionType': connectionType,
      'searchDuration': searchDuration.inSeconds,
    };
  }

  factory CoverageEvent.fromJson(Map<String, dynamic> json) {
    return CoverageEvent(
      timestamp: DateTime.parse(json['timestamp']),
      connectionType: json['connectionType'],
      searchDuration: Duration(seconds: json['searchDuration']),
    );
  }
}
