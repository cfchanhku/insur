import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('provides light and dark themes', () {
      expect(AppTheme.light, isA<ThemeData>());
      expect(AppTheme.dark, isA<ThemeData>());
    });

    test('uses Material 3 in both themes', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    test('uses visible primary colors', () {
      expect(AppTheme.light.colorScheme.primary, isNot(Colors.transparent));
      expect(AppTheme.dark.colorScheme.primary, isNot(Colors.transparent));
    });

    test('body medium follows the 14 pixel small-body token', () {
      expect(AppTheme.light.textTheme.bodyMedium?.fontSize, 14);
      expect(AppTheme.dark.textTheme.bodyMedium?.fontSize, 14);
    });

    test('provides distinct light and dark surfaces', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        isNot(AppTheme.dark.scaffoldBackgroundColor),
      );
    });
  });
}
