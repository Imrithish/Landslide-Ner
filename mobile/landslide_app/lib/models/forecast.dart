import 'prediction.dart';

/// Forecast Window matching FastAPI ForecastWindow (24h, 48h, 72h, 7d)
class ForecastWindow {
  final String horizon;
  final String dateLabel;
  final double landslideProbability;
  final String landslideRiskLevel;
  final double rainfallSurgeMm;
  final double cumulative3dRainMm;
  final double soilMoisturePct;
  final String flashFloodRisk;
  final double floodSusceptibilityScore;
  final double? riverDischargeM3s;
  final String advisory;

  ForecastWindow({
    required this.horizon,
    required this.dateLabel,
    required this.landslideProbability,
    required this.landslideRiskLevel,
    required this.rainfallSurgeMm,
    required this.cumulative3dRainMm,
    required this.soilMoisturePct,
    required this.flashFloodRisk,
    required this.floodSusceptibilityScore,
    this.riverDischargeM3s,
    required this.advisory,
  });

  factory ForecastWindow.fromJson(Map<String, dynamic> json) {
    return ForecastWindow(
      horizon: json['horizon']?.toString() ?? '',
      dateLabel: json['date_label']?.toString() ?? '',
      landslideProbability: (json['landslide_probability'] as num?)?.toDouble() ?? 0.0,
      landslideRiskLevel: json['landslide_risk_level']?.toString() ?? 'LOW',
      rainfallSurgeMm: (json['rainfall_surge_mm'] as num?)?.toDouble() ?? 0.0,
      cumulative3dRainMm: (json['cumulative_3d_rain_mm'] as num?)?.toDouble() ?? 0.0,
      soilMoisturePct: (json['soil_moisture_pct'] as num?)?.toDouble() ?? 0.0,
      flashFloodRisk: json['flash_flood_risk']?.toString() ?? 'LOW',
      floodSusceptibilityScore: (json['flood_susceptibility_score'] as num?)?.toDouble() ?? 0.0,
      riverDischargeM3s: (json['river_discharge_m3s'] as num?)?.toDouble(),
      advisory: json['advisory']?.toString() ?? '',
    );
  }
}

/// Multi-Hazard Rolling Forecast Response Model
class MultiHazardForecastResponse {
  final double latitude;
  final double longitude;
  final double elevationM;
  final double slopeDegrees;
  final PredictionResponse currentAssessment;
  final ForecastWindow forecast24h;
  final ForecastWindow forecast48h;
  final ForecastWindow forecast72h;
  final List<ForecastWindow> timeline7d;
  final String peakHazardDay;
  final String peakHazardType;
  final String summaryAdvisory;
  final String modelName;
  final String generatedAt;

  MultiHazardForecastResponse({
    required this.latitude,
    required this.longitude,
    required this.elevationM,
    required this.slopeDegrees,
    required this.currentAssessment,
    required this.forecast24h,
    required this.forecast48h,
    required this.forecast72h,
    required this.timeline7d,
    required this.peakHazardDay,
    required this.peakHazardType,
    required this.summaryAdvisory,
    this.modelName = 'landslide-rf-final',
    required this.generatedAt,
  });

  factory MultiHazardForecastResponse.fromJson(Map<String, dynamic> json) {
    final timelineList = (json['timeline_7d'] as List<dynamic>? ?? [])
        .map((e) => ForecastWindow.fromJson(e as Map<String, dynamic>))
        .toList();

    return MultiHazardForecastResponse(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      elevationM: (json['elevation_m'] as num?)?.toDouble() ?? 0.0,
      slopeDegrees: (json['slope_degrees'] as num?)?.toDouble() ?? 0.0,
      currentAssessment: PredictionResponse.fromJson(json['current_assessment'] as Map<String, dynamic>),
      forecast24h: ForecastWindow.fromJson(json['forecast_24h'] as Map<String, dynamic>),
      forecast48h: ForecastWindow.fromJson(json['forecast_48h'] as Map<String, dynamic>),
      forecast72h: ForecastWindow.fromJson(json['forecast_72h'] as Map<String, dynamic>),
      timeline7d: timelineList,
      peakHazardDay: json['peak_hazard_day']?.toString() ?? 'N/A',
      peakHazardType: json['peak_hazard_type']?.toString() ?? 'Landslide',
      summaryAdvisory: json['summary_advisory']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? 'landslide-rf-final',
      generatedAt: json['generated_at']?.toString() ?? '',
    );
  }
}
