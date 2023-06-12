// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void method(int value) {
    debugger();
  }
}

class _MyClass {
  void foo() {
    debugger();
  }
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.method(10000);
      (_MyClass()).foo();
    }
  }
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Evaluate against library, class, and instance.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(2));
    expect(stack.frames![0].function!.name, 'method');
    expect((stack.frames![0].function!.owner as ClassRef).name, 'MyClass');

    final LibraryRef lib = isolate.rootLib!;
    final ClassRef cls = stack.frames![0].function!.owner;
    final InstanceRef instance = stack.frames![0].vars![0].value;

    dynamic result =
        await service.evaluate(isolateId, lib.id!, 'globalVar + 5');
    print(result);
    expect(result.valueAsString, '105');

    await expectError(() =>
        service.evaluate(isolateId, lib.id!, 'globalVar + staticVar + 5'));

    result =
        await service.evaluate(isolateId, cls.id!, 'globalVar + staticVar + 5');
    print(result);
    expect(result.valueAsString, '1105');

    await expectError(() => service.evaluate(isolateId, cls.id!, 'this + 5'));

    result = await service.evaluate(isolateId, instance.id!, 'this + 5');
    print(result);
    expect(result.valueAsString, '10005');

    await expectError(
        () => service.evaluate(isolateId, instance.id!, 'this + frog'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolate) async {
    final isolateId = isolate.id!;
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(2));
    expect(stack.frames![0].function!.name, 'foo');
    expect((stack.frames![0].function!.owner as ClassRef).name, '_MyClass');

    final ClassRef cls = stack.frames![0].function!.owner;

    final InstanceRef result =
        await service.evaluate(isolateId, cls.id!, "1+1") as InstanceRef;
    print(result);
    expect(result.valueAsString, "2");
  }
];

expectError(func) async {
  bool gotException = false;
  dynamic result;
  try {
    result = await func();
    fail('Failed to throw');
  } on RPCError catch (e) {
    expect(e.code, 113); // Compile time error.
    gotException = true;
  }
  if (result?.type != 'Error') {
    expect(gotException, true); // dart2 semantics
  }
}

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'eval_test.dart',
      testeeConcurrent: testFunction,
    );
