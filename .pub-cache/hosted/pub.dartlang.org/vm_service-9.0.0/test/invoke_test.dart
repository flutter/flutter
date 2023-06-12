// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

libraryFunction() => "foobar1";

class Klass {
  static classFunction(x) => "foobar2" + x;
  instanceFunction(x, y) => "foobar3" + x + y;
}

var instance;

var apple;
var banana;

void testFunction() {
  instance = Klass();
  apple = "apple";
  banana = "banana";
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final Library lib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final cls = lib.classes!.singleWhere((cls) => cls.name == "Klass");
    FieldRef fieldRef =
        lib.variables!.singleWhere((field) => field.name == "instance");
    Field field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final instance = await service.getObject(isolateId, field.staticValue!.id!);

    fieldRef = lib.variables!.singleWhere((field) => field.name == "apple");
    field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final apple = await service.getObject(isolateId, field.staticValue!.id!);
    fieldRef = lib.variables!.singleWhere((field) => field.name == "banana");
    field = await service.getObject(isolateId, fieldRef.id!) as Field;
    Instance banana =
        await service.getObject(isolateId, field.staticValue!.id!) as Instance;

    dynamic result =
        await service.invoke(isolateId, lib.id!, 'libraryFunction', []);
    expect(result.valueAsString, equals('foobar1'));

    result =
        await service.invoke(isolateId, cls.id!, "classFunction", [apple.id!]);
    expect(result.valueAsString, equals('foobar2apple'));

    result = await service.invoke(
        isolateId, instance.id!, "instanceFunction", [apple.id!, banana.id!]);
    expect(result.valueAsString, equals('foobar3applebanana'));

    // Wrong arity.
    await expectError(() => service
        .invoke(isolateId, instance.id!, "instanceFunction", [apple.id!]));
    // No such target.
    await expectError(() => service
        .invoke(isolateId, instance.id!, "functionDoesNotExist", [apple.id!]));
  },
  resumeIsolate,
];

expectError(func) async {
  dynamic result = await func();
  expect(result.type == 'Error' || result.type == '@Error', isTrue);
}

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'invoke_test.dart',
      testeeConcurrent: testFunction,
    );
