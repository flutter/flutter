// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';
import '../globals.dart';

class LLDB {
  LLDB({
    required Logger logger,
    required ProcessUtils processUtils,
  })  : _logger = logger,
        _processUtils = processUtils;

  final Logger _logger;
  final ProcessUtils _processUtils;

  _LLDBProcess? _lldbProcess;

  bool get isRunning => _lldbProcess != null;

  int? get processId => _lldbProcess?.processId;

  // (lldb) Process 6152 stopped
  static final RegExp _lldbProcessStopped = RegExp(r'Process \d* stopped');

  // (lldb) Process 6152 detached
  static final RegExp _lldbProcessDetached = RegExp(r'Process \d* detached');

  // (lldb) Process 6152 resuming
  static final RegExp _lldbProcessResuming = RegExp(r'Process \d+ resuming');

  static const String _processResume = 'process continue';

  // Print backtrace for all threads while app is stopped.
  static const String _backTraceAll = 'thread backtrace all';

  Future<bool> launchAndAttach(String deviceId, int processId) async {
    if (isRunning) {
      _logger.printTrace('LLDB is already running');
      return false;
    }
    final Completer<bool> attachCompleter = Completer<bool>();
    try {
      _lldbProcess = _LLDBProcess(
        process: await _processUtils.start(<String>['lldb']),
        processId: processId,
        logger: logger,
      );

      final StreamSubscription<String> stdoutSubscription = _lldbProcess!.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {

        if (line.contains(_backTraceAll)) {
          // Even though we're not "detached", just stopped, mark as detached so the backtrace
          // is only show in verbose.
          _lldbProcess?.processStatus = _AppProcessState.detached;
        }

        if (_lldbProcess?.processStatus == _AppProcessState.stopped) {
          _logger.printError(line);
        } else {
          _logger.printTrace(line);
        }

        if (_lldbProcessStopped.hasMatch(line)) {
          if (_lldbProcess?.processStatus == _AppProcessState.suspended) {
            // Wait for process to attach. Attaching will show the process as
            // stopped since the app starts in a suspended state. Continue
            // execution of the process.
            _lldbProcess?.stdinWriteln(_processResume);
            return;
          } else {
            // The app has been stopped. Dump the backtrace, and detach.
            _lldbProcess?.processStatus = _AppProcessState.stopped;
            _lldbProcess?.stdinWriteln(_backTraceAll);
            detach();
            return;
          }
        }

        if (_lldbProcessResuming.hasMatch(line)) {
          _lldbProcess?.processStatus = _AppProcessState.resumed;
          attachCompleter.complete(true);
          return;
        }

        if (_lldbProcessDetached.hasMatch(line)) {
          // The debugger has detached from the app, and there will be no more debugging messages.
          // Kill the lldb process.
          exit();
          return;
        }
      });

      final StreamSubscription<String> stderrSubscription = _lldbProcess!.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
        _logger.printTrace('[stderr] $line');
      });

      unawaited(_lldbProcess!.exitCode.then((int status) async {
        _logger.printTrace('lldb exited with code $exitCode');
        await stdoutSubscription.cancel();
        await stderrSubscription.cancel();
      }).whenComplete(() async {
        if (!attachCompleter.isCompleted) {
          attachCompleter.complete(false);
        }
        _lldbProcess = null;
      }));
    } on ProcessException catch (exception) {
      _logger.printError('Process exception running lldb:\n$exception');
      return false;
    } on ArgumentError catch (exception) {
      _logger.printError('Process exception running lldb:\n$exception');
      return false;
    }

    try {
      await _lldbProcess?.stdinWriteln('device select $deviceId');
      await _lldbProcess?.stdinWriteln('device process attach --pid $processId');
    } on SocketException catch (error) {
      _logger.printTrace('lldb failed: $error');
      return false;
    }

    return attachCompleter.future;
  }

  Future<void> detach() async {
    return _lldbProcess?.stdinWriteln('process detach',
        onError: (Object error, _) {
      // Best effort, try to detach, but maybe the app already exited or already detached.
      _logger.printTrace('Could not detach from debugger: $error');
    });
  }

  bool exit() {
    final bool success = (_lldbProcess == null) || _lldbProcess!.kill();
    _lldbProcess = null;
    return success;
  }
}

class _LLDBProcess {
  _LLDBProcess({
    required Process process,
    required this.processId,
    required Logger logger,
  })  : _lldbProcess = process,
        processStatus = _AppProcessState.suspended,
        _logger = logger;

  final Process _lldbProcess;
  final int processId;
  _AppProcessState processStatus;

  final Logger _logger;

  Stream<List<int>> get stdout => _lldbProcess.stdout;

  Stream<List<int>> get stderr => _lldbProcess.stderr;

  Future<int> get exitCode => _lldbProcess.exitCode;

  Future<void>? _stdinWriteFuture;

  bool kill() {
    return _lldbProcess.kill();
  }

  Future<void> stdinWriteln(
    String line, {
    void Function(Object, StackTrace)? onError,
  }) async {
    Future<void> writeln() {
      return ProcessUtils.writelnToStdinGuarded(
        stdin: _lldbProcess.stdin,
        line: line,
        onError: onError ??
            (Object error, _) {
              _logger.printTrace('Could not write "$line" to stdin: $error');
            },
      );
    }

    _stdinWriteFuture = _stdinWriteFuture?.then<void>((_) => writeln()) ?? writeln();
    return _stdinWriteFuture;
  }
}

enum _AppProcessState {
  /// The app process starts in a suspended state while it waits for a debugger.
  suspended,

  /// The app process is stopped when an error occurs.
  stopped,

  /// The app process is resumed on all threads.
  resumed,

  /// LLDB is detached from the app process.
  detached,
}
