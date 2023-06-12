// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

// TODO(bkonyi): consider deleting now that DBC is no more.
// This test was mostly interesting for DBC, which needed to patch two bytecodes
// to create a breakpoint for fast Smi ops.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_A = 29;
const int LINE_B = 30;
const int LINE_C = 31;

class NotGeneric {}

testeeMain() {
  final x = List<dynamic>.filled(1, null);
  final y = 7;
  debugger();
  print("Statement");
  x[0] = 3; // Line A.
  x is NotGeneric; // Line B.
  y & 4; // Line C.
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Add breakpoints.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    Library rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;

    final script =
        await service.getObject(isolateId, rootLib.scripts![0].id!) as Script;
    final scriptId = script.id!;

    final bpt1 = await service.addBreakpoint(isolateId, scriptId, LINE_A);
    print(bpt1);
    expect(bpt1.resolved, isTrue);
    expect(script.getLineNumberFromTokenPos(bpt1.location!.tokenPos),
        equals(LINE_A));

    final bpt2 = await service.addBreakpoint(isolateId, scriptId, LINE_B);
    print(bpt2);
    expect(bpt2.resolved, isTrue);
    expect(script.getLineNumberFromTokenPos(bpt2.location!.tokenPos),
        equals(LINE_B));

    final bpt3 = await service.addBreakpoint(isolateId, scriptId, LINE_C);
    print(bpt3);
    expect(bpt3.resolved, isTrue);
    expect(script.getLineNumberFromTokenPos(bpt3.location!.tokenPos),
        equals(LINE_C));
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
];

main(args) => runIsolateTests(
      args,
      tests,
      'breakpoint_two_args_checked_test.dart',
      testeeConcurrent: testeeMain,
    );
