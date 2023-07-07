// See file LICENSE for more information.

library benchmark.benchmark.digest_benchmark;

import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';

import '../benchmark/rate_benchmark.dart';

class DigestBenchmark extends RateBenchmark {
  final String _digestName;
  final Uint8List _data;

  late Digest _digest;

  DigestBenchmark(String digestName, [int dataLength = 1024 * 1024])
      : _digestName = digestName,
        _data = Uint8List(dataLength),
        super('Digest | $digestName');

  @override
  void setup() {
    _digest = Digest(_digestName);
  }

  @override
  void run() {
    _digest.process(_data);
    addSample(_data.length);
  }
}
