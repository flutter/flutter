// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'basic_types.dart';
import 'diagnostics.dart';
import 'print.dart';

/// Signature for [FlutterError.onError] handler.
typedef FlutterExceptionHandler = void Function(FlutterErrorDetails details);

//ignore: deprecated_member_use_from_same_package
/// Signature for [FlutterErrorDetails.informationCollector] callback
/// and other callbacks that collect information into a string buffer.
typedef InformationCollector = void Function(StringBuffer information);

/// Diagnostic with a [StackTrace] [value] suitable for displaying stacktraces
/// as part of a [FlutterError] object.
///
/// See also:
///
///  * [FlutterErrorBuilder.addStackTrace], which is the typical way StackTrace
///    objects are added to a [FlutterError].
class DiagnosticsStackTrace extends DiagnosticsBlock {

  /// Creates a diagnostic for a stack trace.
  ///
  /// [name] describes a name the stacktrace is given, e.g.
  /// `When the exception was thrown, this was the stack`.
  /// [stackFilter] provides an optional filter to use to filter which frames
  /// are included. If no filter is specified, [FlutterError.defaultStackFilter]
  /// is used.
  /// [showSeparator] indicates whether to include a ':' after the [name].
  DiagnosticsStackTrace(
    String name,
    StackTrace stack, {
    IterableFilter<String> stackFilter,
    bool showSeparator = true,
  }) : super(
    name: name,
    value: stack,
    properties: (stackFilter ?? FlutterError.defaultStackFilter)(stack.toString().trimRight().split('\n'))
      .map<DiagnosticsNode>(_createStackFrame)
      .toList(),
    style: DiagnosticsTreeStyle.flat,
    showSeparator: showSeparator,
    allowTruncate: true,
  );

  /// Creates a diagnostic describing a single frame from a StackTrace.
  DiagnosticsStackTrace.singleFrame(
    String name, {
    @required String frame,
    bool showSeparator = true,
  }) : super(
    name: name,
    properties: <DiagnosticsNode>[_createStackFrame(frame)],
    style: DiagnosticsTreeStyle.indentedSingleLine,
    showSeparator: showSeparator,
  );

  static DiagnosticsNode _createStackFrame(String frame) {
    return DiagnosticsNode.message(frame, allowWrap: false);
  }
}

/// Class for information provided to [FlutterExceptionHandler] callbacks.
///
/// See [FlutterError.onError].
class FlutterErrorDetails {
  /// Creates a [FlutterErrorDetails] object with the given arguments setting
  /// the object's properties.
  ///
  /// The framework calls this constructor when catching an exception that will
  /// subsequently be reported using [FlutterError.onError].
  ///
  /// The [exception] must not be null; other arguments can be left to
  /// their default values. (`throw null` results in a
  /// [NullThrownError] exception.)
  const FlutterErrorDetails({
    this.exception,
    this.stack,
    this.library = 'Flutter framework',
    this.stackFilter,
    this.informationCollector,
    FlutterErrorBuilder errorBuilder,
    String context,
    Object contextObject,
    this.silent = false
  }) : _contextName = context,
       _contextObject = contextObject,
       _errorBuilder = errorBuilder;
  /// The exception. Often this will be an [AssertionError], maybe specifically
  /// a [FlutterError]. However, this could be any value at all.
  final dynamic exception;

  /// The stack trace from where the [exception] was thrown (as opposed to where
  /// it was caught).
  ///
  /// StackTrace objects are opaque except for their [toString] function.
  ///
  /// If this field is not null, then the [stackFilter] callback, if any, will
  /// be called with the result of calling [toString] on this object and
  /// splitting that result on line breaks. If there's no [stackFilter]
  /// callback, then [FlutterError.defaultStackFilter] is used instead. That
  /// function expects the stack to be in the format used by
  /// [StackTrace.toString].
  final StackTrace stack;

  /// A human-readable brief name describing the library that caught the error
  /// message. This is used by the default error handler in the header dumped to
  /// the console.
  final String library;

