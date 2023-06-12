// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 17; // LINE_A - 4
const int LINE_B = 25; // LINE_A - 3

class Bar {
  static const String field = "field"; // LINE_A
}

Future<String> fooAsync(int x) async {
  if (x == 42) {
    return '*' * x;
  }
  return List.generate(x, (_) => 'xyzzy').join(' ');
} // LINE_B

Future<void> testFunction() async {
  await Future.delayed(Duration(milliseconds: 500));
  // ignore: unawaited_futures
  fooAsync(42).then((_) {});
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
    // Async closure of testFunction
    expect(stack.frames![0].function!.name, 'testFunction');

    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final script = await service.getObject(
        isolateId, rootLib.scripts!.first.id!) as Script;

    final report = await service.getSourceReport(
      isolateId,
      ['Coverage'],
      scriptId: script.id!,
      forceCompile: true,
    );
    int match = 0;
    for (var range in report.ranges!) {
      for (int i in range.coverage!.hits!) {
        int? line = script.getLineNumberFromTokenPos(i);
        if (line == null) {
          throw FormatException('token ${i} was missing source location');
        }
        // Check LINE.
        if (line == LINE_A || line == LINE_A - 3 || line == LINE_A - 4) {
          match = match + 1;
        }
        // _clearAsyncThreadStackTrace should have an invalid token position.
        expect(line, isNot(LINE_B));
      }
    }
    // Neither LINE nor Bar.field should be added into coverage.
    expect(match, 0);
  },
  resumeIsolate
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'coverage_const_field_async_closure_test.dart',
      testeeConcurrent: testFunction,
    );
