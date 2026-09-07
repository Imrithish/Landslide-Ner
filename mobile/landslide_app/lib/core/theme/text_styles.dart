import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Typography definitions using Inter font
class AppTextStyles {
  static TextStyle get h1Dark => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2Dark => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h3Dark => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      );

  static TextStyle get bodyDark => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
      );

  static TextStyle get bodyBoldDark => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      );

  static TextStyle get captionDark => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextMuted,
      );

  // Light Styles
  static TextStyle get h1Light => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get h2Light => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get h3Light => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      );

  static TextStyle get bodyLight => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextSecondary,
      );

  static TextStyle get bodyBoldLight => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      );

  static TextStyle get captionLight => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextMuted,
      );
}
