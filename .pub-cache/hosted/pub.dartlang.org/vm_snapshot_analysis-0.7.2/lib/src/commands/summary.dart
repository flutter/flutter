// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool generates a summary report from a binary size reports produced by
/// the AOT compiler's --print-instructions-sizes-to and
/// --write-v8-snapshot-profile-to flags.
library vm_snapshot_analysis.summary;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/command_runner.dart';

import 'package:vm_snapshot_analysis/ascii_table.dart';
import 'package:vm_snapshot_analysis/precompiler_trace.dart';
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/utils.dart';
import 'package:vm_snapshot_analysis/v8_profile.dart';

import 'utils.dart';

class SummaryCommand extends Command<void> {
  @override
  final name = 'summary';

  @override
  final description = '''
Generate a summary report from a AOT compilers binary size dumps.

This tool can process snapshot size reports produced by
--print-instructions-sizes-to=symbol-sizes.json and
--write-v8-snapshot-profile-to=profile.heapsnapshot flags.
''';

  SummaryCommand() {
    argParser
      ..addOption('column-width',
          help: 'Truncate column content to the given width'
              ' (${AsciiTable.unlimitedWidth} means do not truncate).',
          defaultsTo: AsciiTable.unlimitedWidth.toString())
      ..addOption('by',
          abbr: 'b',
          help: 'Choose breakdown rule of the output.',
          allowed: ['method', 'class', 'library', 'package'],
          defaultsTo: 'method')
      ..addOption(
        'where',
        abbr: 'w',
        help: 'Filter output using the given glob.',
      )
      ..addOption(
        'precompiler-trace',
        abbr: 't',
        help: '''
Precompiler trace to establish dependencies between libraries/packages.
''',
      )
      ..addOption(
        'deps-start-depth',
        abbr: 's',
        defaultsTo: '2',
        help: '''
Depth at which to start the dependency tree. At this depth and above, nodes are
collapsed together. Only has affect if --precompiler-trace is also passed.
''',
      )
      ..addOption(
        'deps-display-depth',
        abbr: 'd',
        defaultsTo: '4',
        help: '''
Display depth of the dependency tree. Nodes below this level will be displayed
as a summary. Only has affect if --precompiler-trace is also passed.
''',
      )
      ..addFlag('collapse-anonymous-closures', help: '''
Collapse all anonymous closures from the same scope into a single entry.
When comparing size of AOT snapshots for two different versions of a
program there is no reliable way to precisely establish which two anonymous
closures are the same and should be compared in size - so
comparison might produce a noisy output. This option reduces confusion
by collapsing different anonymous closures within the same scope into a
single entry. Note that when comparing the same application compiled
with two different versions of an AOT compiler closures can be distinguished
precisely based on their source position (which is included in their name).
''');
  }

  @override
  String get invocation =>
      super.invocation.replaceAll('[arguments]', '<sizes.json>');

  @override
  Future<void> run() async {
    final args = argResults!;

    if (args.rest.length != 1) {
      usageException('Need to specify input JSON.');
    }

    final input = File(args.rest[0]);
    if (!input.existsSync()) {
      usageException('Input file ${input.path} does not exist!');
    }

    final granularity = _parseHistogramType(args['by']);

    final traceJson = args['precompiler-trace'];
    if (traceJson != null) {
      if (!File(traceJson).existsSync()) {
        usageException('Trace $traceJson does not exist!');
      }

      if (granularity != HistogramType.byPackage &&
          granularity != HistogramType.byLibrary) {
        usageException(
            '--precompiler-trace only has effect when summarizing by library or package');
      }
    }

    final columnWidth = args['column-width'];
    final maxWidth = int.tryParse(columnWidth);
    if (maxWidth == null) {
      usageException('Specified column width ($columnWidth) is not an integer');
    }

    final depsStartDepthStr = args['deps-start-depth'];
    final depsStartDepth = int.tryParse(depsStartDepthStr);
    if (depsStartDepth == null) {
      usageException('Specified depsStartDepth ($depsStartDepthStr)'
          ' is not an integer');
    }

    final depsDisplayDepthStr = args['deps-display-depth'];
    final depsDisplayDepth = int.tryParse(depsDisplayDepthStr);
    if (depsDisplayDepth == null) {
      usageException('Specified depsDisplayDepth ($depsStartDepthStr)'
          ' is not an integer');
    }

    await outputSummary(input,
        maxWidth: maxWidth,
        granularity: granularity,
        collapseAnonymousClosures: args['collapse-anonymous-closures'],
        filter: args['where'],
        traceJson: traceJson != null ? File(traceJson) : null,
        depsStartDepth: depsStartDepth,
        depsDisplayDepth: depsDisplayDepth);
  }

