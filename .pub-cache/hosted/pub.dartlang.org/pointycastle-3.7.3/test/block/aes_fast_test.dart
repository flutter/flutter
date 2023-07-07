// See file LICENSE for more information.

library test.block.aes_fast_test;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../test/runners/block_cipher.dart';

/*
  These tests are no longer part of the test suit.
  See aes_test.dart
 */

void main() {
  final key = Uint8List.fromList([
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
  final params = KeyParameter(key);

  runBlockCipherTests(BlockCipher('AES'), params, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    '75020e0812adb36f32b1503e0de7a59691e0db8fd1c9efb920695a626cb633d6db0112c007d19d5ea66fe7ab36c766232b3bcb98fd35f06d27d5a2d475d92728',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    '29523a5e73c0ffb7f9aaabc737a09e73219bad5e98768b71e2c985b2d8ce217730b0720e1a215f7843c8c7e07d44c91212fb1d5b90a791dd147f3746cbc0e28b',
  ]);

  final keyViewBuffer = Uint8List.fromList([
    0,
    0,
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
    0xFF,
    0,
    0
  ]);
  final keyView = Uint8List.view(keyViewBuffer.buffer, 2, 16);
  final paramsView = KeyParameter(keyView);

  runBlockCipherTests(BlockCipher('AES'), paramsView, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    '75020e0812adb36f32b1503e0de7a59691e0db8fd1c9efb920695a626cb633d6db0112c007d19d5ea66fe7ab36c766232b3bcb98fd35f06d27d5a2d475d92728',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    '29523a5e73c0ffb7f9aaabc737a09e73219bad5e98768b71e2c985b2d8ce217730b0720e1a215f7843c8c7e07d44c91212fb1d5b90a791dd147f3746cbc0e28b',
  ]);
}
