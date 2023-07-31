// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'customized_codes.dart';

/// An error code associated with an [AnalysisError].
///
/// Generally, messages should follow the [Guide for Writing
/// Diagnostics](../fasta/diagnostics.md).
abstract class ErrorCode {
  /// Regular expression for identifying positional arguments in error messages.
  static final RegExp _positionalArgumentRegExp = new RegExp(r'{(\d+)\}');

  /**
   * The name of the error code.
   */
  final String name;

  /**
   * The unique name of this error code.
   */
  final String uniqueName;

  final String _problemMessage;

  final String? _correctionMessage;

  /**
   * Return `true` if diagnostics with this code have documentation for them
   * that has been published.
   */
  final bool hasPublishedDocs;

  /**
   * Whether this error is caused by an unresolved identifier.
   */
  final bool isUnresolvedIdentifier;

  /**
   * Initialize a newly created error code to have the given [name]. The message
   * associated with the error will be created from the given [problemMessage]
   * template. The correction associated with the error will be created from the
   * given [correctionMessage] template.
   */
  const ErrorCode({
    String? correctionMessage,
    this.hasPublishedDocs = false,
    this.isUnresolvedIdentifier = false,
    required this.name,
    required String problemMessage,
    required this.uniqueName,
  })  : _correctionMessage = correctionMessage,
        _problemMessage = problemMessage,
        // ignore: unnecessary_null_comparison
        assert(hasPublishedDocs != null),
        // ignore: unnecessary_null_comparison
        assert(isUnresolvedIdentifier != null);

  /**
   * The template used to create the correction to be displayed for this error,
   * or `null` if there is no correction information for this error. The
   * correction should indicate how the user can fix the error.
   */
  String? get correctionMessage =>
      customizedCorrections[uniqueName] ?? _correctionMessage;

  /**
   * The severity of the error.
   */
  ErrorSeverity get errorSeverity;

  /// Whether a finding of this error is ignorable via comments such as
  /// `// ignore:` or `// ignore_for_file:`.
  bool get isIgnorable => errorSeverity != ErrorSeverity.ERROR;

  /**
   * The template used to create the problem message to be displayed for this
   * error. The problem message should indicate what is wrong and why it is
   * wrong.
   */
  String get problemMessage =>
      customizedMessages[uniqueName] ?? _problemMessage;

  int get numParameters {
    int result = 0;
    String? correctionMessage = _correctionMessage;
    for (String s in [
      _problemMessage,
      if (correctionMessage != null) correctionMessage
    ]) {
      for (RegExpMatch match in _positionalArgumentRegExp.allMatches(s)) {
        result = max(result, int.parse(match.group(1)!) + 1);
      }
    }
    return result;
  }

  /**
   * The type of the error.
   */
  ErrorType get type;

  /**
   * Return a URL that can be used to access documentation for diagnostics with
   * this code, or `null` if there is no published documentation.
   */
  String? get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/${name.toLowerCase()}';
    }
    return null;
  }

  @override
  String toString() => uniqueName;
}

/**
 * The severity of an [ErrorCode].
 */
class ErrorSeverity implements Comparable<ErrorSeverity> {
  /**
   * The severity representing a non-error. This is never used for any error
   * code, but is useful for clients.
   */
  static const ErrorSeverity NONE = const ErrorSeverity('NONE', 0, " ", "none");

  /**
   * The severity representing an informational level analysis issue.
   */
  static const ErrorSeverity INFO = const ErrorSeverity('INFO', 1, "I", "info");

  /**
   * The severity representing a warning. Warnings can become errors if the
   * `-Werror` command line flag is specified.
   */
  static const ErrorSeverity WARNING =
      const ErrorSeverity('WARNING', 2, "W", "warning");

  /**
   * The severity representing an error.
   */
  static const ErrorSeverity ERROR =
      const ErrorSeverity('ERROR', 3, "E", "error");

  static const List<ErrorSeverity> values = const [NONE, INFO, WARNING, ERROR];

  /**
   * The name of this error code.
   */
  final String name;

  /**
   * The ordinal value of the error code.
   */
  final int ordinal;

  /**
   * The name of the severity used when producing machine output.
   */
  final String machineCode;

  /**
   * The name of the severity used when producing readable output.
   */
  final String displayName;

  /**
   * Initialize a newly created severity with the given names.
   */
  const ErrorSeverity(
      this.name, this.ordinal, this.machineCode, this.displayName);

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(ErrorSeverity other) => ordinal - other.ordinal;

  /**
   * Return the severity constant that represents the greatest severity.
   */
  ErrorSeverity max(ErrorSeverity severity) =>
      this.ordinal >= severity.ordinal ? this : severity;

  @override
  String toString() => name;
}

/**
 * The type of an [ErrorCode].
 */
class ErrorType implements Comparable<ErrorType> {
  /**
   * Task (todo) comments in user code.
   */
  static const ErrorType TODO = const ErrorType('TODO', 0, ErrorSeverity.INFO);

  /**
   * Extra analysis run over the code to follow best practices, which are not in
   * the Dart Language Specification.
   */
  static const ErrorType HINT = const ErrorType('HINT', 1, ErrorSeverity.INFO);

  /**
   * Compile-time errors are errors that preclude execution. A compile time
   * error must be reported by a Dart compiler before the erroneous code is
   * executed.
   */
  static const ErrorType COMPILE_TIME_ERROR =
      const ErrorType('COMPILE_TIME_ERROR', 2, ErrorSeverity.ERROR);

  /**
   * Checked mode compile-time errors are errors that preclude execution in
   * checked mode.
   */
  static const ErrorType CHECKED_MODE_COMPILE_TIME_ERROR = const ErrorType(
      'CHECKED_MODE_COMPILE_TIME_ERROR', 3, ErrorSeverity.ERROR);

  /**
   * Static warnings are those warnings reported by the static checker. They
   * have no effect on execution. Static warnings must be provided by Dart
   * compilers used during development.
   */
  static const ErrorType STATIC_WARNING =
      const ErrorType('STATIC_WARNING', 4, ErrorSeverity.WARNING);

  /**
   * Many, but not all, static warnings relate to types, in which case they are
   * known as static type warnings.
   */
  static const ErrorType STATIC_TYPE_WARNING =
      const ErrorType('STATIC_TYPE_WARNING', 5, ErrorSeverity.WARNING);

  /**
   * Syntactic errors are errors produced as a result of input that does not
   * conform to the grammar.
   */
  static const ErrorType SYNTACTIC_ERROR =
      const ErrorType('SYNTACTIC_ERROR', 6, ErrorSeverity.ERROR);

  /**
   * Lint warnings describe style and best practice recommendations that can be
   * used to formalize a project's style guidelines.
   */
  static const ErrorType LINT = const ErrorType('LINT', 7, ErrorSeverity.INFO);

  static const List<ErrorType> values = const [
    TODO,
    HINT,
    COMPILE_TIME_ERROR,
    CHECKED_MODE_COMPILE_TIME_ERROR,
    STATIC_WARNING,
    STATIC_TYPE_WARNING,
    SYNTACTIC_ERROR,
    LINT,
  ];

  /**
   * The name of this error type.
   */
  final String name;

  /**
   * The ordinal value of the error type.
   */
  final int ordinal;

  /**
   * The severity of this type of error.
   */
  final ErrorSeverity severity;

  /**
   * Initialize a newly created error type to have the given [name] and
   * [severity].
   */
  const ErrorType(this.name, this.ordinal, this.severity);

  String get displayName => name.toLowerCase().replaceAll('_', ' ');

  @override
  int get hashCode => ordinal;

  @override
  int compareTo(ErrorType other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}
