// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'basic_types.dart';
import 'constants.dart';
import 'diagnostics.dart';
import 'print.dart';

/// Signature for [FlutterError.onError] handler.
typedef FlutterExceptionHandler = void Function(FlutterErrorDetails details);

/// Signature for [DiagnosticPropertiesBuilder] transformer.
typedef DiagnosticPropertiesTransformer = Iterable<DiagnosticsNode> Function(Iterable<DiagnosticsNode> properties);

/// Signature for [FlutterErrorDetails.informationCollector] callback
/// and other callbacks that collect information describing an error.
typedef InformationCollector = Iterable<DiagnosticsNode> Function();

abstract class _ErrorDiagnostic extends DiagnosticsProperty<List<Object>> {
  /// This constructor provides a reliable hook for a kernel transformer to find
  /// error messages that need to be rewritten to include object references for
  /// interactive display of errors.
  _ErrorDiagnostic(
    String message, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.flat,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : assert(message != null),
       super(
         null,
         <Object>[message],
         showName: false,
         showSeparator: false,
         defaultValue: null,
         style: style,
         level: level,
       );

  /// In debug builds, a kernel transformer rewrites calls to the default
  /// constructors for [ErrorSummary], [ErrorDetails], and [ErrorHint] to use
  /// this constructor.
  //
  // ```dart
  // _ErrorDiagnostic('Element $element must be $color')
  // ```
  // Desugars to:
  // ```dart
  // _ErrorDiagnostic.fromParts(<Object>['Element ', element, ' must be ', color])
  // ```
  //
  // Slightly more complex case:
  // ```dart
  // _ErrorDiagnostic('Element ${element.runtimeType} must be $color')
  // ```
  // Desugars to:
  //```dart
  // _ErrorDiagnostic.fromParts(<Object>[
  //   'Element ',
  //   DiagnosticsProperty(null, element, description: element.runtimeType?.toString()),
  //   ' must be ',
  //   color,
  // ])
  // ```
  _ErrorDiagnostic._fromParts(
    List<Object> messageParts, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.flat,
    DiagnosticLevel level = DiagnosticLevel.info,
  }) : assert(messageParts != null),
       super(
         null,
         messageParts,
         showName: false,
         showSeparator: false,
         defaultValue: null,
         style: style,
         level: level,
       );

  @override
  String valueToString({ TextTreeConfiguration parentConfiguration }) {
    return value.join('');
  }
}

/// An explanation of the problem and its cause, any information that may help
/// track down the problem, background information, etc.
///
/// Use [ErrorDescription] for any part of an error message where neither
/// [ErrorSummary] or [ErrorHint] is appropriate.
///
/// See also:
///
///  * [ErrorSummary], which provides a short (one line) description of the
///    problem that was detected.
///  * [ErrorHint], which provides specific, non-obvious advice that may be
///    applicable.
///  * [FlutterError], which is the most common place to use an
///    [ErrorDescription].
class ErrorDescription extends _ErrorDiagnostic {
  /// A lint enforces that this constructor can only be called with a string
  /// literal to match the limitations of the Dart Kernel transformer that
  /// optionally extracts out objects referenced using string interpolation in
  /// the message passed in.
  ///
  /// The message will display with the same text regardless of whether the
  /// kernel transformer is used. The kernel transformer is required so that
  /// debugging tools can provide interactive displays of objects described by
  /// the error.
  ErrorDescription(String message) : super(message, level: DiagnosticLevel.info);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  ErrorDescription._fromParts(List<Object> messageParts) : super._fromParts(messageParts, level: DiagnosticLevel.info);
}

