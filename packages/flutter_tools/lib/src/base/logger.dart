// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:meta/meta.dart';

import '../convert.dart';
import '../globals.dart' as globals;
import 'io.dart';
import 'terminal.dart' show AnsiTerminal, Terminal, TerminalColor, OutputPreferences;
import 'utils.dart';

const int kDefaultStatusPadding = 59;

/// A factory for generating [Stopwatch] instances for [Status] instances.
class StopwatchFactory {
  /// const constructor so that subclasses may be const.
  const StopwatchFactory();

  /// Create a new [Stopwatch] instance.
  Stopwatch createStopwatch() => Stopwatch();
}

typedef VoidCallback = void Function();

abstract class Logger {
  bool get isVerbose => false;

  bool quiet = false;

  bool get supportsColor;

  bool get hasTerminal;

  Terminal get _terminal;

  OutputPreferences get _outputPreferences;

  /// Display an error `message` to the user. Commands should use this if they
  /// fail in some way.
  ///
  /// The `message` argument is printed to the stderr in red by default.
  ///
  /// The `stackTrace` argument is the stack trace that will be printed if
  /// supplied.
  ///
  /// The `emphasis` argument will cause the output message be printed in bold text.
  ///
  /// The `color` argument will print the message in the supplied color instead
  /// of the default of red. Colors will not be printed if the output terminal
  /// doesn't support them.
  ///
  /// The `indent` argument specifies the number of spaces to indent the overall
  /// message. If wrapping is enabled in [outputPreferences], then the wrapped
  /// lines will be indented as well.
  ///
  /// If `hangingIndent` is specified, then any wrapped lines will be indented
  /// by this much more than the first line, if wrapping is enabled in
  /// [outputPreferences].
  ///
  /// If `wrap` is specified, then it overrides the
  /// `outputPreferences.wrapText` setting.
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
  /// The `message` argument is printed to the stderr in red by default.
  ///
  /// The `stackTrace` argument is the stack trace that will be printed if
  /// supplied.
  ///
  /// If the `emphasis` argument is true, it will cause the output message be
  /// printed in bold text. Defaults to false.
  ///
  /// The `color` argument will print the message in the supplied color instead
  /// of the default of red. Colors will not be printed if the output terminal
  /// doesn't support them.
  ///
  /// If `newline` is true, then a newline will be added after printing the
  /// status. Defaults to true.
  ///
  /// The `indent` argument specifies the number of spaces to indent the overall
  /// message. If wrapping is enabled in [outputPreferences], then the wrapped
  /// lines will be indented as well.
  ///
  /// If `hangingIndent` is specified, then any wrapped lines will be indented
  /// by this much more than the first line, if wrapping is enabled in
  /// [outputPreferences].
  ///
  /// If `wrap` is specified, then it overrides the
  /// `outputPreferences.wrapText` setting.
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
  /// The `message` argument is the message to display to the user.
  ///
  /// The `progressId` argument provides an ID that can be used to identify
  /// this type of progress (e.g. `hot.reload`, `hot.restart`).
  ///
  /// The `progressIndicatorPadding` can optionally be used to specify spacing
  /// between the `message` and the progress indicator, if any.
  Status startProgress(
    String message, {
    String progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  });

  /// Send an event to be emitted.
  ///
  /// Only surfaces a value in machine modes, Loggers may ignore this message in
  /// non-machine modes.
  void sendEvent(String name, [Map<String, dynamic> args]) { }

  /// Clears all output.
  void clear();
}

/// A [Logger] that forwards all methods to another one.
///
/// Classes can derive from this to add functionality to an existing [Logger].
class DelegatingLogger implements Logger {
  @visibleForTesting
  @protected
  DelegatingLogger(this._delegate);

  final Logger _delegate;

  @override
  bool get quiet => _delegate.quiet;

  @override
  set quiet(bool value) => _delegate.quiet = value;

  @override
  bool get hasTerminal => _delegate.hasTerminal;

  @override
  Terminal get _terminal => _delegate._terminal;

  @override
  OutputPreferences get _outputPreferences => _delegate._outputPreferences;

  @override
  bool get isVerbose => _delegate.isVerbose;

