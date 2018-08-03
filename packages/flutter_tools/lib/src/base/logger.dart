// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter;

import 'package:meta/meta.dart';

import 'io.dart';
import 'terminal.dart';
import 'utils.dart';

const int kDefaultStatusPadding = 59;

typedef void VoidCallback();

abstract class Logger {
  bool get isVerbose => false;

  bool quiet = false;

  bool get supportsColor => terminal.supportsColor;
  set supportsColor(bool value) {
    terminal.supportsColor = value;
  }

  /// Display an error level message to the user. Commands should use this if they
  /// fail in some way.
  void printError(String message, { StackTrace stackTrace, bool emphasis = false });

  /// Display normal output of the command. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  void printStatus(
    String message,
    { bool emphasis = false, bool newline = true, String ansiAlternative, int indent }
  );

  /// Use this for verbose tracing output. Users can turn this output on in order
  /// to help diagnose issues with the toolchain or with their setup.
  void printTrace(String message);

  /// Start an indeterminate progress display.
  ///
  /// [message] is the message to display to the user; [progressId] provides an ID which can be
  /// used to identify this type of progress (`hot.reload`, `hot.restart`, ...).
  ///
  /// [progressIndicatorPadding] can optionally be used to specify spacing
  /// between the [message] and the progress indicator.
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  });
}

class StdoutLogger extends Logger {

  Status _status;

  @override
  bool get isVerbose => false;

  @override
  void printError(String message, { StackTrace stackTrace, bool emphasis = false }) {
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
    { bool emphasis = false, bool newline = true, String ansiAlternative, int indent }
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
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation = false,
    int progressIndicatorPadding = 59,
  }) {
    if (_status != null) {
      // Ignore nested progresses; return a no-op status object.
      return new Status(onFinish: _clearStatus)..start();
    }
    if (terminal.supportsColor) {
      _status = new AnsiStatus(
        message: message,
        expectSlowOperation: expectSlowOperation,
        padding: progressIndicatorPadding,
        onFinish: _clearStatus,
      )..start();
    } else {
      printStatus(message);
      _status = new Status(onFinish: _clearStatus)..start();
    }
    return _status;
  }

  void _clearStatus() {
    _status = null;
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
    // TODO(jcollins-g): wrong abstraction layer for this, move to [Stdio].
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
  void printError(String message, { StackTrace stackTrace, bool emphasis = false }) {
    _error.writeln(message);
  }

  @override
  void printStatus(
    String message,
    { bool emphasis = false, bool newline = true, String ansiAlternative, int indent }
  ) {
    if (newline)
      _status.writeln(message);
    else
      _status.write(message);
  }

  @override
  void printTrace(String message) => _trace.writeln(message);

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    printStatus(message);
    return new Status()..start();
  }

  /// Clears all buffers.
  void clear() {
    _error.clear();
    _status.clear();
    _trace.clear();
  }
}

class VerboseLogger extends Logger {
  VerboseLogger(this.parent)
    : assert(terminal != null) {
    stopwatch.start();
  }

  final Logger parent;

  Stopwatch stopwatch = new Stopwatch();

  @override
  bool get isVerbose => true;

  @override
  void printError(String message, { StackTrace stackTrace, bool emphasis = false }) {
    _emit(_LogType.error, message, stackTrace);
  }

  @override
  void printStatus(
    String message,
    { bool emphasis = false, bool newline = true, String ansiAlternative, int indent }
  ) {
    _emit(_LogType.status, message);
  }

