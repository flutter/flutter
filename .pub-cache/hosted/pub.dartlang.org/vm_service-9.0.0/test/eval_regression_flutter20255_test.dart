// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class Base<T> {
  String field;

  Base(this.field);
  String foo() => 'Base-$field';
}

class Sub<T> extends Base<T> {
  String field;

  Sub(this.field) : super(field);
  String foo() {
    debugger();
    return 'Sub-$field';
  }
}

class ISub<T> implements Base<T> {
  String field;

  ISub(this.field);
  String foo() => 'ISub-$field';
}

class Box<T> {
  late T value;

  @pragma('vm:never-inline')
  void setValue(T value) {
    this.value = value;
  }
}

final objects = <Base>[Base<int>('b'), Sub<double>('a'), ISub<bool>('c')];

String triggerTypeTestingStubGeneration() {
  final Box<Object> box = Box<Base>();
  for (int i = 0; i < 1000000; ++i) {
    box.setValue(objects.last);
  }
  return 'tts-generated';
}

void testFunction() {
  // Triggers the debugger, which will evaluate an expression in the context of
  // [Sub<double>], which will make a subclass of [Base<T>].
  print(objects[1].foo());

  triggerTypeTestingStubGeneration();

  // Triggers the debugger, which will evaluate an expression in the context of
  // [Sub<double>], which will make a subclass of [Base<T>].
  print(objects[1].foo());
}

Future triggerEvaluation(VmService service, IsolateRef isolateRef) async {
  Stack stack = await service.getStack(isolateRef.id!);

  // Make sure we are in the right place.
  expect(stack.frames!.length, greaterThanOrEqualTo(2));
  expect(stack.frames![0].function!.name, 'foo');
  expect(stack.frames![0].function!.owner.name, 'Sub');

  // Trigger an evaluation, which will create a subclass of Base<T>.
  final dynamic result = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'this.field + " world \$T"',
  );
  expect(result.valueAsString, 'a world double');

  // Trigger an optimization of a type testing stub (and usage of it).
  final dynamic result2 = await service.evaluateInFrame(
    isolateRef.id!,
    0,
    'triggerTypeTestingStubGeneration()',
  );
  expect(result2.valueAsString, 'tts-generated');
}

final testSteps = <IsolateTest>[
  hasStoppedAtBreakpoint,
  triggerEvaluation,
  resumeIsolate,
  hasStoppedAtBreakpoint,
  triggerEvaluation,
  resumeIsolate,
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      testSteps,
      'eval_regression_flutter20255_test.dart',
      testeeConcurrent: testFunction,
    );