  @override
  void printError(String message, {StackTrace stackTrace, bool emphasis, TerminalColor color, int indent, int hangingIndent, bool wrap}) {
    _delegate.printError(
      message,
      stackTrace: stackTrace,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printStatus(String message, {bool emphasis, TerminalColor color, bool newline, int indent, int hangingIndent, bool wrap}) {
    _delegate.printStatus(message,
      emphasis: emphasis,
      color: color,
      newline: newline,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }

  @override
  void printTrace(String message) {
    _delegate.printTrace(message);
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) {
    _delegate.sendEvent(name, args);
  }

  @override
  Status startProgress(String message, {String progressId, bool multilineOutput = false, int progressIndicatorPadding = kDefaultStatusPadding}) {
    return _delegate.startProgress(message,
      progressId: progressId,
      multilineOutput: multilineOutput,
      progressIndicatorPadding: progressIndicatorPadding,
    );
  }

  @override
  bool get supportsColor => _delegate.supportsColor;

  @override
  void clear() => _delegate.clear();
}

/// If [logger] is a [DelegatingLogger], walks the delegate chain and returns
/// the first delegate with the matching type.
///
/// Throws a [StateError] if no matching delegate is found.
@override
T asLogger<T extends Logger>(Logger logger) {
  final Logger original = logger;
  while (true) {
    if (logger is T) {
      return logger;
    } else if (logger is DelegatingLogger) {
      logger = (logger as DelegatingLogger)._delegate;
    } else {
      throw StateError('$original has no ancestor delegate of type $T');
    }
  }
}

class StdoutLogger extends Logger {
  StdoutLogger({
    @required Terminal terminal,
    @required Stdio stdio,
    @required OutputPreferences outputPreferences,
    StopwatchFactory stopwatchFactory = const StopwatchFactory(),
  })
    : _stdio = stdio,
      _terminal = terminal,
      _outputPreferences = outputPreferences,
      _stopwatchFactory = stopwatchFactory;

  @override
  final Terminal _terminal;
  @override
  final OutputPreferences _outputPreferences;
  final Stdio _stdio;
  final StopwatchFactory _stopwatchFactory;

  Status _status;

  @override
  bool get isVerbose => false;

  @override
  bool get supportsColor => _terminal.supportsColor;

  @override
  bool get hasTerminal => _stdio.stdinHasTerminal;

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
    _status?.pause();
    message ??= '';
    message = wrapText(message,
      indent: indent,
      hangingIndent: hangingIndent,
      shouldWrap: wrap ?? _outputPreferences.wrapText,
      columnWidth: _outputPreferences.wrapColumn,
    );
    if (emphasis == true) {
      message = _terminal.bolden(message);
    }
    message = _terminal.color(message, color ?? TerminalColor.red);
    writeToStdErr('$message\n');
    if (stackTrace != null) {
      writeToStdErr('$stackTrace\n');
    }
    _status?.resume();
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
    _status?.pause();
    message ??= '';
    message = wrapText(message,
      indent: indent,
      hangingIndent: hangingIndent,
      shouldWrap: wrap ?? _outputPreferences.wrapText,
      columnWidth: _outputPreferences.wrapColumn,
    );
    if (emphasis == true) {
      message = _terminal.bolden(message);
    }
    if (color != null) {
      message = _terminal.color(message, color);
    }
    if (newline != false) {
      message = '$message\n';
    }
    writeToStdOut(message);
    _status?.resume();
  }

  @protected
  void writeToStdOut(String message) => _stdio.stdoutWrite(message);

  @protected
  void writeToStdErr(String message) => _stdio.stderrWrite(message);

  @override
  void printTrace(String message) { }

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    assert(progressIndicatorPadding != null);
    if (_status != null) {
      // Ignore nested progresses; return a no-op status object.
      return SilentStatus(
        onFinish: _clearStatus,
        stopwatch: _stopwatchFactory.createStopwatch(),
      )..start();
    }
    if (supportsColor) {
      _status = AnsiStatus(
        message: message,
        multilineOutput: multilineOutput,
        padding: progressIndicatorPadding,
        onFinish: _clearStatus,
        stdio: _stdio,
        stopwatch: _stopwatchFactory.createStopwatch(),
        terminal: _terminal,
      )..start();
    } else {
      _status = SummaryStatus(
        message: message,
        padding: progressIndicatorPadding,
        onFinish: _clearStatus,
        stdio: _stdio,
        stopwatch: _stopwatchFactory.createStopwatch(),
      )..start();
    }
    return _status;
  }

  void _clearStatus() {
    _status = null;
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) { }

  @override
  void clear() {
    _status?.pause();
    writeToStdOut(_terminal.clearScreen() + '\n');
    _status?.resume();
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
  WindowsStdoutLogger({
    @required Terminal terminal,
    @required Stdio stdio,
    @required OutputPreferences outputPreferences,
    StopwatchFactory stopwatchFactory = const StopwatchFactory(),
  }) : super(
      terminal: terminal,
      stdio: stdio,
      outputPreferences: outputPreferences,
      stopwatchFactory: stopwatchFactory,
    );

  @override
  void writeToStdOut(String message) {
    final String windowsMessage = _terminal.supportsEmoji
      ? message
      : message.replaceAll('🔥', '')
               .replaceAll('🖼️', '')
               .replaceAll('✗', 'X')
               .replaceAll('✓', '√')
               .replaceAll('🔨', '')
               .replaceAll('💪', '')
               .replaceAll('✏️', '');
    _stdio.stdoutWrite(windowsMessage);
  }
}

class BufferLogger extends Logger {
  BufferLogger({
    @required AnsiTerminal terminal,
    @required OutputPreferences outputPreferences,
    StopwatchFactory stopwatchFactory = const StopwatchFactory(),
  }) : _outputPreferences = outputPreferences,
       _terminal = terminal,
       _stopwatchFactory = stopwatchFactory;

  /// Create a [BufferLogger] with test preferences.
  BufferLogger.test({
    Terminal terminal,
    OutputPreferences outputPreferences,
  }) : _terminal = terminal ?? Terminal.test(),
       _outputPreferences = outputPreferences ?? OutputPreferences.test(),
       _stopwatchFactory = const StopwatchFactory();


  @override
  final OutputPreferences _outputPreferences;

  @override
  final Terminal _terminal;

  final StopwatchFactory _stopwatchFactory;

  @override
  bool get isVerbose => false;

  @override
  bool get supportsColor => _terminal.supportsColor;

  final StringBuffer _error = StringBuffer();
  final StringBuffer _status = StringBuffer();
  final StringBuffer _trace = StringBuffer();
  final StringBuffer _events = StringBuffer();

  String get errorText => _error.toString();
  String get statusText => _status.toString();
  String get traceText => _trace.toString();
  String get eventText => _events.toString();

  @override
  bool get hasTerminal => false;

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
    _error.writeln(_terminal.color(
      wrapText(message,
        indent: indent,
        hangingIndent: hangingIndent,
        shouldWrap: wrap ?? _outputPreferences.wrapText,
        columnWidth: _outputPreferences.wrapColumn,
      ),
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
    if (newline != false) {
      _status.writeln(wrapText(message,
        indent: indent,
        hangingIndent: hangingIndent,
        shouldWrap: wrap ?? _outputPreferences.wrapText,
        columnWidth: _outputPreferences.wrapColumn,
      ));
    } else {
      _status.write(wrapText(message,
        indent: indent,
        hangingIndent: hangingIndent,
        shouldWrap: wrap ?? _outputPreferences.wrapText,
        columnWidth: _outputPreferences.wrapColumn,
      ));
    }
  }

  @override
  void printTrace(String message) => _trace.writeln(message);

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    assert(progressIndicatorPadding != null);
    printStatus(message);
    return SilentStatus(
      stopwatch: _stopwatchFactory.createStopwatch(),
    )..start();
  }

  @override
  void clear() {
    _error.clear();
    _status.clear();
    _trace.clear();
    _events.clear();
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) {
    _events.write(json.encode(<String, Object>{
      'name': name,
      'args': args
    }));
  }
}

class VerboseLogger extends DelegatingLogger {
  VerboseLogger(Logger parent, {
    StopwatchFactory stopwatchFactory = const StopwatchFactory()
  }) : _stopwatch = stopwatchFactory.createStopwatch(),
       _stopwatchFactory = stopwatchFactory,
       super(parent) {
    _stopwatch.start();
  }

  final Stopwatch _stopwatch;

  final StopwatchFactory _stopwatchFactory;

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
      wrapText(message,
        indent: indent,
        hangingIndent: hangingIndent,
        shouldWrap: wrap ?? _outputPreferences.wrapText,
        columnWidth: _outputPreferences.wrapColumn,
      ),
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
    _emit(_LogType.status, wrapText(message,
      indent: indent,
      hangingIndent: hangingIndent,
      shouldWrap: wrap ?? _outputPreferences.wrapText,
      columnWidth: _outputPreferences.wrapColumn,
    ));
  }

  @override
  void printTrace(String message) {
    _emit(_LogType.trace, message);
  }

  @override
  Status startProgress(
    String message, {
    String progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) {
    assert(progressIndicatorPadding != null);
    printStatus(message);
    final Stopwatch timer = _stopwatchFactory.createStopwatch()..start();
    return SilentStatus(
      // This is intentionally a different stopwatch than above.
      stopwatch: _stopwatchFactory.createStopwatch(),
      onFinish: () {
        String time;
        if (timer.elapsed.inSeconds > 2) {
          time = getElapsedAsSeconds(timer.elapsed);
        } else {
          time = getElapsedAsMilliseconds(timer.elapsed);
        }
        printTrace('$message (completed in $time)');
      },
    )..start();
  }

  void _emit(_LogType type, String message, [ StackTrace stackTrace ]) {
    if (message.trim().isEmpty) {
      return;
    }

    final int millis = _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();

    String prefix;
    const int prefixWidth = 8;
    if (millis == 0) {
      prefix = ''.padLeft(prefixWidth);
    } else {
      prefix = '+$millis ms'.padLeft(prefixWidth);
      if (millis >= 100) {
        prefix = _terminal.bolden(prefix);
      }
    }
    prefix = '[$prefix] ';

    final String indent = ''.padLeft(prefix.length);
    final String indentMessage = message.replaceAll('\n', '\n$indent');

    if (type == _LogType.error) {
      super.printError(prefix + _terminal.bolden(indentMessage));
      if (stackTrace != null) {
        super.printError(indent + stackTrace.toString().replaceAll('\n', '\n$indent'));
      }
    } else if (type == _LogType.status) {
      super.printStatus(prefix + _terminal.bolden(indentMessage));
    } else {
      super.printStatus(prefix + indentMessage);
    }
  }

  @override
  void sendEvent(String name, [Map<String, dynamic> args]) { }
}

class PrefixedErrorLogger extends DelegatingLogger {
  PrefixedErrorLogger(Logger parent) : super(parent);

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
    if (message?.trim()?.isNotEmpty == true) {
      message = 'ERROR: $message';
    }
    super.printError(
      message,
      stackTrace: stackTrace,
      emphasis: emphasis,
      color: color,
      indent: indent,
      hangingIndent: hangingIndent,
      wrap: wrap,
    );
  }
}

enum _LogType { error, status, trace }

typedef SlowWarningCallback = String Function();

/// A [Status] class begins when start is called, and may produce progress
/// information asynchronously.
///
/// The [SilentStatus] class never has any output.
///
/// The [AnsiSpinner] subclass shows a spinner, and replaces it with a single
/// space character when stopped or canceled.
///
/// The [AnsiStatus] subclass shows a spinner, and replaces it with timing
/// information when stopped. When canceled, the information isn't shown. In
/// either case, a newline is printed.
///
/// The [SummaryStatus] subclass shows only a static message (without an
/// indicator), then updates it when the operation ends.
///
/// Generally, consider `logger.startProgress` instead of directly creating
/// a [Status] or one of its subclasses.
abstract class Status {
  Status({
    this.onFinish,
    @required Stopwatch stopwatch,
  }) : _stopwatch = stopwatch;