  HistogramType _parseHistogramType(String value) {
    switch (value) {
      case 'method':
        return HistogramType.bySymbol;
      case 'class':
        return HistogramType.byClass;
      case 'library':
        return HistogramType.byLibrary;
      case 'package':
        return HistogramType.byPackage;
      default:
        usageException('Unrecognized histogram type $value');
    }
  }
}

Future<void> outputSummary(File input,
    {int maxWidth = 0,
    bool collapseAnonymousClosures = false,
    HistogramType granularity = HistogramType.bySymbol,
    String? filter,
    File? traceJson,
    int depsStartDepth = 2,
    int depsDisplayDepth = 4,
    int topToReport = 30}) async {
  final inputJson = await loadJsonFromFile(input);
  final info = loadProgramInfoFromJson(inputJson);

  // Compute histogram.
  var histogram = computeHistogram(info, granularity, filter: filter);

  // If precompiler trace is provided, collapse entries based on the dependency
  // graph (dominator tree) extracted from the trace.
  void Function()? printDependencyTrees;
  if (traceJson != null &&
      (granularity == HistogramType.byLibrary ||
          granularity == HistogramType.byPackage)) {
    final traceJsonRaw = await loadJsonFromFile(traceJson);

    final callGraph = generateCallGraphWithDominators(
      traceJsonRaw,
      granularity == HistogramType.byLibrary
          ? NodeType.libraryNode
          : NodeType.packageNode,
    );

    // Compute name mapping from histogram buckets to new coarser buckets, by
    // collapsing dependency tree at [depsStartDepth] level: node 'Foo' with
    // k dominated children (k > 0) becomes 'Foo (+k deps)' and all its children
    // are remapped to this bucket.
    final mapping = <String, String>{};
    final collapsed = <String, CallGraphNode>{};
    callGraph.root.visitDominatorTree((n, depth) {
      if (depth >= depsStartDepth) {
        final children = <String>[];
        n.visitDominatorTree((child, depth) {
          if (n != child && child.data is ProgramInfoNode) {
            children.add(child.data.name);
          }
          return true;
        }, depth + 1);

        if (children.isNotEmpty) {
          final newName = '${n.data.name} (+ ${children.length} deps)';
          mapping[n.data.name] = newName;
          collapsed[newName] = n;
          for (var name in children) {
            mapping[name] = newName;
          }
        }
        return false;
      }
      return true;
    });

    // Compute cumulative sizes and node counts for each node in the dominator
    // tree. We are going to use this information later to display dependency
    // trees at the end of the summary report.
    // This needs to be done before we loose original histogram.
    final totalSizes = <String, int>{};
    final totalCounts = <String, int>{};
    void computeTotalsRecursively(CallGraphNode node) {
      var totalSize = histogram.buckets[node.data.name] ?? 0;
      var totalCount = 1;
      for (var n in node.dominated) {
        computeTotalsRecursively(n);
        totalSize += totalSizes[n.data.name]!;
        totalCount += totalCounts[n.data.name]!;
      }
      totalSizes[node.data.name] = totalSize;
      totalCounts[node.data.name] = totalCount;
    }

    computeTotalsRecursively(callGraph.root);

    // Transform the histogram using the mapping which we computed.
    histogram = histogram.map((bucket) => mapping[bucket] ?? bucket);

    // Create a helper function to print dependency trees at the end of the
    // report.
    printDependencyTrees = () {
      // This will be the list of collapsed entries which were among those
      // [topToReport] printed by [printHistogram] below.
      final collapsedEntries = histogram.bySize
          .take(topToReport)
          .map((k) => collapsed[k])
          .whereType<CallGraphNode>();
      if (collapsedEntries.isNotEmpty) {
        print('\bDependency trees:');
        for (var n in collapsedEntries) {
          print(
              '\n${n.data.qualifiedName} (total ${totalSizes[n.data.name]} bytes)');
          _printDominatedNodes(n,
              totalSizes: totalSizes,
              totalCounts: totalCounts,
              displayDepth: depsDisplayDepth);
        }
      }
    };
  }

  // Now produce the report table.
  printHistogram(info, histogram,
      prefix: histogram.bySize.take(topToReport), maxWidth: maxWidth);

  if (info.snapshotInfo != null) {
    print('\nBreakdown by object type:');
    final typeHistogram =
        computeHistogram(info, HistogramType.byNodeType, filter: filter);
    printHistogram(info, typeHistogram,
        prefix: typeHistogram.bySize, maxWidth: maxWidth);

    print(bucketLegend);
  }

  printDependencyTrees?.call();
}

