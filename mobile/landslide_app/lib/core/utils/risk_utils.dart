import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Utilities for risk classification, color coding, icons, and descriptions
class RiskUtils {
  static String formatProbability(double? probability) {
    if (probability == null) return '0%';
    return '${(probability * 100).round()}%';
  }

  static String getRiskEmoji(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'CRITICAL':
        return '🔴';
      case 'HIGH':
        return '🟠';
      case 'MEDIUM':
      case 'MODERATE':
        return '🟡';
      case 'LOW':
      default:
        return '🟢';
    }
  }

  static IconData getRiskIcon(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'CRITICAL':
        return Icons.dangerous_rounded;
      case 'HIGH':
        return Icons.warning_amber_rounded;
      case 'MEDIUM':
      case 'MODERATE':
        return Icons.info_outline_rounded;
      case 'LOW':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  static String getRiskDescription(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'CRITICAL':
        return 'Extreme landslide hazard. High probability of slope failure. Evacuate dangerous zones.';
      case 'HIGH':
        return 'Severe threat detected. Saturated soil and steep gradient. Monitor alerts closely.';
      case 'MEDIUM':
      case 'MODERATE':
        return 'Elevated moisture or rainfall levels. Exercise caution on hill roads.';
      case 'LOW':
      default:
        return 'Stable terrain conditions. Normal environmental parameters.';
    }
  }

  static String normalizeRiskLevel(String? rawLevel) {
    if (rawLevel == null) return 'LOW';
    final upper = rawLevel.toUpperCase();
    if (upper.contains('CRIT')) return 'CRITICAL';
    if (upper.contains('HIGH')) return 'HIGH';
    if (upper.contains('MED') || upper.contains('MOD')) return 'MODERATE';
    return 'LOW';
  }
}
