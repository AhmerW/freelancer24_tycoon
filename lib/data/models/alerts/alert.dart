import 'package:flutter/cupertino.dart';

enum AlertPriority { high, medium, low }

enum AlertDuration { short, long, permanent }

class Alert {
  final int id;

  final String message;
  final Widget? widget;
  final String title;
  final AlertPriority priority;
  final AlertDuration duration;

  factory Alert.fromWidget(
    String title,
    Widget widget, {
    AlertPriority priority = AlertPriority.low,
    AlertDuration duration = AlertDuration.permanent,
  }) {
    return Alert(
      UniqueKey().hashCode,
      message: "",
      title: title,
      priority: priority,
      widget: widget,
      duration: duration,
    );
  }

  const Alert(
    this.id, {
    required this.message,
    required this.title,
    required this.priority,
    this.widget,
    this.duration = AlertDuration.permanent,
  });
}