  /// A [SilentStatus] or an [AnsiSpinner] (depending on whether the
  /// terminal is fancy enough), already started.
  factory Status.withSpinner({
    @required Stopwatch stopwatch,
    @required Terminal terminal,
    VoidCallback onFinish,
  }) {
    if (terminal.supportsColor) {
      return AnsiSpinner(
        onFinish: onFinish,
        stopwatch: stopwatch,
        terminal: terminal,
      )..start();
    }
    return SilentStatus(
      onFinish: onFinish,
      stopwatch: stopwatch,
    )..start();
  }

  final VoidCallback onFinish;

  @protected
  final Stopwatch _stopwatch;

  @protected
  String get elapsedTime {
    if (_stopwatch.elapsed.inSeconds > 2) {
      return getElapsedAsSeconds(_stopwatch.elapsed);
    }
    return getElapsedAsMilliseconds(_stopwatch.elapsed);
  }

  /// Call to start spinning.
  void start() {
    assert(!_stopwatch.isRunning);
    _stopwatch.start();
  }

  /// Call to stop spinning after success.
  void stop() {
    finish();
  }

  /// Call to cancel the spinner after failure or cancellation.
  void cancel() {
    finish();
  }

  /// Call to clear the current line but not end the progress.
  void pause() { }

  /// Call to resume after a pause.
  void resume() { }

