// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

String optimizedFunction() {
  return 5.toString() + 3.toString();
}

void testFunction() {
  for (var i = 0; i < 20; i++) {
    optimizedFunction();
  }
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    expect(stack.frames![0].function!.name, 'testFunction');

    final root =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final func = await service.getObject(
      isolateId,
      root.functions!.singleWhere((f) => f.name == 'optimizedFunction').id!,
    ) as Func;

    final report = await service.getSourceReport(
      isolateId,
      ['Coverage'],
      scriptId: func.location!.script!.id!,
      tokenPos: func.location!.tokenPos,
      endTokenPos: func.location!.endTokenPos,
      forceCompile: true,
    );
    expect(report.ranges!.length, 1);
    final range = report.ranges![0];
    expect(range.scriptIndex, 0);
    expect(range.startPos, 476);
    expect(range.endPos, 543);
    expect(range.compiled, true);
    final coverage = range.coverage!;
    expect(coverage.hits, const [476, 516, 527, 531]);
    expect(coverage.misses, isEmpty);
    expect(report.scripts!.length, 1);
    expect(
      report.scripts![0].uri,
      endsWith('coverage_optimized_function_test.dart'),
    );
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'coverage_optimized_function_test.dart',
      testeeConcurrent: testFunction,
    );