  /// A human-readable description of where the error was caught (as opposed to
  /// where it was thrown).
  String get context {
    if (_contextName == null && _contextObject == null)
      return null;
    return _diagnosticContext('')?.toStringDeep();
  }

  DiagnosticsNode _diagnosticContext(String namePrefix) {
    final List<String> parts = <String>[];
    if (namePrefix.isNotEmpty) {
      parts.add(namePrefix);
    }
    if (_contextName != null && _contextName.isNotEmpty) {
      parts.add(_contextName);
    }
    final String name = parts.join(' ');
    if (_contextObject == null)
      return DiagnosticsNode.message(name, style: DiagnosticsTreeStyle.headerLine);

    if (_contextObject is Diagnosticable) {
      return DiagnosticsProperty<Object>(
        name,
        _contextObject,
        showName: name.isNotEmpty,
        showSeparator: false,
        expandableValue: true,
        allowNameWrap: true,
        style: DiagnosticsTreeStyle.headerLine,
      );
    }

    return DiagnosticsProperty<Object>(
      name,
      _contextObject,
      allowNameWrap: true,
      showSeparator: false,
      style: DiagnosticsTreeStyle.headerLine,
    );
  }

  final String _contextName;
  final Object _contextObject;

  /// A callback which filters the [stack] trace. Receives an iterable of
  /// strings representing the frames encoded in the way that
  /// [StackTrace.toString()] provides. Should return an iterable of lines to
  /// output for the stack.
  ///
  /// If this is not provided, then [FlutterError.dumpErrorToConsole] will use
  /// [FlutterError.defaultStackFilter] instead.
  ///
  /// If the [FlutterError.defaultStackFilter] behavior is desired, then the
  /// callback should manually call that function. That function expects the
  /// incoming list to be in the [StackTrace.toString()] format. The output of
  /// that function, however, does not always follow this format.
  ///
  /// This won't be called if [stack] is null.
  final IterableFilter<String> stackFilter;

  /// A callback which, when called with a [StringBuffer] will write to that buffer
  /// information that could help with debugging the problem.
  ///
  /// Information collector callbacks can be expensive, so the generated information
  /// should be cached, rather than the callback being called multiple times.
  ///
  /// The text written to the information argument may contain newlines but should
  /// not end with a newline.
  @Deprecated('Use errorBuilder instead to write more structured debug information.')
  final InformationCollector informationCollector;

  final FlutterErrorBuilder _errorBuilder;

  /// Whether this error should be ignored by the default error reporting
  /// behavior in release mode.
  ///
  /// If this is false, the default, then the default error handler will always
  /// dump this error to the console.
  ///
  /// If this is true, then the default error handler would only dump this error
  /// to the console in checked mode. In release mode, the error is ignored.
  ///
  /// This is used by certain exception handlers that catch errors that could be
  /// triggered by environmental conditions (as opposed to logic errors). For
  /// example, the HTTP library sets this flag so as to not report every 404
  /// error to the console on end-user devices, while still allowing a custom
  /// error handler to see the errors even in release builds.
  final bool silent;

  /// Converts the [exception] to a string.
  ///
  /// This applies some additional logic to make [AssertionError] exceptions
  /// prettier, to handle exceptions that stringify to empty strings, to handle
  /// objects that don't inherit from [Exception] or [Error], and so forth.
  String exceptionAsString() {
    String longMessage;
    if (exception is AssertionError) {
      // Regular _AssertionErrors thrown by assert() put the message last, after
      // some code snippets. This leads to ugly messages. To avoid this, we move
      // the assertion message up to before the code snippets, separated by a
      // newline, if we recognise that format is being used.
      final String message = exception.message;
      final String fullMessage = exception.toString();
      if (message is String && message != fullMessage) {
        if (fullMessage.length > message.length) {
          final int position = fullMessage.lastIndexOf(message);
          if (position == fullMessage.length - message.length &&
              position > 2 &&
              fullMessage.substring(position - 2, position) == ': ') {
            longMessage = '${message.trimRight()}\n${fullMessage.substring(0, position - 2)}';
          }
        }
      }
      longMessage ??= fullMessage;
    } else if (exception is String) {
      longMessage = exception;
    } else if (exception is Error || exception is Exception) {
      longMessage = exception.toString();
    } else {
      longMessage = '  ${exception.toString()}';
    }
    longMessage = longMessage.trimRight();
    if (longMessage.isEmpty)
      longMessage = '  <no message available>';
    return longMessage;
  }

