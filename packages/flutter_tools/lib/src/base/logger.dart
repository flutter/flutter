// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

final _AnsiTerminal _terminal = new _AnsiTerminal();
final String _sep = Platform.isWindows ? '-' : '•';

abstract class Logger {
  bool get isVerbose => false;

  String get separator => _sep;

  set supportsColor(bool value) {
    _terminal.supportsColor = value;
  }

  /// Display an error level message to the user. Commands should use this if they
  /// fail in some way.
  void printError(String message, [StackTrace stackTrace]);

  /// Display normal output of the command. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  void printStatus(String message);

  /// Use this for verbose tracing output. Users can turn this output on in order
  /// to help diagnose issues with the toolchain or with their setup.
  void printTrace(String message);

  /// Start an indeterminate progress display.
  Status startProgress(String message);

  /// Flush any buffered output.
  void flush() { }
}

class Status {
  void stop({ bool showElapsedTime: false }) { }
  void cancel() { }
}

class StdoutLogger extends Logger {
  Status _status;

  @override
  bool get isVerbose => false;

  @override
  void printError(String message, [StackTrace stackTrace]) {
    _status?.cancel();
    _status = null;

    stderr.writeln(message);
    if (stackTrace != null)
      stderr.writeln(stackTrace);
  }

  @override
  void printStatus(String message) {
    _status?.cancel();
    _status = null;

    print(message);
  }

  @override
  void printTrace(String message) { }

  @override
  Status startProgress(String message) {
    _status?.cancel();
    _status = null;

    if (_terminal.supportsColor) {
      _status = new _AnsiStatus(message);
      return _status;
    } else {
      printStatus(message);
      return new Status();
    }
  }

  @override
  void flush() { }
}

class BufferLogger extends Logger {
  @override
  bool get isVerbose => false;

  StringBuffer _error = new StringBuffer();
  StringBuffer _status = new StringBuffer();
  StringBuffer _trace = new StringBuffer();

  String get errorText => _error.toString();
  String get statusText => _status.toString();
  String get traceText => _trace.toString();

  @override
  void printError(String message, [StackTrace stackTrace]) => _error.writeln(message);

  @override
  void printStatus(String message) => _status.writeln(message);

  @override
  void printTrace(String message) => _trace.writeln(message);

  @override
  Status startProgress(String message) {
    printStatus(message);
    return new Status();
  }

  @override
  void flush() { }
}

class VerboseLogger extends Logger {
  _LogMessage lastMessage;

  @override
  bool get isVerbose => true;

  @override
  void printError(String message, [StackTrace stackTrace]) {
    _emit();
    lastMessage = new _LogMessage(_LogType.error, message, stackTrace);
  }

  @override
  void printStatus(String message) {
    _emit();
    lastMessage = new _LogMessage(_LogType.status, message);
  }

  @override
  void printTrace(String message) {
    _emit();
    lastMessage = new _LogMessage(_LogType.trace, message);
  }

  @override
  Status startProgress(String message) {
    printStatus(message);
    return new Status();
  }

  @override
  void flush() => _emit();

  void _emit() {
    lastMessage?.emit();
    lastMessage = null;
  }
}

enum _LogType {
  error,
  status,
  trace
}

class _LogMessage {
  _LogMessage(this.type, this.message, [this.stackTrace]) {
    stopwatch.start();
  }

  final _LogType type;
  final String message;
  final StackTrace stackTrace;

  Stopwatch stopwatch = new Stopwatch();

  void emit() {
    stopwatch.stop();

    int millis = stopwatch.elapsedMilliseconds;
    String prefix = '${millis.toString().padLeft(4)} ms $_sep ';
    String indent = ''.padLeft(prefix.length);
    if (millis >= 100)
      prefix = _terminal.writeBold(prefix.substring(0, prefix.length - 3)) + ' $_sep ';
    String indentMessage = message.replaceAll('\n', '\n$indent');

    if (type == _LogType.error) {
      stderr.writeln(prefix + _terminal.writeBold(indentMessage));
      if (stackTrace != null)
        stderr.writeln(indent + stackTrace.toString().replaceAll('\n', '\n$indent'));
    } else if (type == _LogType.status) {
      print(prefix + _terminal.writeBold(indentMessage));
    } else {
      print(prefix + indentMessage);
    }
  }
}

class _AnsiTerminal {
  _AnsiTerminal() {
    // TODO(devoncarew): This detection does not work for Windows.
    String term = Platform.environment['TERM'];
    supportsColor = term != null && term != 'dumb';
  }

  static const String _bold = '\u001B[1m';
  static const String _reset = '\u001B[0m';

  bool supportsColor;

  String writeBold(String str) => supportsColor ? '$_bold$str$_reset' : str;
}

class _AnsiStatus extends Status {
  _AnsiStatus(this.message) {
    stopwatch = new Stopwatch()..start();

    stdout.write('${message.padRight(51)}     ');
    stdout.write('${_progress[0]}');

    timer = new Timer.periodic(new Duration(milliseconds: 100), _callback);
  }

  static final List<String> _progress = <String>['-', r'\', '|', r'/', '-', r'\', '|', '/'];

  final String message;
  Stopwatch stopwatch;
  Timer timer;
  int index = 1;
  bool live = true;

  void _callback(Timer timer) {
    stdout.write('\b${_progress[index]}');
    index = ++index % _progress.length;
  }

  @override
  void stop({ bool showElapsedTime: false }) {
    if (!live)
      return;
    live = false;

    if (showElapsedTime) {
      double seconds = stopwatch.elapsedMilliseconds / 1000.0;
      print('\b\b\b\b${seconds.toStringAsFixed(1)}s');
    } else {
      print('\b ');
    }

    timer.cancel();
  }

  @override
  void cancel() {
    if (!live)
      return;
    live = false;

    print('\b ');
    timer.cancel();
  }
}
