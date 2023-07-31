// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'span.dart';

// TODO(nweiz): Use SourceLocationMixin once we decide to cut a release with
// breaking changes. See SourceLocationMixin for details.

/// A class that describes a single location within a source file.
///
/// This class should not be extended. Instead, [SourceLocationBase] should be
/// extended instead.
class SourceLocation implements Comparable<SourceLocation> {
  /// URL of the source containing this location.
  ///
  /// This may be null, indicating that the source URL is unknown or
  /// unavailable.
  final Uri? sourceUrl;

  /// The 0-based offset of this location in the source.
  final int offset;

  /// The 0-based line of this location in the source.
  final int line;

  /// The 0-based column of this location in the source
  final int column;

  /// Returns a representation of this location in the `source:line:column`
  /// format used by text editors.
  ///
  /// This prints 1-based lines and columns.
  String get toolString {
    final source = sourceUrl ?? 'unknown source';
    return '$source:${line + 1}:${column + 1}';
  }

  /// Creates a new location indicating [offset] within [sourceUrl].
  ///
  /// [line] and [column] default to assuming the source is a single line. This
  /// means that [line] defaults to 0 and [column] defaults to [offset].
  ///
  /// [sourceUrl] may be either a [String], a [Uri], or `null`.
  SourceLocation(this.offset, {sourceUrl, int? line, int? column})
      : sourceUrl =
            sourceUrl is String ? Uri.parse(sourceUrl) : sourceUrl as Uri?,
        line = line ?? 0,
        column = column ?? offset {
    if (offset < 0) {
      throw RangeError('Offset may not be negative, was $offset.');
    } else if (line != null && line < 0) {
      throw RangeError('Line may not be negative, was $line.');
    } else if (column != null && column < 0) {
      throw RangeError('Column may not be negative, was $column.');
    }
  }

  /// Returns the distance in characters between `this` and [other].
  ///
  /// This always returns a non-negative value.
  int distance(SourceLocation other) {
    if (sourceUrl != other.sourceUrl) {
      throw ArgumentError('Source URLs "$sourceUrl" and '
          "\"${other.sourceUrl}\" don't match.");
    }
    return (offset - other.offset).abs();
  }

  /// Returns a span that covers only a single point: this location.
  SourceSpan pointSpan() => SourceSpan(this, this, '');

  /// Compares two locations.
  ///
  /// [other] must have the same source URL as `this`.
  @override
  int compareTo(SourceLocation other) {
    if (sourceUrl != other.sourceUrl) {
      throw ArgumentError('Source URLs "$sourceUrl" and '
          "\"${other.sourceUrl}\" don't match.");
    }
    return offset - other.offset;
  }

  @override
  bool operator ==(other) =>
      other is SourceLocation &&
      sourceUrl == other.sourceUrl &&
      offset == other.offset;

  @override
  int get hashCode => (sourceUrl?.hashCode ?? 0) + offset;

  @override
  String toString() => '<$runtimeType: $offset $toolString>';
}

/// A base class for source locations with [offset], [line], and [column] known
/// at construction time.
class SourceLocationBase extends SourceLocation {
  SourceLocationBase(int offset, {sourceUrl, int? line, int? column})
      : super(offset, sourceUrl: sourceUrl, line: line, column: column);
}