  @override
  String toString() {
    // TODO(jacobr): this logic has a fair amount of overlap with
    // FlutterError.dumpToDiagnostic. It would  be reasonable to merge the two
    // methods if there is not legitimate reason to preserve the slight
    // differences in how the messages are displayed.
    final FlutterErrorBuilder builder = FlutterErrorBuilder();
    final StringBuffer prefix = StringBuffer();
    final bool hasContext = context?.isNotEmpty == true;
    if ((library != null && library != '') || hasContext) {
      if (library != null && library != '') {
        prefix.write('Error caught by $library');
        if (context != null && context != '')
          prefix.write(',');
      } else {
        prefix.write('Exception');
      }

      if (hasContext) {
        prefix.write(' thrown');
      }
      builder.addDiagnostic(_diagnosticContext(prefix.toString()));
    } else {
      builder.addDescription('An error was caught.');
    }
    builder.addDescription(exceptionAsString());
    if (informationCollector != null) { //ignore: deprecated_member_use_from_same_package
      final StringBuffer information = StringBuffer();
      informationCollector(information); //ignore: deprecated_member_use_from_same_package
      builder.addDescription(information.toString().trimRight());
    }
    if (_errorBuilder != null) {
      builder.addAll(_errorBuilder.toDiagnostics());
    }
    if (stack != null) {
      builder.addStackTrace(null, stack, stackFilter: stackFilter);
    }
    return builder.toDiagnostics().map((DiagnosticsNode node) => node.toStringDeep().trimRight()).join('\n').trimRight();
  }
}

typedef ErrorBuilderCallback<B extends FlutterErrorBuilder> = B Function();

/// Helper class used for collecting different pieces of information
/// for constructing an instance of [FlutterError]. It provides a number
/// of methods with names starting with 'add' to make it
/// convenient to add different parts to an error report.
/// In general, the client (e.g., an IDE) displays error parts in the same order
/// of adding them to the error builder.
/// {@tool sample}
/// ```dart
/// throw FlutterErrorBuilder()
///   ..addError('A short summary of the error. This is usually required.')
///   ..addDescription('A more detailed description of the error.')
///   ..addFix('A resolution that is straightforward to implement.')
///   ..addHint('A suggestion about a potential approach to resolving the error.')
///   ..addHint('You can add another suggestion if needed.')
///   ..addProperty('name of the object', object)
///   // adds a named object.The client can display it appropriated based on its type.
///   ..build(); // returns a FlutterError with all the specified parts.
/// ```
/// {@end-tool}
/// {@tool sample}
///
/// See also:
///
///  * [WidgetErrorBuilder], which adds a few ready-made error elements
///    for reporting errors at the widget layer.
///  * [RenderErrorBuilder], which adds a few ready-made error elements
///    for reporting errors at the rendering layer.
class FlutterErrorBuilder {
  /// Creates a [FlutterErrorBuilder]
  FlutterErrorBuilder() : _buildErrorCallback = null;

  /// Creates a [FlutterErrorBuilder] with its details computed only when needed.
  /// Use if computing the error details may throw an exception or is expensive.
  FlutterErrorBuilder.lazy(this._buildErrorCallback);

  /// Function called when building the error parts lazily.
  final ErrorBuilderCallback<FlutterErrorBuilder> _buildErrorCallback;

  /// Overall error message.
  String error;

  final List<DiagnosticsNode> _parts = <DiagnosticsNode>[];

  /// Whether the error report is empty.
  bool get isEmpty => _parts.isEmpty && error == null && _buildErrorCallback == null;