  @override
  void printTrace(String message) {
    _emit(_LogType.trace, message);
  }

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    printStatus(message);
    return new Status(onFinish: () {
      printTrace('$message (completed)');
    })..start();
  }

  void _emit(_LogType type, String message, [StackTrace stackTrace]) {
    if (message.trim().isEmpty)
      return;

    final int millis = stopwatch.elapsedMilliseconds;
    stopwatch.reset();

    String prefix;
    const int prefixWidth = 8;
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

/// A [Status] class begins when start is called, and may produce progress
/// information asynchronously.
///
/// The [Status] class itself never has any output.
///
/// The [AnsiSpinner] subclass shows a spinner, and replaces it with a single
/// space character when stopped or canceled.
///
/// The [AnsiStatus] subclass shows a spinner, and replaces it with timing
/// information when stopped. When canceled, the information isn't shown. In
/// either case, a newline is printed.
///
/// Generally, consider `logger.startProgress` instead of directly creating
/// a [Status] or one of its subclasses.
class Status {
  Status({ this.onFinish });

  /// A straight [Status] or an [AnsiSpinner] (depending on whether the
  /// terminal is fancy enough), already started.
  factory Status.withSpinner({ VoidCallback onFinish }) {
    if (terminal.supportsColor)
      return new AnsiSpinner(onFinish: onFinish)..start();
    return new Status(onFinish: onFinish)..start();
  }

  final VoidCallback onFinish;

  bool _isStarted = false;

  /// Call to start spinning.
  void start() {
    assert(!_isStarted);
    _isStarted = true;
  }

  /// Call to stop spinning after success.
  void stop() {
    assert(_isStarted);
    _isStarted = false;
    if (onFinish != null)
      onFinish();
  }

  /// Call to cancel the spinner after failure or cancelation.
  void cancel() {
    assert(_isStarted);
    _isStarted = false;
    if (onFinish != null)
      onFinish();
  }
}

/// An [AnsiSpinner] is a simple animation that does nothing but implement an
/// ASCII spinner. When stopped or canceled, the animation erases itself.
class AnsiSpinner extends Status {
  AnsiSpinner({ VoidCallback onFinish }) : super(onFinish: onFinish);

  int ticks = 0;
  Timer timer;

  static final List<String> _progress = <String>[r'-', r'\', r'|', r'/'];

  void _callback(Timer timer) {
    stdout.write('\b${_progress[ticks++ % _progress.length]}');
  }

  @override
  void start() {
    super.start();
    assert(timer == null);
    stdout.write(' ');
    timer = new Timer.periodic(const Duration(milliseconds: 100), _callback);
    _callback(timer);
  }

  @override
  void stop() {
    assert(timer.isActive);
    timer.cancel();
    stdout.write('\b \b');
    super.stop();
  }

  @override
  void cancel() {
    assert(timer.isActive);
    timer.cancel();
    stdout.write('\b \b');
    super.cancel();
  }
}

/// Constructor writes [message] to [stdout] with padding, then starts as an
/// [AnsiSpinner].  On [cancel] or [stop], will call [onFinish].
/// On [stop], will additionally print out summary information in
/// milliseconds if [expectSlowOperation] is false, as seconds otherwise.
class AnsiStatus extends AnsiSpinner {
  AnsiStatus({
    this.message,
    this.expectSlowOperation,
    this.padding,
    VoidCallback onFinish,
  }) : super(onFinish: onFinish);

  final String message;
  final bool expectSlowOperation;
  final int padding;

  Stopwatch stopwatch;

  @override
  void start() {
    stopwatch = new Stopwatch()..start();
    stdout.write('${message.padRight(padding)}     ');
    super.start();
  }

  @override
  void stop() {
    super.stop();
    writeSummaryInformation();
    stdout.write('\n');
  }

  @override
  void cancel() {
    super.cancel();
    stdout.write('\n');
  }

  /// Backs up 4 characters and prints a (minimum) 5 character padded time.  If
  /// [expectSlowOperation] is true, the time is in seconds; otherwise,
  /// milliseconds.  Only backs up 4 characters because [super.cancel] backs
  /// up one.
  ///
  /// Example: '\b\b\b\b 0.5s', '\b\b\b\b150ms', '\b\b\b\b1600ms'
  void writeSummaryInformation() {
    if (expectSlowOperation) {
      stdout.write('\b\b\b\b${getElapsedAsSeconds(stopwatch.elapsed).padLeft(5)}');
    } else {
      stdout.write('\b\b\b\b${getElapsedAsMilliseconds(stopwatch.elapsed).padLeft(5)}');
    }
  }
}
