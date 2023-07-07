import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/desede_engine.dart';
import 'package:test/test.dart';

import '../test/src/helpers.dart';

void main() {
  group('DESede Engine', () {
    blockCipherTest(
        0,
        DESedeEngine(),
        DESedeParameters(
          createUint8ListFromHexString('0123456789ABCDEF0123456789ABCDEF'),
        ),
        '4e6f77206973207468652074696d6520666f7220616c6c20',
        '3fa40e8a984d48156a271787ab8883f9893d51ec4b563b53');
    blockCipherTest(
        1,
        DESedeEngine(),
        DESedeParameters(
          createUint8ListFromHexString('0123456789abcdeffedcba9876543210'),
        ),
        '4e6f77206973207468652074696d6520666f7220616c6c20',
        'd80a0d8b2bae5e4e6a0094171abcfc2775d2235a706e232c');

    blockCipherTest(
        2,
        DESedeEngine(),
        DESedeParameters(
          createUint8ListFromHexString(
              '0123456789abcdef0123456789abcdef0123456789abcdef'),
        ),
        '4e6f77206973207468652074696d6520666f7220616c6c20',
        '3fa40e8a984d48156a271787ab8883f9893d51ec4b563b53');
    blockCipherTest(
        3,
        DESedeEngine(),
        DESedeParameters(
          createUint8ListFromHexString(
              '0123456789abcdeffedcba98765432100123456789abcdef'),
        ),
        '4e6f77206973207468652074696d6520666f7220616c6c20',
        'd80a0d8b2bae5e4e6a0094171abcfc2775d2235a706e232c');
  });
}
