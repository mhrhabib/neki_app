import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' show LocationPermission;
import '../../services/location_service.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(LocationInitial());

  /// Silently checks permission + fetches location if already granted.
  /// Does NOT show the OS permission dialog — call [requestAndFetch] for that.
  Future<void> fetchLocation() async {
    debugPrint('🔎 [LocationCubit] Requesting location update...');
    emit(LocationLoading());
    try {
      final userLocation = await _locationService.getUserLocation();
      debugPrint('🔎 [LocationCubit] Success: ${userLocation.address}');
      emit(
        LocationLoaded(
          address: userLocation.address,
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ),
      );
    } on LocationServiceOffException {
      debugPrint('🔎 [LocationCubit] Location service disabled');
      emit(LocationServiceDisabled());
    } on LocationPermissionDeniedException catch (e) {
      debugPrint('🔎 [LocationCubit] Permission denied (permanent: ${e.permanent})');
      emit(LocationPermissionDenied(permanent: e.permanent));
    } catch (e) {
      debugPrint('🔎 [LocationCubit] Error: $e');
      emit(LocationError(e.toString()));
    }
  }

  /// Shows the OS permission dialog, then fetches location if granted.
  Future<void> requestAndFetch() async {
    emit(LocationLoading());
    try {
      final permission = await _locationService.requestPermission();
      debugPrint('🔎 [LocationCubit] Permission after request: $permission');

      if (permission == LocationPermission.denied) {
        emit(const LocationPermissionDenied(permanent: false));
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        emit(const LocationPermissionDenied(permanent: true));
        return;
      }

      // Permission granted — now fetch
      await fetchLocation();
    } catch (e) {
      debugPrint('🔎 [LocationCubit] requestAndFetch error: $e');
      emit(LocationError(e.toString()));
    }
  }

  /// Opens app settings (for permanently denied) then retries on return.
  Future<void> openSettings() async {
    await _locationService.openAppSettings();
  }

  /// Opens device location settings (for service disabled).
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }
}
