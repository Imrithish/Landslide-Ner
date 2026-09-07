import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import '../services/prediction_service.dart';
import '../models/prediction.dart';
import '../models/forecast.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localCache = ref.watch(localCacheProvider);
  return PredictionService(apiClient: apiClient, localCache: localCache);
});

/// Live Prediction Provider that automatically runs inference whenever selected location changes
final currentPredictionProvider = FutureProvider<PredictionResponse>((ref) async {
  final location = ref.watch(selectedLocationProvider);
  final predictionService = ref.watch(predictionServiceProvider);

  return await predictionService.getLandslideRisk(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});

/// 7-Day Multi-Hazard Rolling Forecast Provider
final multiHazardForecastProvider = FutureProvider.family<MultiHazardForecastResponse, (double, double)>(
  (ref, coords) async {
    final predictionService = ref.watch(predictionServiceProvider);
    return await predictionService.getMultiHazardForecast(
      latitude: coords.$1,
      longitude: coords.$2,
    );
  },
);

/// Prediction History Provider
final predictionHistoryProvider = FutureProvider<List<PredictionResponse>>((ref) async {
  final predictionService = ref.watch(predictionServiceProvider);
  return await predictionService.getPredictionHistory();
});
