// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.src.formatter_exception;

import 'package:analyzer/error/error.dart';
import 'package:source_span/source_span.dart';

/// Thrown when one or more errors occurs while parsing the code to be
/// formatted.
class FormatterException implements Exception {
  /// The [AnalysisError]s that occurred.
  final List<AnalysisError> errors;

  /// Creates a new FormatterException with an optional error [message].
  const FormatterException(this.errors);

  /// Creates a human-friendly representation of the analysis errors.
  String message({bool? color}) {
    var buffer = StringBuffer();
    buffer.writeln('Could not format because the source could not be parsed:');

    // In case we get a huge series of cascaded errors, just show the first few.
    var shownErrors = errors;
    if (errors.length > 10) shownErrors = errors.take(10).toList();

    for (var error in shownErrors) {
      var source = error.source.contents.data;

      // If the parse error is for something missing from the end of the file,
      // the error position will go past the end of the source. In that case,
      // just pad the source with spaces so we can report it nicely.
      if (error.offset + error.length > source.length) {
        source += ' ' * (error.offset + error.length - source.length);
      }

      var file = SourceFile.fromString(source, url: error.source.fullName);
      var span = file.span(error.offset, error.offset + error.length);
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(span.message(error.message, color: color));
    }

    if (shownErrors.length != errors.length) {
      buffer.writeln();
      buffer.write('(${errors.length - shownErrors.length} more errors...)');
    }

    return buffer.toString();
  }

  @override
  String toString() => message();
}

/// Exception thrown when the internal sanity check that only whitespace
/// changes are made fails.
class UnexpectedOutputException implements Exception {
  /// The source being formatted.
  final String _input;

  /// The resulting output.
  final String _output;

  UnexpectedOutputException(this._input, this._output);

  @override
  String toString() {
    return '''The formatter produced unexpected output. Input was:
$_input
Which formatted to:
$_output''';
  }
}
