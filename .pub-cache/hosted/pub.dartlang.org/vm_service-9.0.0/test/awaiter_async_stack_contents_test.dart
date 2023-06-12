// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_C = 22;
const LINE_A = 28;
const LINE_B = 34;
const LINE_D = 29;

foobar() async {
  await null;
  debugger();
  print('foobar'); // LINE_C.
}

helper() async {
  await null;
  debugger();
  print('helper'); // LINE_A.
  await foobar(); // LINE_D
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
    // No awaiter frames because we are in a completely synchronous stack.
    expect(stack.awaiterFrames, isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (VmService service, IsolateRef isolateRef) async {
    // Verify awaiter stack trace is the current frame + the awaiter.
    Stack stack = await service.getStack(isolateRef.id!);
    expect(stack.awaiterFrames, isNotNull);
    List<Frame> awaiterFrames = stack.awaiterFrames!;

    expect(awaiterFrames.length, greaterThanOrEqualTo(2));
    // Awaiter frame.
    expect(await awaiterFrames[0].function!.name, 'foobar');
    // Awaiter frame.
    expect(await awaiterFrames[1].function!.name, 'helper');
    // "helper" is not await'ed.
  },
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      'awaiter_async_stack_contents_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
