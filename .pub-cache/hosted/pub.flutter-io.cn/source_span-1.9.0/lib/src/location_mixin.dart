// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'location.dart';
import 'span.dart';

// Note: this class duplicates a lot of functionality of [SourceLocation]. This
// is because in order for SourceLocation to use SourceLocationMixin,
// SourceLocationMixin couldn't implement SourceLocation. In SourceSpan we
// handle this by making the class itself non-extensible, but that would be a
// breaking change for SourceLocation. So until we want to endure the pain of
// cutting a release with breaking changes, we duplicate the code here.

/// A mixin for easily implementing [SourceLocation].
abstract class SourceLocationMixin implements SourceLocation {
  @override
  String get toolString {
    final source = sourceUrl ?? 'unknown source';
    return '$source:${line + 1}:${column + 1}';
  }

  @override
  int distance(SourceLocation other) {
    if (sourceUrl != other.sourceUrl) {
      throw ArgumentError('Source URLs "$sourceUrl" and '
          "\"${other.sourceUrl}\" don't match.");
    }
    return (offset - other.offset).abs();
  }

  @override
  SourceSpan pointSpan() => SourceSpan(this, this, '');

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
