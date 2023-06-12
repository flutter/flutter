// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_snapshot_analysis/precompiler_trace.dart';
import 'package:vm_snapshot_analysis/program_info.dart';

import 'utils.dart';

final testSource = {
  'input.dart': """
class K {
  final value;
  const K(this.value);
}

@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => const K(0),
    () => const K(1),
    () => 11,
  ];
}

class A {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(2);
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(3);
  }
}

class C {
  static dynamic tornOff() async {
    return const K(4);
  }
}

@pragma('vm:never-inline')
Function tearOff(dynamic o) {
  return o.tornOff;
}

void main(List<String> args) {
  for (var cl in makeSomeClosures()) {
    print(cl());
  }
  print(tearOff(args.isEmpty ? A() : B()));
  print(C.tornOff);
}
"""
};

void main() async {
  if (!Platform.executable.contains('dart-sdk')) {
    // If we are not running from the prebuilt SDK then this test does nothing.
    return;
  }

  group('precompiler-trace', () {
    test('basic-parsing', () async {
      await withFlag(testSource, '--trace_precompiler_to', (json) async {
        final jsonRaw = await loadJson(File(json));
        final callGraph = loadTrace(jsonRaw);
        callGraph.computeDominators();

        final main = callGraph.program
            .lookup(['package:input', 'package:input/input.dart', '', 'main'])!;
        final mainNode = callGraph.lookup(main);

        final retainedClasses = mainNode.dominated
            .where((n) => n.isClassNode)
            .map((n) => n.data.name)
            .toList();
        final retainedFunctions = mainNode.dominated
            .where((n) => n.isFunctionNode)
            .map((n) => n.data.name)
            .toList();
        expect(retainedClasses, containsAll(['A', 'B', 'K']));
        expect(retainedFunctions, containsAll(['print', 'tearOff']));

        final getTearOffCall = callGraph.dynamicCalls
            .firstWhere((n) => n.data == 'dyn:get:tornOff');
        expect(
            getTearOffCall.dominated.map((n) => n.data.qualifiedName),
            equals([
              'package:input/input.dart::B.[tear-off-extractor] get:tornOff',
              'package:input/input.dart::A.[tear-off-extractor] get:tornOff',
            ]));
      });
    });

    test('collapse-by-package', () async {
      await withFlag(testSource, '--trace_precompiler_to', (json) async {
        final jsonRaw = await loadJson(File(json));

        final callGraph = loadTrace(jsonRaw).collapse(NodeType.packageNode);

        // Collapsing by package should not collapse dart:* libraries into root
        // node and create predecessors for the root node.
        expect(callGraph.root.pred, isEmpty);
      });
    });

    test('root-dominator-is-null', () async {
      await withFlag(testSource, '--trace_precompiler_to', (json) async {
        final jsonRaw = await loadJson(File(json));

        final callGraph = loadTrace(jsonRaw).collapse(NodeType.classNode);

        expect(callGraph.root.dominator, isNull);
      });
    });
  });
}