  /// Adds a short summary of the error to the report.
  ///
  /// The [summary] should usually be no longer than 2 lines and should
  /// concisely states what the assertion failure or contract violation was.
  ///
  /// The client (e.g., an IDE) usually displays the error summary in red.
  void addError(String sumnmary) {
    _parts.add(DiagnosticsNode.message(
      sumnmary.trimRight(),
      style: DiagnosticsTreeStyle.flat,
      level: DiagnosticLevel.error,
    ));
  }

  /// Adds a more elaborate description of the error.
  ///
  /// It's strongly encouraged to show a summary of the error
  /// using [addError] before showing more details.
  /// The description should include at least the following elements
  /// * Claim: Explanation of the assertion failure or contract violation.
  /// * Grounds: Facts about the user's code that led to the error.
  /// * Warranty: Connections between the grounds and the claim.
  void addDescription(String description) {
    _parts.add(DiagnosticsNode.message(description.trimRight(), style: DiagnosticsTreeStyle.flat));
  }

  /// Adds one or more suggestions for resolving the error.
  ///
  /// An optional [url] may be included in the hint to reference external
  /// material.
  void addHint(String description, {String url}) {
    if (url != null)
      _parts.add(UrlProperty(
        description.trimRight(),
        url: url,
        level:
        DiagnosticLevel.hint,
        style: DiagnosticsTreeStyle.indentedSingleLine,
      ));
    else
      _parts.add(DiagnosticsNode.message(
        description.trimRight(),
        style: DiagnosticsTreeStyle.flat,
        level: DiagnosticLevel.hint,
      ));
  }

  /// Adds a straightforward fix for resolving the error.
  /// A fix should be unambiguous and context-agnostic.
  ///
  /// If there isn't enough confidence in the general applicability of the fix,
  /// consider adding it as a hint using [addHint].
  void addFix(String description) {
    _parts.add(DiagnosticsNode.message(
      description.trimRight(),
      style: DiagnosticsTreeStyle.flat,
      level: DiagnosticLevel.fix,
    ));
  }

  /// Adds a formal contract that has been violated.
  void addContract(String description) {
    _parts.add(DiagnosticsNode.message(
      description.trimRight(),
      style: DiagnosticsTreeStyle.flat,
      level: DiagnosticLevel.contract,
    ));
  }

  /// Adds a statement of contract violation.
  void addViolation(String description) {
    _parts.add(DiagnosticsNode.message(
      description.trimRight(),
      style: DiagnosticsTreeStyle.flat,
      level: DiagnosticLevel.violation,
    ));
  }

  /// Adds a [StringProperty] to the error report.
  void addStringProperty(String name, String value, {DiagnosticLevel level = DiagnosticLevel.info}) {
    _parts.add(StringProperty(name, value, level: level));
  }

  /// Property constructor with nice defaults for a property of an error object.
  void addProperty<T>(
    String name,
    T value, {
    bool showName = true,
    bool showSeparator = true,
    Object defaultValue = kNoDefaultValue,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.indentedSingleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
    String linePrefix,
  }) {
    _parts.add(DiagnosticsProperty<T>(
      name,
      value,
      showName: showName,
      showSeparator: showSeparator,
      defaultValue: defaultValue,
      style: style,
      level: level,
      linePrefix: linePrefix,
      expandableValue: true,
    ));
  }

