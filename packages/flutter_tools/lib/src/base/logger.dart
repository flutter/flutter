// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter;

import 'package:meta/meta.dart';

import 'io.dart';
import 'terminal.dart';
import 'utils.dart';

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
    assert(terminal != null);
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
