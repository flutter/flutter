// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  final a = A<C>();
  print(a.runtimeType);
  debugger();
}

class A<T> {
  A();
}

class B<T> {
  final T data;
  B(this.data);
}

class C extends B<C> {
  C(C data) : super(data);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Evaluate against top frame.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var topFrame = 0;
    final dynamic result = await service.evaluateInFrame(
        isolateId, topFrame, 'a.runtimeType.toString()');
    print(result);
    expect(result.valueAsString, equals("A<C>"));
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'eval_issue_49209_test.dart',
      testeeConcurrent: testFunction,
    );
