// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library vm_snapshot_analysis.utils;

import 'package:vm_snapshot_analysis/ascii_table.dart';
import 'package:vm_snapshot_analysis/instruction_sizes.dart'
    as instruction_sizes;
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/treemap.dart';
import 'package:vm_snapshot_analysis/v8_profile.dart' as v8_profile;

ProgramInfo loadProgramInfoFromJson(Object json,
    {bool collapseAnonymousClosures = false}) {
  if (v8_profile.Snapshot.isV8HeapSnapshot(json)) {
    return v8_profile.toProgramInfo(
        v8_profile.Snapshot.fromJson(json as Map<String, dynamic>),
        collapseAnonymousClosures: collapseAnonymousClosures);
  } else {
    return instruction_sizes.loadProgramInfo(json as List<dynamic>,
        collapseAnonymousClosures: collapseAnonymousClosures);
  }
}

/// Compare two size profiles and return result of the comparison as a treemap.
Map<String, dynamic> buildComparisonTreemap(Object oldJson, Object newJson,
    {TreemapFormat format = TreemapFormat.collapsed,
    bool collapseAnonymousClosures = false}) {
  final oldSizes = loadProgramInfoFromJson(oldJson,
      collapseAnonymousClosures: collapseAnonymousClosures);
  final newSizes = loadProgramInfoFromJson(newJson,
      collapseAnonymousClosures: collapseAnonymousClosures);

  return compareProgramInfo(oldSizes, newSizes, format: format);
}

Map<String, dynamic> compareProgramInfo(
    ProgramInfo oldSizes, ProgramInfo newSizes,
    {TreemapFormat format = TreemapFormat.collapsed}) {
  final diff = computeDiff(oldSizes, newSizes);
  return treemapFromInfo(diff, format: format);
}

String formatPercent(int value, int total, {bool withSign = false}) {
  final p = value / total * 100.0;
  final sign = (withSign && value > 0) ? '+' : '';
  return '$sign${p.toStringAsFixed(2)}%';
}

void printHistogram(ProgramInfo info, Histogram histogram,
    {Iterable<String> prefix = const [],
    Iterable<String> suffix = const [],
    String sizeHeader = 'Size (Bytes)',
    int maxWidth = 0}) {
  final totalSize = info.totalSize;
  final wasFiltered = totalSize != histogram.totalSize;
  final table = AsciiTable(header: [
    for (var col in histogram.bucketInfo.nameComponents) Text.left(col),
    Text.right(sizeHeader),
    Text.right('Percent'),
    if (wasFiltered) Text.right('Of total'),
  ], maxWidth: maxWidth);

  final visibleRows = [prefix, suffix].expand((l) => l).toList();
  final visibleSize =
      visibleRows.fold<int>(0, (sum, key) => sum + histogram.buckets[key]!);
  final numRestRows = histogram.length - (suffix.length + prefix.length);
  final hiddenRows = Set<String>.from(histogram.bySize)
      .difference(Set<String>.from(visibleRows));
  final interestingHiddenRows =
      hiddenRows.any((k) => histogram.buckets[k] != 0);

  if (prefix.isNotEmpty) {
    for (var key in prefix) {
      final size = histogram.buckets[key]!;
      table.addRow([
        ...histogram.bucketInfo.namesFromBucket(key),
        size.toString(),
        formatPercent(size, histogram.totalSize),
        if (wasFiltered) formatPercent(size, totalSize),
      ]);
    }
    table.addSeparator(interestingHiddenRows ? Separator.wave : Separator.line);
  }

  if (interestingHiddenRows) {
    final totalRestBytes = histogram.totalSize - visibleSize;
    table.addTextSeparator(
        '$numRestRows more rows accounting for $totalRestBytes'
        ' (${formatPercent(totalRestBytes, totalSize)} of total) bytes');
    final avg = (totalRestBytes / numRestRows).round();
    table.addTextSeparator(
        'on average that is $avg (${formatPercent(avg, histogram.totalSize)})'
        ' bytes per row');
    table.addSeparator(suffix.isNotEmpty ? Separator.wave : Separator.line);
  }

  if (suffix.isNotEmpty) {
    for (var key in suffix) {
      table.addRow([
        ...histogram.bucketInfo.namesFromBucket(key),
        histogram.buckets[key].toString(),
        formatPercent(histogram.buckets[key]!, histogram.totalSize),
      ]);
    }
    table.addSeparator(Separator.line);
  }

  table.render();

  if (wasFiltered || visibleSize != histogram.totalSize) {
    print('In visible rows: $visibleSize'
        ' (${formatPercent(visibleSize, totalSize)} of total)');
  }
  print('Total: $totalSize bytes');
}

List<String> partsForPath(String path) {
  final parts = path.split('/');
  if (parts.first.startsWith('package:')) {
    // Convert dot separated package name into a path from which this package originated.
    parts.replaceRange(0, 1, parts.first.split('.'));
  }
  return parts;
}