/// A short (one line) description of the problem that was detected.
///
/// Error summaries from the same source location should have little variance,
/// so that they can be recognized as related. For example, they shouldn't
/// include hash codes.
///
/// A [FlutterError] must start with an [ErrorSummary] and may not contain
/// multiple summaries.
///
/// See also:
///
///  * [ErrorDescription], which provides an explanation of the problem and its
///    cause, any information that may help track down the problem, background
///    information, etc.
///  * [ErrorHint], which provides specific, non-obvious advice that may be
///    applicable.
///  * [FlutterError], which is the most common place to use an [ErrorSummary].
class ErrorSummary extends _ErrorDiagnostic {
  /// A lint enforces that this constructor can only be called with a string
  /// literal to match the limitations of the Dart Kernel transformer that
  /// optionally extracts out objects referenced using string interpolation in
  /// the message passed in.
  ///
  /// The message will display with the same text regardless of whether the
  /// kernel transformer is used. The kernel transformer is required so that
  /// debugging tools can provide interactive displays of objects described by
  /// the error.
  ErrorSummary(String message) : super(message, level: DiagnosticLevel.summary);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  ErrorSummary._fromParts(List<Object> messageParts) : super._fromParts(messageParts, level: DiagnosticLevel.summary);
}

/// An [ErrorHint] provides specific, non-obvious advice that may be applicable.
///
/// If your message provides obvious advice that is always applicable it is an
/// [ErrorDescription] not a hint.
///
/// See also:
///
///  * [ErrorSummary], which provides a short (one line) description of the
///    problem that was detected.
///  * [ErrorDescription], which provides an explanation of the problem and its
///    cause, any information that may help track down the problem, background
///    information, etc.
///  * [FlutterError], which is the most common place to use an [ErrorHint].
class ErrorHint extends _ErrorDiagnostic {
  /// A lint enforces that this constructor can only be called with a string
  /// literal to match the limitations of the Dart Kernel transformer that
  /// optionally extracts out objects referenced using string interpolation in
  /// the message passed in.
  ///
  /// The message will display with the same text regardless of whether the
  /// kernel transformer is used. The kernel transformer is required so that
  /// debugging tools can provide interactive displays of objects described by
  /// the error.
  ErrorHint(String message) : super(message, level:DiagnosticLevel.hint);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  ErrorHint._fromParts(List<Object> messageParts) : super._fromParts(messageParts, level:DiagnosticLevel.hint);
}

/// An [ErrorSpacer] creates an empty [DiagnosticsNode], that can be used to
/// tune the spacing between other [DiagnosticsNode] objects.
class ErrorSpacer extends DiagnosticsProperty<void> {
  /// Creates an empty space to insert into a list of [DiagnosticsNode] objects
  /// typically within a [FlutterError] object.
  ErrorSpacer() : super(
    '',
    null,
    description: '',
    showName: false,
  );
}

