// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 28;
const LINE_B = 34;
const LINE_C = 38;

notCalled() async {
  await null;
  await null;
  await null;
  await null;
}

foobar() async {
  await null;
  debugger();
  print('foobar'); // LINE_A.
}

helper() async {
  await null;
  print('helper');
  await foobar(); // LINE_B.
}

testMain() async {
  helper(); // LINE_C.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolate) async {
    final isolateId = isolate.id!;
    // Verify awaiter stack trace is the current frame + the awaiter.
    Stack stack = await service.getStack(isolateId);
    expect(stack.awaiterFrames, isNotNull);
    List<Frame> awaiterFrames = stack.awaiterFrames!;
    expect(awaiterFrames.length, greaterThanOrEqualTo(2));
    // Awaiter frame.
    expect(awaiterFrames[0].function!.name, 'foobar');
    // Awaiter frame.
    expect(awaiterFrames[1].function!.name, 'helper');
  },
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      'awaiter_async_stack_contents_2_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
