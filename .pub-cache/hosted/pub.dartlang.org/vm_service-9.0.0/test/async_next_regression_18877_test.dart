// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 24;
const int LINE_B = 25;
const int LINE_C = 26;

foo() async {}

doAsync(stop) async {
  // Flutter issue 18877:
  // If a closure is defined in the context of an async method, stepping over
  // an await causes the implicit breakpoint to be set for that closure instead
  // of the async_op, resulting in the debugger falling through.
  final baz = () => print('doAsync($stop) done!');
  if (stop) debugger();
  await foo(); // Line A.
  await foo(); // Line B.
  await foo(); // Line C.
  baz();
  return null;
}

testMain() {
  // With two runs of doAsync floating around, async step should only cause
  // us to stop in the run we started in.
  doAsync(false);
  doAsync(true);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver, // foo()
  stoppedAtLine(LINE_A),
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver, // foo()
  stoppedAtLine(LINE_B),
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
];

main(args) => runIsolateTests(
      args,
      tests,
      'async_next_regression_18877_test.dart',
      testeeConcurrent: testMain,
    );
