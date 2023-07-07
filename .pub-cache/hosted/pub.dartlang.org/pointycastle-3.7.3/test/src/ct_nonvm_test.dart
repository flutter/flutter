@OnPlatform({
  'vm': Skip(),
})
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/src/ct.dart';
import 'package:test/test.dart';

import '../digests/cshake_test.dart';

void main() {
  //
  // Not using a secure random otherwise so as not to
  // invoke the platform selection logic.
  //
  var rand = Random();

  group('ct', () {
    test('xor monte', () {
      for (int j = 0; j < 1000; j++) {
        var len = rand.nextInt(256);
        var x = Uint8List.fromList(
            List.generate(len, (index) => rand.nextInt(256)));
        var y = Uint8List.fromList(
            List.generate(len, (index) => rand.nextInt(256)));
        var enable = rand.nextInt(10) >= 5;

        var reason =
            "$enable ${formatBytesAsHexString(x)} ${formatBytesAsHexString(y)}";

        var xExpected = Uint8List.fromList(x);
        _xor(xExpected, y, enable);

        CT_xor(x, y, enable);
        expect(xExpected, equals(x), reason: reason);

        //
        // Should be all zero
        //
        CT_xor(y, y, true);
        y.forEach((element) {
          expect(element, equals(0));
        });
      }
    });

    test('assertion', () {
      var x = Uint8List(1);
      var y = Uint8List(2);
      expect(() {
        CT_xor(x, y, true);
      }, throwsA(isA<AssertionError>()));
    });
  });
}

// naive non ct xor
void _xor(Uint8List x, Uint8List y, bool enable) {
  if (enable) {
    for (int t = 0; t < x.length; t++) {
      x[t] = x[t] ^ y[t];
    }
  }
}
