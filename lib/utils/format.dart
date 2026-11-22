/// Formats money as 12.5, 3.4k, 1.2M, 5B, 7T...
/// Short unit for 1000^[i]: k, M, B, T, Qa, Qi, then aa, ab, ... zz like
/// other idle games.
String moneyUnit(int i) {
  const named = ['', 'k', 'M', 'B', 'T', 'Qa', 'Qi'];
  if (i < named.length) return named[i];
  final n = i - named.length;
  const a = 97; // 'a'
  return String.fromCharCodes([a + (n ~/ 26) % 26, a + n % 26]);
}

String formatMoney(double value) {
  if (value.isNaN) return '0';
  if (value.isInfinite) return value < 0 ? '-∞' : '∞';
  var v = value.abs();
  var unit = 0;
  // 7 named units + 26*26 letter pairs.
  while (v >= 1000 && unit < 7 + 26 * 26 - 1) {
    v /= 1000;
    unit++;
  }
  final digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2);
  var text = v.toStringAsFixed(unit == 0 && v >= 100 ? 0 : digits);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
  return '${value < 0 ? '-' : ''}$text${moneyUnit(unit)}';
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
