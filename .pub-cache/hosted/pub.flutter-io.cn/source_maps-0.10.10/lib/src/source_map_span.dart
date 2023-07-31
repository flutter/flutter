// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_maps.source_map_span;

import 'package:source_span/source_span.dart';

/// A [SourceSpan] for spans coming from or being written to source maps.
///
/// These spans have an extra piece of metadata: whether or not they represent
/// an identifier (see [isIdentifier]).
class SourceMapSpan extends SourceSpanBase {
  /// Whether this span represents an identifier.
  ///
  /// If this is `true`, [text] is the value of the identifier.
  final bool isIdentifier;

  SourceMapSpan(SourceLocation start, SourceLocation end, String text,
      {this.isIdentifier = false})
      : super(start, end, text);

  /// Creates a [SourceMapSpan] for an identifier with value [text] starting at
  /// [start].
  ///
  /// The [end] location is determined by adding [text] to [start].
  SourceMapSpan.identifier(SourceLocation start, String text)
      : this(
            start,
            SourceLocation(start.offset + text.length,
                sourceUrl: start.sourceUrl,
                line: start.line,
                column: start.column + text.length),
            text,
            isIdentifier: true);
}

/// A wrapper aruond a [FileSpan] that implements [SourceMapSpan].
class SourceMapFileSpan implements SourceMapSpan, FileSpan {
  final FileSpan _inner;
  @override
  final bool isIdentifier;

  @override
  SourceFile get file => _inner.file;
  @override
  FileLocation get start => _inner.start;
  @override
  FileLocation get end => _inner.end;
  @override
  String get text => _inner.text;
  @override
  String get context => _inner.context;
  @override
  Uri? get sourceUrl => _inner.sourceUrl;
  @override
  int get length => _inner.length;

  SourceMapFileSpan(this._inner, {this.isIdentifier = false});

  @override
  int compareTo(SourceSpan other) => _inner.compareTo(other);
  @override
  String highlight({color}) => _inner.highlight(color: color);
  @override
  SourceSpan union(SourceSpan other) => _inner.union(other);
  @override
  FileSpan expand(FileSpan other) => _inner.expand(other);
  @override
  String message(String message, {color}) =>
      _inner.message(message, color: color);
  @override
  String toString() =>
      _inner.toString().replaceAll('FileSpan', 'SourceMapFileSpan');
}
