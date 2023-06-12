// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 25;
const int LINE_B = 28;
const int LINE_C = 31;

testFunction() {
  debugger();
  var a;
  try {
    var b;
    try {
      for (int i = 0; i < 10; i++) {
        var x = () => i + a + b;
        return x; // LINE_A
      }
    } finally {
      b = 10; // LINE_B
    }
  } finally {
    a = 1; // LINE_C
  }
}

testMain() {
  var f = testFunction();
  expect(f(), equals(11));
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  // Add breakpoint
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    Isolate isolate = await service.getIsolate(isolateId);
    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;

    final script =
        await service.getObject(isolateId, rootLib.scripts![0].id!) as Script;

    // Add 3 breakpoints.
    {
      final bpt = await service.addBreakpoint(isolateId, script.id!, LINE_A);
      expect(bpt.location!.script.id!, script.id);
      final tmpScript =
          await service.getObject(isolateId, script.id!) as Script;
      expect(
        tmpScript.getLineNumberFromTokenPos(bpt.location!.tokenPos),
        LINE_A,
      );
      isolate = await service.getIsolate(isolateId);
      expect(isolate.breakpoints!.length, 1);
    }

    {
      final bpt = await service.addBreakpoint(isolateId, script.id!, LINE_B);
      expect(bpt.location!.script.id, script.id);
      final tmpScript =
          await service.getObject(isolateId, script.id!) as Script;
      expect(
        tmpScript.getLineNumberFromTokenPos(bpt.location!.tokenPos),
        LINE_B,
      );
      isolate = await service.getIsolate(isolateId);
      expect(isolate.breakpoints!.length, 2);
    }

    {
      final bpt = await service.addBreakpoint(isolateId, script.id!, LINE_C);
      expect(bpt.location!.script.id, script.id!);
      final tmpScript =
          await service.getObject(isolateId, script.id!) as Script;
      expect(
        tmpScript.getLineNumberFromTokenPos(bpt.location!.tokenPos),
        LINE_C,
      );
      isolate = await service.getIsolate(isolateId);
      expect(isolate.breakpoints!.length, 3);
    }
    // Wait for breakpoint events.
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  // We are at the breakpoint on line LINE_A.
  (VmService service, IsolateRef isolateRef) async {
    final stack = await service.getStack(isolateRef.id!);
    expect(stack.frames!.length, greaterThanOrEqualTo(1));

    final script = await service.getObject(
        isolateRef.id!, stack.frames![0].location!.script!.id!) as Script;
    expect(
      script.getLineNumberFromTokenPos(stack.frames![0].location!.tokenPos!),
      LINE_A,
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  // We are at the breakpoint on line LINE_B.
  (VmService service, IsolateRef isolateRef) async {
    final stack = await service.getStack(isolateRef.id!);
    expect(stack.frames!.length, greaterThanOrEqualTo(1));

    final script = await service.getObject(
        isolateRef.id!, stack.frames![0].location!.script!.id!) as Script;
    expect(
      script.getLineNumberFromTokenPos(stack.frames![0].location!.tokenPos!),
      LINE_B,
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  // We are at the breakpoint on line LINE_C.
  (VmService service, IsolateRef isolateRef) async {
    final stack = await service.getStack(isolateRef.id!);
    expect(stack.frames!.length, greaterThanOrEqualTo(1));

    final script = await service.getObject(
        isolateRef.id!, stack.frames![0].location!.script!.id!) as Script;
    expect(
      script.getLineNumberFromTokenPos(stack.frames![0].location!.tokenPos!),
      LINE_C,
    );
  },
  resumeIsolate,
];

main(args) => runIsolateTests(
      args,
      tests,
      'debugging_inlined_finally_test.dart',
      testeeConcurrent: testMain,
    );
