// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show ASCII, LineSplitter;

import 'package:meta/meta.dart';

import 'io.dart';
import 'platform.dart';
import 'utils.dart';

final AnsiTerminal terminal = new AnsiTerminal();

abstract class Logger {
  bool get isVerbose => false;

  bool quiet = false;

  bool get supportsColor => terminal.supportsColor;
  set supportsColor(bool value) {
    terminal.supportsColor = value;
  }

  /// Display an error level message to the user. Commands should use this if they
  /// fail in some way.
  void printError(String message, { StackTrace stackTrace, bool emphasis: false });

  /// Display normal output of the command. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  void printStatus(
    String message,
    { bool emphasis: false, bool newline: true, String ansiAlternative, int indent }
  );

  /// Use this for verbose tracing output. Users can turn this output on in order
  /// to help diagnose issues with the toolchain or with their setup.
  void printTrace(String message);

  /// Start an indeterminate progress display.
  ///
  /// [message] is the message to display to the user; [progressId] provides an ID which can be
  /// used to identify this type of progress (`hot.reload`, `hot.restart`, ...).
  Status startProgress(String message, { String progressId, bool expectSlowOperation: false });
}

class Status {
  void stop() { }
  void cancel() { }
}

typedef void _FinishCallback();

class StdoutLogger extends Logger {

  Status _status;

  @override
  bool get isVerbose => false;

  @override
  void printError(String message, { StackTrace stackTrace, bool emphasis: false }) {
    _status?.cancel();
    _status = null;

    if (emphasis)
      message = terminal.bolden(message);
    stderr.writeln(message);
    if (stackTrace != null)
      stderr.writeln(stackTrace.toString());
  }

  @override
  void printStatus(
    String message,
    { bool emphasis: false, bool newline: true, String ansiAlternative, int indent }
  ) {
    _status?.cancel();
    _status = null;
    if (terminal.supportsColor && ansiAlternative != null)
      message = ansiAlternative;
    if (emphasis)
      message = terminal.bolden(message);
    if (indent != null && indent > 0)
      message = LineSplitter.split(message).map((String line) => ' ' * indent + line).join('\n');
    if (newline)
      message = '$message\n';
    writeToStdOut(message);
  }

  @protected
  void writeToStdOut(String message) {
    stdout.write(message);
  }

  @override
  void printTrace(String message) { }

  @override
  Status startProgress(String message, { String progressId, bool expectSlowOperation: false }) {
    if (_status != null) {
      // Ignore nested progresses; return a no-op status object.
      return new Status();
    } else {
      if (supportsColor) {
        _status = new _AnsiStatus(message, expectSlowOperation, () { _status = null; });
        return _status;
      } else {
        printStatus(message);
        return new Status();
      }
    }
  }
}

/// A [StdoutLogger] which replaces Unicode characters that cannot be printed to
/// the Windows console with alternative symbols.
///
/// By default, Windows uses either "Consolas" or "Lucida Console" as fonts to
/// render text in the console. Both fonts only have a limited character set.
/// Unicode characters, that are not available in either of the two default
/// fonts, should be replaced by this class with printable symbols. Otherwise,
/// they will show up as the unrepresentable character symbol '�'.
class WindowsStdoutLogger extends StdoutLogger {

  @override
  void writeToStdOut(String message) {
    stdout.write(message
        .replaceAll('✗', 'X')
        .replaceAll('✓', '√')
    );
  }
}

class BufferLogger extends Logger {
  @override
  bool get isVerbose => false;

  final StringBuffer _error = new StringBuffer();
  final StringBuffer _status = new StringBuffer();
  final StringBuffer _trace = new StringBuffer();

  String get errorText => _error.toString();
  String get statusText => _status.toString();
  String get traceText => _trace.toString();

  @override
  void printError(String message, { StackTrace stackTrace, bool emphasis: false }) {
    _error.writeln(message);
  }


  @override
  void printStatus(
    String message,
    { bool emphasis: false, bool newline: true, String ansiAlternative, int indent }
  ) {
    if (newline)
      _status.writeln(message);
    else
      _status.write(message);
  }

  @override
  void printTrace(String message) => _trace.writeln(message);

  @override
  Status startProgress(String message, { String progressId, bool expectSlowOperation: false }) {
    printStatus(message);
    return new Status();
  }

  /// Clears all buffers.
  void clear() {
    _error.clear();
    _status.clear();
    _trace.clear();
  }
}

class VerboseLogger extends Logger {
  VerboseLogger(this.parent) {
    stopwatch.start();
  }

  final Logger parent;

  Stopwatch stopwatch = new Stopwatch();

  @override
  bool get isVerbose => true;

  @override
  void printError(String message, { StackTrace stackTrace, bool emphasis: false }) {
    _emit(_LogType.error, message, stackTrace);
  }

