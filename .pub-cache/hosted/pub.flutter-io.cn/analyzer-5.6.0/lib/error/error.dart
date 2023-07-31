// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/error_code_values.g.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';

export 'package:_fe_analyzer_shared/src/base/errors.dart'
    show ErrorCode, ErrorSeverity, ErrorType;
export 'package:analyzer/src/error/error_code_values.g.dart';

/// The lazy initialized map from [ErrorCode.uniqueName] to the [ErrorCode]
/// instance.
final HashMap<String, ErrorCode> _uniqueNameToCodeMap =
    _computeUniqueNameToCodeMap();

/// Return the [ErrorCode] with the given [uniqueName], or `null` if not
/// found.
ErrorCode? errorCodeByUniqueName(String uniqueName) {
  return _uniqueNameToCodeMap[uniqueName];
}

/// Return the map from [ErrorCode.uniqueName] to the [ErrorCode] instance
/// for all [errorCodeValues].
HashMap<String, ErrorCode> _computeUniqueNameToCodeMap() {
  var result = HashMap<String, ErrorCode>();
  for (ErrorCode errorCode in errorCodeValues) {
    var uniqueName = errorCode.uniqueName;
    assert(() {
      if (result.containsKey(uniqueName)) {
        throw StateError('Not unique: $uniqueName');
      }
      return true;
    }());
    result[uniqueName] = errorCode;
  }
  return result;
}

/// An error discovered during the analysis of some Dart code.
///
/// See [AnalysisErrorListener].
class AnalysisError implements Diagnostic {
  /// An empty array of errors used when no errors are expected.
  static const List<AnalysisError> NO_ERRORS = <AnalysisError>[];

  /// A [Comparator] that sorts by the name of the file that the [AnalysisError]
  /// was found.
  static Comparator<AnalysisError> FILE_COMPARATOR =
      (AnalysisError o1, AnalysisError o2) =>
          o1.source.shortName.compareTo(o2.source.shortName);

  /// A [Comparator] that sorts error codes first by their severity (errors
  /// first, warnings second), and then by the error code type.
  static Comparator<AnalysisError> ERROR_CODE_COMPARATOR =
      (AnalysisError o1, AnalysisError o2) {
    ErrorCode errorCode1 = o1.errorCode;
    ErrorCode errorCode2 = o2.errorCode;
    ErrorSeverity errorSeverity1 = errorCode1.errorSeverity;
    ErrorSeverity errorSeverity2 = errorCode2.errorSeverity;
    if (errorSeverity1 == errorSeverity2) {
      ErrorType errorType1 = errorCode1.type;
      ErrorType errorType2 = errorCode2.type;
      return errorType1.compareTo(errorType2);
    } else {
      return errorSeverity2.compareTo(errorSeverity1);
    }
  };

  /// The error code associated with the error.
  final ErrorCode errorCode;

  /// The message describing the problem.
  late final DiagnosticMessage _problemMessage;

  /// The context messages associated with the problem. This list will be empty
  /// if there are no context messages.
  final List<DiagnosticMessage> _contextMessages;

  /// The correction to be displayed for this error, or `null` if there is no
  /// correction information for this error.
  String? _correctionMessage;

  /// The source in which the error occurred, or `null` if unknown.
  final Source source;

  /// Initialize a newly created analysis error. The error is associated with
  /// the given [source] and is located at the given [offset] with the given
  /// [length]. The error will have the given [errorCode] and the list of
  /// [arguments] will be used to complete the message and correction. If any
  /// [contextMessages] are provided, they will be recorded with the error.
  AnalysisError(this.source, int offset, int length, this.errorCode,
      [List<Object?>? arguments,
      List<DiagnosticMessage> contextMessages = const []])
      : _contextMessages = contextMessages {
    assert(
        (arguments ?? const []).length == errorCode.numParameters,
        'Message $errorCode requires ${errorCode.numParameters} '
        'argument${errorCode.numParameters == 1 ? '' : 's'}, but '
        '${(arguments ?? const []).length} '
        'argument${(arguments ?? const []).length == 1 ? ' was' : 's were'} '
        'provided');
    String problemMessage = formatList(errorCode.problemMessage, arguments);
    String? correctionTemplate = errorCode.correctionMessage;
    if (correctionTemplate != null) {
      _correctionMessage = formatList(correctionTemplate, arguments);
    }
    _problemMessage = DiagnosticMessageImpl(
        filePath: source.fullName,
        length: length,
        message: problemMessage,
        offset: offset,
        url: null);
  }

  /// Initialize a newly created analysis error with given values.
  AnalysisError.forValues(this.source, int offset, int length, this.errorCode,
      String message, this._correctionMessage,
      {List<DiagnosticMessage> contextMessages = const []})
      : _contextMessages = contextMessages {
    _problemMessage = DiagnosticMessageImpl(
        filePath: source.fullName,
        length: length,
        message: message,
        offset: offset,
        url: null);
  }

  @override
  List<DiagnosticMessage> get contextMessages => _contextMessages;

  /// Return the template used to create the correction to be displayed for this
  /// error, or `null` if there is no correction information for this error. The
  /// correction should indicate how the user can fix the error.
  String? get correction => _correctionMessage;

  @override
  String? get correctionMessage => _correctionMessage;

  @override
  int get hashCode {
    int hashCode = offset;
    hashCode ^= message.hashCode;
    hashCode ^= source.hashCode;
    return hashCode;
  }

  /// The number of characters from the offset to the end of the source which
  /// encompasses the compilation error.
  int get length => _problemMessage.length;

  /// Return the message to be displayed for this error. The message should
  /// indicate what is wrong and why it is wrong.
  String get message => _problemMessage.messageText(includeUrl: true);

  /// The character offset from the beginning of the source (zero based) where
  /// the error occurred.
  int get offset => _problemMessage.offset;

  @override
  DiagnosticMessage get problemMessage => _problemMessage;

  @override
  Severity get severity {
    switch (errorCode.errorSeverity) {
      case ErrorSeverity.ERROR:
        return Severity.error;
      case ErrorSeverity.WARNING:
        return Severity.warning;
      case ErrorSeverity.INFO:
        return Severity.info;
      default:
        throw StateError('Invalid error severity: ${errorCode.errorSeverity}');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    // prepare other AnalysisError
    if (other is AnalysisError) {
      // Quick checks.
      if (!identical(errorCode, other.errorCode)) {
        return false;
      }
      if (offset != other.offset || length != other.length) {
        return false;
      }
      // Deep checks.
      if (message != other.message) {
        return false;
      }
      if (source != other.source) {
        return false;
      }
      // OK
      return true;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write(source.fullName);
    buffer.write("(");
    buffer.write(offset);
    buffer.write("..");
    buffer.write(offset + length - 1);
    buffer.write("): ");
    //buffer.write("(" + lineNumber + ":" + columnNumber + "): ");
    buffer.write(message);
    return buffer.toString();
  }

  /// Merge all of the errors in the lists in the given list of [errorLists]
  /// into a single list of errors.
  static List<AnalysisError> mergeLists(List<List<AnalysisError>> errorLists) {
    Set<AnalysisError> errors = HashSet<AnalysisError>();
    for (List<AnalysisError> errorList in errorLists) {
      errors.addAll(errorList);
    }
    return errors.toList();
  }
}
