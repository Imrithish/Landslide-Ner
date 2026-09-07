import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../models/location_data.dart';
import '../core/constants/app_constants.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationNotifier extends StateNotifier<LocationData> {
  final LocationService _locationService;

  LocationNotifier(this._locationService)
      : super(const LocationData(
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
          name: AppConstants.defaultLocationName,
          state: 'Sikkim',
          district: 'East Sikkim',
          isGps: false,
        ));

  Future<void> fetchCurrentGpsLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      state = location;
    }
  }

  void setCustomLocation({
    required double latitude,
    required double longitude,
    String? name,
    String? stateName,
    String? district,
  }) {
    state = LocationData(
      latitude: latitude,
      longitude: longitude,
      name: name ?? '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E',
      state: stateName,
      district: district,
      isGps: false,
    );
  }
}

final selectedLocationProvider = StateNotifierProvider<LocationNotifier, LocationData>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});
