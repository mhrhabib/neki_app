import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/location_service.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(LocationInitial());

  Future<void> fetchLocation() async {
    emit(LocationLoading());
    try {
      final userLocation = await _locationService.getUserLocation();
      emit(
        LocationLoaded(
          address: userLocation.address,
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        ),
      );
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }
}
