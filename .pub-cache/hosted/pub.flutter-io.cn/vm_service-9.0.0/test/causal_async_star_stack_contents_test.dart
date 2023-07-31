// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 29;
const LINE_B = 21;
const LINE_C = 23;

foobar() async* {
  await 0; // force async gap
  debugger();
  yield 1; // LINE_B.
  debugger();
  yield 2; // LINE_C.
}

helper() async {
  await 0; // force async gap
  debugger();
  print('helper'); // LINE_A.
  await for (var i in foobar()) {
    print('helper $i');
  }
}

testMain() {
  helper();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // No causal frames because we are in a completely synchronous stack.
    expect(stack.asyncCausalFrames, isNotNull);
    final asyncStack = stack.asyncCausalFrames!;
    expect(asyncStack.length, greaterThanOrEqualTo(1));
    expect(asyncStack[0].function!.name, contains('helper'));
    // helper isn't awaited.
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // Has causal frames (we are inside an async function)
    expect(stack.asyncCausalFrames, isNotNull);
    final asyncStack = stack.asyncCausalFrames!;
    expect(asyncStack.length, greaterThanOrEqualTo(3));
    expect(asyncStack[0].function!.name, contains('foobar'));
    expect(asyncStack[1].kind, equals(FrameKind.kAsyncSuspensionMarker));
    expect(asyncStack[2].function!.name, contains('helper'));
    expect(asyncStack[3].kind, equals(FrameKind.kAsyncSuspensionMarker));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // Has causal frames (we are inside a function called by an async function)
    expect(stack.asyncCausalFrames, isNotNull);
    final asyncStack = stack.asyncCausalFrames!;
    expect(asyncStack.length, greaterThanOrEqualTo(4));
    final script = await service.getObject(
        isolateRef.id!, asyncStack[0].location!.script!.id!) as Script;
    expect(asyncStack[0].function!.name, contains('foobar'));
    expect(
      script.getLineNumberFromTokenPos(asyncStack[0].location!.tokenPos!),
      LINE_C,
    );
    expect(asyncStack[1].kind, equals(FrameKind.kAsyncSuspensionMarker));
    expect(asyncStack[2].function!.name, contains('helper'));
    expect(
      script.getLineNumberFromTokenPos(asyncStack[2].location!.tokenPos!),
      30,
    );
    expect(asyncStack[3].kind, equals(FrameKind.kAsyncSuspensionMarker));
  },
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      'causal_async_star_stack_contents_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
