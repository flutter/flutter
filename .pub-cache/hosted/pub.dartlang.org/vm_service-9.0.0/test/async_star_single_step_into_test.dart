// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 18;
const LINE_B = 19;
const LINE_C = 23;
const LINE_D = 27;
const LINE_E = 33;
const LINE_F = 34;
const LINE_G = 25;

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
  // ignore: unused_local_variable
  await for (var i in foobar()) /* LINE_G. */ {
    debugger();
    print('loop'); // LINE_D.
  }
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_E.
  helper(); // LINE_F.
  print('z');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_G), // foobar()
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_G), // await for
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // Resume here to exit the generator function.
  // TODO(johnmccutchan): Implement support for step-out of async functions.
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_G),
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main([args = const <String>[]]) => runIsolateTestsSynchronous(
      args,
      tests,
      'async_star_single_step_into_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