  /// Adds a named property with a [value] of type [T]
  /// to the error report.
  void addErrorProperty<T>(
    String name,
    T value, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.indentedSingleLine,
    String linePrefix,
  }) {
    addProperty<T>(name, value, level: DiagnosticLevel.error, style: style, linePrefix: linePrefix);
  }

  /// Returns a list of DiagnosticsNode objects including all parts of
  /// the error report.
  List<DiagnosticsNode> toDiagnostics() {
    if (error == null && _buildErrorCallback == null) {
      return _parts;
    }

    List<DiagnosticsNode> diagnostics;
    if (_buildErrorCallback != null) {
      diagnostics = _buildErrorCallback().toDiagnostics();
    } else {
      diagnostics = <DiagnosticsNode>[];
    }
    if (error != null) {
      diagnostics.insert(0, DiagnosticsNode.message(error, level: DiagnosticLevel.error));
    }
    diagnostics.addAll(_parts);
    return diagnostics;
  }
  
  /// Adds a property only displayed in GUI debugging tools and not in text
  /// messages.
  void addDebugProperty<T>(String name, T value) {
    _parts.add(DiagnosticsProperty<T>(name, value, level: DiagnosticLevel.debug));
  }

  /// Adds a property with an `Iterable<T>` [value] to the error report.
  void addIterable<T>(String name, Iterable<T> children, {DiagnosticLevel level = DiagnosticLevel.info}) {
    _parts.add(IterableProperty<T>(
      name,
      children,
      style: DiagnosticsTreeStyle.whitespace,
      level: level,
    ));
  }

  /// Adds a [StackTrace] relevant to the error.
  void addStackTrace(String name, StackTrace stackTrace, {IterableFilter<String> stackFilter}) {
    _parts.add(DiagnosticsStackTrace(name, stackTrace, stackFilter: stackFilter));
  }

  /// Adds an [IntProperty]
  void addIntProperty(String name, int value) {
    _parts.add(IntProperty(name, value));
  }

  /// Adds extra space between two parts of the error report.
  ///
  /// The client can decide how the "separator" is rendered.
  /// It falls back to an extra line break in the console.
  void addSeparator() {
    _parts.add(DiagnosticsNode.message(''));
  }

  /// Adds an instance of [DiagnosticNode] to the error report.
  ///
  /// In general, other methods that add specific error parts should be used
  /// before resorting to this method, since the other methods will by default
  /// use styles consistent with other error displays.
  /// For example, indenting values to show on the next line, etc.
  void addDiagnostic(DiagnosticsNode diagnostic) {
    _parts.add(diagnostic);
  }

  /// Adds a list of [DiagnosticNode] instances to the error report.
  /// See also:
  ///
  ///  * [addDiagnostic], which adds a single diagnostic.
  void addAll(Iterable<DiagnosticsNode> diagnostics) {
    _parts.addAll(diagnostics);
  }

  /// Builds a FlutterError based on the message parts collected by
  /// this instance of FlutterErrorBuilder.
  FlutterError build() {
    return FlutterError.from(this);
  }
}

/// Error class used to report Flutter-specific assertion failures and
/// contract violations.
class FlutterError extends AssertionError {
  /// Creates a [FlutterError].
  ///
  /// Include as much detail as possible in the full error message,
  /// including specifics about the state of the app that might be
  /// relevant to debugging the error.
  /// [error] describes the error that occurred.
  /// [description] provides more details about the error that occurred.
  /// [hint] explains the cause of the issue.
  /// [fix] explains a way to fix the issue.
  ///
  /// See also:
  ///
  ///  * [FlutterErrorBuilder], which should be used to generate [FlutterError]
  ///    objects with more structure than this constructor allows.
  FlutterError(
    String error, {
    String violation,
    String description,
    String fix,
    String contract,
    String hint,
  }) : messageParts = _createDiagnosticsList(
    error: error,
    violation: violation,
    description: description,
    fix: fix,
    contract: contract,
    hint: hint,
  );

  /// Creates an [FlutterError] from a [FlutterErrorBuilder].
  ///
  /// Use this named constructor to create errors with structured debugging
  /// information. Prefer the default constructor for cases where the error
  /// only consists of a sequence of string messages in an order consistent with
  /// the default constructor.
  FlutterError.from(FlutterErrorBuilder builder) :
        messageParts = builder.toDiagnostics();

