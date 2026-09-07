import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_cache_service.dart';
import '../models/alert.dart';
import '../models/risk_zone.dart';

/// Alert Service for active landslide warnings and regional dashboard summaries
class AlertService {
  final ApiClient _apiClient;
  final LocalCacheService _localCache;

  AlertService({
    required ApiClient apiClient,
    required LocalCacheService localCache,
  })  : _apiClient = apiClient,
        _localCache = localCache;

  Future<List<Alert>> getAlerts({
    String? status,
    String? riskLevel,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.alerts,
        queryParameters: {
          if (status != null) 'status': status,
          if (riskLevel != null) 'risk_level': riskLevel,
        },
      );

      final list = (response as List<dynamic>)
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList();

      await _localCache.cacheAlerts(list.map((a) => a.toJson()).toList());
      return list;
    } catch (_) {
      final cached = _localCache.getCachedAlerts();
      if (cached.isNotEmpty) {
        return cached.map((e) => Alert.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _apiClient.get(ApiEndpoints.dashboardSummary);
    return response as Map<String, dynamic>;
  }

  Future<List<RiskZone>> getRiskZones() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.riskZones);
      final list = (response as List<dynamic>)
          .map((e) => RiskZone.fromJson(e as Map<String, dynamic>))
          .toList();

      await _localCache.cacheRiskZones(list.map((z) => z.toJson()).toList());
      return list;
    } catch (_) {
      final cached = _localCache.getCachedRiskZones();
      if (cached.isNotEmpty) {
        return cached.map((e) => RiskZone.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<List<RiskZone>> getRiskMapPoints({String? state, double minProbability = 0.0}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.riskMap,
        queryParameters: {
          if (state != null) 'state': state,
          'min_probability': minProbability,
        },
      );

      final dataList = (response['data'] as List<dynamic>? ?? []);
      return dataList.map((e) => RiskZone.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return getRiskZones();
    }
  }
}