  @protected
  void finish() {
    assert(_stopwatch.isRunning);
    _stopwatch.stop();
    if (onFinish != null) {
      onFinish();
    }
  }
}

/// A [SilentStatus] shows nothing.
class SilentStatus extends Status {
  SilentStatus({
    @required Stopwatch stopwatch,
    VoidCallback onFinish,
  }) : super(
    onFinish: onFinish,
    stopwatch: stopwatch,
  );

  @override
  void finish() {
    if (onFinish != null) {
      onFinish();
    }
  }
}

/// Constructor writes [message] to [stdout].  On [cancel] or [stop], will call
/// [onFinish]. On [stop], will additionally print out summary information.
class SummaryStatus extends Status {
  SummaryStatus({
    this.message = '',
    @required Stopwatch stopwatch,
    this.padding = kDefaultStatusPadding,
    VoidCallback onFinish,
    Stdio stdio,
  }) : assert(message != null),
       assert(padding != null),
       _stdio = stdio ?? globals.stdio,
       super(
         onFinish: onFinish,
         stopwatch: stopwatch,
        );

  final String message;
  final int padding;
  final Stdio _stdio;

  bool _messageShowingOnCurrentLine = false;

  @override
  void start() {
    _printMessage();
    super.start();
  }

  void _writeToStdOut(String message) => _stdio.stdoutWrite(message);

