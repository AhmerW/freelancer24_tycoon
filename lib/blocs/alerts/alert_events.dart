part of "alert_bloc.dart";

class AlertEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAlertsEvent extends AlertEvent {}

class PushAlertEvent extends AlertEvent {
  final Alert alert;

  PushAlertEvent(this.alert);

  @override
  List<Object?> get props => [alert];
}

class RemoveAlertEvent extends AlertEvent {
  final Alert alert;

  RemoveAlertEvent(this.alert);

  @override
  List<Object?> get props => [alert];
}
