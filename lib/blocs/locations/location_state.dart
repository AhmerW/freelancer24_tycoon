part of "location_bloc.dart";

class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object> get props => [];
}

class LoadedLocationState extends LocationState {
  final List<Location> locations;

  const LoadedLocationState(this.locations);

  LoadedLocationState.copyWith({
    List<Location>? locations,
  }) : locations = locations ?? [];

  const LoadedLocationState.empty() : locations = const [];

  @override
  List<Object> get props => [locations];
}
