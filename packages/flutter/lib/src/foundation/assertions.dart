// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:meta/meta.dart';

import 'basic_types.dart';
import 'constants.dart';
import 'diagnostics.dart';
import 'error_dumper.dart';
import 'ui_primitives.dart';

export 'basic_types.dart' show IterableFilter;

// Examples can assume:
// late String runtimeType;
// late bool draconisAlive;
// late bool draconisAmulet;
// late Diagnosticable draconis;
// void methodThatMayThrow() { }
// class Trace implements StackTrace { late StackTrace vmTrace; }
// class Chain implements StackTrace { Trace toTrace() => Trace(); }

/// Signature for [FlutterError.onError] handler.
typedef FlutterExceptionHandler = void Function(FlutterErrorDetails details);

/// Signature for [DiagnosticPropertiesBuilder] transformer.
typedef DiagnosticPropertiesTransformer =
    Iterable<DiagnosticsNode> Function(Iterable<DiagnosticsNode> properties);

/// Signature for [FlutterErrorDetails.informationCollector] callback
/// and other callbacks that collect information describing an error.
typedef InformationCollector = Iterable<DiagnosticsNode> Function();

/// Signature for a function that demangles [StackTrace] objects into a format
/// that can be parsed by [StackFrame].
///
/// See also:
///
///   * [FlutterError.demangleStackTrace], which shows an example implementation.
typedef StackTraceDemangler = StackTrace Function(StackTrace details);

abstract class _ErrorDiagnostic extends DiagnosticsProperty<List<Object>> {
  /// This constructor provides a reliable hook for a kernel transformer to find
  /// error messages that need to be rewritten to include object references for
  /// interactive display of errors.
  _ErrorDiagnostic(String message, {super.level = DiagnosticLevel.info})
    : super(
        null,
        <Object>[message],
        showName: false,
        showSeparator: false,
        defaultValue: null,
        style: DiagnosticsTreeStyle.flat,
      );

  /// In debug builds, a kernel transformer rewrites calls to the default
  /// constructors for [ErrorSummary], [ErrorDescription], and [ErrorHint] to use
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
    super.style = DiagnosticsTreeStyle.flat,
    super.level = DiagnosticLevel.info,
  }) : super(null, messageParts, showName: false, showSeparator: false, defaultValue: null);

  @override
  String toString({
    TextTreeConfiguration? parentConfiguration,
    DiagnosticLevel minLevel = DiagnosticLevel.info,
  }) {
    return valueToString(parentConfiguration: parentConfiguration);
  }

  @override
  List<Object> get value => super.value!;

  @override
  String valueToString({TextTreeConfiguration? parentConfiguration}) {
    return value.join();
  }
}

/// An [ErrorHint] provides specific, non-obvious advice that may be applicable.
///
/// If your message provides obvious advice that is always applicable, it is an
/// [ErrorDescription] not a hint.
///
/// In debug builds, values interpolated into the `message` are
/// expanded and placed into [value], which is of type [List<Object>].
/// This allows IDEs to examine values interpolated into error messages.
///
/// See also:
///
///  * [ErrorSummary], which provides a short (one line) description of the
///    problem that was detected.
///  * [ErrorDescription], which provides an explanation of the problem and its
///    cause, any information that may help track down the problem, background
///    information, etc.
///  * [ErrorSpacer], which renders as a blank line.
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
  ErrorHint(super.message) : super(level: DiagnosticLevel.hint);

  /// Calls to the default constructor may be rewritten to use this constructor
  /// in debug mode using a kernel transformer.
  // ignore: unused_element
  ErrorHint._fromParts(super.messageParts) : super._fromParts(level: DiagnosticLevel.hint);
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
void debugPrintStack({StackTrace? stackTrace, String? label, int? maxFrames}) {
  if (label != null) {
    ErrorToConsoleDumper.dump(label);
  }
  if (stackTrace == null) {
    stackTrace = StackTrace.current;
  } else {
    stackTrace = FlutterError.demangleStackTrace(stackTrace);
  }
  Iterable<String> lines = stackTrace.toString().trimRight().split('\n');
  if (kIsWeb && lines.isNotEmpty) {
    // Remove extra call to StackTrace.current for web platform.
    // TODO(ferhat): remove when https://github.com/flutter/flutter/issues/37635
    // is addressed.
    lines = lines.skipWhile((String line) {
      return line.contains('StackTrace.current') ||
          line.contains('dart-sdk/lib/_internal') ||
          line.contains('dart:sdk_internal');
    });
  }
  if (maxFrames != null) {
    lines = lines.take(maxFrames);
  }
  ErrorToConsoleDumper.dump(FlutterError.defaultStackFilter(lines).join('\n'));
}
