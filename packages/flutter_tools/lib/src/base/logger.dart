// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'io.dart';
import 'platform.dart';
import 'terminal.dart';
import 'utils.dart';

const int kDefaultStatusPadding = 59;

typedef VoidCallback = void Function();

abstract class Logger {
  bool get isVerbose => false;

  bool quiet = false;

  bool get supportsColor => terminal.supportsColor;

  bool get hasTerminal => stdio.hasTerminal;

  /// Display an error [message] to the user. Commands should use this if they
  /// fail in some way.
  ///
  /// The [message] argument is printed to the stderr in red by default.
  /// The [stackTrace] argument is the stack trace that will be printed if
  /// supplied.
  /// The [emphasis] argument will cause the output message be printed in bold text.
  /// The [color] argument will print the message in the supplied color instead
  /// of the default of red. Colors will not be printed if the output terminal
  /// doesn't support them.
  /// The [indent] argument specifies the number of spaces to indent the overall
  /// message. If wrapping is enabled in [outputPreferences], then the wrapped
  /// lines will be indented as well.
  /// If [hangingIndent] is specified, then any wrapped lines will be indented
  /// by this much more than the first line, if wrapping is enabled in
  /// [outputPreferences].
  /// If [wrap] is specified, then it overrides the
  /// [outputPreferences.wrapText] setting.
  void printError(
    String message, {
    StackTrace stackTrace,
    bool emphasis,
    TerminalColor color,
    int indent,
    int hangingIndent,
    bool wrap,
  });

  /// Display normal output of the command. This should be used for things like
  /// progress messages, success messages, or just normal command output.
  ///
  /// The [message] argument is printed to the stderr in red by default.
  /// The [stackTrace] argument is the stack trace that will be printed if
  /// supplied.
  /// If the [emphasis] argument is true, it will cause the output message be
  /// printed in bold text. Defaults to false.
  /// The [color] argument will print the message in the supplied color instead
  /// of the default of red. Colors will not be printed if the output terminal
  /// doesn't support them.
  /// If [newline] is true, then a newline will be added after printing the
  /// status. Defaults to true.
  /// The [indent] argument specifies the number of spaces to indent the overall
  /// message. If wrapping is enabled in [outputPreferences], then the wrapped
  /// lines will be indented as well.
  /// If [hangingIndent] is specified, then any wrapped lines will be indented
  /// by this much more than the first line, if wrapping is enabled in
  /// [outputPreferences].
  /// If [wrap] is specified, then it overrides the
  /// [outputPreferences.wrapText] setting.
  void printStatus(
    String message, {
    bool emphasis,
    TerminalColor color,
    bool newline,
    int indent,
    int hangingIndent,
    bool wrap,
  });

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
    bool expectSlowOperation,
    bool multilineOutput,
    int progressIndicatorPadding,
  });
}

class StdoutLogger extends Logger {
  Status _status;

  @override
  bool get isVerbose => false;

  @override
  void printError(
    String message, {
    StackTrace stackTrace,
    bool emphasis,
    TerminalColor color,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    message ??= '';
    message = wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap);
    _status?.cancel();
    _status = null;
    if (emphasis == true)
      message = terminal.bolden(message);
    message = terminal.color(message, color ?? TerminalColor.red);
    stderr.writeln(message);
    if (stackTrace != null) {
      stderr.writeln(stackTrace.toString());
    }
  }

  @override
  void printStatus(
    String message, {
    bool emphasis,
    TerminalColor color,
    bool newline,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    message ??= '';
    message = wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap);
    _status?.cancel();
    _status = null;
    if (emphasis == true)
      message = terminal.bolden(message);
    if (color != null)
      message = terminal.color(message, color);
    if (newline != false)
      message = '$message\n';
    writeToStdOut(message);
  }

  @protected
  void writeToStdOut(String message) {
    stdout.write(message);
  }

