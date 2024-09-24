part of "alert_bloc.dart";

class AlertState extends Equatable {
  const AlertState();
  @override
  List<Object?> get props => [];
}

class LoadedAlertState extends AlertState {
  final List<Alert> alerts;

  const LoadedAlertState(this.alerts);

  factory LoadedAlertState.empty() => const LoadedAlertState([]);

  LoadedAlertState copyWith({List<Alert>? alerts}) {
    return LoadedAlertState(alerts ?? this.alerts);
  }

  LoadedAlertState join(List<Alert> a) {
    return LoadedAlertState(alerts + a);
  }

  @override
  List<Object?> get props => [alerts];
}
