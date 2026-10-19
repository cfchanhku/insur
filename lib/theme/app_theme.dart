/// Material 3 themes and design tokens based on docs/WIREFRAMES.md Section 1.
library;

import 'package:flutter/material.dart';

/// Semantic light and dark color tokens.
class AppColors {
  const AppColors._();

  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color darkBackground = Color(0xFF11151B);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1B222B);
  static const Color lightSurfaceVariant = Color(0xFFEEF1F5);
  static const Color darkSurfaceVariant = Color(0xFF27313D);
  static const Color lightTextPrimary = Color(0xFF182230);
  static const Color darkTextPrimary = Color(0xFFF4F6F8);
  static const Color lightTextSecondary = Color(0xFF526174);
  static const Color darkTextSecondary = Color(0xFFBCC6D1);
  static const Color lightTextDisabled = Color(0xFF8994A2);
  static const Color darkTextDisabled = Color(0xFF778493);
  static const Color lightOutline = Color(0xFFAAB4C0);
  static const Color darkOutline = Color(0xFF566271);
  static const Color lightPrimary = Color(0xFF145C74);
  static const Color darkPrimary = Color(0xFF67C4D8);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnPrimary = Color(0xFF08212A);
  static const Color lightSecondary = Color(0xFF4D6279);
  static const Color darkSecondary = Color(0xFFA9BDD2);
  static const Color lightSuccess = Color(0xFF216B4A);
  static const Color darkSuccess = Color(0xFF75C99C);
  static const Color lightWarning = Color(0xFF875400);
  static const Color darkWarning = Color(0xFFF0BB62);
  static const Color lightError = Color(0xFFB3261E);
  static const Color darkError = Color(0xFFFF8A80);
  static const Color lightInfo = Color(0xFF315E9A);
  static const Color darkInfo = Color(0xFF91B8F2);
  static const Color lightScrim = Color(0x66000000);
  static const Color darkScrim = Color(0x99000000);
}

/// Four-pixel-grid spacing tokens.
class AppSpacing {
  const AppSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

/// Corner-radius tokens and standard rounded shapes.
class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 28;
  static const double full = 999;

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(
    Radius.circular(full),
  );
}

/// Standard elevation shadows for cards and overlays.
class AppElevation {
  const AppElevation._();

  static const List<BoxShadow> e1 = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const List<BoxShadow> e2 = <BoxShadow>[
    BoxShadow(color: Color(0x24000000), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const List<BoxShadow> e3 = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 12), blurRadius: 32),
  ];
  static const List<BoxShadow> e4 = <BoxShadow>[
    BoxShadow(color: Color(0x3D000000), offset: Offset(0, 16), blurRadius: 40),
  ];
}

/// Typography tokens with scalable, platform-default font families.
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle button = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
}

/// Builds the application's light and dark Material 3 themes.
class AppTheme {
  const AppTheme._();

  /// Light theme using the wireframe semantic color tokens.
  static ThemeData get light => _buildTheme(Brightness.light);

  /// Dark theme using the wireframe semantic color tokens.
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          onPrimary: isDark
              ? AppColors.darkOnPrimary
              : AppColors.lightOnPrimary,
          secondary: isDark
              ? AppColors.darkSecondary
              : AppColors.lightSecondary,
          surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          surfaceContainerHighest: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          onSurface: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          onSurfaceVariant: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          outline: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          error: isDark ? AppColors.darkError : AppColors.lightError,
          scrim: isDark ? AppColors.darkScrim : AppColors.lightScrim,
        );
    final foreground = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryForeground = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.display.copyWith(color: foreground),
      headlineMedium: AppTextStyles.headline.copyWith(color: foreground),
      titleLarge: AppTextStyles.title.copyWith(color: foreground),
      titleMedium: AppTextStyles.subtitle.copyWith(color: foreground),
      bodyLarge: AppTextStyles.body.copyWith(color: foreground),
      bodyMedium: AppTextStyles.bodySm.copyWith(color: foreground),
      bodySmall: AppTextStyles.caption.copyWith(color: secondaryForeground),
      labelLarge: AppTextStyles.label.copyWith(color: foreground),
      labelMedium: AppTextStyles.caption.copyWith(color: secondaryForeground),
    );
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.roundedMd);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 1,
        margin: const EdgeInsets.all(AppSpacing.s4),
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedSm,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: AppTextStyles.button,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: AppTextStyles.button,
          minimumSize: const Size(48, 48),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: AppTextStyles.button,
          minimumSize: const Size(48, 48),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
      ),
    );
  }
}
