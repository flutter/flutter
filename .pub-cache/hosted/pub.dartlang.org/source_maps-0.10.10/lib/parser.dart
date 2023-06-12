// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains the top-level function to parse source maps version 3.
library source_maps.parser;

import 'dart:convert';

import 'package:source_span/source_span.dart';

import 'builder.dart' as builder;
import 'src/source_map_span.dart';
import 'src/utils.dart';
import 'src/vlq.dart';

/// Parses a source map directly from a json string.
///
/// [mapUrl], which may be either a [String] or a [Uri], indicates the URL of
/// the source map file itself. If it's passed, any URLs in the source
/// map will be interpreted as relative to this URL when generating spans.
// TODO(sigmund): evaluate whether other maps should have the json parsed, or
// the string represenation.
// TODO(tjblasi): Ignore the first line of [jsonMap] if the JSON safety string
// `)]}'` begins the string representation of the map.
Mapping parse(String jsonMap,
        {Map<String, Map>? otherMaps, /*String|Uri*/ Object? mapUrl}) =>
    parseJson(jsonDecode(jsonMap), otherMaps: otherMaps, mapUrl: mapUrl);

/// Parses a source map or source map bundle directly from a json string.
///
/// [mapUrl], which may be either a [String] or a [Uri], indicates the URL of
/// the source map file itself. If it's passed, any URLs in the source
/// map will be interpreted as relative to this URL when generating spans.
Mapping parseExtended(String jsonMap,
        {Map<String, Map>? otherMaps, /*String|Uri*/ Object? mapUrl}) =>
    parseJsonExtended(jsonDecode(jsonMap),
        otherMaps: otherMaps, mapUrl: mapUrl);

/// Parses a source map or source map bundle.
///
/// [mapUrl], which may be either a [String] or a [Uri], indicates the URL of
/// the source map file itself. If it's passed, any URLs in the source
/// map will be interpreted as relative to this URL when generating spans.
Mapping parseJsonExtended(/*List|Map*/ Object? json,
    {Map<String, Map>? otherMaps, /*String|Uri*/ Object? mapUrl}) {
  if (json is List) {
    return MappingBundle.fromJson(json, mapUrl: mapUrl);
  }
  return parseJson(json as Map);
}

/// Parses a source map
///
/// [mapUrl], which may be either a [String] or a [Uri], indicates the URL of
/// the source map file itself. If it's passed, any URLs in the source
/// map will be interpreted as relative to this URL when generating spans.
Mapping parseJson(Map map,
    {Map<String, Map>? otherMaps, /*String|Uri*/ Object? mapUrl}) {
  if (map['version'] != 3) {
    throw ArgumentError('unexpected source map version: ${map["version"]}. '
        'Only version 3 is supported.');
  }

  if (map.containsKey('sections')) {
    if (map.containsKey('mappings') ||
        map.containsKey('sources') ||
        map.containsKey('names')) {
      throw FormatException('map containing "sections" '
          'cannot contain "mappings", "sources", or "names".');
    }
    return MultiSectionMapping.fromJson(map['sections'], otherMaps,
        mapUrl: mapUrl);
  }
  return SingleMapping.fromJson(map, mapUrl: mapUrl);
}

/// A mapping parsed out of a source map.
abstract class Mapping {
  /// Returns the span associated with [line] and [column].
  ///
  /// [uri] is the optional location of the output file to find the span for
  /// to disambiguate cases where a mapping may have different mappings for
  /// different output files.
  SourceMapSpan? spanFor(int line, int column,
      {Map<String, SourceFile>? files, String? uri});

  /// Returns the span associated with [location].
  SourceMapSpan? spanForLocation(SourceLocation location,
      {Map<String, SourceFile>? files}) {
    return spanFor(location.line, location.column,
        uri: location.sourceUrl?.toString(), files: files);
  }
}

/// A meta-level map containing sections.
class MultiSectionMapping extends Mapping {
  /// For each section, the start line offset.
  final List<int> _lineStart = <int>[];

  /// For each section, the start column offset.
  final List<int> _columnStart = <int>[];

