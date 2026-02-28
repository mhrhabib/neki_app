import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserLocation {
  final String address;
  final double latitude;
  final double longitude;

  UserLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  Future<UserLocation> getUserLocation() async {
    try {
      debugPrint('📍 [LocationService] Starting location fetch...');
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 [LocationService] Service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      debugPrint('📍 [LocationService] Initial permission status: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('📍 [LocationService] Requesting permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('📍 [LocationService] Status after request: $permission');
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Use a slightly higher accuracy and a timeout to avoid hanging on iOS
      debugPrint(
        '📍 [LocationService] Fetching current position (Accuracy: Medium)...',
      );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      debugPrint(
        '📍 [LocationService] Position obtained: ${position.latitude}, ${position.longitude}',
      );

      String address =
          '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';

      try {
        debugPrint('📍 [LocationService] Starting reverse geocoding...');
        // Reverse geocoding can be slow or fail on iOS, so we wrap it in its own try-catch
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          debugPrint(
            '📍 [LocationService] Placemark detail — locality: "${place.locality}", subLocality: "${place.subLocality}", subAdmin: "${place.subAdministrativeArea}", admin: "${place.administrativeArea}", country: "${place.country}"',
          );

          // iOS geocoder often returns empty strings instead of null,
          // so we treat empty strings as missing values.
          String? nonEmpty(String? v) =>
              (v != null && v.trim().isNotEmpty) ? v.trim() : null;

          final city =
              nonEmpty(place.locality) ??
              nonEmpty(place.subAdministrativeArea) ??
              nonEmpty(place.administrativeArea) ??
              nonEmpty(place.country);

          final area =
              nonEmpty(place.subLocality) ??
              nonEmpty(place.name) ??
              nonEmpty(place.thoroughfare);

          if (city != null && area != null && city != area) {
            address = '$area, $city';
          } else if (city != null) {
            address = city;
          } else if (area != null) {
            address = area;
          }
          // else: keep the coordinate fallback set above
        }
      } catch (e) {
        // Fallback already set to coordinates above if geocoding fails
        debugPrint(
          '📍 [LocationService] Geocoding failed, using coordinates: $e',
        );
      }

      debugPrint('📍 [LocationService] Final address result: $address');
      return UserLocation(
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('📍 [LocationService] ERROR in getUserLocation: $e');
      rethrow;
    }
  }
}
