// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../xcode_project.dart';
library;

import 'dart:async';

import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';

/// LLDB is the default debugger in Xcode on macOS. Once the application has
/// launched on a physical iOS device, you can attach to it using LLDB.
///
/// See `xcrun devicectl device process launch --help` for more information.
class LLDB {
  LLDB({required Logger logger, required ProcessUtils processUtils})
    : _logger = logger,
      _processUtils = processUtils;

  final Logger _logger;
  final ProcessUtils _processUtils;

  _LLDBProcess? _lldbProcess;

  /// Whether or not a LLDB process is running.
  bool get isRunning => _lldbProcess != null;

  /// Whether or not the LLDB process has attached and resumed the application process.
  var _isAttached = false;

  /// The process id of the application running on the iOS device.
  int? get appProcessId => _lldbProcess?.appProcessId;

  _LLDBLogPatternCompleter? _logCompleter;

  /// Pattern of lldb log when the process is stopped.
  ///
  /// Example: (lldb) Process 6152 stopped
  static final _lldbProcessStopped = RegExp(r'Process \d* stopped');

  /// Pattern of lldb log when the process is resuming.
  ///
  /// Example: (lldb) Process 6152 resuming
  static final _lldbProcessResuming = RegExp(r'Process \d+ resuming');

  /// Pattern of lldb log when the breakpoint is added.
  ///
  /// Example: Breakpoint 1: no locations (pending).
  static final _breakpointPattern = RegExp(r'Breakpoint (\d+)*:');

  /// A list of log patterns to ignore.
  static final _ignorePatterns = <Pattern>[RegExp(r'\d+ location added to breakpoint \d+')];

  /// Breakpoint script required for JIT on iOS.
  ///
  /// This should match the "handle_new_rx_page" function in [IosProject._lldbPythonHelperTemplate].
  static const _pythonScript = '''
"""Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages."""
base = frame.register["x0"].GetValueAsAddress()
page_len = frame.register["x1"].GetValueAsUnsigned()

# Note: NOTIFY_DEBUGGER_ABOUT_RX_PAGES will check contents of the
# first page to see if handled it correctly. This makes diagnosing
# misconfiguration (e.g. missing breakpoint) easier.
data = bytearray(page_len)
data[0:8] = b'IHELPED!'

error = lldb.SBError()
frame.GetThread().GetProcess().WriteMemory(base, data, error)
if not error.Success():
    print(f'Failed to write into {base}[+{page_len}]', error)
    return

# If the returned value is False, that tells LLDB not to stop at the breakpoint
return False
''';

  /// Starts an LLDB process and inputs commands to start debugging the [appProcessId].
  /// This will start a debugserver on the device, which is required for JIT.
  ///
  /// After attaching and starting the app process, forwards logs to [lldbLogForwarder].
  /// This may include crash logs.
  Future<bool> attachAndStart({
    required String deviceId,
    required int appProcessId,
    required LLDBLogForwarder lldbLogForwarder,
  }) async {
    Timer? timer;
    try {
      timer = Timer(const Duration(minutes: 1), () {
        _logger.printError(
          'LLDB is taking longer than expected to start debugging the app. '
          "LLDB debugging can be disabled for the project by adding the following in the project's pubspec.yaml:\n"
          'flutter:\n'
          '  config:\n'
          '    enable-lldb-debugging: false\n'
          'Or disable LLDB debugging globally with the following command:\n'
          '  "flutter config --no-enable-lldb-debugging"',
        );
      });

      final bool start = await _startLLDB(
        appProcessId: appProcessId,
        lldbLogForwarder: lldbLogForwarder,
      );
      if (!start) {
        return false;
      }
      await _selectDevice(deviceId);
      await _setBreakpoint();
      await _attachToAppProcess(appProcessId);
      await _resumeProcess();
      _isAttached = true;
    } on _LLDBError catch (e) {
      _logger.printTrace('lldb failed with error: ${e.message}');
      exit();
      return false;
    } finally {
      timer?.cancel();
    }
    return true;
  }

