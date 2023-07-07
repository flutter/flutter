// See file LICENSE for more information.

library test.modes.ige_test;

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/block_cipher.dart';
import '../test/src/helpers.dart';

void main() {
  final key1 = createUint8ListFromHexString(
      '000102030405060708090A0B0C0D0E0F'.toLowerCase());
  final iv1 = createUint8ListFromHexString(
      '000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F'
          .toLowerCase());
  final params1 = ParametersWithIV(KeyParameter(key1), iv1);

  final data1 = String.fromCharCodes(createUint8ListFromHexString(
      '0000000000000000000000000000000000000000000000000000000000000000'));
  final ct1 = '1A8519A6557BE652E9DA8E43DA4EF4453CF456B4CA488AA383C79C98B34797CB'
      .toLowerCase();

  runBlockCipherTests(BlockCipher('AES/IGE'), params1, [data1, ct1]);

  final key2 = createUint8ListFromHexString(
      '5468697320697320616E20696D706C65'.toLowerCase());
  final iv2 = createUint8ListFromHexString(
      '6D656E746174696F6E206F6620494745206D6F646520666F72204F70656E5353'
          .toLowerCase());
  final params2 = ParametersWithIV(KeyParameter(key2), iv2);

  final data2 = String.fromCharCodes(createUint8ListFromHexString(
      '99706487A1CDE613BC6DE0B6F24B1C7AA448C8B9C3403E3467A8CAD89340F53B'));
  final ct2 = '4C2E204C6574277320686F70652042656E20676F74206974207269676874210A'
      .toLowerCase();

  runBlockCipherTests(BlockCipher('AES/IGE'), params2, [data2, ct2]);
}
