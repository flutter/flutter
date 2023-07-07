// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'location.dart';
import 'span.dart';
import 'utils.dart';

/// A class that describes a segment of source text with additional context.
class SourceSpanWithContext extends SourceSpanBase {
  // This is a getter so that subclasses can override it.
  /// Text around the span, which includes the line containing this span.
  String get context => _context;
  final String _context;

  /// Creates a new span from [start] to [end] (exclusive) containing [text], in
  /// the given [context].
  ///
  /// [start] and [end] must have the same source URL and [start] must come
  /// before [end]. [text] must have a number of characters equal to the
  /// distance between [start] and [end]. [context] must contain [text], and
  /// [text] should start at `start.column` from the beginning of a line in
  /// [context].
  SourceSpanWithContext(
      SourceLocation start, SourceLocation end, String text, this._context)
      : super(start, end, text) {
    if (!context.contains(text)) {
      throw ArgumentError('The context line "$context" must contain "$text".');
    }

    if (findLineStart(context, text, start.column) == null) {
      throw ArgumentError('The span text "$text" must start at '
          'column ${start.column + 1} in a line within "$context".');
    }
  }
}

// TODO(#52): Move these to instance methods in the next breaking release.
/// Extension methods on the base [SourceSpan] API.
extension SourceSpanWithContextExtension on SourceSpanWithContext {
  /// Returns a span from [start] code units (inclusive) to [end] code units
  /// (exclusive) after the beginning of this span.
  SourceSpanWithContext subspan(int start, [int? end]) {
    RangeError.checkValidRange(start, end, length);
    if (start == 0 && (end == null || end == length)) return this;

    final locations = subspanLocations(this, start, end);
    return SourceSpanWithContext(
        locations[0], locations[1], text.substring(start, end), context);
  }
}
