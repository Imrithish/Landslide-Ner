/// Citizen / Field Hazard Report Model matching FastAPI HazardReport
class HazardReport {
  final String id;
  final String location;
  final String? state;
  final String? district;
  final double latitude;
  final double longitude;
  final String hazardType;
  final String severity;
  final String description;
  final String status;
  final bool visibleCracks;
  final bool rockfallObserved;
  final bool roadBlocked;
  final bool waterAccumulation;
  final bool soilMovement;
  final String? mediaUrl;
  final String? adminNotes;
  final String? reporterName;
  final String? contactInfo;
  final String? idempotencyKey;
  final bool isSynced;
  final String createdAt;

  HazardReport({
    required this.id,
    required this.location,
    this.state,
    this.district,
    required this.latitude,
    required this.longitude,
    this.hazardType = 'Landslide',
    this.severity = 'medium',
    required this.description,
    this.status = 'NEW',
    this.visibleCracks = false,
    this.rockfallObserved = false,
    this.roadBlocked = false,
    this.waterAccumulation = false,
    this.soilMovement = false,
    this.mediaUrl,
    this.adminNotes,
    this.reporterName,
    this.contactInfo,
    this.idempotencyKey,
    this.isSynced = true,
    required this.createdAt,
  });

  factory HazardReport.fromJson(Map<String, dynamic> json) {
    return HazardReport(
      id: json['id']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      hazardType: json['hazard_type']?.toString() ?? json['hazardType']?.toString() ?? 'Landslide',
      severity: json['severity']?.toString() ?? 'medium',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NEW',
      visibleCracks: json['visible_cracks'] == true,
      rockfallObserved: json['rockfall_observed'] == true,
      roadBlocked: json['road_blocked'] == true,
      waterAccumulation: json['water_accumulation'] == true,
      soilMovement: json['soil_movement'] == true,
      mediaUrl: json['media_url']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      reporterName: json['reporter_name']?.toString(),
      contactInfo: json['contact_info']?.toString(),
      idempotencyKey: json['idempotency_key']?.toString(),
      isSynced: json['is_synced'] != false,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
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
      'hazard_type': hazardType,
      'severity': severity,
      'description': description,
      'status': status,
      'visible_cracks': visibleCracks,
      'rockfall_observed': rockfallObserved,
      'road_blocked': roadBlocked,
      'water_accumulation': waterAccumulation,
      'soil_movement': soilMovement,
      'media_url': mediaUrl,
      'admin_notes': adminNotes,
      'reporter_name': reporterName,
      'contact_info': contactInfo,
      'idempotency_key': idempotencyKey,
      'is_synced': isSynced,
      'created_at': createdAt,
    };
  }

  HazardReport copyWith({
    String? id,
    String? location,
    String? state,
    String? district,
    double? latitude,
    double? longitude,
    String? hazardType,
    String? severity,
    String? description,
    String? status,
    bool? visibleCracks,
    bool? rockfallObserved,
    bool? roadBlocked,
    bool? waterAccumulation,
    bool? soilMovement,
    String? mediaUrl,
    String? adminNotes,
    String? reporterName,
    String? contactInfo,
    String? idempotencyKey,
    bool? isSynced,
    String? createdAt,
  }) {
    return HazardReport(
      id: id ?? this.id,
      location: location ?? this.location,
      state: state ?? this.state,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hazardType: hazardType ?? this.hazardType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      status: status ?? this.status,
      visibleCracks: visibleCracks ?? this.visibleCracks,
      rockfallObserved: rockfallObserved ?? this.rockfallObserved,
      roadBlocked: roadBlocked ?? this.roadBlocked,
      waterAccumulation: waterAccumulation ?? this.waterAccumulation,
      soilMovement: soilMovement ?? this.soilMovement,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      adminNotes: adminNotes ?? this.adminNotes,
      reporterName: reporterName ?? this.reporterName,
      contactInfo: contactInfo ?? this.contactInfo,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
