// See file LICENSE for more information.

library benchmark.benchmark.rate_benchmark;

import 'package:benchmark_harness/benchmark_harness.dart';

typedef Operation = void Function();

class OperationBenchmark extends BenchmarkBase {
  static const _RUN_LENGTH_MILLIS = 6000;

  final Operation _operation;
  final int _runLengthMillis;

  int? _iterations;

  OperationBenchmark(String name, this._operation,
      [this._runLengthMillis = _RUN_LENGTH_MILLIS])
      : super(name, emitter: OperationEmitter()) {
    emitter.benchmark = this;
  }

  @override
  OperationEmitter get emitter => super.emitter as OperationEmitter;

  @override
  void run() {
    _operation();
  }

  @override
  void exercise() {
    _iterations = 0;

    var watch = Stopwatch()..start();
    while (watch.elapsedMilliseconds < _runLengthMillis) {
      run();
      _iterations = _iterations! + 1;
    }
  }
}

class OperationEmitter implements ScoreEmitter {
  late OperationBenchmark benchmark;

  int? get iterations => benchmark._iterations;

  @override
  void emit(String testName, double value) {
    var ms = value / 1000;
    var s = ms / 1000;
    print('| $testName | '
        '${_formatOperations(iterations! / s)}/s | '
        '$iterations iterations | '
        '${ms.toInt()} ms |');
  }

  String _formatOperations(num opsPerSec) {
    if (opsPerSec < 1000) {
      return '${opsPerSec.toStringAsFixed(2)} Ops';
    } else if (opsPerSec < (1000 * 1000)) {
      return '${(opsPerSec / 1000).toStringAsFixed(2)} KOps';
    } else if (opsPerSec < (1000 * 1000 * 1000)) {
      return '${(opsPerSec / (1000 * 1000)).toStringAsFixed(2)} MOps';
    } else {
      return '${(opsPerSec / (1000 * 1000 * 1000)).toStringAsFixed(2)} GOPs';
    }
  }
}
