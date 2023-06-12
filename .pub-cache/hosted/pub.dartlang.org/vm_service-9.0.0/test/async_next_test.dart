// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 18;
const int LINE_B = 19;
const int LINE_C = 20;

foo() async {}

doAsync(stop) async {
  if (stop) debugger();
  await foo(); // Line A.
  await foo(); // Line B.
  await foo(); // Line C.
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
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver, // foo()
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'async_next_test.dart',
      testeeConcurrent: testMain,
    );
