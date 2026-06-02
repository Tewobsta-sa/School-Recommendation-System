import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'typography.dart';

/// Custom color palette for Fidel Guide
/// Designed to be distinctive, professional, and education-focused
class AppColors {
  // Primary brand colors - Deep burgundy for elegance and professionalism
  static const primary = Color(0xFF590016);
  static const primaryLight = Color(0xFF8A1538);
  static const primaryDark = Color(0xFF3D0010);

  // Secondary colors - Warm gold for premium academic feel
  static const secondary = Color(0xFFD4A017);
  static const secondaryLight = Color(0xFFF3D46B);
  static const secondaryDark = Color(0xFFA97800);

  // Accent colors - Muted rose for complementary depth
  static const accent = Color(0xFFA64D79);
  static const accentLight = Color(0xFFC779A0);
  static const accentDark = Color(0xFF7A2E55);

  // Semantic colors
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);

  // Neutral colors - Warm rose-gray palette
  static const background = Color(0xFFFAF7F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5EEF1);
  static const surfaceHighlight = Color(0xFFE8DCE1);

  // Text colors
  static const textPrimary = Color(0xFF2B0D16);
  static const textSecondary = Color(0xFF5C4450);
  static const textTertiary = Color(0xFFA78A98);
  static const textInverse = Color(0xFFFFFFFF);

  // Border and outline colors
  static const outline = Color(0xFFE8DCE1);
  static const outlineVariant = Color(0xFFD5C5CC);

  // Gradient definitions
  static const primaryGradient = LinearGradient(
    colors: [primaryLight, primary], // Rose burgundy → deep burgundy
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary], // Soft gold → warm gold
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGradient = LinearGradient(
    colors: [surface, surfaceVariant], // White → soft rose-gray
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData appTheme() {
  // Custom ColorScheme built from our distinctive palette
  final scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.textInverse,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    
    secondary: AppColors.secondary,
    onSecondary: AppColors.textInverse,
    secondaryContainer: AppColors.secondaryLight,
    onSecondaryContainer: AppColors.secondaryDark,
    
    tertiary: AppColors.accent,
    onTertiary: AppColors.textInverse,
    tertiaryContainer: AppColors.accentLight,
    onTertiaryContainer: AppColors.accentDark,
    
    error: AppColors.error,
    onError: AppColors.textInverse,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.error,
    
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceVariant: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.textSecondary,
    
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,

    scaffoldBackgroundColor: AppColors.background,

    // Custom color extensions for semantic usage
    extensions: [
      _AppColorExtension(
        success: AppColors.success,
        successLight: AppColors.successLight,
        warning: AppColors.warning,
        warningLight: AppColors.warningLight,
        info: AppColors.info,
        infoLight: AppColors.infoLight,
      ),
    ],

    textTheme: AppTypography.toTextTheme(),

    cardTheme: CardThemeData(
      elevation: 2,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.outline,
          width: 1,
        ),
      ),
      shadowColor: AppColors.textPrimary.withOpacity(0.08),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.3),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(
          color: AppColors.outline,
          width: 1.5,
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.2,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),

      hintStyle: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),

      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.outline,
          width: 1.5,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
    ),

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
      titleTextStyle: AppTypography.titleLarge,
    ),

    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: AppColors.outline,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withOpacity(0.12),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withOpacity(0.12),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent.withOpacity(0.12);
          }
          return AppColors.surfaceVariant;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.textSecondary;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textInverse,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      elevation: 8,
    ),
  );
}

/// Custom color extension for semantic colors
@immutable
class _AppColorExtension extends ThemeExtension<_AppColorExtension> {
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color info;
  final Color infoLight;

  const _AppColorExtension({
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.info,
    required this.infoLight,
  });

  @override
  _AppColorExtension copyWith({
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? info,
    Color? infoLight,
  }) {
    return _AppColorExtension(
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
    );
  }

  @override
  _AppColorExtension lerp(ThemeExtension<_AppColorExtension>? other, double t) {
    if (other is! _AppColorExtension) return this;
    return _AppColorExtension(
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
    );
  }
}