import 'package:flutter/widgets.dart';
import 'dart:math' as math;

double roundDouble(double value, {int places = 2}) {
  return double.parse(value.toStringAsFixed(places));
}

String formatMoney(double value) {
  // return k for thousands, M for million, B for billions, etc.
  if (value >= 1.0e9) {
    return "${roundDouble(value / 1.0e9)}B";
  } else if (value >= 1.0e6) {
    return "${roundDouble(value / 1.0e6)}M";
  } else if (value >= 1.0e3) {
    return "${roundDouble(value / 1.0e3)}k";
  } else {
    return "${roundDouble(value)}";
  }
}

String formatMoneyInt(int value) {
  return formatMoney(value.toDouble());
}

Color getRandomColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

Color getRandomDarkColor() =>
    Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.5);

int randomRange(int min, int max) => math.Random().nextInt(max) + min;

// extend string dollar sign
String dollar(double value) {
  return "${r'$'}${formatMoney(value)}";
}

String dollarInt(int value) {
  return "${r'$'}${formatMoneyInt(value)}";
}
