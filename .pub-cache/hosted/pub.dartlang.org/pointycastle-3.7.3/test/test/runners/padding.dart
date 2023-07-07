// See file LICENSE for more information.

library test.test.padding_tests;

import 'dart:typed_data' show Uint8List;

import 'package:test/test.dart';
import 'package:pointycastle/pointycastle.dart';

import '../src/helpers.dart';

void runPaddingTest(Padding pad, CipherParameters? params, Uint8List unpadData,
    int padLength, String padData) {
  group('${pad.algorithmName}:', () {
    test('addPadding: ${unpadData.toString()}', () {
      var expectedBytes = createUint8ListFromHexString(padData);
      var dataBytes = Uint8List(padLength)..setAll(0, unpadData);

      pad.init(params);
      var ret = pad.addPadding(dataBytes, unpadData.length);

      expect(ret, equals(padLength - unpadData.length));
      expect(dataBytes, equals(expectedBytes));
    });

    test('padCount: $padData', () {
      var dataBytes = createUint8ListFromHexString(padData);

      pad.init(params);
      var ret = pad.padCount(dataBytes);

      expect(ret, equals(padLength - unpadData.length));
    });
  });
}