  static List<DiagnosticsNode> _createDiagnosticsList({
    @required String error,
    String violation,
    String description,
    String fix,
    String contract,
    String hint,
  }) {
    final FlutterErrorBuilder errorBuilder = FlutterErrorBuilder();
    errorBuilder.addError(error);

    if (violation?.isNotEmpty == true)
      errorBuilder.addViolation(violation);

    if (description?.isNotEmpty == true)
      errorBuilder.addDescription(description);

    if (fix?.isNotEmpty == true)
      errorBuilder.addFix(fix);

    if (hint?.isNotEmpty == true)
      errorBuilder.addHint(hint);

    if (contract?.isNotEmpty == true)
      errorBuilder.addContract(contract);

    return errorBuilder.toDiagnostics();
  }

  /// Diagnostics providing a tool friendly description of the cause of the
  /// FlutterError.
  final List<DiagnosticsNode> messageParts;

  /// The message associated with this error.
  ///
  /// The message may have newlines in it. The first line should be a terse
  /// description of the error, e.g. "Incorrect GlobalKey usage" or "setState()
  /// or markNeedsBuild() called during build". Subsequent lines should contain
  /// substantial additional information, ideally sufficient to develop a
  /// correct solution to the problem.
  ///
  /// In some cases, when a FlutterError is reported to the user, only the first
  /// line is included. For example, Flutter will typically only fully report
  /// the first exception at runtime, displaying only the first line of
  /// subsequent errors.
  ///
  /// All sentences in the error should be correctly punctuated (i.e.,
  /// do end the error message with a period).
  @override
  String get message {
    if (messageParts == null) {
      return super.message;
    }
    final TextRenderer renderer = TextRenderer(wrapWidth: wrapWidth);
    return messageParts.map((DiagnosticsNode node) => renderer.render(node).trimRight()).join('\n');
  }

  @override
  String toString({DiagnosticLevel minLevel}) => message;

  /// Called whenever the Flutter framework catches an error.
  ///
  /// The default behavior is to call [dumpErrorToConsole].
  ///
  /// You can set this to your own function to override this default behavior.
  /// For example, you could report all errors to your server.
  ///
  /// If the error handler throws an exception, it will not be caught by the
  /// Flutter framework.
  ///
  /// Set this to null to silently catch and ignore errors. This is not
  /// recommended.
  static FlutterExceptionHandler onError = dumpErrorToConsole;

  static int _errorCount = 0;

  /// Resets the count of errors used by [dumpErrorToConsole] to decide whether
  /// to show a complete error message or an abbreviated one.
  ///
  /// After this is called, the next error message will be shown in full.
  static void resetErrorCount() {
    _errorCount = 0;
  }

  /// The width to which [dumpErrorToConsole] will wrap lines.
  ///
  /// This can be used to ensure strings will not exceed the length at which
  /// they will wrap, e.g. when placing ASCII art diagrams in messages.
  static const int wrapWidth = 100;

