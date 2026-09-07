/// Landslide Alert Model matching FastAPI AlertResponse
class Alert {
  final int id;
  final String location;
  final String? state;
  final String? district;
  final double latitude;
  final double longitude;
  final String riskLevel;
  final double probability;
  final String status;
  final int affectedPopulation;
  final String description;
  final String? recommendedAction;
  final String escalationLevel;
  final String createdAt;
  final String? updatedAt;

  Alert({
    required this.id,
    required this.location,
    this.state,
    this.district,
    required this.latitude,
    required this.longitude,
    required this.riskLevel,
    required this.probability,
    required this.status,
    this.affectedPopulation = 0,
    required this.description,
    this.recommendedAction,
    this.escalationLevel = 'LOCAL',
    required this.createdAt,
    this.updatedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      location: json['location']?.toString() ?? '',
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level']?.toString() ?? json['riskLevel']?.toString() ?? 'LOW',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'active',
      affectedPopulation: (json['affected_population'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      recommendedAction: json['recommended_action']?.toString(),
      escalationLevel: json['escalation_level']?.toString() ?? 'LOCAL',
      createdAt: json['created_at']?.toString() ?? json['timestamp']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'state': state,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'risk_level': riskLevel,
      'probability': probability,
      'status': status,
      'affected_population': affectedPopulation,
      'description': description,
      'recommended_action': recommendedAction,
      'escalation_level': escalationLevel,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
