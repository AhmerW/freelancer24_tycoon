import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer24_tycoon/utils/format.dart';

void main() {
  test('money uses named units, then aa, ab, ...', () {
    expect(formatMoney(999), '999');
    expect(formatMoney(1500), '1.5k');
    expect(formatMoney(2e6), '2M');
    expect(formatMoney(3.5e18), '3.5Qi');
    expect(formatMoney(1e21), '1aa');
    expect(formatMoney(4.2e24), '4.2ab');
    expect(formatMoney(1e21 * 1e75), '1az');
    expect(formatMoney(1e99), '1ba');
    expect(formatMoney(-2e21), '-2aa');
    expect(dollar(1e21), r'$1aa');
  });
}
