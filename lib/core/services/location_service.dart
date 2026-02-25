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
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String? city =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea;
        String? subLocality = place.subLocality;

        if (city != null && subLocality != null) {
          address = '$city, $subLocality';
        } else if (city != null) {
          address = city;
        }
      }

      return UserLocation(
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      rethrow;
    }
  }
}