  /// Starts LLDB process and leave it running.
  ///
  /// Streams `stdout` and `stderr`. When receiving a log from `stdout`, check
  /// if it matches the pattern [_logCompleter] is waiting for. If a log is sent
  /// to `stderr`, complete with an error and stop the process.
  Future<bool> _startLLDB({
    required int appProcessId,
    required LLDBLogForwarder lldbLogForwarder,
  }) async {
    if (_lldbProcess != null) {
      _logger.printTrace(
        'An LLDB process is already running. It must be stopped before starting a new one.',
      );
      return false;
    }
    try {
      _lldbProcess = _LLDBProcess(
        process: await _processUtils.start(<String>['lldb']),
        appProcessId: appProcessId,
        logger: _logger,
      );

      final StreamSubscription<String> stdoutSubscription = _lldbProcess!.stdout
          .transform(utf8LineDecoder)
          .listen((String line) {
            if (_isAttached && !_ignoreLog(line)) {
              // Only forwards logs after LLDB is attached. All logs before then are part of the
              // attach process.

              lldbLogForwarder.addLog(line);
            } else {
              _logger.printTrace('[lldb]: $line');
              _logCompleter?.checkForMatch(line);
            }
          });

      final StreamSubscription<String> stderrSubscription = _lldbProcess!.stderr
          .transform(utf8LineDecoder)
          .listen((String line) {
            _monitorError(line);
            if (_isAttached && !_ignoreLog(line)) {
              // Only forwards logs after LLDB is attached. All logs before then are part of the
              // attach process.
              lldbLogForwarder.addLog(line);
            } else {
              _logger.printTrace('[lldb]: $line');
            }
          });

      unawaited(
        _lldbProcess!.exitCode
            .then((int status) async {
              _logger.printTrace('lldb exited with code $status');
              await stdoutSubscription.cancel();
              await stderrSubscription.cancel();
            })
            .whenComplete(() async {
              _lldbProcess = null;
            }),
      );
    } on ProcessException catch (exception) {
      _logger.printTrace('Process exception running lldb:\n$exception');
      return false;
    }
    return true;
  }

  /// Kill [_lldbProcess] if available and set it to null.
  bool exit() {
    final bool success = (_lldbProcess == null) || _lldbProcess!.kill();
    _lldbProcess = null;
    _logCompleter = null;
    _isAttached = false;
    return success;
  }

  /// Selects a device for LLDB to interact with.
  Future<void> _selectDevice(String deviceId) async {
    await _lldbProcess?.stdinWriteln('device select $deviceId');
  }

  /// Attaches LLDB to the [appProcessId] running on the device.
  Future<void> _attachToAppProcess(int appProcessId) async {
    // Since the app starts stopped (--start-stopped), we expect a stopped state
    // after attaching.
    final Future<String> futureLog = _startWaitingForLog(
      _lldbProcessStopped,
    ).then((value) => value, onError: _handleAsyncError);

    await _lldbProcess?.stdinWriteln('device process attach --pid $appProcessId');
    await futureLog;
  }

  /// Sets a breakpoint, waits for it print the breakpoint id, and adds a python
  /// script command to be executed whenever the breakpoint is hit.
  Future<void> _setBreakpoint() async {
    final Future<String> futureLog = _startWaitingForLog(
      _breakpointPattern,
    ).then((value) => value, onError: _handleAsyncError);

    await _lldbProcess?.stdinWriteln(
      r"breakpoint set --func-regex '^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$'",
    );
    final String log = await futureLog;
    final Match? match = _breakpointPattern.firstMatch(log);
    final String? breakpointId = match?.group(1);
    if (breakpointId == null) {
      throw _LLDBError('LLDB failed to get breakpoint from log: $log');
    }

    // Once it has the breakpoint id, set the python script.
    // For more information, see: lldb > help break command add
    await _lldbProcess?.stdinWriteln('breakpoint command add --script-type python $breakpointId');
    await _lldbProcess?.stdinWriteln(_pythonScript);
    await _lldbProcess?.stdinWriteln('DONE');
  }

