// See file LICENSE for more information.

library test.modes.ofb_test;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/src/registry/registry.dart';

import '../test/runners/block_cipher.dart';
import '../test/src/null_block_cipher.dart';

void main() {
  final iv = Uint8List.fromList([
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
  final params = ParametersWithIV(null, iv);

  registry.register(NullBlockCipher.factoryConfig);

  runBlockCipherTests(BlockCipher('Null/OFB-128'), params, [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit ........',
    '4c7e505629750f07fbecc79ba8b282907231515a3075071aeded869bafb2808c6572565630201457e9fdc3cba5ae8d966e760256283c1257a6b78495e2f3c0d1',
    'En un lugar de La Mancha, de cuyo nombre no quiero acordarme ...',
    '457f02462a750a02eff8d89ba8b8ceb361316f522a360e16a4b9cedeecbe9b866f314c5c29371412a8f7c59bbda8879a727e0252273a1413e9ebc7deecf3c0d1',
  ]);
}
