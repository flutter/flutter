// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show UTF8;
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

final AnsiTerminal terminal = new AnsiTerminal();

/// The Hider class is used to inform an active command line when
/// logging is occuring so that it can hide the status line and then
/// show it.  This is used to implement command lines and status
/// lines.
abstract class Hider {
  void hide();
  void show();
}

abstract class Logger {
  bool get isVerbose => false;

  bool quiet = false;

  bool get supportsColor => terminal.supportsColor;
  set supportsColor(bool value) {
    terminal.supportsColor = value;
  }

  /// Display an error level message to the user. Commands should use this if they
  /// fail in some way.
  void printError(String message, [StackTrace stackTrace]);

  /// Display normal output. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  void printStatus(String message,
                   { bool emphasis: false, bool newline: true }) {
    hideStatusLine();
    printRaw(message, emphasis: emphasis, newline: newline);
    showStatusLine();
  }

  /// Display output without saving the status line.  Most people will
  /// not call this directly.
  void printRaw(String message, { bool emphasis: false, bool newline: true });

  /// Use this for verbose tracing output. Users can turn this output on in order
  /// to help diagnose issues with the toolchain or with their setup.
  void printTrace(String message);

  /// Flush any buffered output.
  void flush() { }

  Hider commandLine;
  Status _activeStatus;

  /// Overridein subclasses to implement progress reports.
  Status newProgress(String message) {
    return new DumbStatus(this, message);
  }

  Status startProgress(String message) {
    assert(_activeStatus == null);
    commandLine?.hide();
    _activeStatus = newProgress(message);
    _activeStatus.start();

    return _activeStatus;
  }

  void stopProgress() {
    _activeStatus = null;
    commandLine?.show();
  }

  void hideStatusLine() {
    if (_activeStatus != null) {
      _activeStatus?.hide();
    } else {
      commandLine?.hide();
    }
  }

  void showStatusLine() {
    if (_activeStatus != null) {
      _activeStatus?.show();
    } else {
      commandLine?.show();
    }
  }
}

abstract class Status implements Hider {
  Status(this.logger);

  final Logger logger;

  bool _done = false;
  bool get done => _done;

  bool _canceled = false;
  bool get canceled => _canceled;

  int ticks = 0;
  Timer _timer;

  // Overridden in subclasses.
  @override
  void hide() {}

  @override
  void show() {}

  void refresh();

  void start() {
    refresh();
    _timer = new Timer.periodic(new Duration(milliseconds: 100),
                                _timerCallback);
  }

  void _timerCallback(Timer timer) {
    ticks++;
    refresh();
  }

  void stop() {
    if (_done)
      return;
    _done = true;
    refresh();
    _timer.cancel();
    logger.stopProgress();
  }

  void cancel() {
    if (_done)
      return;
    _done = true;
    _canceled = true;
    refresh();
    _timer.cancel();
    logger.stopProgress();
  }
}

class StdoutLogger extends Logger {
  @override
  bool get isVerbose => false;

  @override
  void printError(String message, [StackTrace stackTrace]) {
    hideStatusLine();
    stderr.writeln(message);
    if (stackTrace != null)
      stderr.writeln(new Chain.forTrace(stackTrace).terse.toString());

    showStatusLine();
  }

  @override
  void printRaw(String message, { bool emphasis: false, bool newline: true }) {
    if (newline)
      stdout.writeln(emphasis ? terminal.toBold(message) : message);
    else
      stdout.write(emphasis ? terminal.toBold(message) : message);
  }

  @override
  void printStatus(String message, { bool emphasis: false, bool newline: true }) {
    hideStatusLine();
    printRaw(message, emphasis: emphasis, newline: newline);
    showStatusLine();
  }

  @override
  void printTrace(String message) { }