  /// Converts the given exception details to a tree of [DiagnosticsNode]
  /// objects.
  ///
  /// The returned [DiagnosticsNode] should be used to log FlutterErrorDetails
  /// objects to the console and by debugging tools that display rich
  /// interactive versions of error objects.
  ///
  /// See also:
  ///
  ///  * [FlutterError.dumpErrorToConsole], which uses this DiagnosticsNode to
  ///    dump the error to the console.
  ///  * [InspectorService], which uses this method to send errors to GUI
  ///    clients in a structured manner.
  static DiagnosticsNode errorToDiagnostic(FlutterErrorDetails details) {
    final FlutterErrorBuilder errorBuilder = FlutterErrorBuilder();

    void addContextHeader(String namePrefix, [String nameSuffix = ':']) {
      // Hixie, we are ingoring suffix for now. Can we just standardize to
      // all header lines ending with ':' or is that a step backwards?
      // XXX resolve this question before submitting. See the calls to this
      // method that indicate what the header should be in each case if we care.
      errorBuilder.addDiagnostic(details._diagnosticContext('$namePrefix thrown'));
    }
    if (details.exception is NullThrownError) {
      addContextHeader('The null value was', '.');
    } else if (details.exception is num) {
      addContextHeader('The number ${details.exception} was', '.');
    } else if (details.exception is FlutterError) {
      final FlutterError flutterError = details.exception;
      addContextHeader('The following assertion was');
      errorBuilder.addAll(flutterError.messageParts);
    }
    else {
      String errorName;
      if (details.exception is AssertionError) {
        errorName = 'assertion';
      } else if (details.exception is String) {
        errorName = 'message';
      } else if (details.exception is Error || details.exception is Exception) {
        errorName = '${details.exception.runtimeType}';
      } else {
        errorName = '${details.exception.runtimeType} object';
      }
      // Many exception classes put their type at the head of their message.
      // This is redundant with the way we display exceptions, so attempt to
      // strip out that header when we see it.
      final String prefix = '${details.exception.runtimeType}: ';
      String message = details.exceptionAsString();
      if (message.startsWith(prefix))
        message = message.substring(prefix.length);
      addContextHeader('The following $errorName was');
      errorBuilder.addDescription(message);
    }
    final Iterable<String> stackLines = (details.stack != null) ? details.stack.toString().trimRight().split('\n') : null;
    if ((details.exception is AssertionError) && (details.exception is! FlutterError)) {
      bool ourFault = true;
      if (stackLines != null) {
        final List<String> stackList = stackLines.take(2).toList();
        if (stackList.length >= 2) {
          // TODO(ianh): This has bitrotted and is no longer matching. https://github.com/flutter/flutter/issues/4021
          final RegExp throwPattern = RegExp(
              r'^#0 +_AssertionError._throwNew \(dart:.+\)$');
          final RegExp assertPattern = RegExp(
              r'^#1 +[^(]+ \((.+?):([0-9]+)(?::[0-9]+)?\)$');
          if (throwPattern.hasMatch(stackList[0])) {
            final Match assertMatch = assertPattern.firstMatch(stackList[1]);
            if (assertMatch != null) {
              assert(assertMatch.groupCount == 2);
              final RegExp ourLibraryPattern = RegExp(r'^package:flutter/');
              ourFault = ourLibraryPattern.hasMatch(assertMatch.group(1));
            }
          }
        }
      }
      if (ourFault) {
        errorBuilder.addSeparator();
        errorBuilder.addHint(
          'Either the assertion indicates an error in the framework itself, or we should '
          'provide substantially more information in this error message to help you determine '
          'and fix the underlying cause.\n'
          'In either case, please report this assertion by filing a bug on GitHub',
          url: 'https://github.com/flutter/flutter/issues/new?template=BUG.md',
        );
      }
    }
    if (details.stack != null) {
      errorBuilder.addSeparator();
      errorBuilder.addStackTrace('When the exception was thrown, this was the stack', details.stack, stackFilter: details.stackFilter);
      if (details.informationCollector != null || details._errorBuilder != null) //ignore: deprecated_member_use_from_same_package
        errorBuilder.addSeparator();
    }
    if (details.informationCollector != null) { //ignore: deprecated_member_use_from_same_package
      final StringBuffer information = StringBuffer();
      details.informationCollector(information); //ignore: deprecated_member_use_from_same_package
      errorBuilder.addDescription(information.toString().trimRight());
    }
    if (details._errorBuilder != null) {
      errorBuilder.addAll(details._errorBuilder.toDiagnostics());
    }
    return DiagnosticsBlock(name: 'EXCEPTION CAUGHT BY', description: details.library.toUpperCase(),
      properties: errorBuilder.toDiagnostics(),
      showSeparator: false,
      style: DiagnosticsTreeStyle.error,
    );
  }

