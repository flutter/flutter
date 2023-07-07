// See file LICENSE for more information.

library test.stream.salsa20_test;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/stream_cipher.dart';

void main() {
  final keyBytes = Uint8List.fromList([
    0x00,
    0x11,
    0x22,
    0x33,
    0x44,
    0x55,
    0x66,
    0x77,
    0x88,
    0x99,
    0xAA,
    0xBB,
    0xCC,
    0xDD,
    0xEE,
    0xFF
  ]);
  final key = KeyParameter(keyBytes);
  final iv =
      Uint8List.fromList([0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77]);
  final params = ParametersWithIV(key, iv);

  runStreamCipherTests(StreamCipher('Salsa20'), params, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    '9d8d611ee047b47fc5e2bd5db4284463008aa89c174093d3ce4b3e8cc2594acfe9a62a84388fe060f75247d425c2fe0cd283cfce887f5c6b5dfea86d927efb36',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    '948c330ee347b17ad1f6a25db4220840138a96940d039adf871f76c9815551c5e3e5308e2198e025b65841843dc4f400ce8bcfca87795a2f12a2eb269c7efb36',
  ]);
}
