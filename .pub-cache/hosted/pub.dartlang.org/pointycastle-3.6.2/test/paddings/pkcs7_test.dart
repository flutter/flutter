// See file LICENSE for more information.

library test.paddings.pkcs7_test;

import 'dart:typed_data' show Uint8List;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/padding.dart';
import '../test/src/helpers.dart';

void main() {
  runPaddingTest(Padding('PKCS7'), null, createUint8ListFromString('123456789'),
      16, '31323334353637383907070707070707');
  runPaddingTest(Padding('PKCS7'), null, Uint8List.fromList([]), 16,
      '10101010101010101010101010101010');
}
