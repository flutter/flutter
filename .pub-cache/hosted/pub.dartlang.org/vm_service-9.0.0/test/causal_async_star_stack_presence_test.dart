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

const LINE_A = 26;
const LINE_B = 19;
const LINE_C = 21;

foobar() async* {
  debugger();
  yield 1; // LINE_B.
  debugger();
  yield 2; // LINE_C.
}

helper() async {
  debugger();
  print('helper'); // LINE_A.
  await for (var i in foobar()) {
    print('helper $i');
  }
}

testMain() {
  helper();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // No causal frames because we are in a completely synchronous stack.
    expect(stack.asyncCausalFrames, isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // Has causal frames (we are inside an async function)
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
      'causal_async_star_stack_presence_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