  /// Prints the given exception details to the console.
  ///
  /// The first time this is called, it dumps a very verbose message to the
  /// console using [debugPrint].
  ///
  /// Subsequent calls only dump the first line of the exception, unless
  /// `forceReport` is set to true (in which case it dumps the verbose message).
  ///
  /// Call [resetErrorCount] to cause this method to go back to acting as if it
  /// had not been called before (so the next message is verbose again).
  ///
  /// The default behavior for the [onError] handler is to call this function.
  static void dumpErrorToConsole(FlutterErrorDetails details, { bool forceReport = false }) {
    assert(details != null);
    assert(details.exception != null);
    bool reportError = details.silent != true; // could be null
    assert(() {
      // In checked mode, we ignore the "silent" flag.
      reportError = true;
      return true;
    }());
    if (!reportError && !forceReport)
      return;
    if (_errorCount == 0 || forceReport) {
      debugPrint(TextRenderer(wrapWidth: wrapWidth, wrapWidthProperties: wrapWidth, maxDescendentsTruncatableNode: 5).render(errorToDiagnostic(details)));
    } else {
      debugPrint('Another exception was thrown: ${details.exceptionAsString().split("\n")[0].trimLeft()}');
    }
    _errorCount += 1;
  }

  /// Converts a stack to a string that is more readable by omitting stack
  /// frames that correspond to Dart internals.
  ///
  /// This is the default filter used by [dumpErrorToConsole] if the
  /// [FlutterErrorDetails] object has no [FlutterErrorDetails.stackFilter]
  /// callback.
  ///
  /// This function expects its input to be in the format used by
  /// [StackTrace.toString()]. The output of this function is similar to that
  /// format but the frame numbers will not be consecutive (frames are elided)
  /// and the final line may be prose rather than a stack frame.
  static Iterable<String> defaultStackFilter(Iterable<String> frames) {
    const List<String> filteredPackages = <String>[
      'dart:async-patch',
      'dart:async',
      'package:stack_trace',
    ];
    const List<String> filteredClasses = <String>[
      '_AssertionError',
      '_FakeAsync',
      '_FrameCallbackEntry',
    ];
    final RegExp stackParser = RegExp(r'^#[0-9]+ +([^.]+).* \(([^/\\]*)[/\\].+:[0-9]+(?::[0-9]+)?\)$');
    final RegExp packageParser = RegExp(r'^([^:]+):(.+)$');
    final List<String> result = <String>[];
    final List<String> skipped = <String>[];
    for (String line in frames) {
      final Match match = stackParser.firstMatch(line);
      if (match != null) {
        assert(match.groupCount == 2);
        if (filteredPackages.contains(match.group(2))) {
          final Match packageMatch = packageParser.firstMatch(match.group(2));
          if (packageMatch != null && packageMatch.group(1) == 'package') {
            skipped.add('package ${packageMatch.group(2)}'); // avoid "package package:foo"
          } else {
            skipped.add('package ${match.group(2)}');
          }
          continue;
        }
        if (filteredClasses.contains(match.group(1))) {
          skipped.add('class ${match.group(1)}');
          continue;
        }
      }
      result.add(line);
    }
    if (skipped.length == 1) {
      result.add('(elided one frame from ${skipped.single})');
    } else if (skipped.length > 1) {
      final List<String> where = Set<String>.from(skipped).toList()..sort();
      if (where.length > 1)
        where[where.length - 1] = 'and ${where.last}';
      if (where.length > 2) {
        result.add('(elided ${skipped.length} frames from ${where.join(", ")})');
      } else {
        result.add('(elided ${skipped.length} frames from ${where.join(" ")})');
      }
    }
    return result;
  }

  /// Calls [onError] with the given details, unless it is null.
  static void reportError(FlutterErrorDetails details) {
    assert(details != null);
    assert(details.exception != null);
    if (onError != null)
      onError(details);
  }
}

/// Dump the current stack to the console using [debugPrint] and
/// [FlutterError.defaultStackFilter].
///
/// The current stack is obtained using [StackTrace.current].
///
/// The `maxFrames` argument can be given to limit the stack to the given number
/// of lines. By default, all non-filtered stack lines are shown.
///
/// The `label` argument, if present, will be printed before the stack.
void debugPrintStack({ String label, int maxFrames }) {
  if (label != null)
    debugPrint(label);
  Iterable<String> lines = StackTrace.current.toString().trimRight().split('\n');
  if (maxFrames != null)
    lines = lines.take(maxFrames);
  debugPrint(FlutterError.defaultStackFilter(lines).join('\n'));
}