  @override
  void printTrace(String message) {}

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation,
    bool multilineOutput,
    int progressIndicatorPadding,
  }) {
    expectSlowOperation ??= false;
    progressIndicatorPadding ??= kDefaultStatusPadding;
    if (_status != null) {
      // Ignore nested progresses; return a no-op status object.
      return Status(onFinish: _clearStatus)..start();
    }
    if (terminal.supportsColor) {
      _status = AnsiStatus(
        message: message,
        expectSlowOperation: expectSlowOperation,
        multilineOutput: multilineOutput,
        padding: progressIndicatorPadding,
        onFinish: _clearStatus,
      )..start();
    } else {
      _status = SummaryStatus(
        message: message,
        expectSlowOperation: expectSlowOperation,
        padding: progressIndicatorPadding,
        onFinish: _clearStatus,
      )..start();
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

  final StringBuffer _error = StringBuffer();
  final StringBuffer _status = StringBuffer();
  final StringBuffer _trace = StringBuffer();

  String get errorText => _error.toString();
  String get statusText => _status.toString();
  String get traceText => _trace.toString();

  @override
  void printError(
    String message, {
    StackTrace stackTrace,
    bool emphasis,
    TerminalColor color,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _error.writeln(terminal.color(
      wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap),
      color ?? TerminalColor.red,
    ));
  }

  @override
  void printStatus(
    String message, {
    bool emphasis,
    TerminalColor color,
    bool newline,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    if (newline != false)
      _status.writeln(wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap));
    else
      _status.write(wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap));
  }

  @override
  void printTrace(String message) => _trace.writeln(message);

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation,
    bool multilineOutput,
    int progressIndicatorPadding,
  }) {
    printStatus(message);
    return Status()..start();
  }

  /// Clears all buffers.
  void clear() {
    _error.clear();
    _status.clear();
    _trace.clear();
  }
}

class VerboseLogger extends Logger {
  VerboseLogger(this.parent) : assert(terminal != null) {
    stopwatch.start();
  }

  final Logger parent;

  Stopwatch stopwatch = Stopwatch();

  @override
  bool get isVerbose => true;

  @override
  void printError(
    String message, {
    StackTrace stackTrace,
    bool emphasis,
    TerminalColor color,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _emit(
      _LogType.error,
      wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap),
      stackTrace,
    );
  }

  @override
  void printStatus(
    String message, {
    bool emphasis,
    TerminalColor color,
    bool newline,
    int indent,
    int hangingIndent,
    bool wrap,
  }) {
    _emit(_LogType.status, wrapText(message, indent: indent, hangingIndent: hangingIndent, shouldWrap: wrap));
  }

