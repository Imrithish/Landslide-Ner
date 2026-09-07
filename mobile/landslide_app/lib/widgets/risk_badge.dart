import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';

/// Reusable Risk Badge widget showing risk level with color-coded styling
class RiskBadge extends StatelessWidget {
  final String riskLevel;
  final double? fontSize;
  final bool compact;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.fontSize,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRiskColor(riskLevel);
    final emoji = _getEmoji(riskLevel);
    final label = riskLevel.toUpperCase();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: fontSize ?? 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: (fontSize ?? 14) + 2)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: fontSize ?? 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL': return '🔴';
      case 'HIGH': return '🟠';
      case 'MEDIUM':
      case 'MODERATE': return '🟡';
      default: return '🟢';
    }
  }
}
