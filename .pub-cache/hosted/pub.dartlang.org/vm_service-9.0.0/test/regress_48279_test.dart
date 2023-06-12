// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that generic type argument ('T') can be evaluated
// when stopped on an exception which is thrown during type check in
// the implicit field setter.
// Regression test for https://github.com/dart-lang/sdk/issues/48279.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class A<T, U, V> {
  List<T> foo = [];
}

testeeMain() {
  A<num, Object, Object> object = A<int, String, String>();
  object.foo = <double>[];
}

var tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  (VmService? service, IsolateRef? isolateRef) async {
    print("We stopped!");
    final isolateId = isolateRef!.id!;
    final stack = await service!.getStack(isolateId);
    final topFrame = stack.frames![0];
    expect(topFrame.function!.name, equals('foo='));
    final result = await service.evaluateInFrame(isolateId, 0, 'T');
    print(result);
    expect((result as InstanceRef).name, equals("int"));
  }
];

main(args) => runIsolateTests(
      args,
      tests,
      'regress_48279_test.dart',
      pause_on_unhandled_exceptions: true,
      testeeConcurrent: testeeMain,
    );
