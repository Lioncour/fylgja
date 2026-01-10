// This is a basic Flutter widget test for Fylgja app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fylgja/theme/app_theme.dart';

void main() {
  testWidgets('Fylgja theme test', (WidgetTester tester) async {
    // Test the theme configuration
    final theme = AppTheme.theme;
    
    expect(theme.useMaterial3, true);
    expect(theme.colorScheme.primary, AppTheme.indicatorAndIcon);
    expect(theme.colorScheme.surface, AppTheme.primaryBackground);
  });
  
  testWidgets('Fylgja color constants test', (WidgetTester tester) async {
    // Test that color constants are properly defined
    expect(AppTheme.primaryBackground, const Color(0xFFFFFDE7));
    expect(AppTheme.bottomPanel, const Color(0xFF4A3F55));
    expect(AppTheme.notificationPanel, const Color(0xFFD9D5D8));
    expect(AppTheme.buttonAndAbout, const Color(0xFFF5ECEB));
    expect(AppTheme.indicatorAndIcon, const Color(0xFFD4AF37));
    expect(AppTheme.darkText, const Color(0xFF4B3C52));
    expect(AppTheme.primaryText, const Color(0xFF2C2C2C));
    expect(AppTheme.secondaryText, const Color(0xFF666666));
    expect(AppTheme.whiteText, const Color(0xFFFFFFFF));
  });
}
