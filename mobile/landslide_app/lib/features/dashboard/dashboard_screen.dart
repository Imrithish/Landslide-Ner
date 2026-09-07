import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/sync_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/risk_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/offline_banner.dart';
import '../../core/utils/risk_utils.dart';
import '../../core/utils/date_formatter.dart';
import '../prediction/risk_details_screen.dart';
import '../map/interactive_map_screen.dart';
import '../prediction/analyze_location_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final location = ref.watch(selectedLocationProvider);
    final predictionAsync = ref.watch(currentPredictionProvider);
    final alertsAsync = ref.watch(alertsListProvider(null));
    final syncState = ref.watch(syncStateProvider);

    final user = authState.user;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentPredictionProvider);
            ref.invalidate(alertsListProvider(null));
          },
          color: AppColors.primary,
          child: Column(
            children: [
              // Offline sync banner
              OfflineBanner(
                isOffline: false,
                isSyncing: syncState.isSyncing,
                pendingCount: syncState.pendingCount,
                onSync: () => ref.read(syncStateProvider.notifier).syncNow(),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting${user != null ? ', ${user.fullName.split(' ').first}' : ''}',
                              style: const TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  location.displayName,
                                  style: const TextStyle(
                                    color: AppColors.darkTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // GPS button
                        GestureDetector(
                          onTap: () {
                            ref.read(selectedLocationProvider.notifier).fetchCurrentGpsLocation();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Risk Card
                    predictionAsync.when(
                      loading: () => const LoadingView(message: 'Analyzing location...'),
                      error: (err, _) => ErrorView(
                        message: err.toString(),
                        onRetry: () => ref.invalidate(currentPredictionProvider),
                        icon: Icons.warning_amber_rounded,
                      ),
                      data: (prediction) => RiskCard(
                        prediction: prediction,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RiskDetailsScreen(prediction: prediction),
                          ));
                        },
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                    ),

                    const SizedBox(height: 20),

                    // Environmental Metrics
                    predictionAsync.whenData((prediction) {
                      final f = prediction.features;
                      return _EnvMetricsGrid(
                        rainfall1d: f.rainfall1d,
                        rainfall7d: f.rainfall7d,
                        slopeDegrees: f.slopeDegrees,
                        elevationM: f.elevationM,
                        soilMoisture: f.soilMoisture,
                        confidence: prediction.confidence,
                      );
                    }).valueOrNull ?? const SizedBox.shrink(),

                    const SizedBox(height: 20),

                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.map_rounded,
                            label: 'View Map',
                            onTap: () {},
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.radar_rounded,
                            label: 'Analyze',
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const AnalyzeLocationScreen(),
                              ));
                            },
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Recent Alerts
                    const Text(
                      'Recent Alerts',
                      style: TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 12),

                    alertsAsync.when(
                      loading: () => const LoadingView(message: 'Loading alerts...'),
                      error: (err, _) => ErrorView(
                        message: 'Could not load alerts',
                        onRetry: () => ref.invalidate(alertsListProvider(null)),
                      ),
                      data: (alerts) {
                        if (alerts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: const Center(
                              child: Text(
                                '✅ No active alerts',
                                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        final recentAlerts = alerts.take(5).toList();
                        return Column(
                          children: recentAlerts.asMap().entries.map((entry) {
                            final alert = entry.value;
                            final color = AppColors.getRiskColor(alert.riskLevel);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withAlpha(60)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        RiskUtils.getRiskEmoji(alert.riskLevel),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.location,
                                          style: const TextStyle(
                                            color: AppColors.darkTextPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${(alert.probability * 100).round()}% · ${alert.riskLevel}',
                                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          DateFormatter.formatRelative(alert.createdAt),
                                          style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: Duration(milliseconds: 100 * entry.key)).fadeIn(duration: 300.ms);
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvMetricsGrid extends StatelessWidget {
  final double? rainfall1d;
  final double? rainfall7d;
  final double? slopeDegrees;
  final double? elevationM;
  final double? soilMoisture;
  final double? confidence;

  const _EnvMetricsGrid({
    this.rainfall1d,
    this.rainfall7d,
    this.slopeDegrees,
    this.elevationM,
    this.soilMoisture,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENVIRONMENTAL FACTORS',
            style: TextStyle(
              color: AppColors.darkTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _MetricTile(label: 'Rainfall', value: rainfall1d != null ? '${rainfall1d!.toStringAsFixed(0)} mm' : 'N/A', icon: '🌧️'),
              _MetricTile(label: '7d Rain', value: rainfall7d != null ? '${rainfall7d!.toStringAsFixed(0)} mm' : 'N/A', icon: '🌊'),
              _MetricTile(label: 'Slope', value: slopeDegrees != null ? '${slopeDegrees!.toStringAsFixed(1)}°' : 'N/A', icon: '⛰️'),
              _MetricTile(label: 'Elevation', value: elevationM != null ? '${elevationM!.toStringAsFixed(0)} m' : 'N/A', icon: '📏'),
              _MetricTile(label: 'Moisture', value: soilMoisture != null ? '${(soilMoisture! * 100).toStringAsFixed(0)}%' : 'N/A', icon: '💧'),
              _MetricTile(label: 'Confidence', value: confidence != null ? '${(confidence! * 100).round()}%' : 'N/A', icon: '🎯'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _MetricTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.darkCardHover,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
