// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=super-parameters

// @dart=2.17

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class S<T> {
  num? n;
  T? t;
  String constrName;
  S({this.n, this.t}) : constrName = "S";
  S.named({this.t, this.n}) : constrName = "S.named";
}

class C<T> extends S<T> {
  C.constr1(String s, {super.t});
  C.constr2(int i, String s, {super.n}) : super();
  C.constr3(int i, String s, {super.n, super.t}) : super.named() {
    debugger();
  }
}

class R<T> {
  final f1;
  var v1;
  num i1;
  T t1;
  R(this.f1, this.v1, this.i1, this.t1);
}

class B<T> extends R<T> {
  B(super.f1, super.v1, super.i1, super.t1) {
    debugger();
  }
}

void testMain() {
  debugger();
  C.constr3(1, 'abc', n: 3.14, t: 42);
  B('a', 3.14, 2.718, 42);
}

late final String isolateId;
late final String rootLibId;

createInstance(VmService service, String expr) async {
  return await service.evaluate(
      isolateId,
      rootLibId,
      expr,
      disableBreakpoints: true,
    );
}

evaluateGetter(VmService service, String instanceId, String getter) async {
  dynamic result = await service.evaluate(isolateId, instanceId, getter);
  return await service.getObject(isolateId, result.id);
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    // Initialization
    isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    rootLibId = isolate.rootLib!.id!;
  },
  (VmService service, _) async {
    dynamic instance = await createInstance(service, 'C.constr1("abc", t: 42)');
    dynamic result = await evaluateGetter(service, instance.id, 'n');
    expect(result.valueAsString, 'null');
    result = await evaluateGetter(service, instance.id, 't');
    expect(result.valueAsString, '42');
    result = await evaluateGetter(service, instance.id, 'constrName');
    expect(result.valueAsString, 'S');
    result = await service.evaluate(isolateId, instance.id, 'T');
    expect(result.json['name'], 'int');

    instance = await createInstance(service, 'C.constr1("abc", t: "42")');
    result = await evaluateGetter(service, instance.id, 'n');
    expect(result.valueAsString, 'null');
    result = await evaluateGetter(service, instance.id, 't');
    expect(result.valueAsString, '42');
    result = await evaluateGetter(service, instance.id, 'constrName');
    expect(result.valueAsString, 'S');
    result = await service.evaluate(isolateId, instance.id, 'T');
    expect(result.json['name'], 'String');
  },
  (VmService service, _) async {
    dynamic instance = await createInstance(service, 'C.constr2(1, "abc", n: 3.14)');
    dynamic result = await evaluateGetter(service, instance.id, 'n');
    expect(result.valueAsString, '3.14');
    result = await evaluateGetter(service, instance.id, 't');
    expect(result.valueAsString, 'null');
    result = await evaluateGetter(service, instance.id, 'constrName');
    expect(result.valueAsString, 'S');
    result = await service.evaluate(isolateId, instance.id, 'T');
    expect(result.json['name'], 'dynamic');

    instance = await createInstance(service, 'C.constr2(1, "abc", n: 2)');
    result = await evaluateGetter(service, instance.id, 'n');
    expect(result.valueAsString, '2');
    result = await evaluateGetter(service, instance.id, 't');
    expect(result.valueAsString, 'null');
    result = await evaluateGetter(service, instance.id, 'constrName');
    expect(result.valueAsString, 'S');
    result = await service.evaluate(isolateId, instance.id, 'T');
    expect(result.json['name'], 'dynamic');
  },
  (VmService service, _) async {
    dynamic instance = await createInstance(service, 'C.constr3(1, "abc", n: 42, t: 3.14)');
    dynamic result = await evaluateGetter(service, instance.id, 'n');
    expect(result.valueAsString, '42');
    result = await evaluateGetter(service, instance.id, 't');
    expect(result.valueAsString, '3.14');
    result = await evaluateGetter(service, instance.id, 'constrName');
    expect(result.valueAsString, 'S.named');
    result = await service.evaluate(isolateId, instance.id, 'T');
    expect(result.json['name'], 'double');

    instance = await createInstance(service, 'C.constr3(1, "abc", n: 3.14, t: 42)');
    result = await evaluateGetter(service, instance.id, 'n');
    expect(result.valueAsString, '3.14');
    result = await evaluateGetter(service, instance.id, 't');
    expect(result.valueAsString, '42');
    result = await evaluateGetter(service, instance.id, 'constrName');
    expect(result.valueAsString, 'S.named');
    result = await service.evaluate(isolateId, instance.id, 'T');
    expect(result.json['name'], 'int');
  },
  (VmService service, _) async {
    dynamic instance = await createInstance(service, 'B(1, 2, 3, 4)');
    dynamic result = await evaluateGetter(service, instance.id, 'f1');
    expect(result.valueAsString, '1');
    result = await evaluateGetter(service, instance.id, 'v1');
    expect(result.valueAsString, '2');
    result = await evaluateGetter(service, instance.id, 'i1');
    expect(result.valueAsString, '3');
    result = await evaluateGetter(service, instance.id, 't1');
    expect(result.valueAsString, '4');
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, _) async {
    dynamic result = await service.evaluateInFrame(isolateId, 0, 'n');
    expect(result.valueAsString, '3.14');
    result = await service.evaluateInFrame(isolateId, 0, 't');
    expect(result.valueAsString, '42');
    result = await service.evaluateInFrame(isolateId, 0, 'constrName');
    expect(result.valueAsString, 'S.named');
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, _) async {
    dynamic result = await service.evaluateInFrame(isolateId, 0, 'f1');
    expect(result.valueAsString, 'a');
    result = await service.evaluateInFrame(isolateId, 0, 'v1');
    expect(result.valueAsString, '3.14');
    result = await service.evaluateInFrame(isolateId, 0, 'i1');
    expect(result.valueAsString, '2.718');
    result = await service.evaluateInFrame(isolateId, 0, 't1');
    expect(result.valueAsString, '42');
  }
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'super_constructor_invocation_test.dart',
      testeeConcurrent: testMain,
      experiments: ['super-parameters'],
    );
