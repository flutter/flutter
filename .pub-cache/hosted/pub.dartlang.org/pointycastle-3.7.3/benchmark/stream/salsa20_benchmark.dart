// See file LICENSE for more information.

library benchmark.stream.salsa20_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../benchmark/stream_cipher_benchmark.dart';

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

  StreamCipherBenchmark('Salsa20', null, true, () => params).report();
  StreamCipherBenchmark('Salsa20', null, false, () => params).report();
}
