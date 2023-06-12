// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 20;
const int LINE_B = 26;

foo() {}

doAsync(param1) async {
  var local1 = param1 + 1;
  foo(); // Line A.
  await local1;
}

doAsyncStar(param2) async* {
  var local2 = param2 + 1;
  foo(); // Line B.
  yield local2;
}

testeeDo() {
  debugger();

  doAsync(1).then((_) {
    doAsyncStar(1).listen((_) {});
  });
}

Future<void> checkAsyncVarDescriptors(
    VmService? service, IsolateRef? isolateRef) async {
  final isolateId = isolateRef!.id!;
  final stack = await service!.getStack(isolateId);
  expect(stack.frames!.length, greaterThanOrEqualTo(1));
  final frame = stack.frames![0];
  final vars = frame.vars!.map((v) => v.name).join(' ');
  expect(vars, 'param1 local1'); // no :async_op et al
}

Future checkAsyncStarVarDescriptors(
    VmService? service, IsolateRef? isolateRef) async {
  final isolateId = isolateRef!.id!;
  final stack = await service!.getStack(isolateId);
  expect(stack.frames!.length, greaterThanOrEqualTo(1));
  final frame = stack.frames![0];
  final vars = frame.vars!.map((v) => v.name).join(' ');
  expect(vars, 'param2 local2'); // no :async_op et al
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint, // debugger()
  setBreakpointAtLine(LINE_A),
  setBreakpointAtLine(LINE_B),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  checkAsyncVarDescriptors,
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  checkAsyncStarVarDescriptors,
  resumeIsolate,
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'async_scope_test.dart',
      testeeConcurrent: testeeDo,
    );
