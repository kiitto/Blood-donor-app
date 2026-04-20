import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static TextStyle display({Color color = AppColors.ink, double size = 40}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.05,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle headline({Color color = AppColors.ink, double size = 26}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle title({Color color = AppColors.ink, double size = 18}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.1,
        color: color,
      );

  static TextStyle body({Color color = AppColors.ink, double size = 15}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  static TextStyle bodyStrong({Color color = AppColors.ink, double size = 15}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle caption({Color color = AppColors.inkMuted, double size = 12.5}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  static TextStyle label({Color color = AppColors.inkMuted, double size = 11}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.2,
        color: color,
      );

  static TextStyle monoTag({Color color = AppColors.ink, double size = 11.5}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color,
      );

  static TextStyle button({Color color = AppColors.onMaroon, double size = 14}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: color,
      );
}
