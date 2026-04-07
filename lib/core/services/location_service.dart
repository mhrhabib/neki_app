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

/// Thrown when the device's location service is turned off.
class LocationServiceOffException implements Exception {
  @override
  String toString() => 'Location services are disabled.';
}

/// Thrown when the user has denied location permission.
class LocationPermissionDeniedException implements Exception {
  /// Whether the denial is permanent ("Don't ask again" / settings-only).
  final bool permanent;
  const LocationPermissionDeniedException({this.permanent = false});

  @override
  String toString() => permanent
      ? 'Location permission permanently denied.'
      : 'Location permission denied.';
}

class LocationService {
  /// Checks current permission status without requesting anything.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Requests location permission from the OS.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Opens the device's app settings so the user can grant permission manually.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Opens the device's location settings.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Fetches current location. Throws [LocationServiceOffException] or
  /// [LocationPermissionDeniedException] when applicable.
  Future<UserLocation> getUserLocation() async {
    try {
      debugPrint('📍 [LocationService] Starting location fetch...');

      // 1. Check if location service is on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('📍 [LocationService] Service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        throw LocationServiceOffException();
      }

      // 2. Check permission (do NOT request here — the UI handles that)
      var permission = await Geolocator.checkPermission();
      debugPrint('📍 [LocationService] Permission status: $permission');

      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException(permanent: false);
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationPermissionDeniedException(permanent: true);
      }

      // 3. Fetch position
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
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          debugPrint(
            '📍 [LocationService] Placemark detail — locality: "${place.locality}", subLocality: "${place.subLocality}", subAdmin: "${place.subAdministrativeArea}", admin: "${place.administrativeArea}", country: "${place.country}"',
          );

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
        }
      } catch (e) {
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
    } on LocationServiceOffException {
      rethrow;
    } on LocationPermissionDeniedException {
      rethrow;
    } catch (e) {
      debugPrint('📍 [LocationService] ERROR in getUserLocation: $e');
      rethrow;
    }
  }
}
