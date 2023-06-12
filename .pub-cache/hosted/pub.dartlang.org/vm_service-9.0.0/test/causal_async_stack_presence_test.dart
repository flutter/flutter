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

const LINE_C = 19;
const LINE_A = 25;
const LINE_B = 31;

foobar() {
  debugger();
  print('foobar'); // LINE_C.
}

helper() async {
  await 0; // Yield. The rest will run async.
  debugger();
  print('helper'); // LINE_A.
  foobar();
}

testMain() {
  debugger();
  helper(); // LINE_B.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // No causal frames because we are in a completely synchronous stack.
    // Async function hasn't yielded yet.
    expect(stack.asyncCausalFrames, isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // Async function has yielded once, so it's now running async.
    expect(stack.asyncCausalFrames, isNotNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // Has causal frames (we are inside a function called by an async function)
    expect(stack.asyncCausalFrames, isNotNull);
  },
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      'causal_async_stack_presence_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
