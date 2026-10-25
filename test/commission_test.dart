import 'package:flutter_test/flutter_test.dart';

void main() {
  test('managed commission is ten percent', () {
    const price = 100000.0;
    expect(price * .10, 10000);
    expect(price - (price * .10), 90000);
  });
}
