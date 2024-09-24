import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/blocs/users/user_bloc.dart';
import 'package:freelancer24_tycoon/data/models/locations/location.dart';
import 'package:freelancer24_tycoon/data/repositories/location_repository.dart';
import 'package:freelancer24_tycoon/data/repositories/user_repository.dart';

part "location_events.dart";
part "location_state.dart";

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _locationRepository;
  final UserRepository _userRepository;
  LocationBloc(this._locationRepository, this._userRepository)
      : super(const LoadedLocationState.empty()) {
    on<UnlockLocationEvent>(_unlockLocation);
    on<LoadLocationsEvent>(_loadLocations);
    on<ResetLocationsEvent>(_resetLocations);
    on<UnlockEmployeeSlotEvent>(_unlockEmployeeSlot);
  }

  List<Location> getAllLocations() {
    return _locationRepository.getAllLocations();
  }

  int employeeSlotPrice(Location loc) =>
      loc.employeeSlotPrice * loc.employeeSlots;

  void _loadLocations(
    LoadLocationsEvent event,
    Emitter<LocationState> emit,
  ) {
    emit(LoadedLocationState(_locationRepository.getLocations()));
  }

  void _unlockLocation(
    UnlockLocationEvent event,
    Emitter<LocationState> emit,
  ) {
    if (_userRepository.getBalance() < event.location.price) {
      return;
    }
    if (state is LoadedLocationState) {
      _userRepository.userStreamController
          .add(DecreaseUserBalanceEvent(event.location.price.toDouble()));
      _locationRepository.unlockLocation(event.location);
      emit(LoadedLocationState.copyWith(
        locations: List<Location>.from((state as LoadedLocationState).locations)
          ..add(event.location),
      ));
    }
  }

  void _resetLocations(
    ResetLocationsEvent event,
    Emitter<LocationState> emit,
  ) {
    _locationRepository.resetLocations();
    emit(LoadedLocationState(_locationRepository.getLocations()));
  }

  void _unlockEmployeeSlot(
    UnlockEmployeeSlotEvent event,
    Emitter<LocationState> emit,
  ) {
    if (state is LoadedLocationState) {
      if (_userRepository.getBalance() < event.location.employeeSlotPrice) {
        return;
      }
      _userRepository.userStreamController.add(
        DecreaseUserBalanceEvent(
          event.location.employeeSlotPrice.toDouble(),
        ),
      );
      _locationRepository.unlockEmployeeSlot(event.location);

      emit(LoadedLocationState.copyWith(
        locations:
            List<Location>.from((state as LoadedLocationState).locations),
      ));
    }
  }
}
