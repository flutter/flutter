// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This command allows to inspect information written into the
/// precompiler trace (`--trace-precompiler-to` output).
library vm_snapshot_analysis.explain;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/command_runner.dart';

import 'package:vm_snapshot_analysis/name.dart';
import 'package:vm_snapshot_analysis/precompiler_trace.dart';
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/utils.dart';

import 'utils.dart';

class ExplainCommand extends Command<void> {
  @override
  final name = 'explain';

  @override
  final description = '''
Explain why certain methods were pulled into the binary.
''';

  ExplainCommand() {
    addSubcommand(ExplainDynamicCallsCommand());
  }
}

/// Generates a summary report about dynamic calls sorted by approximation
/// of their retained size, i.e. the amount of bytes these calls are pulling
/// into the snapshot.
class ExplainDynamicCallsCommand extends Command<void> {
  @override
  final name = 'dynamic-calls';

  @override
  final description = '''
This command explains impact of the dynamic calls on the binary size.

It needs AOT snapshot size profile (an output of either
--write-v8-snapshot-profile-to or --print-instructions-sizes-to flags) and
precompiler trace (an output of --trace-precompiler-to flag).
''';

  ExplainDynamicCallsCommand();

  @override
  Future<void> run() async {
    final args = argResults!;

    final sizesJson = File(args.rest[0]);
    if (!sizesJson.existsSync()) {
      usageException('Size profile ${sizesJson.path} does not exist!');
    }
    final sizesJsonRaw = await loadJsonFromFile(sizesJson);

    final traceJson = File(args.rest[1]);
    if (!traceJson.existsSync()) {
      usageException('Size profile ${traceJson.path} does not exist!');
    }
    final traceJsonRaw = await loadJsonFromFile(traceJson);

    final callGraph = loadTrace(traceJsonRaw);
    callGraph.computeDominators();

    final programInfo = loadProgramInfoFromJson(sizesJsonRaw);

    final histogram = Histogram.fromIterable<CallGraphNode>(
        callGraph.dynamicCalls, sizeOf: (dynamicCall) {
      // Compute approximate retained size by traversing the dominator tree
      // and consulting snapshot profile.
      var totalSize = 0;
      dynamicCall.visitDominatorTree((retained, depth) {
        if (retained.isFunctionNode) {
          // Note that call graph keeps private library keys intact in the
          // names (because we need to distinguish dynamic invocations
          // through with the same private name in different libraries).
          // So we need to scrub the path before we lookup information in the
          // profile.
          final path = (retained.data as ProgramInfoNode)
              .path
              .map((n) => Name(n).scrubbed)
              .toList();
          if (path.last.startsWith('[tear-off] ')) {
            // Tear-off forwarder is placed into the function that is torn so
            // we need to slightly tweak the path to be able to find it.
            path.insert(
                path.length - 1, path.last.replaceAll('[tear-off] ', ''));
          }
          final retainedSize = programInfo.lookup(path);
          totalSize += (retainedSize?.totalSize ?? 0);
        }
        return true;
      });
      return totalSize;
    }, bucketFor: (n) {
      return (n.data as String).replaceAll('dyn:', '');
    }, bucketInfo: BucketInfo(nameComponents: ['Selector']));

    printHistogram(programInfo, histogram,
        prefix: histogram.bySize.where((key) => histogram.buckets[key]! > 0));

    // For top 10 dynamic selectors print the functions which contain these
    // dynamic calls.
    for (var selector
        in histogram.bySize.take(math.min(10, histogram.length))) {
      final dynSelector = 'dyn:$selector';
      final callNodes = callGraph.nodes
          .where((n) => n.data == selector || n.data == dynSelector);

      print('\nDynamic call to $selector'
          ' (retaining ~${histogram.buckets[selector]} bytes) occurs in:');
      for (var node in callNodes) {
        for (var pred in node.pred) {
          print('    ${pred.data.qualifiedName}');
        }
      }
    }
  }

  @override
  String get invocation =>
      super.invocation.replaceAll('[arguments]', '<sizes.json> <trace.json>');
}
