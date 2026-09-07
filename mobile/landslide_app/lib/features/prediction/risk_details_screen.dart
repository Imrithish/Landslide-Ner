import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../models/prediction.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/risk_badge.dart';

class RiskDetailsScreen extends StatelessWidget {
  final PredictionResponse prediction;

  const RiskDetailsScreen({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final riskColor = AppColors.getRiskColor(prediction.riskLevel);
    final f = prediction.features;
    final probability = (prediction.probability * 100).round();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Risk Details'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Risk Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [riskColor.withAlpha(35), riskColor.withAlpha(12)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskColor.withAlpha(100), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  'LANDSLIDE RISK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.darkTextMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$probability%',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                RiskBadge(riskLevel: prediction.riskLevel, fontSize: 16),
                const SizedBox(height: 8),
                Text(
                  'probability',
                  style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 20),

          // Location Details
          _SectionCard(
            title: 'LOCATION',
            icon: Icons.location_on_rounded,
            children: [
              _DetailRow('Latitude', '${prediction.latitude.toStringAsFixed(6)}° N'),
              _DetailRow('Longitude', '${prediction.longitude.toStringAsFixed(6)}° E'),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Environmental Factors
          _SectionCard(
            title: 'ENVIRONMENTAL FACTORS',
            icon: Icons.thermostat_rounded,
            children: [
              if (f.rainfall1d != null)
                _DetailRow('Rainfall (1 Day)', '${f.rainfall1d!.toStringAsFixed(1)} mm'),
              if (f.rainfall3d != null)
                _DetailRow('Rainfall (3 Days)', '${f.rainfall3d!.toStringAsFixed(1)} mm'),
              if (f.rainfall7d != null)
                _DetailRow('Rainfall (7 Days)', '${f.rainfall7d!.toStringAsFixed(1)} mm'),
              if (f.elevationM != null)
                _DetailRow('Elevation', '${f.elevationM!.toStringAsFixed(0)} m'),
              if (f.slopeDegrees != null)
                _DetailRow('Slope', '${f.slopeDegrees!.toStringAsFixed(1)}°'),
              if (f.soilMoisture != null)
                _DetailRow('Soil Moisture', '${(f.soilMoisture! * 100).toStringAsFixed(1)}%'),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Why is this location risky?
          _SectionCard(
            title: 'WHY IS THIS LOCATION RISKY?',
            icon: Icons.psychology_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  prediction.explanation.isNotEmpty
                      ? prediction.explanation
                      : 'Insufficient data to generate a detailed explanation.',
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              if (prediction.isMock) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Environmental data providers returned no data; ML imputer medians were used.',
                          style: TextStyle(color: AppColors.warning, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 14),

          // Model Info
          _SectionCard(
            title: 'MODEL INFORMATION',
            icon: Icons.smart_toy_rounded,
            children: [
              _DetailRow('Model', prediction.modelName),
              _DetailRow('Version', prediction.modelVersion),
              _DetailRow('Confidence', '${(prediction.confidence * 100).round()}%'),
              _DetailRow('Prediction ID', prediction.predictionId),
              _DetailRow('Generated', DateFormatter.formatDateTime(prediction.timestamp)),
            ],
          ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkTextMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