/// Class for information provided to [FlutterExceptionHandler] callbacks.
///
/// See [FlutterError.onError].
class FlutterErrorDetails extends Diagnosticable {
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
    this.context,
    this.stackFilter,
    this.informationCollector,
    this.silent = false,
  });

  /// Transformers to transform [DiagnosticsNode] in [DiagnosticPropertiesBuilder]
  /// into a more descriptive form.
  ///
  /// There are layers that attach certain [DiagnosticsNode] into
  /// [FlutterErrorDetails] that require knowledge from other layers to parse.
  /// To correctly interpret those [DiagnosticsNode], register transformers in
  /// the layers that possess the knowledge.
  ///
  /// See also:
  ///
  ///  * [WidgetsBinding.initInstances], which registers its transformer.
  static final List<DiagnosticPropertiesTransformer> propertiesTransformers =
    <DiagnosticPropertiesTransformer>[];

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
  ///
  /// The string should be in a form that will make sense in English when
  /// following the word "thrown", as in "thrown while obtaining the image from
  /// the network" (for the context "while obtaining the image from the
  /// network").
  final DiagnosticsNode context;

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
  final InformationCollector informationCollector;

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
      // newline, if we recognize that format is being used.
      final Object message = exception.message;
      final String fullMessage = exception.toString();
      if (message is String && message != fullMessage) {
        if (fullMessage.length > message.length) {
          final int position = fullMessage.lastIndexOf(message);
          if (position == fullMessage.length - message.length &&
              position > 2 &&
              fullMessage.substring(position - 2, position) == ': ') {
            // Add a linebreak so that the filename at the start of the
            // assertion message is always on its own line.
            String body = fullMessage.substring(0, position - 2);
            final int splitPoint = body.indexOf(' Failed assertion:');
            if (splitPoint >= 0) {
              body = '${body.substring(0, splitPoint)}\n${body.substring(splitPoint + 1)}';
            }
            longMessage = '${message.trimRight()}\n$body';
          }
        }
      }
      longMessage ??= fullMessage;
    } else if (exception is String) {
      longMessage = exception as String;
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

  Diagnosticable _exceptionToDiagnosticable() {
    if (exception is FlutterError) {
      return exception as FlutterError;
    }
    if (exception is AssertionError && exception.message is FlutterError) {
      return exception.message as FlutterError;
    }
    return null;
  }

  /// Returns a short (one line) description of the problem that was detected.
  ///
  /// If the exception contains an [ErrorSummary] that summary is used,
  /// otherwise the summary is inferred from the string representation of the
  /// exception.
  ///
  /// In release mode, this always returns a [DiagnosticsNode.message] with a
  /// formatted version of the exception.
  DiagnosticsNode get summary {
    String formatException() => exceptionAsString().split('\n')[0].trimLeft();
    if (kReleaseMode) {
      return DiagnosticsNode.message(formatException());
    }
    final Diagnosticable diagnosticable = _exceptionToDiagnosticable();
    DiagnosticsNode summary;
    if (diagnosticable != null) {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      debugFillProperties(builder);
      summary = builder.properties.firstWhere((DiagnosticsNode node) => node.level == DiagnosticLevel.summary, orElse: () => null);
    }
    return summary ?? ErrorSummary('${formatException()}');
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final DiagnosticsNode verb = ErrorDescription('thrown${ context != null ? ErrorDescription(" $context") : ""}');
    final Diagnosticable diagnosticable = _exceptionToDiagnosticable();
    if (exception is NullThrownError) {
      properties.add(ErrorDescription('The null value was $verb.'));
    } else if (exception is num) {
      properties.add(ErrorDescription('The number $exception was $verb.'));
    } else {
      DiagnosticsNode errorName;
      if (exception is AssertionError) {
        errorName = ErrorDescription('assertion');
      } else if (exception is String) {
        errorName = ErrorDescription('message');
      } else if (exception is Error || exception is Exception) {
        errorName = ErrorDescription('${exception.runtimeType}');
      } else {
        errorName = ErrorDescription('${exception.runtimeType} object');
      }
      properties.add(ErrorDescription('The following $errorName was $verb:'));
      if (diagnosticable != null) {
        diagnosticable.debugFillProperties(properties);
      } else {
        // Many exception classes put their type at the head of their message.
        // This is redundant with the way we display exceptions, so attempt to
        // strip out that header when we see it.
        final String prefix = '${exception.runtimeType}: ';
        String message = exceptionAsString();
        if (message.startsWith(prefix))
          message = message.substring(prefix.length);
        properties.add(ErrorSummary('$message'));
      }
    }

    final Iterable<String> stackLines = (stack != null) ? stack.toString().trimRight().split('\n') : null;
    if (exception is AssertionError && diagnosticable == null) {
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
        properties.add(ErrorSpacer());
        properties.add(ErrorHint(
          'Either the assertion indicates an error in the framework itself, or we should '
          'provide substantially more information in this error message to help you determine '
          'and fix the underlying cause.\n'
          'In either case, please report this assertion by filing a bug on GitHub:\n'
          '  https://github.com/flutter/flutter/issues/new?template=BUG.md'
        ));
      }
    }
    if (stack != null) {
      properties.add(ErrorSpacer());
      properties.add(DiagnosticsStackTrace('When the exception was thrown, this was the stack', stack, stackFilter: stackFilter));
    }
    if (informationCollector != null) {
      properties.add(ErrorSpacer());
      informationCollector().forEach(properties.add);
    }
  }

  @override
  String toStringShort() {
    return library != null ? 'Exception caught by $library' : 'Exception caught';
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return toDiagnosticsNode(style: DiagnosticsTreeStyle.error).toStringDeep(minLevel: minLevel);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({ String name, DiagnosticsTreeStyle style }) {
    return _FlutterErrorDetailsNode(
      name: name,
      value: this,
      style: style,
    );
  }
}

