// See file LICENSE for more information.

library src.utils_test;

import 'package:pointycastle/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('BigInt utility functions ', () {
    testUnsignedEncoding();
    testArbitrarySignDecoding();
    testTwosComplimentBigIntEncoding();
    testTwosComplimentBigIntOverRange();
  });
}

void testTwosComplimentBigIntEncoding() {
  test('twos compliment encoding', () {
    var bi1 = BigInt.zero - BigInt.from(128);

    var out = encodeBigInt(bi1);
    expect([128], equals(out));
    out = encodeBigIntAsUnsigned(bi1);
    expect([128], equals(out));

    var bi2 = BigInt.from(128);
    out = encodeBigInt(bi2); // [0,128]
    expect([0, 128], equals(out));
    out = encodeBigIntAsUnsigned(bi2);
    expect([128], equals(out));

    expect(decodeBigInt(encodeBigInt(BigInt.from(-1001))),
        equals(BigInt.from(-1001)));

    expect(decodeBigInt(encodeBigInt(BigInt.from(0))), equals(BigInt.from(0)));

    expect(decodeBigInt([0]), equals(BigInt.from(0)));

    expect(decodeBigInt([]), equals(BigInt.from(0)));
  });
}

void testTwosComplimentBigIntOverRange() {
  test('decode encode twos compliment roundtrip', () {
    for (var t = -0xFFFFFFFF; t < 0xFFFFFFFF; t += 0x1024) {
      var n = BigInt.from(t);
      var encoded = encodeBigInt(n);
      if (n == BigInt.zero) {
        expect(encoded.length, equals(1),
            reason: 'Zero value is one element array with zero byte value');
        expect(encoded[0], equals(0),
            reason: 'Zero value is one element array with zero byte value');
      } else if (n.isNegative) {
        expect(encoded[0] & 0x80, equals(0x80), reason: 'sign bit must be set');
      } else {
        expect(encoded[0] & 0x80, equals(0), reason: 'sign bit must not set');
      }
      expect(n, equals(decodeBigInt(encoded)));
    }
  });
}

void testUnsignedEncoding() {
  test('unsigned encoding', () {
    expect(encodeBigIntAsUnsigned(BigInt.from(33025)), [0x81, 0x01]);
    expect(encodeBigIntAsUnsigned(BigInt.from(-33025)), [0xFF, 0x7E, 0xFF]);

    var theEncoded = encodeBigIntAsUnsigned(BigInt.from(0));
    expect(theEncoded.length, 1);
    expect(theEncoded[0], 0);
  });
}

void testArbitrarySignDecoding() {
  test('arbitrary sign decoding', () {
    expect(decodeBigIntWithSign(1, [0x81, 0x01]), BigInt.from(33025));
    expect(decodeBigIntWithSign(-1, [0xFF, 0x7E, 0xFF]), BigInt.from(-33025));
    expect(decodeBigIntWithSign(1, [0xFF, 0x7E, 0xFF]), BigInt.from(16744191));
    expect(decodeBigIntWithSign(0, []), BigInt.from(0));

    expect(decodeBigIntWithSign(-1, [0]), BigInt.from(0));
    expect(decodeBigIntWithSign(1, [0]), BigInt.from(0));
  });
}
