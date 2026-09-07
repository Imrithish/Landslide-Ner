import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/prediction.dart';
import '../core/utils/risk_utils.dart';
import '../core/utils/date_formatter.dart';
import 'risk_badge.dart';

/// Large summary card displaying current ML prediction risk level
class RiskCard extends StatelessWidget {
  final PredictionResponse prediction;
  final VoidCallback? onTap;
  final bool isCompact;

  const RiskCard({
    super.key,
    required this.prediction,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskColor = AppColors.getRiskColor(prediction.riskLevel);
    final probability = (prediction.probability * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              riskColor.withAlpha(30),
              riskColor.withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: riskColor.withAlpha(80), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT RISK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  if (prediction.isMock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('MOCK DATA', style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      )),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$probability%',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: riskColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RiskBadge(riskLevel: prediction.riskLevel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Probability bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: prediction.probability,
                  backgroundColor: riskColor.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  minHeight: 6,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 16),
                Text(
                  prediction.explanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Updated ${DateFormatter.formatRelative(prediction.timestamp)}  ·  ${prediction.modelName} v${prediction.modelVersion}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details →',
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