  @override
  void printStatus(
    String message,
    { bool emphasis: false, bool newline: true, String ansiAlternative, int indent }
  ) {
    _emit(_LogType.status, message);
  }

  @override
  void printTrace(String message) {
    _emit(_LogType.trace, message);
  }

  @override
  Status startProgress(String message, { String progressId, bool expectSlowOperation: false }) {
    printStatus(message);
    return new Status();
  }

  void _emit(_LogType type, String message, [StackTrace stackTrace]) {
    if (message.trim().isEmpty)
      return;

    final int millis = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    String prefix;
    const int prefixWidth = 12;
    if (millis == 0) {
      prefix = ''.padLeft(prefixWidth);
    } else {
      prefix = '+$millis ms'.padLeft(prefixWidth);
      if (millis >= 100)
        prefix = terminal.bolden(prefix);
    }
    prefix = '[$prefix] ';

    final String indent = ''.padLeft(prefix.length);
    final String indentMessage = message.replaceAll('\n', '\n$indent');

    if (type == _LogType.error) {
      parent.printError(prefix + terminal.bolden(indentMessage));
      if (stackTrace != null)
        parent.printError(indent + stackTrace.toString().replaceAll('\n', '\n$indent'));
    } else if (type == _LogType.status) {
      parent.printStatus(prefix + terminal.bolden(indentMessage));
    } else {
      parent.printStatus(prefix + indentMessage);
    }
  }
}

enum _LogType {
  error,
  status,
  trace
}

class AnsiTerminal {
  static const String _bold  = '\u001B[1m';
  static const String _reset = '\u001B[0m';
  static const String _clear = '\u001B[2J\u001B[H';

  static const int _ENXIO = 6;
  static const int _ENOTTY = 25;
  static const int _ENETRESET = 102;
  static const int _INVALID_HANDLE = 6;

  /// Setting the line mode can throw for some terminals (with "Operation not
  /// supported on socket"), but the error can be safely ignored.
  static const List<int> _lineModeIgnorableErrors = const <int>[
    _ENXIO,
    _ENOTTY,
    _ENETRESET,
    _INVALID_HANDLE,
  ];

  bool supportsColor = platform.stdoutSupportsAnsi;

  String bolden(String message) {
    if (!supportsColor)
      return message;
    final StringBuffer buffer = new StringBuffer();
    for (String line in message.split('\n'))
      buffer.writeln('$_bold$line$_reset');
    final String result = buffer.toString();
    // avoid introducing a new newline to the emboldened text
    return (!message.endsWith('\n') && result.endsWith('\n'))
        ? result.substring(0, result.length - 1)
        : result;
  }

  String clearScreen() => supportsColor ? _clear : '\n\n';

  set singleCharMode(bool value) {
    // TODO(goderbauer): instead of trying to set lineMode and then catching
    // [_ENOTTY] or [_INVALID_HANDLE], we should check beforehand if stdin is
    // connected to a terminal or not.
    // (Requires https://github.com/dart-lang/sdk/issues/29083 to be resolved.)
    try {
      // The order of setting lineMode and echoMode is important on Windows.
      if (value) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      } else {
        stdin.lineMode = true;
        stdin.echoMode = true;
      }
    } on StdinException catch (error) {
      if (!_lineModeIgnorableErrors.contains(error.osError?.errorCode))
        rethrow;
    }
  }

  /// Return keystrokes from the console.
  ///
  /// Useful when the console is in [singleCharMode].
  Stream<String> get onCharInput => stdin.transform(ASCII.decoder);
}

class _AnsiStatus extends Status {
  _AnsiStatus(this.message, this.expectSlowOperation, this.onFinish) {
    stopwatch = new Stopwatch()..start();

    stdout.write('${message.padRight(52)}     ');
    stdout.write('${_progress[0]}');

    timer = new Timer.periodic(const Duration(milliseconds: 100), _callback);
  }

  static final List<String> _progress = <String>['-', r'\', '|', r'/', '-', r'\', '|', '/'];

  final String message;
  final bool expectSlowOperation;
  final _FinishCallback onFinish;
  Stopwatch stopwatch;
  Timer timer;
  int index = 1;
  bool live = true;

  void _callback(Timer timer) {
    stdout.write('\b${_progress[index]}');
    index = ++index % _progress.length;
  }

  @override
  void stop() {
    onFinish();

    if (!live)
      return;
    live = false;

    if (expectSlowOperation) {
      print('\b\b\b\b\b${getElapsedAsSeconds(stopwatch.elapsed).padLeft(5)}');
    } else {
      print('\b\b\b\b\b${getElapsedAsMilliseconds(stopwatch.elapsed).padLeft(5)}');
    }

    timer.cancel();
  }

  @override
  void cancel() {
    onFinish();

    if (!live)
      return;
    live = false;

    print('\b ');
    timer.cancel();
  }
}
