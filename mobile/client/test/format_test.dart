import 'package:flutter_test/flutter_test.dart';
import 'package:tumai_market_client/utils/format.dart';

void main() {
  test('amounts are grouped by thousands and never break the line', () {
    expect(formatFcfa(800000), '800\u00A0000\u00A0FCFA');
    expect(formatFcfa(25000.0), '25\u00A0000\u00A0FCFA');
    expect(formatFcfa(950), '950\u00A0FCFA');
    expect(formatFcfa(1234567.6), '1\u00A0234\u00A0568\u00A0FCFA');
  });
}