  /// For each section, the actual source map information, which is not adjusted
  /// for offsets.
  final List<Mapping> _maps = <Mapping>[];

  /// Creates a section mapping from json.
  MultiSectionMapping.fromJson(List sections, Map<String, Map>? otherMaps,
      {/*String|Uri*/ Object? mapUrl}) {
    for (var section in sections) {
      var offset = section['offset'];
      if (offset == null) throw FormatException('section missing offset');

      var line = section['offset']['line'];
      if (line == null) throw FormatException('offset missing line');

      var column = section['offset']['column'];
      if (column == null) throw FormatException('offset missing column');

      _lineStart.add(line);
      _columnStart.add(column);

      var url = section['url'];
      var map = section['map'];

      if (url != null && map != null) {
        throw FormatException("section can't use both url and map entries");
      } else if (url != null) {
        var other = otherMaps?[url];
        if (otherMaps == null || other == null) {
          throw FormatException(
              'section contains refers to $url, but no map was '
              'given for it. Make sure a map is passed in "otherMaps"');
        }
        _maps.add(parseJson(other, otherMaps: otherMaps, mapUrl: url));
      } else if (map != null) {
        _maps.add(parseJson(map, otherMaps: otherMaps, mapUrl: mapUrl));
      } else {
        throw FormatException('section missing url or map');
      }
    }
    if (_lineStart.isEmpty) {
      throw FormatException('expected at least one section');
    }
  }

  int _indexFor(int line, int column) {
    for (var i = 0; i < _lineStart.length; i++) {
      if (line < _lineStart[i]) return i - 1;
      if (line == _lineStart[i] && column < _columnStart[i]) return i - 1;
    }
    return _lineStart.length - 1;
  }

  @override
  SourceMapSpan? spanFor(int line, int column,
      {Map<String, SourceFile>? files, String? uri}) {
    // TODO(jacobr): perhaps verify that targetUrl matches the actual uri
    // or at least ends in the same file name.
    var index = _indexFor(line, column);
    return _maps[index].spanFor(
        line - _lineStart[index], column - _columnStart[index],
        files: files);
  }

  @override
  String toString() {
    var buff = StringBuffer('$runtimeType : [');
    for (var i = 0; i < _lineStart.length; i++) {
      buff
        ..write('(')
        ..write(_lineStart[i])
        ..write(',')
        ..write(_columnStart[i])
        ..write(':')
        ..write(_maps[i])
        ..write(')');
    }
    buff.write(']');
    return buff.toString();
  }
}

class MappingBundle extends Mapping {
  final Map<String, SingleMapping> _mappings = {};

  MappingBundle();

  MappingBundle.fromJson(List json, {/*String|Uri*/ Object? mapUrl}) {
    for (var map in json) {
      addMapping(parseJson(map, mapUrl: mapUrl) as SingleMapping);
    }
  }

  void addMapping(SingleMapping mapping) {
    // TODO(jacobr): verify that targetUrl is valid uri instead of a windows
    // path.
    // TODO: Remove type arg https://github.com/dart-lang/sdk/issues/42227
    var targetUrl = ArgumentError.checkNotNull<String>(
        mapping.targetUrl, 'mapping.targetUrl');
    _mappings[targetUrl] = mapping;
  }

  /// Encodes the Mapping mappings as a json map.
  List toJson() => _mappings.values.map((v) => v.toJson()).toList();

  @override
  String toString() {
    var buff = StringBuffer();
    for (var map in _mappings.values) {
      buff.write(map.toString());
    }
    return buff.toString();
  }

  bool containsMapping(String url) => _mappings.containsKey(url);