  /// Resume the stopped process.
  Future<void> _resumeProcess() async {
    final Future<String> futureLog = _startWaitingForLog(
      _lldbProcessResuming,
    ).then((value) => value, onError: _handleAsyncError);

    await _lldbProcess?.stdinWriteln('process continue');
    await futureLog;
  }

  /// Creates a completer and returns its future. Methods that utilize this should
  /// start waiting for the log before writing to stdin to avoid race conditions.
  ///
  /// When the [_lldbProcess]'s `stdout` receives a log that matches the [pattern],
  /// the future will complete.
  Future<String> _startWaitingForLog(RegExp pattern) async {
    if (_lldbProcess == null) {
      throw _LLDBError('LLDB is not running.');
    }
    _logCompleter = _LLDBLogPatternCompleter(pattern);
    return _logCompleter!.future;
  }

  Future<String> _handleAsyncError(Object error) async {
    if (error is _LLDBError) {
      throw error;
    }
    throw _LLDBError('Unexpected error when waiting for lldb.');
  }

  /// Checks if [error] is a fatal error and stops the process if so.
  void _monitorError(String error) {
    // The LLDB process does not stop when it receives these errors but is no
    // longer debugging the application. When one of these errors is received,
    // stop the LLDB process.
    final fatalErrors = <String>[
      "error: 'device' is not a valid command.",
      "no device selected: use 'device select <identifier>' to select a device.",
      'The specified device was not found.',
      'Timeout while connecting to remote device.',
      'Internal logic error: Connection was invalidated',
    ];

    if (fatalErrors.contains(error)) {
      _logCompleter?.completeError(_LLDBError(error));
      exit();
    }
  }

  bool _ignoreLog(String log) {
    return _ignorePatterns.any((Pattern pattern) => log.contains(pattern));
  }
}

class _LLDBError implements Exception {
  _LLDBError(this.message);

  final String message;
}

/// A completer that waits for a log line to match a pattern.
class _LLDBLogPatternCompleter {
  _LLDBLogPatternCompleter(this._pattern);

  final RegExp _pattern;
  final _completer = Completer<String>();

  Future<String> get future => _completer.future;

  void checkForMatch(String line) {
    if (_completer.isCompleted) {
      return;
    }
    if (_pattern.hasMatch(line)) {
      _completer.complete(line);
    }
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }
}

/// A container class for associating a [Process] that is is running LLDB with
/// the iOS device process of an application.
class _LLDBProcess {
  _LLDBProcess({required Process process, required this.appProcessId, required Logger logger})
    : _lldbProcess = process,
      _logger = logger;

  final Process _lldbProcess;
  final int appProcessId;

  final Logger _logger;

  Stream<List<int>> get stdout => _lldbProcess.stdout;

  Stream<List<int>> get stderr => _lldbProcess.stderr;

  Future<int> get exitCode => _lldbProcess.exitCode;

  Future<void>? _stdinWriteFuture;

  bool kill() {
    return _lldbProcess.kill();
  }

  /// Writes [line] to [_lldbProcess]'s `stdin` and catches exceptions
  /// (see https://github.com/flutter/flutter/pull/139784).
  Future<void> stdinWriteln(String line, {void Function(Object, StackTrace)? onError}) async {
    Future<void> writeln() {
      return ProcessUtils.writelnToStdinGuarded(
        stdin: _lldbProcess.stdin,
        line: line,
        onError:
            onError ??
            (Object error, _) {
              _logger.printTrace('Could not write "$line" to stdin: $error');
            },
      );
    }

    _stdinWriteFuture = _stdinWriteFuture?.then<void>((_) => writeln()) ?? writeln();
    return _stdinWriteFuture;
  }
}

/// This class is used to forward logs from LLDB to any active listeners.
class LLDBLogForwarder {
  final _streamController = StreamController<String>.broadcast();
  Stream<String> get logLines => _streamController.stream;

  void addLog(String log) {
    if (!_streamController.isClosed) {
      _streamController.add(log);
    }
  }

  Future<bool> exit() async {
    if (_streamController.hasListener) {
      // Tell listeners the process died.
      await _streamController.close();
    }
    return true;
  }
}
