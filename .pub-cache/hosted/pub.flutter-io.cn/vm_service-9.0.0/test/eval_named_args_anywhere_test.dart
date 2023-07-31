// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.17
// ignore_for_file: unused_element

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

int foo(int a, {required int b}) {
  return a - b;
}

class _MyClass {
  int foo(int a, {required int b}) {
    return a - b;
  }

  static int baz(int a, {required int b}) {
    return a - b;
  }
}

void testFunction() {
  debugger();
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);

    final rootLibId = isolate.rootLib!.id!;

    // Evaluate top-level function
    var result = await service.evaluate(
      isolateId,
      rootLibId,
      'foo(b: 10, 50)',
    ) as InstanceRef;
    expect(result.valueAsString, '40');

    // Evaluate class instance method
    result = await service.evaluate(
      isolateId,
      rootLibId,
      '_MyClass().foo(b: 10, 50)',
    ) as InstanceRef;
    expect(result.valueAsString, '40');

    // Evaluate static method
    result = await service.evaluate(
      isolateId,
      rootLibId,
      '_MyClass.baz(b: 10, 50)',
    ) as InstanceRef;
    expect(result.valueAsString, '40');
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'eval_named_args_anywhere_test.dart',
      testeeConcurrent: testFunction,
      experiments: ['named-arguments-anywhere'],
    );
