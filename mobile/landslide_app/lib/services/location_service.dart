import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_data.dart';
import '../core/constants/app_constants.dart';

/// Location Service handling Android GPS permissions, coordinates, and reverse geocoding
class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // GPS is disabled on the device
      return const LocationData(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        name: AppConstants.defaultLocationName,
        state: 'Sikkim',
        district: 'East Sikkim',
        isGps: false,
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationData(
          latitude: AppConstants.defaultLatitude,
          longitude: AppConstants.defaultLongitude,
          name: AppConstants.defaultLocationName,
          state: 'Sikkim',
          district: 'East Sikkim',
          isGps: false,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationData(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        name: AppConstants.defaultLocationName,
        state: 'Sikkim',
        district: 'East Sikkim',
        isGps: false,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      String? localityName;
      String? stateName;
      String? subLocality;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          localityName = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
          stateName = place.administrativeArea;
          subLocality = place.subLocality;
        }
      } catch (_) {
        // Geocoding service might fail offline or without Google Play services
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        name: localityName ?? subLocality ?? 'Current Location',
        state: stateName,
        district: localityName,
        isGps: true,
      );
    } catch (_) {
      return const LocationData(
        latitude: AppConstants.defaultLatitude,
        longitude: AppConstants.defaultLongitude,
        name: AppConstants.defaultLocationName,
        state: 'Sikkim',
        district: 'East Sikkim',
        isGps: false,
      );
    }
  }

  Future<LocationData?> searchLocationByName(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LocationData(
          latitude: loc.latitude,
          longitude: loc.longitude,
          name: query,
          isGps: false,
        );
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }
}