  @override
  SourceMapSpan? spanFor(int line, int column,
      {Map<String, SourceFile>? files, String? uri}) {
    // TODO: Remove type arg https://github.com/dart-lang/sdk/issues/42227
    uri = ArgumentError.checkNotNull<String>(uri, 'uri');

    // Find the longest suffix of the uri that matches the sourcemap
    // where the suffix starts after a path segment boundary.
    // We consider ":" and "/" as path segment boundaries so that
    // "package:" uris can be handled with minimal special casing. Having a
    // few false positive path segment boundaries is not a significant issue
    // as we prefer the longest matching prefix.
    // Using package:path `path.split` to find path segment boundaries would
    // not generate all of the path segment boundaries we want for "package:"
    // urls as "package:package_name" would be one path segment when we want
    // "package" and "package_name" to be sepearate path segments.

    var onBoundary = true;
    var separatorCodeUnits = ['/'.codeUnitAt(0), ':'.codeUnitAt(0)];
    for (var i = 0; i < uri.length; ++i) {
      if (onBoundary) {
        var candidate = uri.substring(i);
        var candidateMapping = _mappings[candidate];
        if (candidateMapping != null) {
          return candidateMapping.spanFor(line, column,
              files: files, uri: candidate);
        }
      }
      onBoundary = separatorCodeUnits.contains(uri.codeUnitAt(i));
    }

    // Note: when there is no source map for an uri, this behaves like an
    // identity function, returning the requested location as the result.

    // Create a mock offset for the output location. We compute it in terms
    // of the input line and column to minimize the chances that two different
    // line and column locations are mapped to the same offset.
    var offset = line * 1000000 + column;
    var location = SourceLocation(offset,
        line: line, column: column, sourceUrl: Uri.parse(uri));
    return SourceMapSpan(location, location, '');
  }
}

/// A map containing direct source mappings.
class SingleMapping extends Mapping {
  /// Source urls used in the mapping, indexed by id.
  final List<String> urls;

  /// Source names used in the mapping, indexed by id.
  final List<String> names;

  /// The [SourceFile]s to which the entries in [lines] refer.
  ///
  /// This is in the same order as [urls]. If this was constructed using
  /// [SingleMapping.fromEntries], this contains files from any [FileLocation]s
  /// used to build the mapping. If it was parsed from JSON, it contains files
  /// for any sources whose contents were provided via the `"sourcesContent"`
  /// field.
  ///
  /// Files whose contents aren't available are `null`.
  final List<SourceFile?> files;

  /// Entries indicating the beginning of each span.
  final List<TargetLineEntry> lines;

  /// Url of the target file.
  String? targetUrl;

  /// Source root prepended to all entries in [urls].
  String? sourceRoot;

  final Uri? _mapUrl;

  final Map<String, dynamic> extensions;

  SingleMapping._(this.targetUrl, this.files, this.urls, this.names, this.lines)
      : _mapUrl = null,
        extensions = {};

  factory SingleMapping.fromEntries(Iterable<builder.Entry> entries,
      [String? fileUrl]) {
    // The entries needs to be sorted by the target offsets.
    var sourceEntries = entries.toList()..sort();
    var lines = <TargetLineEntry>[];

    // Indices associated with file urls that will be part of the source map. We
    // rely on map order so that `urls.keys[urls[u]] == u`
    var urls = <String, int>{};

    // Indices associated with identifiers that will be part of the source map.
    // We rely on map order so that `names.keys[names[n]] == n`
    var names = <String, int>{};

    /// The file for each URL, indexed by [urls]' values.
    var files = <int, SourceFile>{};

    var lineNum;
    late List<TargetEntry> targetEntries;
    for (var sourceEntry in sourceEntries) {
      if (lineNum == null || sourceEntry.target.line > lineNum) {
        lineNum = sourceEntry.target.line;
        targetEntries = <TargetEntry>[];
        lines.add(TargetLineEntry(lineNum, targetEntries));
      }

      var sourceUrl = sourceEntry.source.sourceUrl;
      var urlId = urls.putIfAbsent(
          sourceUrl == null ? '' : sourceUrl.toString(), () => urls.length);

      if (sourceEntry.source is FileLocation) {
        files.putIfAbsent(
            urlId, () => (sourceEntry.source as FileLocation).file);
      }

      var sourceEntryIdentifierName = sourceEntry.identifierName;
      var srcNameId = sourceEntryIdentifierName == null
          ? null
          : names.putIfAbsent(sourceEntryIdentifierName, () => names.length);
      targetEntries.add(TargetEntry(sourceEntry.target.column, urlId,
          sourceEntry.source.line, sourceEntry.source.column, srcNameId));
    }
    return SingleMapping._(fileUrl, urls.values.map((i) => files[i]).toList(),
        urls.keys.toList(), names.keys.toList(), lines);
  }

