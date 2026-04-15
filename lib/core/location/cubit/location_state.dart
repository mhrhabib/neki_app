import 'package:equatable/equatable.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final String address;
  final double latitude;
  final double longitude;
  final String? countryCode;

  const LocationLoaded({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.countryCode,
  });

  @override
  List<Object?> get props => [address, latitude, longitude, countryCode];
}

class LocationPermissionDenied extends LocationState {
  /// true when the user selected "Don't ask again" / permanently denied.
  final bool permanent;

  const LocationPermissionDenied({this.permanent = false});

  @override
  List<Object?> get props => [permanent];
}

class LocationServiceDisabled extends LocationState {}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}