  void _printMessage() {
    assert(!_messageShowingOnCurrentLine);
    _writeToStdOut('${message.padRight(padding)}     ');
    _messageShowingOnCurrentLine = true;
  }

  @override
  void stop() {
    if (!_messageShowingOnCurrentLine) {
      _printMessage();
    }
    super.stop();
    writeSummaryInformation();
    _writeToStdOut('\n');
  }

  @override
  void cancel() {
    super.cancel();
    if (_messageShowingOnCurrentLine) {
      _writeToStdOut('\n');
    }
  }

  /// Prints a (minimum) 8 character padded time.
  void writeSummaryInformation() {
    assert(_messageShowingOnCurrentLine);
    _writeToStdOut(elapsedTime.padLeft(_kTimePadding));
  }

  @override
  void pause() {
    super.pause();
    _writeToStdOut('\n');
    _messageShowingOnCurrentLine = false;
  }
}

/// An [AnsiSpinner] is a simple animation that does nothing but implement a
/// terminal spinner. When stopped or canceled, the animation erases itself.
class AnsiSpinner extends Status {
  AnsiSpinner({
    @required Stopwatch stopwatch,
    @required Terminal terminal,
    VoidCallback onFinish,
    Stdio stdio,
  }) : _stdio = stdio ?? globals.stdio,
       _terminal = terminal,
       super(
         onFinish: onFinish,
         stopwatch: stopwatch,
        );

  final String _backspaceChar = '\b';
  final String _clearChar = ' ';
  final Stdio _stdio;
  final Terminal _terminal;

  bool timedOut = false;