  SingleMapping.fromJson(Map map, {mapUrl})
      : targetUrl = map['file'],
        urls = List<String>.from(map['sources']),
        names = List<String>.from(map['names'] ?? []),
        files = List.filled(map['sources'].length, null),
        sourceRoot = map['sourceRoot'],
        lines = <TargetLineEntry>[],
        _mapUrl = mapUrl is String ? Uri.parse(mapUrl) : mapUrl,
        extensions = {} {
    var sourcesContent = map['sourcesContent'] == null
        ? const <String?>[]
        : List<String?>.from(map['sourcesContent']);
    for (var i = 0; i < urls.length && i < sourcesContent.length; i++) {
      var source = sourcesContent[i];
      if (source == null) continue;
      files[i] = SourceFile.fromString(source, url: urls[i]);
    }

    var line = 0;
    var column = 0;
    var srcUrlId = 0;
    var srcLine = 0;
    var srcColumn = 0;
    var srcNameId = 0;
    var tokenizer = _MappingTokenizer(map['mappings']);
    var entries = <TargetEntry>[];

    while (tokenizer.hasTokens) {
      if (tokenizer.nextKind.isNewLine) {
        if (entries.isNotEmpty) {
          lines.add(TargetLineEntry(line, entries));
          entries = <TargetEntry>[];
        }
        line++;
        column = 0;
        tokenizer._consumeNewLine();
        continue;
      }

      // Decode the next entry, using the previous encountered values to
      // decode the relative values.
      //
      // We expect 1, 4, or 5 values. If present, values are expected in the
      // following order:
      //   0: the starting column in the current line of the generated file
      //   1: the id of the original source file
      //   2: the starting line in the original source
      //   3: the starting column in the original source
      //   4: the id of the original symbol name
      // The values are relative to the previous encountered values.
      if (tokenizer.nextKind.isNewSegment) throw _segmentError(0, line);
      column += tokenizer._consumeValue();
      if (!tokenizer.nextKind.isValue) {
        entries.add(TargetEntry(column));
      } else {
        srcUrlId += tokenizer._consumeValue();
        if (srcUrlId >= urls.length) {
          throw StateError(
              'Invalid source url id. $targetUrl, $line, $srcUrlId');
        }
        if (!tokenizer.nextKind.isValue) throw _segmentError(2, line);
        srcLine += tokenizer._consumeValue();
        if (!tokenizer.nextKind.isValue) throw _segmentError(3, line);
        srcColumn += tokenizer._consumeValue();
        if (!tokenizer.nextKind.isValue) {
          entries.add(TargetEntry(column, srcUrlId, srcLine, srcColumn));
        } else {
          srcNameId += tokenizer._consumeValue();
          if (srcNameId >= names.length) {
            throw StateError('Invalid name id: $targetUrl, $line, $srcNameId');
          }
          entries.add(
              TargetEntry(column, srcUrlId, srcLine, srcColumn, srcNameId));
        }
      }
      if (tokenizer.nextKind.isNewSegment) tokenizer._consumeNewSegment();
    }
    if (entries.isNotEmpty) {
      lines.add(TargetLineEntry(line, entries));
    }

    map.forEach((name, value) {
      if (name.startsWith('x_')) extensions[name] = value;
    });
  }

