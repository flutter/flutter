// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/88104.
//
// Ensures that the `TypeArguments` register is correctly preserved when
// regenerating the allocation stub for generic classes after enabling
// allocation tracing.
import 'dart:async';
import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class Foo<T> {}

testMain() async {
  debugger();
  for (int i = 0; i < 10; ++i) {
    Foo<int>();
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;
    final rootLib = await service.getObject(isolateId, rootLibId) as Library;
    final fooCls = rootLib.classes!.first;
    await service.setTraceClassAllocation(isolateId, fooCls.id!, true);
  },
  resumeIsolate,
  hasStoppedAtExit,
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'regress_88104_test.dart',
      testeeConcurrent: testMain,
      pause_on_exit: true,
    );
