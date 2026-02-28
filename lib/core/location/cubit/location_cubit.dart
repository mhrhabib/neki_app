import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/location_service.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(LocationInitial());

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
    } catch (e) {
      debugPrint('🔎 [LocationCubit] Error: $e');
      emit(LocationError(e.toString()));
    }
  }
}