/// Error class used to report Flutter-specific assertion failures and
/// contract violations.
///
/// See also:
///
///  * <https://flutter.dev/docs/testing/errors>, more information about error
///    handling in Flutter.
class FlutterError extends Error with DiagnosticableTreeMixin implements AssertionError {
  /// Create an error message from a string.
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
  ///
  /// This constructor defers to the [new FlutterError.fromParts] constructor.
  /// The first line is wrapped in an implied [ErrorSummary], and subsequent
  /// lines are wrapped in implied [ErrorDescription]s. Consider using the
  /// [new FlutterError.fromParts] constructor to provide more detail, e.g.
  /// using [ErrorHint]s or other [DiagnosticsNode]s.
  factory FlutterError(String message) {
    final List<String> lines = message.split('\n');
    return FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(lines.first),
      ...lines.skip(1).map<DiagnosticsNode>((String line) => ErrorDescription(line)),
    ]);
  }

  /// Create an error message from a list of [DiagnosticsNode]s.
  ///
  /// By convention, there should be exactly one [ErrorSummary] in the list,
  /// and it should be the first entry.
  ///
  /// Other entries are typically [ErrorDescription]s (for material that is
  /// always applicable for this error) and [ErrorHint]s (for material that may
  /// be sometimes useful, but may not always apply). Other [DiagnosticsNode]
  /// subclasses, such as [DiagnosticsStackTrace], may
  /// also be used.
  FlutterError.fromParts(this.diagnostics) : assert(diagnostics.isNotEmpty, FlutterError.fromParts(<DiagnosticsNode>[ErrorSummary('Empty FlutterError')])) {
    assert(
      diagnostics.first.level == DiagnosticLevel.summary,
      FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('FlutterError is missing a summary.'),
        ErrorDescription(
          'All FlutterError objects should start with a short (one line) '
          'summary description of the problem that was detected.'
        ),
        DiagnosticsProperty<FlutterError>('Malformed', this, expandableValue: true, showSeparator: false, style: DiagnosticsTreeStyle.whitespace),
        ErrorDescription(
          '\nThis error should still help you solve your problem, '
          'however please also report this malformed error in the '
          'framework by filing a bug on GitHub:\n'
          '  https://github.com/flutter/flutter/issues/new?template=BUG.md'
        ),
      ],
    ));
    assert(() {
      final Iterable<DiagnosticsNode> summaries = diagnostics.where((DiagnosticsNode node) => node.level == DiagnosticLevel.summary);
      if (summaries.length > 1) {
        final List<DiagnosticsNode> message = <DiagnosticsNode>[
          ErrorSummary('FlutterError contained multiple error summaries.'),
          ErrorDescription(
            'All FlutterError objects should have only a single short '
            '(one line) summary description of the problem that was '
            'detected.'
          ),
          DiagnosticsProperty<FlutterError>('Malformed', this, expandableValue: true, showSeparator: false, style: DiagnosticsTreeStyle.whitespace),
          ErrorDescription('\nThe malformed error has ${summaries.length} summaries.'),
        ];
        int i = 1;
        for (final DiagnosticsNode summary in summaries) {
          message.add(DiagnosticsProperty<DiagnosticsNode>('Summary $i', summary, expandableValue : true));
          i += 1;
        }
        message.add(ErrorDescription(
          '\nThis error should still help you solve your problem, '
          'however please also report this malformed error in the '
          'framework by filing a bug on GitHub:\n'
          '  https://github.com/flutter/flutter/issues/new?template=BUG.md'
        ));
        throw FlutterError.fromParts(message);
      }
      return true;
    }());
  }

  /// The information associated with this error, in structured form.
  ///
  /// The first node is typically an [ErrorSummary] giving a short description
  /// of the problem, suitable for an index of errors, a log, etc.
  ///
  /// Subsequent nodes should give information specific to this error. Typically
  /// these will be [ErrorDescription]s or [ErrorHint]s, but they could be other
  /// objects also. For instance, an error relating to a timer could include a
  /// stack trace of when the timer was scheduled using the
  /// [DiagnosticsStackTrace] class.
  final List<DiagnosticsNode> diagnostics;

  /// The message associated with this error.
  ///
  /// This is generated by serializing the [diagnostics].
  @override
  String get message => toString();

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
      debugPrint(
        TextTreeRenderer(
          wrapWidth: wrapWidth,
          wrapWidthProperties: wrapWidth,
          maxDescendentsTruncatableNode: 5,
        ).render(details.toDiagnosticsNode(style: DiagnosticsTreeStyle.error)).trimRight(),
      );
    } else {
      debugPrint('Another exception was thrown: ${details.summary}');
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
    for (final String line in frames) {
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    diagnostics?.forEach(properties.add);
  }

  @override
  String toStringShort() => 'FlutterError';

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    // Avoid wrapping lines.
    final TextTreeRenderer renderer = TextTreeRenderer(wrapWidth: 4000000000);
    return diagnostics.map((DiagnosticsNode node) => renderer.render(node).trimRight()).join('\n');
  }

  /// Calls [onError] with the given details, unless it is null.
  static void reportError(FlutterErrorDetails details) {
    assert(details != null);
    assert(details.exception != null);
    if (onError != null)
      onError(details);
  }
}