  int ticks = 0;
  Timer timer;

  // Windows console font has a limited set of Unicode characters.
  List<String> get _animation => !_terminal.supportsEmoji
      ? const <String>[r'-', r'\', r'|', r'/']
      : const <String>['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'];

  String get _currentAnimationFrame => _animation[ticks % _animation.length];
  int get _currentLength => _currentAnimationFrame.length;
  String get _backspace => _backspaceChar * (spinnerIndent + _currentLength);
  String get _clear => _clearChar *  (spinnerIndent + _currentLength);

  @protected
  int get spinnerIndent => 0;

  @override
  void start() {
    super.start();
    assert(timer == null);
    _startSpinner();
  }

  void _writeToStdOut(String message) => _stdio.stdoutWrite(message);

  void _startSpinner() {
    _writeToStdOut(_clear); // for _callback to backspace over
    timer = Timer.periodic(const Duration(milliseconds: 100), _callback);
    _callback(timer);
  }

  void _callback(Timer timer) {
    assert(this.timer == timer);
    assert(timer != null);
    assert(timer.isActive);
    _writeToStdOut(_backspace);
    ticks += 1;
    _writeToStdOut('${_clearChar * spinnerIndent}$_currentAnimationFrame');
  }

  @override
  void finish() {
    assert(timer != null);
    assert(timer.isActive);
    timer.cancel();
    timer = null;
    _clearSpinner();
    super.finish();
  }

  void _clearSpinner() {
    _writeToStdOut('$_backspace$_clear$_backspace');
  }

  @override
  void pause() {
    assert(timer != null);
    assert(timer.isActive);
    _clearSpinner();
    timer.cancel();
  }

  @override
  void resume() {
    assert(timer != null);
    assert(!timer.isActive);
    _startSpinner();
  }
}

const int _kTimePadding = 8; // should fit "99,999ms"

/// Constructor writes [message] to [stdout] with padding, then starts an
/// indeterminate progress indicator animation (it's a subclass of
/// [AnsiSpinner]).
///
/// On [cancel] or [stop], will call [onFinish]. On [stop], will
/// additionally print out summary information.
class AnsiStatus extends AnsiSpinner {
  AnsiStatus({
    this.message = '',
    this.multilineOutput = false,
    this.padding = kDefaultStatusPadding,
    @required Stopwatch stopwatch,
    @required Terminal terminal,
    VoidCallback onFinish,
    Stdio stdio,
  }) : assert(message != null),
       assert(multilineOutput != null),
       assert(padding != null),
       super(
         onFinish: onFinish,
         stdio: stdio,
         stopwatch: stopwatch,
         terminal: terminal,
        );

  final String message;
  final bool multilineOutput;
  final int padding;

  static const String _margin = '     ';

  @override
  int get spinnerIndent => _kTimePadding - 1;

  int _totalMessageLength;

  @override
  void start() {
    _startStatus();
    super.start();
  }

  void _startStatus() {
    final String line = '${message.padRight(padding)}$_margin';
    _totalMessageLength = line.length;
    _writeToStdOut(line);
  }

  @override
  void stop() {
    super.stop();
    writeSummaryInformation();
    _writeToStdOut('\n');
  }

  @override
  void cancel() {
    super.cancel();
    _writeToStdOut('\n');
  }

  /// Print summary information when a task is done.
  ///
  /// If [multilineOutput] is false, replaces the spinner with the summary message.
  ///
  /// If [multilineOutput] is true, then it prints the message again on a new
  /// line before writing the elapsed time.
  void writeSummaryInformation() {
    if (multilineOutput) {
      _writeToStdOut('\n${'$message Done'.padRight(padding)}$_margin');
    }
    _writeToStdOut(elapsedTime.padLeft(_kTimePadding));
  }

  void _clearStatus() {
    _writeToStdOut(
      '${_backspaceChar * _totalMessageLength}'
      '${_clearChar * _totalMessageLength}'
      '${_backspaceChar * _totalMessageLength}',
    );
  }

  @override
  void pause() {
    super.pause();
    _clearStatus();
  }

  @override
  void resume() {
    _startStatus();
    super.resume();
  }
}