  /// Encodes the Mapping mappings as a json map.
  ///
  /// If [includeSourceContents] is `true`, this includes the source file
  /// contents from [files] in the map if possible.
  Map toJson({bool includeSourceContents = false}) {
    var buff = StringBuffer();
    var line = 0;
    var column = 0;
    var srcLine = 0;
    var srcColumn = 0;
    var srcUrlId = 0;
    var srcNameId = 0;
    var first = true;

    for (var entry in lines) {
      var nextLine = entry.line;
      if (nextLine > line) {
        for (var i = line; i < nextLine; ++i) {
          buff.write(';');
        }
        line = nextLine;
        column = 0;
        first = true;
      }

      for (var segment in entry.entries) {
        if (!first) buff.write(',');
        first = false;
        column = _append(buff, column, segment.column);

        // Encoding can be just the column offset if there is no source
        // information.
        var newUrlId = segment.sourceUrlId;
        if (newUrlId == null) continue;
        srcUrlId = _append(buff, srcUrlId, newUrlId);
        srcLine = _append(buff, srcLine, segment.sourceLine!);
        srcColumn = _append(buff, srcColumn, segment.sourceColumn!);

        if (segment.sourceNameId == null) continue;
        srcNameId = _append(buff, srcNameId, segment.sourceNameId!);
      }
    }

    var result = {
      'version': 3,
      'sourceRoot': sourceRoot ?? '',
      'sources': urls,
      'names': names,
      'mappings': buff.toString()
    };
    if (targetUrl != null) result['file'] = targetUrl!;

    if (includeSourceContents) {
      result['sourcesContent'] = files.map((file) => file?.getText(0)).toList();
    }
    extensions.forEach((name, value) => result[name] = value);

    return result;
  }

  /// Appends to [buff] a VLQ encoding of [newValue] using the difference
  /// between [oldValue] and [newValue]
  static int _append(StringBuffer buff, int oldValue, int newValue) {
    buff.writeAll(encodeVlq(newValue - oldValue));
    return newValue;
  }

  StateError _segmentError(int seen, int line) =>
      StateError('Invalid entry in sourcemap, expected 1, 4, or 5'
          ' values, but got $seen.\ntargeturl: $targetUrl, line: $line');

  /// Returns [TargetLineEntry] which includes the location in the target [line]
  /// number. In particular, the resulting entry is the last entry whose line
  /// number is lower or equal to [line].
  TargetLineEntry? _findLine(int line) {
    var index = binarySearch(lines, (e) => e.line > line);
    return (index <= 0) ? null : lines[index - 1];
  }

  /// Returns [TargetEntry] which includes the location denoted by
  /// [line], [column]. If [lineEntry] corresponds to [line], then this will be
  /// the last entry whose column is lower or equal than [column]. If
  /// [lineEntry] corresponds to a line prior to [line], then the result will be
  /// the very last entry on that line.
  TargetEntry? _findColumn(int line, int column, TargetLineEntry? lineEntry) {
    if (lineEntry == null || lineEntry.entries.isEmpty) return null;
    if (lineEntry.line != line) return lineEntry.entries.last;
    var entries = lineEntry.entries;
    var index = binarySearch(entries, (e) => e.column > column);
    return (index <= 0) ? null : entries[index - 1];
  }

  @override
  SourceMapSpan? spanFor(int line, int column,
      {Map<String, SourceFile>? files, String? uri}) {
    var entry = _findColumn(line, column, _findLine(line));
    if (entry == null) return null;

    var sourceUrlId = entry.sourceUrlId;
    if (sourceUrlId == null) return null;

    var url = urls[sourceUrlId];
    if (sourceRoot != null) {
      url = '${sourceRoot}${url}';
    }

    var sourceNameId = entry.sourceNameId;
    var file = files?[url];
    if (file != null) {
      var start = file.getOffset(entry.sourceLine!, entry.sourceColumn);
      if (sourceNameId != null) {
        var text = names[sourceNameId];
        return SourceMapFileSpan(file.span(start, start + text.length),
            isIdentifier: true);
      } else {
        return SourceMapFileSpan(file.location(start).pointSpan());
      }
    } else {
      var start = SourceLocation(0,
          sourceUrl: _mapUrl?.resolve(url) ?? url,
          line: entry.sourceLine,
          column: entry.sourceColumn);

      // Offset and other context is not available.
      if (sourceNameId != null) {
        return SourceMapSpan.identifier(start, names[sourceNameId]);
      } else {
        return SourceMapSpan(start, start, '');
      }
    }
  }

