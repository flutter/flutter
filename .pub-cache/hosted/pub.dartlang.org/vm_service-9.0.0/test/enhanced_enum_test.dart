// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=enhanced-enums

// @dart=2.17

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class I1 {
  int interfaceMethod1() => 0;
  int get interfaceGetter1 => 0;
  set interfaceSetter1(int value) {}
}

abstract class I2 {
  int interfaceMethod2();
  int get interfaceGetter2;
  set interfaceSetter2(int value);
}

mixin M on Object {
  int mixedInMethod() => 42;
}

enum E with M implements I1, I2 {
  e1,
  e2,
  e3;

  int interfaceMethod1() => 42;
  int get interfaceGetter1 => 42;
  set interfaceSetter1(int value) {}
  int interfaceMethod2() => 42;
  int get interfaceGetter2 => 42;
  set interfaceSetter2(int value) {}

  static int staticMethod() => 42;
  static int get staticGetter => _staticField;
  static set staticSetter(int x) => _staticField = x;
  static int _staticField = 0;
}

enum F<T> {
  f1<int>(1),
  f2('foo'),
  f3(<String, dynamic>{});

  const F(this.value);

  void debugMethod() {
    debugger();
  }

  final T value;

  String toString() => 'OVERRIDE ${value.toString()}';
}

void testMain() {
  debugger();
  F.f1.debugMethod();
}

Future<void> expectError(func) async {
  bool gotException = false;
  try {
    await func();
    fail('Failed to throw');
  } on RPCError catch (e) {
    expect(e.code, 113); // Compile time error.
    gotException = true;
  }
  expect(gotException, true);
}

