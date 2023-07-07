// See file LICENSE for more information.

library test.digests.sm3_test;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

import '../test/runners/digest.dart';
import '../test/src/helpers.dart';

void main() {
  runDigestTests(Digest('SM3'), [
    // Example 1, From GB/T 32905-2016
    'abc',
    '66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0',
    // Example 2, From GB/T 32905-2016
    'abcd' * 16,
    'debe9ff92275b8a138604889c18e5a4d6fdb70e5387e5765293dcba39c0c5732',
  ]);

  group("optional SM3 tests", () {
    test("64K Digest", () {
      var dig = Digest('SM3');

      for (var i = 0; i < 65536; i++) {
        dig.updateByte(i);
      }

      var out = Uint8List(dig.digestSize);
      dig.doFinal(out, 0);

      expect(
          createUint8ListFromHexString(
              '97049bdc8f0736bc7300eafa9980aeb9cf00f24f7ec3a8f1f8884954d7655c1d'),
          equals(out));
    });

    test("10^6 'a' Test", () {
      var dig = Digest('SM3');

      for (var i = 0; i < 1000000; i++) {
        dig.updateByte(97);
      }

      var out = Uint8List(dig.digestSize);
      dig.doFinal(out, 0);

      expect(
          createUint8ListFromHexString(
              'c8aaf89429554029e231941a2acc0ad61ff2a5acd8fadd25847a3a732b3b02c3'),
          equals(out));
    });
  });
}