  @override
  Status newProgress(String message) {
    if (supportsColor) {
      return new _AnsiStatus(this, message);
    } else {
      return new DumbStatus(this, message);
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
  void printRaw(String message, { bool emphasis: false, bool newline: true }) {
    if (newline)
      _status.writeln(message);
    else
      _status.write(message);
  }

  @override
  void printStatus(String message, { bool emphasis: false, bool newline: true }) {
    printRaw(message, emphasis: emphasis, newline: newline);
  }

  @override
  void printTrace(String message) => _trace.writeln(message);

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
  void printRaw(String message, { bool emphasis: false, bool newline: true }) {
    // TODO(ianh): We ignore newline and emphasis here.
    _emit();
    lastMessage = new _LogMessage(_LogType.status, message);
  }

  @override
  void printStatus(String message, { bool emphasis: false, bool newline: true }) {
    printRaw(message, emphasis: emphasis, newline: newline);
  }

  @override
  void printTrace(String message) {
    _emit();
    lastMessage = new _LogMessage(_LogType.trace, message);
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
    String prefix = '${millis.toString().padLeft(4)} ms • ';
    String indent = ''.padLeft(prefix.length);
    if (millis >= 100)
      prefix = terminal.toBold(prefix.substring(0, prefix.length - 3)) + ' • ';
    String indentMessage = message.replaceAll('\n', '\n$indent');

    if (type == _LogType.error) {
      stderr.writeln(prefix + terminal.toBold(indentMessage));
      if (stackTrace != null)
        stderr.writeln(indent + stackTrace.toString().replaceAll('\n', '\n$indent'));
    } else if (type == _LogType.status) {
      print(prefix + terminal.toBold(indentMessage));
    } else {
      print(prefix + indentMessage);
    }
  }
}

String _tputGetSequence(String capName, { String orElse }) {
  if (AnsiTerminal._testMode)
    return '[$capName]';

  if (Platform.isWindows)
    return orElse;

  ProcessResult result =
      Process.runSync('tput',  <String>['$capName'], stdoutEncoding:UTF8);
  if (result.exitCode != 0)
    return orElse;

  return result.stdout;
}

class AnsiTerminal {
  AnsiTerminal() {
    // TODO(devoncarew): This detection does not work for Windows.
    String term = Platform.environment['TERM'];
    // TODO(turnidge): Switch users of 'supportsColor' to 'isDumb' instead.
    supportsColor = term != null && term != 'dumb';
  }

  // Used during development to see all special characters in output.
  static final bool _testMode = false;

  bool get isDumb {
    return (cursorBack == null ||
            cursorForward == null ||
            cursorUp == null ||
            cursorDown == null ||
            clearEOL == null ||
            clearScreen == null);
  }

  // Function keys.
  final String keyF1  = _tputGetSequence('kf1',  orElse: '\u001BOP');
  final String keyF5  = _tputGetSequence('kf5',  orElse: '\u001B[15~');
  final String keyF6  = _tputGetSequence('kf6',  orElse: '\u001B[17~');
  final String keyF10 = _tputGetSequence('kf10', orElse: '\u001B[21~');

  // Back one character.
  final String cursorBack = _tputGetSequence('cub1');

  // Forward one character.
  final String cursorForward = _tputGetSequence('cuf1');

  // Up one character.
  final String cursorUp = _tputGetSequence('cuu1');

  // Down one character.
  final String cursorDown = _tputGetSequence('cud1');

  // Clear to end of line.
  final String clearEOL = _tputGetSequence('el');

  // Clear screen and home cursor.
  final String clearScreen = _tputGetSequence('clear', orElse: '\n\n');

  // Enter bold text mode.
  final String boldText = _tputGetSequence('bold', orElse: '');

  // Exit text attributes.
  final String resetText = _tputGetSequence('sgr0', orElse: '');

  int get cols => stdout.terminalColumns;

  bool supportsColor;

  // Convenience method for bolding text.
  String toBold(String str) => '$boldText$str$resetText';
}

class _AnsiStatus extends Status {
  _AnsiStatus(Logger logger, this.message) : super(logger) {
    stopwatch = new Stopwatch()..start();
  }

  static final List<String> _progress =
      <String>['-', r'\', '|', r'/', '-', r'\', '|', '/'];

  final String message;
  Stopwatch stopwatch;
  String _currentLine;
  bool _shown = true;

  void _hide() {
    if (!_shown)
      return;

    _shown = false;
    if (_currentLine != null) {
      for (int i = 0; i < _currentLine.length; i += 1) {
        stdout.write(terminal.cursorBack);
      }
    }
  }

  void _show() {
    if (_shown)
      return;

    _shown = true;
    if (done) {
      double seconds = stopwatch.elapsedMilliseconds / 1000.0;
      String secondsStr = seconds.toStringAsFixed(1);
      String canceledStr = canceled ? ' [canceled]' : '';
      _currentLine =
          '${message.padRight(51)}     ${secondsStr}s$canceledStr\n';
    } else {
      int index = ticks % _progress.length;
      _currentLine = '${message.padRight(51)}     ${_progress[index]}';
    }
    stdout.write(_currentLine);
  }

  @override
  void hide() {
    _hide();
  }

  @override
  void show() {
    _show();
  }

  @override
  void refresh() {
    if (!_shown)
      return;

    _hide();
    _show();
  }
}

class DumbStatus extends Status {
  DumbStatus(Logger logger, this.message) : super(logger) {
    stopwatch = new Stopwatch()..start();
  }

  final String message;
  Stopwatch stopwatch;

  bool _first = true;
  bool _shown = true;

  void _writeSeconds() {
    double seconds = stopwatch.elapsedMilliseconds / 1000.0;
    String secondsStr = seconds.toStringAsFixed(1);
    String canceledStr = canceled ? ' [canceled]' : '';
    logger.printRaw(' ${secondsStr}s$canceledStr',
                    newline: true);
  }

  void _write() {
    logger.printRaw('${message.padRight(51)}     ',
                    newline: false);
    if (done)
      _writeSeconds();
  }

  void _update() {
    if (done)
      _writeSeconds();
  }

  @override
  void hide() {
    if (!_shown)
      return;

    _shown = false;

    // Give the log message a fresh line.
    logger.printRaw('', newline: true);
  }

  @override
  void show() {
    _shown = true;

    // Rewrite the entire status line.
    _write();
  }

  @override
  void refresh() {
    if (!_shown)
      return;

    if (_first) {
      _first = false;
      _write();
    } else {
      _update();
    }
  }
}

class NullStatus extends Status {
  NullStatus(Logger logger) : super(logger);

  @override
  void refresh() {}
}
