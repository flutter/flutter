// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import 'highlighter.dart';
import 'span.dart';
import 'span_with_context.dart';
import 'utils.dart';

/// A mixin for easily implementing [SourceSpan].
///
/// This implements the [SourceSpan] methods in terms of [start], [end], and
/// [text]. This assumes that [start] and [end] have the same source URL, that
/// [start] comes before [end], and that [text] has a number of characters equal
/// to the distance between [start] and [end].
abstract class SourceSpanMixin implements SourceSpan {
  @override
  Uri? get sourceUrl => start.sourceUrl;

  @override
  int get length => end.offset - start.offset;

  @override
  int compareTo(SourceSpan other) {
    final result = start.compareTo(other.start);
    return result == 0 ? end.compareTo(other.end) : result;
  }

  @override
  SourceSpan union(SourceSpan other) {
    if (sourceUrl != other.sourceUrl) {
      throw ArgumentError('Source URLs "$sourceUrl" and '
          " \"${other.sourceUrl}\" don't match.");
    }

    final start = min(this.start, other.start);
    final end = max(this.end, other.end);
    final beginSpan = start == this.start ? this : other;
    final endSpan = end == this.end ? this : other;

    if (beginSpan.end.compareTo(endSpan.start) < 0) {
      throw ArgumentError('Spans $this and $other are disjoint.');
    }

    final text = beginSpan.text +
        endSpan.text.substring(beginSpan.end.distance(endSpan.start));
    return SourceSpan(start, end, text);
  }

  @override
  String message(String message, {color}) {
    final buffer = StringBuffer()
      ..write('line ${start.line + 1}, column ${start.column + 1}');
    if (sourceUrl != null) buffer.write(' of ${p.prettyUri(sourceUrl)}');
    buffer.write(': $message');

    final highlight = this.highlight(color: color);
    if (highlight.isNotEmpty) {
      buffer
        ..writeln()
        ..write(highlight);
    }

    return buffer.toString();
  }

  @override
  String highlight({color}) {
    if (this is! SourceSpanWithContext && length == 0) return '';
    return Highlighter(this, color: color).highlight();
  }

  @override
  bool operator ==(other) =>
      other is SourceSpan && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '<$runtimeType: from $start to $end "$text">';
}
