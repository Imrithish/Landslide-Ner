/// Risk Zone Model for Interactive GIS Map and Station Overlays
class RiskZone {
  final String id;
  final String name;
  final String state;
  final String? district;
  final double latitude;
  final double longitude;
  final double? elevationM;
  final double? slopeDegrees;
  final String riskLevel;
  final double probability;
  final double radius;
  final double? rainfall7d;
  final double? soilMoisture;

  RiskZone({
    required this.id,
    required this.name,
    required this.state,
    this.district,
    required this.latitude,
    required this.longitude,
    this.elevationM,
    this.slopeDegrees,
    required this.riskLevel,
    required this.probability,
    this.radius = 15.0,
    this.rainfall7d,
    this.soilMoisture,
  });

  factory RiskZone.fromJson(Map<String, dynamic> json) {
    return RiskZone(
      id: json['id']?.toString() ?? 'zone_unknown',
      name: json['name']?.toString() ?? 'Monitored Station',
      state: json['state']?.toString() ?? 'NER Region',
      district: json['district']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      elevationM: (json['elevation_m'] as num?)?.toDouble(),
      slopeDegrees: (json['slope_degrees'] as num?)?.toDouble(),
      riskLevel: json['risk_level']?.toString() ?? json['riskLevel']?.toString() ?? 'LOW',
      probability: (json['risk_probability'] as num?)?.toDouble() ??
          (json['probability'] as num?)?.toDouble() ??
          0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 15.0,
      rainfall7d: (json['rainfall_7d'] as num?)?.toDouble(),
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'elevation_m': elevationM,
      'slope_degrees': slopeDegrees,
      'risk_level': riskLevel,
      'probability': probability,
      'radius': radius,
      'rainfall_7d': rainfall7d,
      'soil_moisture': soilMoisture,
    };
  }
}
