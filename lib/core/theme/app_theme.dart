import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';
import 'chat_theme.dart';

/// Application theme configuration with Material Design 3 support
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      iconButtonTheme: _buildIconButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      progressIndicatorTheme: _buildProgressIndicatorTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
      splashColor: colorScheme.primary.withOpacity(0.12),
      highlightColor: colorScheme.primary.withOpacity(0.08),
      focusColor: colorScheme.primary.withOpacity(0.12),
      hoverColor: colorScheme.primary.withOpacity(0.08),
      extensions: [
        ChatTheme.light(colorScheme),
      ],
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceVariant: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      iconButtonTheme: _buildIconButtonTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      progressIndicatorTheme: _buildProgressIndicatorTheme(colorScheme),
      scaffoldBackgroundColor: colorScheme.surface,
      splashColor: colorScheme.primary.withOpacity(0.12),
      highlightColor: colorScheme.primary.withOpacity(0.08),
      focusColor: colorScheme.primary.withOpacity(0.12),
      hoverColor: colorScheme.primary.withOpacity(0.08),
      extensions: [
        ChatTheme.dark(colorScheme),
      ],
    );
  }

  // Text Theme
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge:
          AppTypography.displayLarge.copyWith(color: colorScheme.onSurface),
      displayMedium:
          AppTypography.displayMedium.copyWith(color: colorScheme.onSurface),
      displaySmall:
          AppTypography.displaySmall.copyWith(color: colorScheme.onSurface),
      headlineLarge:
          AppTypography.headlineLarge.copyWith(color: colorScheme.onSurface),
      headlineMedium:
          AppTypography.headlineMedium.copyWith(color: colorScheme.onSurface),
      headlineSmall:
          AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface),
      titleLarge:
          AppTypography.titleLarge.copyWith(color: colorScheme.onSurface),
      titleMedium:
          AppTypography.titleMedium.copyWith(color: colorScheme.onSurface),
      titleSmall: AppTypography.titleSmall
          .copyWith(color: colorScheme.onSurfaceVariant),
      labelLarge:
          AppTypography.labelLarge.copyWith(color: colorScheme.onSurface),
      labelMedium: AppTypography.labelMedium
          .copyWith(color: colorScheme.onSurfaceVariant),
      labelSmall: AppTypography.labelSmall
          .copyWith(color: colorScheme.onSurfaceVariant),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface),
      bodyMedium:
          AppTypography.bodyMedium.copyWith(color: colorScheme.onSurface),
      bodySmall:
          AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }

  // App Bar Theme
  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: AppSpacing.elevationNone,
      scrolledUnderElevation: AppSpacing.elevationLow,
      centerTitle: true,
      titleTextStyle: AppTypography.appBarTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      systemOverlayStyle: colorScheme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSpacing.iconMd,
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSpacing.iconMd,
      ),
    );
  }

  // Button Themes
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
      ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        elevation: AppSpacing.elevationLow,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        minimumSize: const Size(0, AppSpacing.minButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.buttonText,
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, AppSpacing.minButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.buttonText,
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
      ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        minimumSize: const Size(0, AppSpacing.minButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.buttonText,
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
      ColorScheme colorScheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        minimumSize: const Size(0, AppSpacing.minButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.buttonText,
      ),
    );
  }

  static IconButtonThemeData _buildIconButtonTheme(ColorScheme colorScheme) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        iconSize: AppSpacing.iconMd,
        minimumSize:
            const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFABTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: AppSpacing.elevationMedium,
      focusElevation: AppSpacing.elevationMedium,
      hoverElevation: AppSpacing.elevationHigh,
      highlightElevation: AppSpacing.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }

  // Input Decoration Theme
  static InputDecorationTheme _buildInputDecorationTheme(
      ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
      contentPadding: const EdgeInsets.all(AppSpacing.inputPadding),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      labelStyle: AppTypography.inputLabel
          .copyWith(color: colorScheme.onSurfaceVariant),
      hintStyle:
          AppTypography.inputHint.copyWith(color: colorScheme.onSurfaceVariant),
      errorStyle: AppTypography.errorText.copyWith(color: colorScheme.error),
      helperStyle:
          AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }

  // Card Theme
  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: AppSpacing.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    );
  }

  // List Tile Theme
  static ListTileThemeData _buildListTileTheme(ColorScheme colorScheme) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.listItemPadding,
        vertical: AppSpacing.sm,
      ),
      titleTextStyle:
          AppTypography.bodyLarge.copyWith(color: colorScheme.onSurface),
      subtitleTextStyle: AppTypography.bodyMedium
          .copyWith(color: colorScheme.onSurfaceVariant),
      leadingAndTrailingTextStyle: AppTypography.labelSmall
          .copyWith(color: colorScheme.onSurfaceVariant),
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
    );
  }

  // Other Component Themes
  static DividerThemeData _buildDividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: AppTypography.bodyMedium
          .copyWith(color: colorScheme.onInverseSurface),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: AppSpacing.elevationMedium,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(
      ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: AppSpacing.elevationLow,
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(
      ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppTypography.labelSmall
              .copyWith(color: colorScheme.onSurface);
        }
        return AppTypography.labelSmall
            .copyWith(color: colorScheme.onSurfaceVariant);
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(color: colorScheme.onSecondaryContainer);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
      elevation: AppSpacing.elevationLow,
      height: 80,
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.onSurface.withOpacity(0.12),
      selectedColor: colorScheme.secondaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      labelStyle: AppTypography.labelLarge
          .copyWith(color: colorScheme.onSurfaceVariant),
      secondaryLabelStyle: AppTypography.labelLarge
          .copyWith(color: colorScheme.onSecondaryContainer),
      brightness: colorScheme.brightness,
      elevation: AppSpacing.elevationNone,
      pressElevation: AppSpacing.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }

  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: AppSpacing.elevationHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      titleTextStyle:
          AppTypography.headlineSmall.copyWith(color: colorScheme.onSurface),
      contentTextStyle: AppTypography.bodyMedium
          .copyWith(color: colorScheme.onSurfaceVariant),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: AppSpacing.elevationLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
    );
  }

  static TabBarThemeData _buildTabBarTheme(ColorScheme colorScheme) {
    return TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: AppTypography.titleSmall,
      unselectedLabelStyle: AppTypography.titleSmall,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  static SwitchThemeData _buildSwitchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.outline;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.surfaceVariant;
      }),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(colorScheme.onPrimary),
      side: BorderSide(color: colorScheme.onSurfaceVariant, width: 2),
    );
  }

  static RadioThemeData _buildRadioTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurfaceVariant;
      }),
    );
  }

  static SliderThemeData _buildSliderTheme(ColorScheme colorScheme) {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceVariant,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withOpacity(0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle:
          AppTypography.labelSmall.copyWith(color: colorScheme.onPrimary),
    );
  }

  static ProgressIndicatorThemeData _buildProgressIndicatorTheme(
      ColorScheme colorScheme) {
    return ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceVariant,
      circularTrackColor: colorScheme.surfaceVariant,
    );
  }
}
