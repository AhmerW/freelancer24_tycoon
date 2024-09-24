import 'dart:async';

import 'package:freelancer24_tycoon/blocs/alerts/alert_bloc.dart';
import 'package:freelancer24_tycoon/data/models/alerts/alert.dart';

class AlertRepository {
  final StreamController<AlertEvent> alertStreamController =
      StreamController<AlertEvent>.broadcast();

  List<Alert> loadAlerts() {
    return [];
  }
}
