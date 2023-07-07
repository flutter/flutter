// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that expressions evaluated in a frame see the same scope as the
// frame's method.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'evaluate_activation_in_method_class_other.dart';

var topLevel = "TestLibrary";

class Subclass extends Superclass1 {
  var _instVar = 'Subclass';
  var instVar = 'Subclass';
  method() => 'Subclass';
  static staticMethod() => 'Subclass';
  suppress_warning() => _instVar;
}

testeeDo() {
  var obj = Subclass();
  obj.test();
}

Future testerDo(VmService service, IsolateRef isolateRef) async {
  await hasStoppedAtBreakpoint(service, isolateRef);
  final isolateId = isolateRef.id!;

  // Make sure we are in the right place.
  var stack = await service.getStack(isolateId);
  var topFrame = 0;
  expect(
    stack.frames![topFrame].function!.name,
    equals('test'),
  );
  expect(
    stack.frames![topFrame].function!.owner.name,
    equals('Superclass1'),
  );

  InstanceRef result;

  result = await service.evaluateInFrame(isolateId, topFrame, '_local')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Superclass1'));

  result = await service.evaluateInFrame(isolateId, topFrame, '_instVar')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Superclass1'));

  result = await service.evaluateInFrame(isolateId, topFrame, 'instVar')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Subclass'));

  result = await service.evaluateInFrame(isolateId, topFrame, 'method()')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Subclass'));

  result = await service.evaluateInFrame(isolateId, topFrame, 'super._instVar')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Superclass2'));

  result = await service.evaluateInFrame(isolateId, topFrame, 'super.instVar')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Superclass2'));

  result = await service.evaluateInFrame(isolateId, topFrame, 'super.method()')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Superclass2'));

  result = await service.evaluateInFrame(isolateId, topFrame, 'staticMethod()')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('Superclass1'));

  // function.Owner verus function.Origin
  // The mixin of Superclass is in _other.dart and the mixin
  // application is in _test.dart.
  result = await service.evaluateInFrame(isolateId, topFrame, 'topLevel')
      as InstanceRef;
  print(result);
  expect(result.valueAsString, equals('OtherLibrary'));
}

main([args = const <String>[]]) => runIsolateTests(
      args,
      [testerDo],
      'evaluate_activation_in_method_class_test.dart',
      testeeConcurrent: testeeDo,
    );
