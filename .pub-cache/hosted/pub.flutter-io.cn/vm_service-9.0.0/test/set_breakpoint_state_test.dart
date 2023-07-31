// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 17;
const int LINE_B = LINE_A + 1;

testMain() {
  while (true) {
    print('a'); // LINE_A
    print('b'); // LINE_B
  }
}

late Breakpoint bpt;

var tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    bpt = await service.addBreakpointWithScriptUri(
      isolateRef.id!,
      'set_breakpoint_state_test.dart',
      LINE_A,
    );
    expect(bpt.enabled, true);
  },
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    bpt = await service.setBreakpointState(
      isolateRef.id!,
      bpt.id!,
      false,
    );
    expect(bpt.enabled, false);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    bpt = await service.setBreakpointState(
      isolateRef.id!,
      bpt.id!,
      true,
    );
    expect(bpt.enabled, true);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'set_breakpoint_state_test.dart',
      pause_on_start: true,
      testeeConcurrent: testMain,
    );
