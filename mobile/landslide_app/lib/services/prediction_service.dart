import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_cache_service.dart';
import '../models/prediction.dart';
import '../models/forecast.dart';

/// Prediction Service interfacing with the FastAPI ML inference pipeline
class PredictionService {
  final ApiClient _apiClient;
  final LocalCacheService _localCache;

  PredictionService({
    required ApiClient apiClient,
    required LocalCacheService localCache,
  })  : _apiClient = apiClient,
        _localCache = localCache;

  /// Main Prediction API Call: sends coordinates to FastAPI backend
  Future<PredictionResponse> getLandslideRisk({
    required double latitude,
    required double longitude,
    double? rainfall1d,
    double? rainfall3d,
    double? rainfall7d,
    double? elevationM,
    double? slopeDegrees,
    double? soilMoisture,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.predictions,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (rainfall1d != null) 'rainfall_1d': rainfall1d,
          if (rainfall3d != null) 'rainfall_3d': rainfall3d,
          if (rainfall7d != null) 'rainfall_7d': rainfall7d,
          if (elevationM != null) 'elevation_m': elevationM,
          if (slopeDegrees != null) 'slope_degrees': slopeDegrees,
          if (soilMoisture != null) 'soil_moisture': soilMoisture,
        },
      );

      final pred = PredictionResponse.fromJson(response as Map<String, dynamic>);
      // Cache last valid prediction for offline viewing
      await _localCache.cachePrediction(pred.toJson());
      return pred;
    } catch (e) {
      // If network fails, check if we have a cached prediction
      final cached = _localCache.getCachedPrediction();
      if (cached != null) {
        return PredictionResponse.fromJson(cached);
      }
      rethrow;
    }
  }

  /// 7-Day Multi-Hazard Forecast with Future ML Predictions
  Future<MultiHazardForecastResponse> getMultiHazardForecast({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.multiHazardForecast,
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return MultiHazardForecastResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Historical Prediction Query
  Future<List<PredictionResponse>> getPredictionHistory({
    int limit = 20,
    String? riskLevel,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.predictionHistory,
        queryParameters: {
          'limit': limit,
          if (riskLevel != null) 'risk_level': riskLevel,
        },
      );
      final list = (response['history'] as List<dynamic>? ?? []);
      return list.map((e) => PredictionResponse.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Return cached prediction if list unavailable
      final cached = _localCache.getCachedPrediction();
      if (cached != null) {
        return [PredictionResponse.fromJson(cached)];
      }
      return [];
    }
  }

  /// Fetch ML Model Metadata
  Future<Map<String, dynamic>> getModelInfo() async {
    final response = await _apiClient.get(ApiEndpoints.modelInfo);
    return response as Map<String, dynamic>;
  }
}
