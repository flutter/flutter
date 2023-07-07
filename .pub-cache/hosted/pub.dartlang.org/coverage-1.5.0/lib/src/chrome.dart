// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:coverage/src/hitmap.dart';
import 'package:source_maps/parser.dart';

/// Returns a Dart based hit-map containing coverage report for the provided
/// Chrome [preciseCoverage].
///
/// [sourceProvider] returns the source content for the Chrome scriptId, or null
/// if not available.
///
/// [sourceMapProvider] returns the associated source map content for the Chrome
/// scriptId, or null if not available.
///
/// [sourceUriProvider] returns the uri for the provided sourceUrl and
/// associated scriptId, or null if not available.
///
/// Chrome coverage information for which the corresponding source map or source
/// content is null will be ignored.
Future<Map<String, dynamic>> parseChromeCoverage(
  List<Map<String, dynamic>> preciseCoverage,
  Future<String?> Function(String scriptId) sourceProvider,
  Future<String?> Function(String scriptId) sourceMapProvider,
  Future<Uri?> Function(String sourceUrl, String scriptId) sourceUriProvider,
) async {
  final coverageReport = <Uri, Map<int, bool>>{};
  for (var entry in preciseCoverage) {
    final scriptId = entry['scriptId'] as String;

    final mapResponse = await sourceMapProvider(scriptId);
    if (mapResponse == null) continue;

    SingleMapping mapping;
    try {
      mapping = parse(mapResponse) as SingleMapping;
    } on FormatException {
      continue;
    } on ArgumentError {
      continue;
    }

    final compiledSource = await sourceProvider(scriptId);
    if (compiledSource == null) continue;

    final coverageInfo = _coverageInfoFor(entry);
    final offsetCoverage = _offsetCoverage(coverageInfo, compiledSource.length);
    final coveredPositions = _coveredPositions(compiledSource, offsetCoverage);

    for (var lineEntry in mapping.lines) {
      for (var columnEntry in lineEntry.entries) {
        final sourceUrlId = columnEntry.sourceUrlId;
        if (sourceUrlId == null) continue;
        final sourceUrl = mapping.urls[sourceUrlId];

        // Ignore coverage information for the SDK.
        if (sourceUrl.startsWith('org-dartlang-sdk:')) continue;

        final uri = await sourceUriProvider(sourceUrl, scriptId);
        if (uri == null) continue;
        final coverage = coverageReport.putIfAbsent(uri, () => <int, bool>{});

        final sourceLine = columnEntry.sourceLine!;
        final current = coverage[sourceLine + 1] ?? false;
        coverage[sourceLine + 1] = current ||
            coveredPositions.contains(
                _Position(lineEntry.line + 1, columnEntry.column + 1));
      }
    }
  }

  final coverageHitMaps = <Uri, HitMap>{};
  coverageReport.forEach((uri, coverage) {
    final hitMap = HitMap();
    for (var line in coverage.keys.toList()..sort()) {
      hitMap.lineHits[line] = coverage[line]! ? 1 : 0;
    }
    coverageHitMaps[uri] = hitMap;
  });

  final allCoverage = <Map<String, dynamic>>[];
  coverageHitMaps.forEach((uri, hitMap) {
    allCoverage.add(hitmapToJson(hitMap, uri));
  });
  return <String, dynamic>{'type': 'CodeCoverage', 'coverage': allCoverage};
}

/// Returns all covered positions in a provided source.
Set<_Position> _coveredPositions(
    String compiledSource, List<bool> offsetCoverage) {
  final positions = <_Position>{};
  // Line is 1 based.
  var line = 1;
  // Column is 1 based.
  var column = 0;
  for (var offset = 0; offset < compiledSource.length; offset++) {
    if (compiledSource[offset] == '\n') {
      line++;
      column = 0;
    } else {
      column++;
    }
    if (offsetCoverage[offset]) positions.add(_Position(line, column));
  }
  return positions;
}

/// Returns coverage information for a Chrome entry.
List<_CoverageInfo> _coverageInfoFor(Map<String, dynamic> entry) {
  final result = <_CoverageInfo>[];
  for (var functions
      in (entry['functions'] as List).cast<Map<String, dynamic>>()) {
    for (var range
        in (functions['ranges'] as List).cast<Map<String, dynamic>>()) {
      result.add(_CoverageInfo(
        range['startOffset'] as int,
        range['endOffset'] as int,
        (range['count'] as int) > 0,
      ));
    }
  }
  return result;
}

/// Returns the coverage information for each offset.
List<bool> _offsetCoverage(List<_CoverageInfo> coverageInfo, int sourceLength) {
  final offsetCoverage = List.filled(sourceLength, false);

  // Sort coverage information by their size.
  // Coverage information takes granularity as precedence.
  coverageInfo.sort((a, b) =>
      (b.endOffset - b.startOffset).compareTo(a.endOffset - a.startOffset));

  for (var range in coverageInfo) {
    for (var i = range.startOffset; i < range.endOffset; i++) {
      offsetCoverage[i] = range.isCovered;
    }
  }

  return offsetCoverage;
}

class _CoverageInfo {
  _CoverageInfo(this.startOffset, this.endOffset, this.isCovered);

  /// 0 based byte offset.
  final int startOffset;

  /// 0 based byte offset.
  final int endOffset;

  final bool isCovered;
}

/// A covered position in a source file where [line] and [column] are 1 based.
class _Position {
  _Position(this.line, this.column);

  final int line;
  final int column;

  @override
  int get hashCode => Object.hash(line, column);

  @override
  bool operator ==(dynamic o) =>
      o is _Position && o.line == line && o.column == column;
}
