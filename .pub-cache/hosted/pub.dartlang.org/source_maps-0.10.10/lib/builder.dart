// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains a builder object useful for creating source maps programatically.
library source_maps.builder;

// TODO(sigmund): add a builder for multi-section mappings.

import 'dart:convert';

import 'package:source_span/source_span.dart';

import 'parser.dart';
import 'src/source_map_span.dart';

/// Builds a source map given a set of mappings.
class SourceMapBuilder {
  final List<Entry> _entries = <Entry>[];

  /// Adds an entry mapping the [targetOffset] to [source].
  void addFromOffset(SourceLocation source, SourceFile targetFile,
      int targetOffset, String identifier) {
    ArgumentError.checkNotNull(targetFile, 'targetFile');
    _entries.add(Entry(source, targetFile.location(targetOffset), identifier));
  }

  /// Adds an entry mapping [target] to [source].
  ///
  /// If [isIdentifier] is true or if [target] is a [SourceMapSpan] with
  /// `isIdentifier` set to true, this entry is considered to represent an
  /// identifier whose value will be stored in the source map. [isIdentifier]
  /// takes precedence over [target]'s `isIdentifier` value.
  void addSpan(SourceSpan source, SourceSpan target, {bool? isIdentifier}) {
    isIdentifier ??= source is SourceMapSpan ? source.isIdentifier : false;

    var name = isIdentifier ? source.text : null;
    _entries.add(Entry(source.start, target.start, name));
  }

  /// Adds an entry mapping [target] to [source].
  void addLocation(
      SourceLocation source, SourceLocation target, String? identifier) {
    _entries.add(Entry(source, target, identifier));
  }

  /// Encodes all mappings added to this builder as a json map.
  Map build(String fileUrl) {
    return SingleMapping.fromEntries(_entries, fileUrl).toJson();
  }

  /// Encodes all mappings added to this builder as a json string.
  String toJson(String fileUrl) => jsonEncode(build(fileUrl));
}

/// An entry in the source map builder.
class Entry implements Comparable<Entry> {
  /// Span denoting the original location in the input source file
  final SourceLocation source;

  /// Span indicating the corresponding location in the target file.
  final SourceLocation target;

  /// An identifier name, when this location is the start of an identifier.
  final String? identifierName;

  /// Creates a new [Entry] mapping [target] to [source].
  Entry(this.source, this.target, this.identifierName);

  /// Implements [Comparable] to ensure that entries are ordered by their
  /// location in the target file. We sort primarily by the target offset
  /// because source map files are encoded by printing each mapping in order as
  /// they appear in the target file.
  @override
  int compareTo(Entry other) {
    var res = target.compareTo(other.target);
    if (res != 0) return res;
    res = source.sourceUrl
        .toString()
        .compareTo(other.source.sourceUrl.toString());
    if (res != 0) return res;
    return source.compareTo(other.source);
  }
}
