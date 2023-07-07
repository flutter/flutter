// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

/// A wrapper around an [io.Process] class that adds some convenience methods.
class ProcessWrapper implements io.Process {
  /// Constructs a [ProcessWrapper] object that delegates to the specified
  /// underlying object.
  ProcessWrapper(this._delegate)
      : _stdout = StreamController<List<int>>(),
        _stderr = StreamController<List<int>>(),
        _stdoutDone = Completer<void>(),
        _stderrDone = Completer<void>() {
    _monitorStdioStream(_delegate.stdout, _stdout, _stdoutDone);
    _monitorStdioStream(_delegate.stderr, _stderr, _stderrDone);
  }

  final io.Process _delegate;
  final StreamController<List<int>> _stdout;
  final StreamController<List<int>> _stderr;
  final Completer<void> _stdoutDone;
  final Completer<void> _stderrDone;

  /// Listens to the specified [stream], repeating events on it via
  /// [controller], and completing [completer] once the stream is done.
  void _monitorStdioStream(
    Stream<List<int>> stream,
    StreamController<List<int>> controller,
    Completer<void> completer,
  ) {
    stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        controller.close();
        completer.complete();
      },
    );
  }

  @override
  Future<int> get exitCode => _delegate.exitCode;

  /// A [Future] that completes when the process has exited and its standard
  /// output and error streams have closed.
  ///
  /// This exists as an alternative to [exitCode], which does not guarantee
  /// that the stdio streams have closed (it is possible for the exit code to
  /// be available before stdout and stderr have closed).
  ///
  /// The future returned here will complete with the exit code of the process.
  Future<int> get done async {
    late int result;
    await Future.wait<void>(<Future<void>>[
      _stdoutDone.future,
      _stderrDone.future,
      _delegate.exitCode.then((int value) {
        result = value;
      }),
    ]);
    return result;
  }

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    return _delegate.kill(signal);
  }

  @override
  int get pid => _delegate.pid;

  @override
  io.IOSink get stdin => _delegate.stdin;

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;
}
