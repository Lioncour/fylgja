/// Model representing a coverage found event
class CoverageEvent {
  final DateTime timestamp;
  final String? connectionType; // 'wifi' or 'mobile'
  final Duration searchDuration;
  final double? latitude;
  final double? longitude;

  CoverageEvent({
    required this.timestamp,
    this.connectionType,
    required this.searchDuration,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'connectionType': connectionType,
      'searchDuration': searchDuration.inSeconds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory CoverageEvent.fromJson(Map<String, dynamic> json) {
    return CoverageEvent(
      timestamp: DateTime.parse(json['timestamp']),
      connectionType: json['connectionType'],
      searchDuration: Duration(seconds: json['searchDuration']),
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }
}
