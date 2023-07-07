// See file LICENSE for more information.

library test.macs.cbc_block_cipher_mac_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/mac.dart';
import '../test/src/helpers.dart';

void main() {
  final mac = Mac('AES/CBC_CMAC/PKCS7');

  // Test vectors from BouncyCastle CBCBlockCipherMac (was DES/CBC_CMAC/PKCS7).
  // Note: Key and expected outputs adapted from DES engine to AES
  final key = createUint8ListFromHexString('0123456789abcdef0123456789abcdef');
  final keyParam = KeyParameter(key);

  final input1 = createUint8ListFromHexString(
      '37363534333231204e6f77206973207468652074696d6520666f7220');
  final input2 = createUint8ListFromHexString('3736353433323120');

  final output5WithAes = '0376f977de2166d1';
  final output6WithAes = 'f338ed02ba54413f';

  mac.init(keyParam);

  runMacTests(mac, [
    PlainTextDigestPair(input2, output5WithAes),
    PlainTextDigestPair(input1, output6WithAes),
    // same input again:
    PlainTextDigestPair(input1, output6WithAes)
  ]);
}
