/// Formats money as 12.5, 3.4k, 1.2M, 5B, 7T...
String formatMoney(double value) {
  const units = ['', 'k', 'M', 'B', 'T', 'Qa', 'Qi'];
  var v = value.abs();
  var unit = 0;
  while (v >= 1000 && unit < units.length - 1) {
    v /= 1000;
    unit++;
  }
  final digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2);
  var text = v.toStringAsFixed(unit == 0 && v >= 100 ? 0 : digits);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return '${value < 0 ? '-' : ''}$text${units[unit]}';
}

String dollar(num value) => '\$${formatMoney(value.toDouble())}';

/// "1h 05m", "3m 20s", "45s".
String formatDuration(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  if (h > 0) return '${h}h ${two(m)}m';
  if (m > 0) return '${m}m ${two(s)}s';
  return '${s}s';
}
