part of "location_bloc.dart";

class LocationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class UnlockLocationEvent extends LocationEvent {
  final Location location;

  UnlockLocationEvent(this.location);

  @override
  List<Object> get props => [location];
}

class LoadLocationsEvent extends LocationEvent {}

class ResetLocationsEvent extends LocationEvent {}

class UnlockEmployeeSlotEvent extends LocationEvent {
  final Location location;

  UnlockEmployeeSlotEvent(this.location);

  @override
  List<Object> get props => [location];
}
