import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/alert_provider.dart';
import '../../constants/app_colors.dart';
import '../../models/alert.dart';
import '../../core/utils/risk_utils.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/risk_badge.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String? _riskFilter;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsListProvider(_riskFilter));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Active Alerts'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(alertsListProvider(_riskFilter)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _riskFilter == null,
                  onTap: () => setState(() => _riskFilter = null),
                ),
                const SizedBox(width: 8),
                ...['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((level) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: level,
                    isActive: _riskFilter == level,
                    color: AppColors.getRiskColor(level),
                    onTap: () => setState(() => _riskFilter = level == _riskFilter ? null : level),
                  ),
                )),
              ],
            ),
          ),

          Expanded(
            child: alertsAsync.when(
              loading: () => const LoadingView(message: 'Loading alerts...'),
              error: (err, _) => ErrorView(
                message: 'Failed to load alerts: ${err.toString()}',
                onRetry: () => ref.invalidate(alertsListProvider(_riskFilter)),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.riskLow, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No Active Alerts',
                          style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _riskFilter != null
                              ? 'No $_riskFilter alerts at this time'
                              : 'All monitored NER stations are reporting safe conditions',
                          style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(alertsListProvider(_riskFilter)),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      return _AlertCard(alert: alerts[index], index: index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final int index;

  const _AlertCard({required this.alert, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRiskColor(alert.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(RiskUtils.getRiskEmoji(alert.riskLevel), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                RiskBadge(riskLevel: alert.riskLevel, compact: true),
                const Spacer(),
                Text(
                  '${(alert.probability * 100).round()}% probability',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.location,
                  style: const TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (alert.state != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    alert.state!,
                    style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  alert.description,
                  style: const TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alert.recommendedAction != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            alert.recommendedAction!,
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.darkTextMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatRelative(alert.createdAt),
                      style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                    ),
                    const Spacer(),
                    if (alert.affectedPopulation > 0)
                      Text(
                        '~${alert.affectedPopulation.toString()} at risk',
                        style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.05, end: 0).fadeIn(duration: 300.ms);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withAlpha(30) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppColors.darkBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : AppColors.darkTextSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