/// Helper method for printing dominator tree in the form:
///
/// A (total ... bytes)
/// ├── B (total ... bytes)
/// ├── C (total ... bytes)
/// │   ├── D (total ... bytes)
/// │   └── E (total ... bytes)
/// ├── F (total ... bytes)
/// └── G (total ... bytes)
///
/// Stops printing at the given depth ([displayDepth]) and after the
/// given amount of children at each node ([maxChildrenToPrint]).
void _printDominatedNodes(CallGraphNode node,
    {int displayDepth = 4,
    int maxChildrenToPrint = 10,
    List<bool>? isLastPerLevel,
    required Map<String, int> totalSizes,
    required Map<String, int> totalCounts}) {
  isLastPerLevel ??= [];

  // Subtract one to account for the parent node that is printed before the
  // recursive call.
  if (isLastPerLevel.length >= displayDepth - 1) {
    maxChildrenToPrint = 0;
  }

  final sizes = node.dominated.map((n) => totalSizes[n.data.name]).toList();
  final order = List.generate(node.dominated.length, (i) => i)
    ..sort((a, b) => sizes[b]! - sizes[a]!);
  final lastIndex = order.lastIndexWhere((i) => sizes[i]! > 0);

  for (var j = 0, n = math.min(maxChildrenToPrint - 1, lastIndex);
      j <= n;
      j++) {
    final isLast = j == lastIndex;
    final i = order[j];
    final n = node.dominated[i];
    final size = sizes[i];
    isLastPerLevel.add(isLast);
    print(
        '${_treeLines(isLastPerLevel)}${n.data.qualifiedName} (total $size bytes)');
    _printDominatedNodes(n,
        displayDepth: displayDepth,
        isLastPerLevel: isLastPerLevel,
        totalCounts: totalCounts,
        totalSizes: totalSizes);
    isLastPerLevel.removeLast();
  }

  if (maxChildrenToPrint < lastIndex) {
    isLastPerLevel.add(true);
    print(
        '${_treeLines(isLastPerLevel)} ... (+${totalCounts[node.data.name]! - 1} deps)');
    isLastPerLevel.removeLast();
  }
}

String _treeLines(List<bool> isLastPerLevel) {
  final sb = StringBuffer();
  for (var i = 0; i < isLastPerLevel.length - 1; i++) {
    sb.write(isLastPerLevel[i] ? '    ' : '│   ');
  }
  sb.write(isLastPerLevel.last ? '└── ' : '├── ');
  return sb.toString();
}
