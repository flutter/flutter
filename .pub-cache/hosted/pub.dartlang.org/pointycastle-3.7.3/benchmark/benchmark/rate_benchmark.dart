// See file LICENSE for more information.

library benchmark.benchmark.rate_benchmark;

import 'package:benchmark_harness/benchmark_harness.dart';

abstract class RateBenchmark extends BenchmarkBase {
  static const _RUN_LENGTH_MILLIS = 6000;

  int _totalData = 0;
  int _iterations = 0;

  RateBenchmark(String name) : super(name, emitter: RateEmitter()) {
    emitter.benchmark = this;
  }

  @override
  RateEmitter get emitter => super.emitter as RateEmitter;

  void addSample(int processedData) {
    _totalData += processedData;
  }

  @override
  void exercise() {
    _totalData = 0;
    _iterations = 0;

    var watch = Stopwatch()..start();
    while (watch.elapsedMilliseconds < _RUN_LENGTH_MILLIS) {
      run();
      _iterations++;
    }
  }
}

class RateEmitter implements ScoreEmitter {
  late RateBenchmark benchmark;

  int get totalData => benchmark._totalData;
  int get iterations => benchmark._iterations;

  @override
  void emit(String testName, double value) {
    var ms = value / 1000;
    var s = ms / 1000;
    print('| $testName | '
        '${_formatDataLength(totalData / s)}/s | '
        '$iterations iterations | '
        '${ms.toInt()} ms | '
        '${_formatDataLength(totalData)} |');
  }

  String _formatDataLength(num dataLen) {
    if (dataLen < 1024) {
      return '${dataLen.toStringAsFixed(2)} B';
    } else if (dataLen < (1024 * 1024)) {
      return '${(dataLen / 1024).toStringAsFixed(2)} KB';
    } else if (dataLen < (1024 * 1024 * 1024)) {
      return '${(dataLen / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(dataLen / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
