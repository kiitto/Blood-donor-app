import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.maroon,
        onPrimary: AppColors.onMaroon,
        secondary: AppColors.red,
        onSecondary: AppColors.onMaroon,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        onError: AppColors.onMaroon,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AppText.display(),
        headlineLarge: AppText.headline(size: 30),
        headlineMedium: AppText.headline(),
        titleLarge: AppText.title(size: 20),
        titleMedium: AppText.title(),
        bodyLarge: AppText.body(size: 16),
        bodyMedium: AppText.body(),
        bodySmall: AppText.caption(),
        labelLarge: AppText.button(color: AppColors.ink),
        labelMedium: AppText.label(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title(size: 17),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.hairlineStrong, width: 1),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.hairlineStrong, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.maroon, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: AppText.body(color: AppColors.inkFaint),
        labelStyle: AppText.label(),
        errorStyle: AppText.caption(color: AppColors.danger, size: 11.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(color: AppColors.onMaroon, size: 14),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}