  @override
  String toString() {
    return (StringBuffer('$runtimeType : [')
          ..write('targetUrl: ')
          ..write(targetUrl)
          ..write(', sourceRoot: ')
          ..write(sourceRoot)
          ..write(', urls: ')
          ..write(urls)
          ..write(', names: ')
          ..write(names)
          ..write(', lines: ')
          ..write(lines)
          ..write(']'))
        .toString();
  }

  String get debugString {
    var buff = StringBuffer();
    for (var lineEntry in lines) {
      var line = lineEntry.line;
      for (var entry in lineEntry.entries) {
        buff
          ..write(targetUrl)
          ..write(': ')
          ..write(line)
          ..write(':')
          ..write(entry.column);
        var sourceUrlId = entry.sourceUrlId;
        if (sourceUrlId != null) {
          buff
            ..write('   -->   ')
            ..write(sourceRoot)
            ..write(urls[sourceUrlId])
            ..write(': ')
            ..write(entry.sourceLine)
            ..write(':')
            ..write(entry.sourceColumn);
        }
        var sourceNameId = entry.sourceNameId;
        if (sourceNameId != null) {
          buff..write(' (')..write(names[sourceNameId])..write(')');
        }
        buff.write('\n');
      }
    }
    return buff.toString();
  }
}

/// A line entry read from a source map.
class TargetLineEntry {
  final int line;
  List<TargetEntry> entries;
  TargetLineEntry(this.line, this.entries);

  @override
  String toString() => '$runtimeType: $line $entries';
}

/// A target segment entry read from a source map
class TargetEntry {
  final int column;
  final int? sourceUrlId;
  final int? sourceLine;
  final int? sourceColumn;
  final int? sourceNameId;

  TargetEntry(this.column,
      [this.sourceUrlId,
      this.sourceLine,
      this.sourceColumn,
      this.sourceNameId]);

  @override
  String toString() => '$runtimeType: '
      '($column, $sourceUrlId, $sourceLine, $sourceColumn, $sourceNameId)';
}

/// A character iterator over a string that can peek one character ahead.
class _MappingTokenizer implements Iterator<String> {
  final String _internal;
  final int _length;
  int index = -1;
  _MappingTokenizer(String internal)
      : _internal = internal,
        _length = internal.length;

  // Iterator API is used by decodeVlq to consume VLQ entries.
  @override
  bool moveNext() => ++index < _length;

  @override
  String get current => (index >= 0 && index < _length)
      ? _internal[index]
      : throw RangeError.index(index, _internal);

  bool get hasTokens => index < _length - 1 && _length > 0;

  _TokenKind get nextKind {
    if (!hasTokens) return _TokenKind.EOF;
    var next = _internal[index + 1];
    if (next == ';') return _TokenKind.LINE;
    if (next == ',') return _TokenKind.SEGMENT;
    return _TokenKind.VALUE;
  }

  int _consumeValue() => decodeVlq(this);
  void _consumeNewLine() {
    ++index;
  }

  void _consumeNewSegment() {
    ++index;
  }

  // Print the state of the iterator, with colors indicating the current
  // position.
  @override
  String toString() {
    var buff = StringBuffer();
    for (var i = 0; i < index; i++) {
      buff.write(_internal[i]);
    }
    buff.write('[31m');
    try {
      buff.write(current);
    } on RangeError catch (_) {}
    buff.write('[0m');
    for (var i = index + 1; i < _internal.length; i++) {
      buff.write(_internal[i]);
    }
    buff.write(' ($index)');
    return buff.toString();
  }
}

class _TokenKind {
  static const _TokenKind LINE = _TokenKind(isNewLine: true);
  static const _TokenKind SEGMENT = _TokenKind(isNewSegment: true);
  static const _TokenKind EOF = _TokenKind(isEof: true);
  static const _TokenKind VALUE = _TokenKind();
  final bool isNewLine;
  final bool isNewSegment;
  final bool isEof;
  bool get isValue => !isNewLine && !isNewSegment && !isEof;

  const _TokenKind(
      {this.isNewLine = false, this.isNewSegment = false, this.isEof = false});
}
