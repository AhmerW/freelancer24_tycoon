import 'dart:math';

class ProgressService {
  final int rate = 4;
  final double start = 0.5;
  final double base = 1;

  double f(x) {
    return rate * log(x + start) + base;
  }

  double getProgress() {
    return 0;
  }
}
