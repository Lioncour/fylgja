import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'logger.dart';

class _MapApp {
  final String name;
  final Uri uri;

  const _MapApp(this.name, this.uri);
}

/// Opens a position in a map app the user picks.
class MapLauncher {
  static Future<void> open(BuildContext context, double latitude, double longitude) async {
    final opened = defaultTargetPlatform == TargetPlatform.iOS
        ? await _openOnIOS(context, latitude, longitude)
        : await _openOnAndroid(latitude, longitude);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke åpne kartet.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Android lets the user pick among the installed map apps for a geo: link
  /// (unless one is set as the default).
  static Future<bool> _openOnAndroid(double latitude, double longitude) async {
    final geo = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude');
    if (await _launch(geo)) return true;
    return _launch(_googleMapsWeb(latitude, longitude));
  }

  /// iOS has no picker for map links, so list the installed map apps. Checking
  /// for an app needs its scheme in LSApplicationQueriesSchemes in Info.plist.
  static Future<bool> _openOnIOS(BuildContext context, double latitude, double longitude) async {
    final ll = '$latitude,$longitude';
    final candidates = [
      _MapApp('Apple Kart', Uri.parse('https://maps.apple.com/?ll=$ll&q=$ll')),
      _MapApp('Google Maps', Uri.parse('comgooglemaps://?q=$ll&center=$ll')),
      _MapApp('Waze', Uri.parse('waze://?ll=$ll')),
    ];

    final apps = <_MapApp>[];
    for (final app in candidates) {
      if (app.uri.scheme == 'https' || await canLaunchUrl(app.uri)) {
        apps.add(app);
      }
    }
    if (apps.length == 1) return _launch(apps.first.uri);
    if (!context.mounted) return false;

    final picked = await showModalBottomSheet<_MapApp>(
      context: context,
      backgroundColor: AppTheme.primaryBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Åpne i',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
            ),
            for (final app in apps)
              ListTile(
                leading: const Icon(Icons.map, color: AppTheme.indicatorAndIcon),
                title: Text(app.name, style: const TextStyle(color: AppTheme.primaryText)),
                onTap: () => Navigator.of(context).pop(app),
              ),
          ],
        ),
      ),
    );
    // Dismissing the sheet is not a failure.
    if (picked == null) return true;
    return _launch(picked.uri);
  }

  static Uri _googleMapsWeb(double latitude, double longitude) =>
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

  /// launchUrl reports a missing app by returning false on iOS and by throwing
  /// on Android.
  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.warning('Could not open $uri: $e');
      return false;
    }
  }
}