late final String isolateId;
late final Isolate isolate;
late final String rootLibraryId;
late final Class enumECls;
late final String enumEClsId;
late final Class enumFCls;
late final String enumFClsId;

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    // Initialization.
    isolateId = isolateRef.id!;
    isolate = await service.getIsolate(isolateId);
    rootLibraryId = isolate.rootLib!.id!;
    final rootLibrary = await service.getObject(
      isolateId,
      rootLibraryId,
    ) as Library;

    final enumERef = rootLibrary.classes!.firstWhere((c) => c.name == 'E');
    enumECls = await service.getObject(isolateId, enumERef.id!) as Class;
    enumEClsId = enumECls.id!;

    final enumFRef = rootLibrary.classes!.firstWhere((c) => c.name == 'F');
    enumFCls = await service.getObject(isolateId, enumFRef.id!) as Class;
    enumFClsId = enumFCls.id!;
  },
  (VmService service, _) async {
    // Check all functions and fields are found.
    expect(
      enumECls.functions!.map((f) => f.name),
      containsAll([
        'e1',
        'e2',
        'e3',
        'values',
        'toString',
        'interfaceSetter1=',
        'interfaceGetter1',
        'interfaceSetter2=',
        'interfaceGetter2',
        'interfaceMethod1',
        'interfaceMethod2',
        'staticGetter',
        'staticSetter=',
      ]),
    );
    expect(
      enumECls.fields!.map((f) => f.name),
      containsAll([
        'e1',
        'e2',
        'e3',
        'values',
        '_staticField',
      ]),
    );
  },
  (VmService service, _) async {
    // Ensure attempting to create an instance of an Enum fails.
    await expectError(() => service.evaluate(isolateId, rootLibraryId, 'E()'));
    await expectError(
      () => service.evaluate(isolateId, rootLibraryId, 'E(10, "staticGetter")'),
    );
  },
  (VmService service, _) async {
    // Ensure we can evaluate enum values in the context of the enum Class.
    dynamic result = await service.evaluate(isolateId, enumEClsId, 'e1');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'E');
    result = await service.evaluate(isolateId, result.id!, 'name');
    expect(result.valueAsString, 'e1');

    result = await service.evaluate(isolateId, enumEClsId, 'e2');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'E');
    result = await service.evaluate(isolateId, result.id!, 'name');
    expect(result.valueAsString, 'e2');

    result = await service.evaluate(isolateId, enumEClsId, 'e3');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'E');
    result = await service.evaluate(isolateId, result.id!, 'name');
    expect(result.valueAsString, 'e3');
  },
  (VmService service, _) async {
    // Ensure we can evaluate enum values in the context of the library.
    dynamic result = await service.evaluate(isolateId, rootLibraryId, 'E.e1');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'E');
    result = await service.evaluate(isolateId, result.id!, 'name');
    expect(result.valueAsString, 'e1');

    result = await service.evaluate(isolateId, rootLibraryId, 'E.e2');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'E');
    result = await service.evaluate(isolateId, result.id!, 'name');
    expect(result.valueAsString, 'e2');

    result = await service.evaluate(isolateId, rootLibraryId, 'E.e3');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'E');
    result = await service.evaluate(isolateId, result.id!, 'name');
    expect(result.valueAsString, 'e3');
  },
  (VmService service, _) async {
    // Ensure we can evaluate instance getters and methods.
    dynamic e1 = await service.evaluate(isolateId, enumEClsId, 'e1');
    expect(e1, isA<InstanceRef>());
    final e1Id = e1.id!;

    dynamic result = await service.evaluate(isolateId, e1Id, 'interfaceGetter1');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.evaluate(isolateId, e1Id, 'interfaceGetter2');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.evaluate(isolateId, e1Id, 'interfaceMethod1()');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.evaluate(isolateId, e1Id, 'interfaceMethod2()');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.evaluate(isolateId, e1Id, 'mixedInMethod()');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.evaluate(isolateId, e1Id, 'toString()');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, 'E.e1');
  },
  (VmService service, _) async {
    // Ensure we can evaluate static getters and methods.
    dynamic result = await service.evaluate(isolateId, enumEClsId, 'staticGetter');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '0');

    result = await service.evaluate(isolateId, enumEClsId, 'staticMethod()');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');
  },
  (VmService service, _) async {
    // Ensure we can invoke instance methods.
    dynamic e1 = await service.evaluate(isolateId, enumEClsId, 'e1');
    expect(e1, isA<InstanceRef>());
    final e1Id = e1.id!;

    dynamic result = await service.invoke(isolateId, e1Id, 'interfaceMethod1', []);
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.invoke(isolateId, e1Id, 'interfaceMethod2', []);
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.invoke(isolateId, e1Id, 'mixedInMethod', []);
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');

    result = await service.invoke(isolateId, e1Id, 'toString', []);
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, 'E.e1');
  },
  (VmService service, _) async {
    // Ensure we can invoke static methods.
    dynamic result = await service.evaluate(isolateId, enumEClsId, 'staticMethod()');
    expect(result, isA<InstanceRef>());
    expect(result.valueAsString, '42');
  },
  (VmService service, _) async {
    // Ensure we can evaluate enums user defined properties.
    dynamic result = await service.evaluate(isolateId, rootLibraryId, 'F.f1');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'F');
    result = await service.evaluate(isolateId, result.id!, 'value');
    expect(result.valueAsString, '1');

    result = await service.evaluate(isolateId, rootLibraryId, 'F.f2');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'F');
    result = await service.evaluate(isolateId, result.id!, 'value');
    expect(result.valueAsString, 'foo');

    result = await service.evaluate(isolateId, rootLibraryId, 'F.f3');
    expect(result, isA<InstanceRef>());
    expect(result.classRef.name, 'F');
    result = await service.evaluate(isolateId, result.id!, 'value');
    expect(result.kind, 'Map');
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, _) async {
    dynamic result = await service.evaluateInFrame(isolateId, 0, 'T.toString()');
    expect(result.valueAsString, 'int');

    result = await service.evaluateInFrame(isolateId, 0, 'value');
    expect(result.kind, 'Int');
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'enhanced_enum_test.dart',
      testeeConcurrent: testMain,
      experiments: ['enhanced-enums'],
    );
