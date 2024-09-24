import 'package:equatable/equatable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer24_tycoon/data/models/alerts/alert.dart';
import 'package:freelancer24_tycoon/data/repositories/alert_repository.dart';

part "alert_events.dart";
part "alert_state.dart";

class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final AlertRepository _alertRepository;

  AlertBloc(this._alertRepository) : super(LoadedAlertState.empty()) {
    _alertRepository.alertStreamController.stream.listen((event) {
      if (event is PushAlertEvent) {
        add(PushAlertEvent(event.alert));
      } else if (event is RemoveAlertEvent) {
        add(RemoveAlertEvent(event.alert));
      }
    });
    on<PushAlertEvent>(_pushAlert);
    on<RemoveAlertEvent>(_removeAlert);
    on<LoadAlertsEvent>(_loadAlerts);
  }

  void _loadAlerts(LoadAlertsEvent event, Emitter<AlertState> emit) {
    emit(LoadedAlertState(_alertRepository.loadAlerts()));
  }

  void _pushAlert(PushAlertEvent event, Emitter<AlertState> emit) {
    if (state is LoadedAlertState) {
      if (event.alert.duration != AlertDuration.permanent) {
        Future.delayed(
            event.alert.duration == AlertDuration.short ? 4.seconds : 8.seconds,
            () {
          add(RemoveAlertEvent(event.alert));
        });
      }
      emit((state as LoadedAlertState).join(
        [event.alert],
      ));
    }
  }

  void _removeAlert(RemoveAlertEvent event, Emitter<AlertState> emit) {
    if (state is LoadedAlertState) {
      emit(LoadedAlertState((state as LoadedAlertState)
          .alerts
          .where((a) =>
              a.id != event.alert.id) // removeWhere a.id == event.alert.id
          .toList()));
    }
  }
}
