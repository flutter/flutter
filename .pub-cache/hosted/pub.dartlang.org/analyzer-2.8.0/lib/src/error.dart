// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/error/error.dart';

/// A wrapper around [AnalysisError] that provides a more user-friendly string
/// representation.
class AnalyzerError implements Exception {
  final AnalysisError error;

  AnalyzerError(this.error);

  String get message => toString();

  @override
  String toString() {
    var builder = StringBuffer();

    // Print a less friendly string representation to ensure that
    // error.source.contents is not executed, as .contents it isn't async
    String sourceName = error.source.shortName;
    // sourceName ??= '<unknown source>';
    builder.write("Error in $sourceName: ${error.message}");

//    var content = error.source.contents.data;
//    var beforeError = content.substring(0, error.offset);
//    var lineNumber = "\n".allMatches(beforeError).length + 1;
//    builder.writeln("Error on line $lineNumber of ${error.source.fullName}: "
//        "${error.message}");

//    var errorLineIndex = beforeError.lastIndexOf("\n") + 1;
//    var errorEndOfLineIndex = content.indexOf("\n", error.offset);
//    if (errorEndOfLineIndex == -1) errorEndOfLineIndex = content.length;
//    var errorLine = content.substring(
//        errorLineIndex, errorEndOfLineIndex);
//    var errorColumn = error.offset - errorLineIndex;
//    var errorLength = error.length;
//
//    // Ensure that the error line we display isn't too long.
//    if (errorLine.length > _MAX_ERROR_LINE_LENGTH) {
//      var leftLength = errorColumn;
//      var rightLength = errorLine.length - leftLength;
//      if (leftLength > _MAX_ERROR_LINE_LENGTH ~/ 2 &&
//          rightLength > _MAX_ERROR_LINE_LENGTH ~/ 2) {
//        errorLine = "..." + errorLine.substring(
//            errorColumn - _MAX_ERROR_LINE_LENGTH ~/ 2 + 3,
//            errorColumn + _MAX_ERROR_LINE_LENGTH ~/ 2 - 3)
//            + "...";
//        errorColumn = _MAX_ERROR_LINE_LENGTH ~/ 2;
//      } else if (rightLength > _MAX_ERROR_LINE_LENGTH ~/ 2) {
//        errorLine = errorLine.substring(0, _MAX_ERROR_LINE_LENGTH - 3) + "...";
//      } else {
//        assert(leftLength > _MAX_ERROR_LINE_LENGTH ~/ 2);
//        errorColumn -= errorLine.length - _MAX_ERROR_LINE_LENGTH;
//        errorLine = "..." + errorLine.substring(
//            errorLine.length - _MAX_ERROR_LINE_LENGTH + 3, errorLine.length);
//      }
//      errorLength = math.min(errorLength, _MAX_ERROR_LINE_LENGTH - errorColumn);
//    }
//    builder.writeln(errorLine);
//
//    for (var i = 0; i < errorColumn; i++) builder.write(" ");
//    for (var i = 0; i < errorLength; i++) builder.write("^");
    builder.writeln();

    return builder.toString();
  }
}

/// An error class that collects multiple [AnalyzerError]s that are emitted
/// during a single analysis.
class AnalyzerErrorGroup implements Exception {
  final List<AnalyzerError> _errors;
  AnalyzerErrorGroup(Iterable<AnalyzerError> errors)
      : _errors = errors.toList();

  /// Creates an [AnalyzerErrorGroup] from a list of lower-level
  /// [AnalysisError]s.
  AnalyzerErrorGroup.fromAnalysisErrors(Iterable<AnalysisError> errors)
      : this(errors.map((e) => AnalyzerError(e)));

  /// The errors in this collection.
  List<AnalyzerError> get errors =>
      UnmodifiableListView<AnalyzerError>(_errors);

  String get message => toString();
  @override
  String toString() => errors.join("\n");
}
