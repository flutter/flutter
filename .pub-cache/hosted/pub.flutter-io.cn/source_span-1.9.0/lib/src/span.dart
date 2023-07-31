// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:term_glyph/term_glyph.dart' as glyph;

import 'file.dart';
import 'highlighter.dart';
import 'location.dart';
import 'span_mixin.dart';
import 'span_with_context.dart';
import 'utils.dart';

/// A class that describes a segment of source text.
abstract class SourceSpan implements Comparable<SourceSpan> {
  /// The start location of this span.
  SourceLocation get start;

  /// The end location of this span, exclusive.
  SourceLocation get end;

  /// The source text for this span.
  String get text;

  /// The URL of the source (typically a file) of this span.
  ///
  /// This may be null, indicating that the source URL is unknown or
  /// unavailable.
  Uri? get sourceUrl;

  /// The length of this span, in characters.
  int get length;

  /// Creates a new span from [start] to [end] (exclusive) containing [text].
  ///
  /// [start] and [end] must have the same source URL and [start] must come
  /// before [end]. [text] must have a number of characters equal to the
  /// distance between [start] and [end].
  factory SourceSpan(SourceLocation start, SourceLocation end, String text) =>
      SourceSpanBase(start, end, text);

  /// Creates a new span that's the union of `this` and [other].
  ///
  /// The two spans must have the same source URL and may not be disjoint.
  /// [text] is computed by combining `this.text` and `other.text`.
  SourceSpan union(SourceSpan other);

  /// Compares two spans.
  ///
  /// [other] must have the same source URL as `this`. This orders spans by
  /// [start] then [length].
  @override
  int compareTo(SourceSpan other);

  /// Formats [message] in a human-friendly way associated with this span.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an [ANSI terminal color escape][] that should
  /// be used to highlight the span's text (for example, `"\u001b[31m"` will
  /// color red). If it's `true`, it indicates that the text should be
  /// highlighted using the default color. If it's `false` or `null`, it
  /// indicates that the text shouldn't be highlighted.
  ///
  /// This uses the full range of Unicode characters to highlight the source
  /// span if [glyph.ascii] is `false` (the default), but only uses ASCII
  /// characters if it's `true`.
  ///
  /// [ANSI terminal color escape]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  String message(String message, {color});

  /// Prints the text associated with this span in a user-friendly way.
  ///
  /// This is identical to [message], except that it doesn't print the file
  /// name, line number, column number, or message. If [length] is 0 and this
  /// isn't a [SourceSpanWithContext], returns an empty string.
  ///
  /// [color] may either be a [String], a [bool], or `null`. If it's a string,
  /// it indicates an [ANSI terminal color escape][] that should
  /// be used to highlight the span's text (for example, `"\u001b[31m"` will
  /// color red). If it's `true`, it indicates that the text should be
  /// highlighted using the default color. If it's `false` or `null`, it
  /// indicates that the text shouldn't be highlighted.
  ///
  /// This uses the full range of Unicode characters to highlight the source
  /// span if [glyph.ascii] is `false` (the default), but only uses ASCII
  /// characters if it's `true`.
  ///
  /// [ANSI terminal color escape]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  String highlight({color});
}

/// A base class for source spans with [start], [end], and [text] known at
/// construction time.
class SourceSpanBase extends SourceSpanMixin {
  @override
  final SourceLocation start;
  @override
  final SourceLocation end;
  @override
  final String text;

  SourceSpanBase(this.start, this.end, this.text) {
    if (end.sourceUrl != start.sourceUrl) {
      throw ArgumentError('Source URLs "${start.sourceUrl}" and '
          " \"${end.sourceUrl}\" don't match.");
    } else if (end.offset < start.offset) {
      throw ArgumentError('End $end must come after start $start.');
    } else if (text.length != start.distance(end)) {
      throw ArgumentError('Text "$text" must be ${start.distance(end)} '
          'characters long.');
    }
  }
}

// TODO(#52): Move these to instance methods in the next breaking release.
/// Extension methods on the base [SourceSpan] API.
extension SourceSpanExtension on SourceSpan {
  /// Like [SourceSpan.message], but also highlights [secondarySpans] to provide
  /// the user with additional context.
  ///
  /// Each span takes a label ([label] for this span, and the values of the
  /// [secondarySpans] map for the secondary spans) that's used to indicate to
  /// the user what that particular span represents.
  ///
  /// If [color] is `true`, [ANSI terminal color escapes][] are used to color
  /// the resulting string. By default this span is colored red and the
  /// secondary spans are colored blue, but that can be customized by passing
  /// ANSI escape strings to [primaryColor] or [secondaryColor].
  ///
  /// [ANSI terminal color escapes]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  ///
  /// Each span in [secondarySpans] must refer to the same document as this
  /// span. Throws an [ArgumentError] if any secondary span has a different
  /// source URL than this span.
  ///
  /// Note that while this will work with plain [SourceSpan]s, it will produce
  /// much more useful output with [SourceSpanWithContext]s (including
  /// [FileSpan]s).
  String messageMultiple(
      String message, String label, Map<SourceSpan, String> secondarySpans,
      {bool color = false, String? primaryColor, String? secondaryColor}) {
    final buffer = StringBuffer()
      ..write('line ${start.line + 1}, column ${start.column + 1}');
    if (sourceUrl != null) buffer.write(' of ${p.prettyUri(sourceUrl)}');
    buffer
      ..writeln(': $message')
      ..write(highlightMultiple(label, secondarySpans,
          color: color,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor));
    return buffer.toString();
  }

  /// Like [SourceSpan.highlight], but also highlights [secondarySpans] to
  /// provide the user with additional context.
  ///
  /// Each span takes a label ([label] for this span, and the values of the
  /// [secondarySpans] map for the secondary spans) that's used to indicate to
  /// the user what that particular span represents.
  ///
  /// If [color] is `true`, [ANSI terminal color escapes][] are used to color
  /// the resulting string. By default this span is colored red and the
  /// secondary spans are colored blue, but that can be customized by passing
  /// ANSI escape strings to [primaryColor] or [secondaryColor].
  ///
  /// [ANSI terminal color escapes]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
  ///
  /// Each span in [secondarySpans] must refer to the same document as this
  /// span. Throws an [ArgumentError] if any secondary span has a different
  /// source URL than this span.
  ///
  /// Note that while this will work with plain [SourceSpan]s, it will produce
  /// much more useful output with [SourceSpanWithContext]s (including
  /// [FileSpan]s).
  String highlightMultiple(String label, Map<SourceSpan, String> secondarySpans,
          {bool color = false, String? primaryColor, String? secondaryColor}) =>
      Highlighter.multiple(this, label, secondarySpans,
              color: color,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor)
          .highlight();

  /// Returns a span from [start] code units (inclusive) to [end] code units
  /// (exclusive) after the beginning of this span.
  SourceSpan subspan(int start, [int? end]) {
    RangeError.checkValidRange(start, end, length);
    if (start == 0 && (end == null || end == length)) return this;

    final locations = subspanLocations(this, start, end);
    return SourceSpan(locations[0], locations[1], text.substring(start, end));
  }
}
