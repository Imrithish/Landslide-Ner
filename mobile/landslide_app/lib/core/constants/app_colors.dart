import 'package:flutter/material.dart';

/// Curated Color Palette for NER Landslide Emergency & Risk Monitoring
class AppColors {
  // Risk Severity Colors
  static const Color riskLow = Color(0xFF10B981); // Emerald Green
  static const Color riskModerate = Color(0xFFF59E0B); // Amber Yellow
  static const Color riskHigh = Color(0xFFF97316); // Bright Orange
  static const Color riskCritical = Color(0xFFEF4444); // Crimson Red

  // Dark Theme Surfaces
  static const Color darkBg = Color(0xFF0F172A); // Deep Slate Navy
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkCardHover = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Surfaces
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Brand & Accent Colors
  static const Color primary = Color(0xFF3B82F6); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFF8B5CF6); // Purple
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color syncPending = Color(0xFFF59E0B);
  static const Color synced = Color(0xFF10B981);

  // Helpers for Risk Level Colors
  static Color getRiskColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'CRITICAL':
        return riskCritical;
      case 'HIGH':
        return riskHigh;
      case 'MEDIUM':
      case 'MODERATE':
        return riskModerate;
      case 'LOW':
      default:
        return riskLow;
    }
  }

  static Color getRiskColorWithAlpha(String? riskLevel, [int alpha = 40]) {
    return getRiskColor(riskLevel).withAlpha(alpha);
  }
}
