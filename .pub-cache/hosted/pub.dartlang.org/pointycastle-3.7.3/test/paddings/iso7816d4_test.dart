// See file LICENSE for more information.

library test.paddings.iso7816d4_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/padding.dart';
import '../test/src/helpers.dart';

void main() {
  runPaddingTest(Padding('ISO7816-4'), null,
      createUint8ListFromHexString('ffffff'), 8, 'ffffff8000000000');
  runPaddingTest(Padding('ISO7816-4'), null,
      createUint8ListFromHexString('00000000'), 8, '0000000080000000');
}
