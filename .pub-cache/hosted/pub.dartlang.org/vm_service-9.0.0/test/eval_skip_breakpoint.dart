// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 22;
const int LINE_B = 17;

bar() {
  print('bar');
}

testMain() {
  debugger();
  bar();
  print("Done");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // Add breakpoint
  setBreakpointAtLine(LINE_B),
  // Evaluate 'bar()'
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    await service.evaluate(
      isolateRef.id!,
      isolate.rootLib!.id!,
      'bar()',
      disableBreakpoints: true,
    );
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'eval_skip_breakpoint.dart',
      testeeConcurrent: testMain,
    );
