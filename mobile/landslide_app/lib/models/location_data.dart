/// Selected Location Model containing GPS Coordinates and Place Metadata
class LocationData {
  final double latitude;
  final double longitude;
  final String? name;
  final String? state;
  final String? district;
  final bool isGps;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
    this.state,
    this.district,
    this.isGps = false,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (state != null && state!.isNotEmpty) {
      return district != null && district!.isNotEmpty
          ? '$district, $state'
          : state!;
    }
    return '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name']?.toString(),
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      isGps: json['is_gps'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'state': state,
      'district': district,
      'is_gps': isGps,
    };
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? name,
    String? state,
    String? district,
    bool? isGps,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      state: state ?? this.state,
      district: district ?? this.district,
      isGps: isGps ?? this.isGps,
    );
  }
}