  @override
  void printTrace(String message) {
    _emit(_LogType.trace, message);
  }

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool expectSlowOperation,
    bool multilineOutput,
    int progressIndicatorPadding,
  }) {
    printStatus(message);
    return Status(onFinish: () {
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

enum _LogType { error, status, trace }

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
  Status({this.onFinish});

  /// A straight [Status] or an [AnsiSpinner] (depending on whether the
  /// terminal is fancy enough), already started.
  factory Status.withSpinner({ VoidCallback onFinish }) {
    if (terminal.supportsColor)
      return AnsiSpinner(onFinish: onFinish)..start();
    return Status(onFinish: onFinish)..start();
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

  /// Call to cancel the spinner after failure or cancellation.
  void cancel() {
    assert(_isStarted);
    _isStarted = false;
    if (onFinish != null)
      onFinish();
  }
}

/// An [AnsiSpinner] is a simple animation that does nothing but implement a
/// ASCII/Unicode spinner. When stopped or canceled, the animation erases
/// itself.
class AnsiSpinner extends Status {
  AnsiSpinner({VoidCallback onFinish}) : super(onFinish: onFinish);

  int ticks = 0;
  Timer timer;

  // Windows console font has a limited set of Unicode characters.
  List<String> get _animation => platform.isWindows
      ? <String>[r'-', r'\', r'|', r'/']
      : <String>['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];

  String get _backspace => '\b' * _animation[0].length;
  String get _clear => ' ' *  _animation[0].length;

  void _callback(Timer timer) {
    stdout.write('$_backspace${_animation[ticks++ % _animation.length]}');
  }

  @override
  void start() {
    super.start();
    assert(timer == null);
    stdout.write(' ');
    timer = Timer.periodic(const Duration(milliseconds: 100), _callback);
    _callback(timer);
  }

  @override
  void stop() {
    assert(timer.isActive);
    timer.cancel();
    stdout.write('$_backspace$_clear$_backspace');
    super.stop();
  }

  @override
  void cancel() {
    assert(timer.isActive);
    timer.cancel();
    stdout.write('$_backspace$_clear$_backspace');
    super.cancel();
  }
}

/// Constructor writes [message] to [stdout] with padding, then starts as an
/// [AnsiSpinner].  On [cancel] or [stop], will call [onFinish].
/// On [stop], will additionally print out summary information in
/// milliseconds if [expectSlowOperation] is false, as seconds otherwise.
class AnsiStatus extends AnsiSpinner {
  AnsiStatus({
    String message,
    bool expectSlowOperation,
    bool multilineOutput,
    int padding,
    VoidCallback onFinish,
  })  : message = message ?? '',
        padding = padding ?? 0,
        expectSlowOperation = expectSlowOperation ?? false,
        multilineOutput = multilineOutput ?? false,
        super(onFinish: onFinish);

  final String message;
  final bool expectSlowOperation;
  final bool multilineOutput;
  final int padding;

  Stopwatch stopwatch;

  static const String _margin = '     ';

  @override
  void start() {
    assert(stopwatch == null || !stopwatch.isRunning);
    stopwatch = Stopwatch()..start();
    stdout.write('${message.padRight(padding)}$_margin');
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

  /// Print summary information when a task is done.
  ///
  /// If [multilineOutput] is false, backs up 4 characters and prints a
  /// (minimum) 5 character padded time. If [expectSlowOperation] is true, the
  /// time is in seconds; otherwise, milliseconds. Only backs up 4 characters
  /// because [super.cancel] backs up one.
  ///
  /// If [multilineOutput] is true, then it prints the message again on a new
  /// line before writing the elapsed time, and doesn't back up at all.
  void writeSummaryInformation() {
    final String prefix = multilineOutput
        ? '\n${'$message Done'.padRight(padding - 4)}$_margin'
        : '\b\b\b\b';
    if (expectSlowOperation) {
      stdout.write('$prefix${getElapsedAsSeconds(stopwatch.elapsed).padLeft(5)}');
    } else {
      stdout.write('$prefix${getElapsedAsMilliseconds(stopwatch.elapsed).padLeft(5)}');
    }
  }
}

/// Constructor writes [message] to [stdout].  On [cancel] or [stop], will call
/// [onFinish]. On [stop], will additionally print out summary information in
/// milliseconds if [expectSlowOperation] is false, as seconds otherwise.
class SummaryStatus extends Status {
  SummaryStatus({
    String message,
    bool expectSlowOperation,
    int padding,
    VoidCallback onFinish,
  })  : message = message ?? '',
        padding = padding ?? 0,
        expectSlowOperation = expectSlowOperation ?? false,
        super(onFinish: onFinish);

  final String message;
  final bool expectSlowOperation;
  final int padding;

  Stopwatch stopwatch;

  @override
  void start() {
    stopwatch = Stopwatch()..start();
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

  /// Prints a (minimum) 5 character padded time.  If [expectSlowOperation] is
  /// true, the time is in seconds; otherwise, milliseconds.
  ///
  /// Example: ' 0.5s', '150ms', '1600ms'
  void writeSummaryInformation() {
    if (expectSlowOperation) {
      stdout.write(getElapsedAsSeconds(stopwatch.elapsed).padLeft(5));
    } else {
      stdout.write(getElapsedAsMilliseconds(stopwatch.elapsed).padLeft(5));
    }
  }
}
