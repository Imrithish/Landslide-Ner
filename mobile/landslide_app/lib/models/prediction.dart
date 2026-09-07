/// Environmental Telemetry Features matching FastAPI EnvironmentalFeatures
class EnvironmentalFeatures {
  final double? rainfall1d;
  final double? rainfall3d;
  final double? rainfall7d;
  final double? elevationM;
  final double? slopeDegrees;
  final double? soilMoisture;

  EnvironmentalFeatures({
    this.rainfall1d,
    this.rainfall3d,
    this.rainfall7d,
    this.elevationM,
    this.slopeDegrees,
    this.soilMoisture,
  });

  factory EnvironmentalFeatures.fromJson(Map<String, dynamic>? json) {
    if (json == null) return EnvironmentalFeatures();
    return EnvironmentalFeatures(
      rainfall1d: (json['rainfall_1d'] as num?)?.toDouble(),
      rainfall3d: (json['rainfall_3d'] as num?)?.toDouble(),
      rainfall7d: (json['rainfall_7d'] as num?)?.toDouble(),
      elevationM: (json['elevation_m'] as num?)?.toDouble(),
      slopeDegrees: (json['slope_degrees'] as num?)?.toDouble(),
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rainfall_1d': rainfall1d,
      'rainfall_3d': rainfall3d,
      'rainfall_7d': rainfall7d,
      'elevation_m': elevationM,
      'slope_degrees': slopeDegrees,
      'soil_moisture': soilMoisture,
    };
  }
}

/// Prediction Response matching FastAPI PredictionResponse
class PredictionResponse {
  final String predictionId;
  final double latitude;
  final double longitude;
  final String riskLevel;
  final double probability;
  final double confidence;
  final EnvironmentalFeatures features;
  final bool featuresImputed;
  final bool isMock;
  final String explanation;
  final String modelName;
  final String modelVersion;
  final String timestamp;

  PredictionResponse({
    required this.predictionId,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
    required this.probability,
    required this.confidence,
    required this.features,
    this.featuresImputed = false,
    this.isMock = false,
    required this.explanation,
    this.modelName = 'landslide-rf-final',
    this.modelVersion = '1.0.0',
    required this.timestamp,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      predictionId: json['prediction_id']?.toString() ?? 'pred_unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level']?.toString() ?? 'LOW',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      features: EnvironmentalFeatures.fromJson(json['features'] as Map<String, dynamic>?),
      featuresImputed: json['features_imputed'] == true,
      isMock: json['is_mock'] == true,
      explanation: json['explanation']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? 'landslide-rf-final',
      modelVersion: json['model_version']?.toString() ?? '1.0.0',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction_id': predictionId,
      'latitude': latitude,
      'longitude': longitude,
      'risk_level': riskLevel,
      'probability': probability,
      'confidence': confidence,
      'features': features.toJson(),
      'features_imputed': featuresImputed,
      'is_mock': isMock,
      'explanation': explanation,
      'model_name': modelName,
      'model_version': modelVersion,
      'timestamp': timestamp,
    };
  }
}