/// Dump the stack to the console using [debugPrint] and
/// [FlutterError.defaultStackFilter].
///
/// If the `stackTrace` parameter is null, the [StackTrace.current] is used to
/// obtain the stack.
///
/// The `maxFrames` argument can be given to limit the stack to the given number
/// of lines before filtering is applied. By default, all stack lines are
/// included.
///
/// The `label` argument, if present, will be printed before the stack.
void debugPrintStack({StackTrace stackTrace, String label, int maxFrames}) {
  if (label != null)
    debugPrint(label);
  stackTrace ??= StackTrace.current;
  Iterable<String> lines = stackTrace.toString().trimRight().split('\n');
  if (kIsWeb && lines.isNotEmpty) {
    // Remove extra call to StackTrace.current for web platform.
    // TODO(ferhat): remove when https://github.com/flutter/flutter/issues/37635
    // is addressed.
    lines = lines.skipWhile((String line) {
      return line.contains('StackTrace.current') ||
             line.contains('dart:sdk_internal');
    });
  }
  if (maxFrames != null)
    lines = lines.take(maxFrames);
  debugPrint(FlutterError.defaultStackFilter(lines).join('\n'));
}

/// Diagnostic with a [StackTrace] [value] suitable for displaying stack traces
/// as part of a [FlutterError] object.
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
    style: DiagnosticsTreeStyle.whitespace,
    showSeparator: showSeparator,
  );

  static DiagnosticsNode _createStackFrame(String frame) {
    return DiagnosticsNode.message(frame, allowWrap: false);
  }
}

class _FlutterErrorDetailsNode extends DiagnosticableNode<FlutterErrorDetails> {
  _FlutterErrorDetailsNode({
    String name,
    @required FlutterErrorDetails value,
    @required DiagnosticsTreeStyle style,
  }) : super(
    name: name,
    value: value,
    style: style,
  );

  @override
  DiagnosticPropertiesBuilder get builder {
    final DiagnosticPropertiesBuilder builder = super.builder;
    if (builder == null){
      return null;
    }
    Iterable<DiagnosticsNode> properties = builder.properties;
    for (final DiagnosticPropertiesTransformer transformer in FlutterErrorDetails.propertiesTransformers) {
      properties = transformer(properties);
    }
    return DiagnosticPropertiesBuilder.fromProperties(properties.toList());
  }
}
