// See file LICENSE for more information.

library benchmark.block.aes_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../benchmark/block_cipher_benchmark.dart';

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

  BlockCipherBenchmark('AES', '128', true, () => params).report();
  BlockCipherBenchmark('AES', '128', false, () => params).report();

  BlockCipherBenchmark('AES', '192', true, () => params).report();
  BlockCipherBenchmark('AES', '192', false, () => params).report();

  BlockCipherBenchmark('AES', '256', true, () => params).report();
  BlockCipherBenchmark('AES', '256', false, () => params).report();
}
