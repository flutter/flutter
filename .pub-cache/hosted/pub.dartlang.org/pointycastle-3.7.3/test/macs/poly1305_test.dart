@TestOn('vm')
// See file LICENSE for more information.

library test.macs.poly1305_test;

import 'package:pointycastle/export.dart';
import 'package:pointycastle/macs/poly1305.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/runners/mac.dart';
import '../test/src/helpers.dart';

void main() {
  var mac = Poly1305.withCipher(AESEngine());

  // Test vectors from BouncyCastle Poly1305 class
  final key = createUint8ListFromHexString(
      '0000000000000000000000000000000000000000000000000000000000000000');
  final iv = createUint8ListFromHexString('00000000000000000000000000000000');
  final params = ParametersWithIV<KeyParameter>(KeyParameter(key), iv);

  final input1 = createUint8ListFromHexString('');

  final output1 = '66e94bd4ef8a2c3b884cfa59ca342b2e';

  mac.init(params);

  runMacTests(mac, [
    PlainTextDigestPair(input1, output1),
    // same input again:
    PlainTextDigestPair(input1, output1)
  ]);

  mac = Poly1305.withCipher(AESEngine());
  final key2 = createUint8ListFromHexString(
      'f795bd0a50e29e0710d3130a20e98d0cf795bd4a52e29ed713d313fa20e98dbc');
  final iv2 = createUint8ListFromHexString('917cf69ebd68b2ec9b9fe9a3eadda692');
  final params2 = ParametersWithIV<KeyParameter>(KeyParameter(key2), iv2);

  var input2 = createUint8ListFromHexString('66f7');
  var output2 = '5ca585c75e8f8f025e710cabc9a1508b';
  mac.init(params2);

  runMacTests(mac, [
    PlainTextDigestPair(input2, output2),
    // same input again:
    PlainTextDigestPair(input2, output2)
  ]);

  mac = Poly1305.withCipher(AESEngine());
  final key3 = createUint8ListFromHexString(
      '3ef49901c8e11c000430d90ad45e7603e69dae0aab9f91c03a325dcc9436fa90');
  final iv3 = createUint8ListFromHexString('166450152e2394835606a9d1dd2cdc8b');
  final params3 = ParametersWithIV<KeyParameter>(KeyParameter(key3), iv3);

  var input3 = createUint8ListFromHexString('66f75c0e0c7a406586');
  var output3 = '2924f51b9c2eff5df09db61dd03a9ca1';
  mac.init(params3);

  runMacTests(mac, [
    PlainTextDigestPair(input3, output3),
    // same input again:
    PlainTextDigestPair(input3, output3)
  ]);

  mac = Poly1305();
  final key4 = createUint8ListFromHexString(
      'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');
  final params4 = KeyParameter(key4);

  var input4 = createUint8ListFromHexString(
      'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');
  var output4 = 'c80cb43844f387946e5aa6085bdf67da';
  mac.init(params4);

  runMacTests(mac, [
    PlainTextDigestPair(input4, output4),
    // same input again:
    PlainTextDigestPair(input4, output4)
  ]);
}
