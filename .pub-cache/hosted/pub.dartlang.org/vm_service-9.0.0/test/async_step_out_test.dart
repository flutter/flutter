// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 17;
const LINE_B = 18;
const LINE_C = 19;
const LINE_D = 24;
const LINE_E = 25;
const LINE_F = 26;

helper() async {
  await null; // LINE_A.
  print('helper'); // LINE_B.
  print('foobar'); // LINE_C.
}

testMain() async {
  debugger();
  print('mmmmm'); // LINE_D.
  await helper(); // LINE_E.
  print('z'); // LINE_F.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  asyncNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOut, // out of helper to awaiter testMain.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'async_step_out_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
