import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/alert_service.dart';
import '../models/alert.dart';
import '../models/risk_zone.dart';

final alertServiceProvider = Provider<AlertService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localCache = ref.watch(localCacheProvider);
  return AlertService(apiClient: apiClient, localCache: localCache);
});

final alertsListProvider = FutureProvider.family<List<Alert>, String?>((ref, riskLevelFilter) async {
  final alertService = ref.watch(alertServiceProvider);
  return await alertService.getAlerts(riskLevel: riskLevelFilter);
});

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final alertService = ref.watch(alertServiceProvider);
  return await alertService.getDashboardSummary();
});

final riskZonesProvider = FutureProvider<List<RiskZone>>((ref) async {
  final alertService = ref.watch(alertServiceProvider);
  return await alertService.getRiskZones();
});
